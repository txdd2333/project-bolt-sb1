import express, { Request, Response, NextFunction } from 'express'
import cors from 'cors'
import mysql from 'mysql2/promise'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'
import fs from 'fs'
import path from 'path'
import multer from 'multer'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const app = express()
const PORT = process.env.PORT || 3000

app.use(cors())
app.use(express.json())

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production'
const JWT_EXPIRES_IN = '7d'

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_DATABASE || 'ops_workflow_center',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
})

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '../uploads')
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true })
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const bucket = req.body.bucket || 'default'
    const bucketPath = path.join(UPLOAD_DIR, bucket)
    if (!fs.existsSync(bucketPath)) {
      fs.mkdirSync(bucketPath, { recursive: true })
    }
    cb(null, bucketPath)
  },
  filename: (req, file, cb) => {
    const customPath = req.body.path || `${Date.now()}-${file.originalname}`
    cb(null, customPath)
  },
})

const upload = multer({ storage })

interface AuthRequest extends Request {
  userId?: string
}

const authenticateToken = (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization']
  const token = authHeader && authHeader.split(' ')[1]

  if (!token) {
    return res.status(401).json({ message: 'Authentication required' })
  }

  jwt.verify(token, JWT_SECRET, (err: any, decoded: any) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid or expired token' })
    }
    req.userId = decoded.userId
    next()
  })
}

app.post('/api/auth/register', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' })
    }

    const [existingUsers] = await pool.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    )

    if (Array.isArray(existingUsers) && existingUsers.length > 0) {
      return res.status(400).json({ message: 'User already exists' })
    }

    const passwordHash = await bcrypt.hash(password, 10)
    const userId = crypto.randomUUID()

    await pool.query(
      'INSERT INTO users (id, email, password_hash, created_at) VALUES (?, ?, ?, NOW())',
      [userId, email, passwordHash]
    )

    const accessToken = jwt.sign({ userId, email }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN })
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()

    res.json({
      user: { id: userId, email },
      access_token: accessToken,
      refresh_token: accessToken,
      expires_at: expiresAt,
    })
  } catch (error) {
    console.error('Register error:', error)
    res.status(500).json({ message: 'Internal server error' })
  }
})

app.post('/api/auth/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' })
    }

    const [users] = await pool.query(
      'SELECT id, email, password_hash FROM users WHERE email = ?',
      [email]
    )

    if (!Array.isArray(users) || users.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' })
    }

    const user = users[0] as any
    const isValid = await bcrypt.compare(password, user.password_hash)

    if (!isValid) {
      return res.status(401).json({ message: 'Invalid credentials' })
    }

    await pool.query(
      'UPDATE users SET last_login = NOW() WHERE id = ?',
      [user.id]
    )

    const accessToken = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN })
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()

    res.json({
      user: { id: user.id, email: user.email },
      access_token: accessToken,
      refresh_token: accessToken,
      expires_at: expiresAt,
    })
  } catch (error) {
    console.error('Login error:', error)
    res.status(500).json({ message: 'Internal server error' })
  }
})

app.get('/api/data/:table', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { table } = req.params
    const userId = req.userId

    const allowedTables = ['modules', 'workflows', 'scenarios', 'execution_logs']
    if (!allowedTables.includes(table)) {
      return res.status(400).json({ message: 'Invalid table name' })
    }

    let query = `SELECT * FROM ${table} WHERE user_id = ?`
    const params: any[] = [userId]

    if (req.query.order) {
      const [column, direction] = (req.query.order as string).split(':')
      query += ` ORDER BY ${column} ${direction.toUpperCase()}`
    }

    if (req.query.limit) {
      query += ` LIMIT ?`
      params.push(parseInt(req.query.limit as string))
    }

    if (req.query.offset) {
      query += ` OFFSET ?`
      params.push(parseInt(req.query.offset as string))
    }

    const [rows] = await pool.query(query, params)

    res.json({ data: rows })
  } catch (error) {
    console.error('Query error:', error)
    res.status(500).json({ message: 'Internal server error' })
  }
})

