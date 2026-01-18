# OPS Workflow Center - MySQL 数据库部署指南

## 📋 适用场景

本指南适用于使用 **OceanBase MySQL 模式** 或 **标准 MySQL** 数据库的本地部署。

---

## 🚀 快速部署（5步完成）

### 第一步：准备数据库

#### 1.1 创建数据库和表

连接到您的 OceanBase/MySQL 数据库，执行初始化脚本：

```bash
# 方式1：使用 MySQL 客户端
mysql -h 数据库地址 -u root -p < scripts/init-mysql-database.sql

# 方式2：登录后执行
mysql -h 数据库地址 -u root -p
source /path/to/ops-workflow-center/scripts/init-mysql-database.sql
```

初始化脚本会创建以下表：
- `users` - 用户表
- `modules` - 模块表
- `workflows` - 工作流表
- `scenarios` - 场景表
- `execution_logs` - 执行日志表

#### 1.2 验证数据库

```sql
USE ops_workflow_center;
SHOW TABLES;

-- 应该看到 5 个表
-- +--------------------------------+
-- | Tables_in_ops_workflow_center |
-- +--------------------------------+
-- | execution_logs                |
-- | modules                       |
-- | scenarios                     |
-- | users                         |
-- | workflows                     |
-- +--------------------------------+
```

---

### 第二步：配置环境变量

编辑 `.env` 文件：

```bash
cd /opt/ops-workflow-center
vi .env
```

配置内容：

```bash
# 服务提供商（必须设置为 custom）
VITE_SERVICE_PROVIDER=custom

# API 服务器地址
VITE_API_URL=http://localhost:3000

# MySQL 数据库配置（请修改为您的实际配置）
DB_HOST=192.168.1.100          # 数据库服务器地址
DB_PORT=3306                    # 数据库端口
DB_USER=root                    # 数据库用户名
DB_PASSWORD=your_password       # 数据库密码
DB_DATABASE=ops_workflow_center # 数据库名称

# JWT 密钥（请修改为随机字符串）
JWT_SECRET=your-random-secret-key-here

# 文件上传目录
UPLOAD_DIR=./uploads
```

**重要配置说明：**

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `VITE_SERVICE_PROVIDER` | 必须设置为 `custom` | `custom` |
| `DB_HOST` | OceanBase/MySQL 服务器地址 | `192.168.1.70` |
| `DB_PORT` | 数据库端口（OceanBase 默认 2883，MySQL 默认 3306） | `2883` 或 `3306` |
| `DB_USER` | 数据库用户名<br>**标准 MySQL**: `root`<br>**OceanBase**: `用户名@租户名#集群名` | `root`<br>或<br>`root@Tianji4_MySQL#Tianji4` |
| `DB_PASSWORD` | 数据库密码 | `your_password` |
| `DB_DATABASE` | 数据库名称 | `ops_workflow_center` |
| `JWT_SECRET` | JWT 加密密钥，建议使用随机字符串 | `abc123xyz...` |

---

### 第三步：测试数据库连接

在部署前测试数据库连接：

**标准 MySQL**：
```bash
mysql -h 192.168.1.100 -u root -p -e "USE ops_workflow_center; SELECT COUNT(*) FROM users;"
```

**OceanBase MySQL 模式**：
```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -p -e "USE ops_workflow_center; SELECT COUNT(*) FROM users;"
```

应该返回：
```
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
```

---

### 第四步：Docker 部署

```bash
# 确保在项目目录
cd /opt/ops-workflow-center

# 一键部署
sudo bash docker-deploy.sh
```

部署脚本会自动：
- ✅ 安装 Docker 和 Docker Compose
- ✅ 验证数据库配置
- ✅ 构建 Docker 镜像
- ✅ 启动服务

---

### 第五步：配置防火墙

```bash
# CentOS 7 / Rocky Linux 8
sudo firewall-cmd --permanent --add-port=5173/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

# Ubuntu / Debian
sudo ufw allow 5173/tcp
sudo ufw allow 3000/tcp
sudo ufw reload
```

**云服务器还需要配置安全组：**
- 端口 5173 (前端)
- 端口 3000 (后端 API)

---

## 🎯 验证部署

### 1. 检查容器状态

