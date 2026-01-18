import express from 'express'
import cors from 'cors'
import { PlaywrightExecutor } from './playwright-executor.js'
import { WorkflowRunner } from './workflow-runner.js'

const app = express()
const PORT = process.env.PORT || 3000

app.use(cors())
app.use(express.json())

const playwrightExecutor = new PlaywrightExecutor()
const workflowRunner = new WorkflowRunner(playwrightExecutor)

app.post('/api/playwright/execute', async (req, res) => {
  try {
    const { workflow, variables } = req.body

    if (!workflow) {
      return res.status(400).json({ error: 'Workflow is required' })
    }

    const executionId = await workflowRunner.startExecution(workflow, variables || {})

    res.json({
      success: true,
      executionId,
      message: 'Workflow execution started'
    })
  } catch (error: any) {
    console.error('Execution error:', error)
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to execute workflow'
    })
  }
})

app.post('/api/playwright/test-module', async (req, res) => {
  try {
    const { module, workflow } = req.body

    if (!module || !workflow) {
      return res.status(400).json({ error: 'Module and workflow are required' })
    }

    const executionId = await workflowRunner.startExecution(workflow, {})

    await new Promise(resolve => setTimeout(resolve, 2000))

    res.json({
      success: true,
      executionId,
      message: 'Module test started'
    })
  } catch (error: any) {
    console.error('Test error:', error)
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to test module'
    })
  }
})

app.get('/api/playwright/execution/:id', async (req, res) => {
  try {
    const { id } = req.params
    const status = workflowRunner.getExecutionStatus(id)

    if (!status) {
      return res.status(404).json({ error: 'Execution not found' })
    }

    res.json(status)
  } catch (error: any) {
    console.error('Status error:', error)
    res.status(500).json({ error: error.message })
  }
})

app.get('/api/playwright/execution/:id/stream', async (req, res) => {
  const { id } = req.params

  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')

  const sendUpdate = (data: any) => {
    res.write(`data: ${JSON.stringify(data)}\n\n`)
  }

  workflowRunner.onExecutionUpdate(id, sendUpdate)

  req.on('close', () => {
    workflowRunner.offExecutionUpdate(id, sendUpdate)
  })
})

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'playwright-backend' })
})

app.listen(PORT, () => {
  console.log(`🚀 Playwright Backend Server running on http://localhost:${PORT}`)
  console.log(`📊 Health check: http://localhost:${PORT}/health`)
})