app.post('/api/data/:table', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { table } = req.params
    const userId = req.userId
    const { data } = req.body

    const allowedTables = ['modules', 'workflows', 'scenarios', 'execution_logs']
    if (!allowedTables.includes(table)) {
      return res.status(400).json({ message: 'Invalid table name' })
    }

    const records = Array.isArray(data) ? data : [data]
    const insertedRecords = []

    for (const record of records) {
      const id = crypto.randomUUID()
      const recordWithMeta = {
        ...record,
        id,
        user_id: userId,
        created_at: new Date(),
      }

      const columns = Object.keys(recordWithMeta)
      const values = Object.values(recordWithMeta)
      const placeholders = columns.map(() => '?').join(', ')

      await pool.query(
        `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${placeholders})`,
        values
      )

      insertedRecords.push(recordWithMeta)
    }

    res.json({ data: insertedRecords })
  } catch (error) {
    console.error('Insert error:', error)
    res.status(500).json({ message: 'Internal server error' })
  }
})

app.put('/api/data/:table/:id', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { table, id } = req.params
    const userId = req.userId
    const { data } = req.body

    const allowedTables = ['modules', 'workflows', 'scenarios', 'execution_logs']
    if (!allowedTables.includes(table)) {
      return res.status(400).json({ message: 'Invalid table name' })
    }

    const updates = Object.entries(data)
      .filter(([key]) => key !== 'id' && key !== 'user_id')
      .map(([key]) => `${key} = ?`)
      .join(', ')

    const values = Object.entries(data)
      .filter(([key]) => key !== 'id' && key !== 'user_id')
      .map(([, value]) => value)

    values.push(id, userId)

    await pool.query(
      `UPDATE ${table} SET ${updates}, updated_at = NOW() WHERE id = ? AND user_id = ?`,
      values
    )

    const [rows] = await pool.query(
      `SELECT * FROM ${table} WHERE id = ? AND user_id = ?`,
      [id, userId]
    )

    res.json({ data: Array.isArray(rows) && rows.length > 0 ? rows[0] : null })
  } catch (error) {
    console.error('Update error:', error)
    res.status(500).json({ message: 'Internal server error' })
  }
})

app.delete('/api/data/:table/:id', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { table, id } = req.params
    const userId = req.userId

    const allowedTables = ['modules', 'workflows', 'scenarios', 'execution_logs']
    if (!allowedTables.includes(table)) {
      return res.status(400).json({ message: 'Invalid table name' })
    }

    await pool.query(
      `DELETE FROM ${table} WHERE id = ? AND user_id = ?`,
      [id, userId]
    )

    res.json({ success: true })
  } catch (error) {
    console.error('Delete error:', error)
    res.status(500).json({ message: 'Internal server error' })
  }
})

app.post('/api/storage/upload', authenticateToken, upload.single('file'), (req: AuthRequest, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' })
    }

    const bucket = req.body.bucket || 'default'
    const filePath = req.file.filename

    res.json({ path: filePath, bucket })
  } catch (error) {
    console.error('Upload error:', error)
    res.status(500).json({ message: 'Internal server error' })
  }
})

app.get('/api/storage/public/:bucket/:path', (req: Request, res: Response) => {
  try {
    const { bucket, path: filePath } = req.params
    const fullPath = path.join(UPLOAD_DIR, bucket, filePath)

    if (!fs.existsSync(fullPath)) {
      return res.status(404).json({ message: 'File not found' })
    }

    res.sendFile(fullPath)
  } catch (error) {
    console.error('Download error:', error)
    res.status(500).json({ message: 'Internal server error' })
  }
})

app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

app.listen(PORT, () => {
  console.log(`API Server running on port ${PORT}`)
  console.log(`Environment:`)
  console.log(`  - DB_HOST: ${process.env.DB_HOST || 'localhost'}`)
  console.log(`  - DB_PORT: ${process.env.DB_PORT || '3306'}`)
  console.log(`  - DB_DATABASE: ${process.env.DB_DATABASE || 'ops_workflow_center'}`)
  console.log(`  - UPLOAD_DIR: ${UPLOAD_DIR}`)
})