```bash
sudo docker-compose ps

# 应该看到容器在运行
# NAME                    STATUS          PORTS
# ops-workflow-center     Up 2 minutes    0.0.0.0:3000->3000/tcp, 0.0.0.0:5173->5173/tcp
```

### 2. 查看日志

```bash
# 查看所有日志
sudo docker-compose logs -f

# 查看 API 服务器日志
sudo docker-compose logs -f app | grep api-server

# 应该看到类似输出：
# API Server running on port 3000
# Environment:
#   - DB_HOST: 192.168.1.100
#   - DB_PORT: 3306
#   - DB_DATABASE: ops_workflow_center
```

### 3. 测试服务

```bash
# 测试前端
curl http://localhost:5173

# 测试后端 API
curl http://localhost:3000/health

# 应该返回：
# {"status":"ok","timestamp":"2024-01-18T12:34:56.789Z"}
```

### 4. 浏览器访问

- **前端**: `http://服务器IP:5173`
- **后端 API**: `http://服务器IP:3000`

尝试注册一个账号并登录，验证数据库写入是否正常。

---

## 🔧 网络配置

### 场景1：数据库和应用在同一服务器

```bash
# .env 配置
DB_HOST=localhost
DB_PORT=3306
```

### 场景2：数据库在其他服务器

```bash
# .env 配置
DB_HOST=192.168.1.100  # 数据库服务器IP
DB_PORT=3306

# 确保网络连通
ping 192.168.1.100

# 确保数据库允许远程访问
# 在数据库服务器上：
mysql -u root -p -e "GRANT ALL PRIVILEGES ON ops_workflow_center.* TO 'root'@'%' IDENTIFIED BY 'password';"
mysql -u root -p -e "FLUSH PRIVILEGES;"
```

### 场景3：OceanBase 集群

**重要**: OceanBase MySQL 模式的用户名格式为：`用户名@租户名#集群名`

```bash
# .env 配置
DB_HOST=192.168.1.70                           # OBProxy 地址
DB_PORT=2883                                    # OBProxy 端口（OceanBase 默认）
DB_USER=root@Tianji4_MySQL#Tianji4             # 用户名@租户名#集群名
DB_PASSWORD=your_password
DB_DATABASE=ops_workflow_center
```

**测试连接命令**：
```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -p
# 输入密码后应该能成功连接
```

---

## 📊 数据库维护

### 备份数据库

```bash
# 导出数据库
mysqldump -h 192.168.1.100 -u root -p ops_workflow_center > backup-$(date +%Y%m%d).sql

# 压缩备份
gzip backup-$(date +%Y%m%d).sql
```

### 恢复数据库

```bash
# 解压备份
gunzip backup-20240118.sql.gz

# 恢复数据
mysql -h 192.168.1.100 -u root -p ops_workflow_center < backup-20240118.sql
```

### 查看数据库大小

```sql
SELECT
  table_name AS '表名',
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS '大小(MB)'
FROM information_schema.TABLES
WHERE table_schema = 'ops_workflow_center'
ORDER BY (data_length + index_length) DESC;
```

### 优化表

```sql
-- 优化所有表
OPTIMIZE TABLE users, modules, workflows, scenarios, execution_logs;

-- 分析表
ANALYZE TABLE users, modules, workflows, scenarios, execution_logs;
```

---

## 🔍 故障排查

### 问题1：无法连接数据库

```bash
# 1. 检查数据库是否运行
mysql -h 192.168.1.100 -u root -p -e "SELECT 1;"

# 2. 检查网络连通性
ping 192.168.1.100
telnet 192.168.1.100 3306

# 3. 查看应用日志
sudo docker-compose logs | grep -i "error\|connection"

# 常见错误：
# - "Access denied" - 用户名或密码错误
# - "Host is not allowed" - 数据库未授权远程访问
# - "Unknown database" - 数据库不存在
# - "Connection refused" - 无法连接到数据库服务器
```

### 问题2：数据库连接数过多

```sql
-- 查看当前连接数
SHOW STATUS LIKE 'Threads_connected';

-- 查看最大连接数
SHOW VARIABLES LIKE 'max_connections';

-- 增加最大连接数（需要 root 权限）
SET GLOBAL max_connections = 500;
```

修改应用配置（如需要）：

```bash
# 在 server/api-server.ts 中
# connectionLimit: 10  # 默认值，可以增加
```

### 问题3：字符编码问题

```sql
-- 检查数据库字符集
SHOW CREATE DATABASE ops_workflow_center;

-- 应该是 utf8mb4
-- 如果不是，重新创建：
DROP DATABASE ops_workflow_center;
CREATE DATABASE ops_workflow_center CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 问题4：表不存在

```bash
# 重新执行初始化脚本
mysql -h 192.168.1.100 -u root -p ops_workflow_center < scripts/init-mysql-database.sql
```

---

## ⚙️ 性能优化

### 1. 添加索引

```sql
-- 为常用查询添加索引
CREATE INDEX idx_user_workflow ON workflows(user_id, status);
CREATE INDEX idx_user_scenario ON scenarios(user_id, workflow_id);
CREATE INDEX idx_execution_time ON execution_logs(user_id, start_time);
```

### 2. 连接池配置

编辑 `server/api-server.ts`，调整连接池参数：

```javascript
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE,
  waitForConnections: true,
  connectionLimit: 20,        // 增加连接数
  queueLimit: 0,
  connectTimeout: 10000,      // 连接超时
  acquireTimeout: 10000,      // 获取连接超时
});
```

### 3. 查询优化

```sql
-- 查看慢查询
SHOW VARIABLES LIKE 'slow_query_log%';

-- 启用慢查询日志
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;  -- 2秒以上的查询
```

---

## 🔐 安全建议

### 1. 数据库用户权限

```sql
-- 创建专用应用用户（推荐）
CREATE USER 'ops_app'@'%' IDENTIFIED BY 'strong_password';

-- 仅授予必需权限
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_workflow_center.* TO 'ops_app'@'%';
FLUSH PRIVILEGES;

-- 更新 .env 配置
# DB_USER=ops_app
# DB_PASSWORD=strong_password
```

### 2. 加密连接（可选）

如果数据库支持 SSL/TLS：

```bash
# .env 添加
DB_SSL=true
```

修改 `server/api-server.ts`：

```javascript
const pool = mysql.createPool({
  // ... 其他配置
  ssl: process.env.DB_SSL === 'true' ? {
    rejectUnauthorized: false
  } : undefined
});
```

### 3. JWT 密钥安全

```bash
# 生成随机密钥
openssl rand -base64 32

# 更新 .env
JWT_SECRET=生成的随机密钥
```

---

## 📈 监控

### 数据库监控

```sql
-- 查看数据库状态
SHOW STATUS;

-- 查看表大小
SELECT
  table_name,
  table_rows,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'ops_workflow_center';

-- 查看当前连接
SHOW PROCESSLIST;
```

### 应用监控

```bash
# 查看容器资源使用
sudo docker stats ops-workflow-center

# 查看应用日志
tail -f logs/api-out.log
tail -f logs/frontend-out.log
```

---

## 📞 常见问题

### Q: 支持哪些数据库版本？

A:
- MySQL 5.7+
- MySQL 8.0+
- OceanBase MySQL 模式
- MariaDB 10.3+

### Q: 可以使用 PostgreSQL 吗？

A: 目前仅支持 MySQL 兼容的数据库。如需 PostgreSQL，需要修改代码。

### Q: 数据库必须在本地吗？

A: 不是。可以连接任何网络可达的 MySQL 数据库，包括云数据库。

### Q: 如何迁移数据？

A:
```bash
# 1. 导出旧数据
mysqldump -h 旧库地址 -u root -p ops_workflow_center > data.sql

# 2. 导入新数据库
mysql -h 新库地址 -u root -p ops_workflow_center < data.sql
```

### Q: 支持主从复制吗？

A: 支持。配置主库地址即可，应用会自动连接。

---

## 📚 相关文档

- [Docker 部署指南](DOCKER_DEPLOYMENT.md)
- [快速开始](DOCKER_QUICKSTART.md)
- [部署方案对比](DEPLOYMENT_OPTIONS.md)
- [数据库脚本](scripts/init-mysql-database.sql)

---

**更新时间**: 2024-01-18

**适用版本**: v1.0.0
