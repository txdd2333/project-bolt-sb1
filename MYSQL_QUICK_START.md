# 切换到 OceanBase MySQL 快速部署指南

本文档提供从 Supabase 切换到 OceanBase MySQL 数据库的快速部署步骤。

## 前提条件

- 已安装 Node.js 18+ 和 npm
- 已配置并可访问的 OceanBase MySQL 实例
- 数据库用户具有创建表和执行 DDL 的权限

## 快速步骤

### 1. 停止开发服务器

如果开发服务器正在运行，请先停止：

```bash
# 按 Ctrl+C 停止前端开发服务器
# 如果后端服务器在运行，也需要停止
```

### 2. 切换到 MySQL 模式

**Windows 系统：**
```bash
.\switch-to-mysql.bat
```

**Linux/Mac 系统：**
```bash
./switch-to-mysql.sh
```

或者手动编辑 `.env` 文件：
```bash
# 将 VITE_SERVICE_PROVIDER 改为 custom
VITE_SERVICE_PROVIDER=custom
```

### 3. 配置数据库连接

编辑项目根目录下的 `.env` 文件，更新以下数据库配置：

```env
# MySQL 数据库配置
DB_HOST=192.168.1.70          # 数据库服务器地址
DB_PORT=2883                   # 端口，MySQL默认3306，OceanBase默认2883
DB_USER=root@Tianji4_MySQL#Tianji4  # OceanBase格式: 用户名@租户名#集群名
DB_PASSWORD=your_password      # 数据库密码
DB_DATABASE=ops_workflow_center # 数据库名称
```

**重要说明：**
- 标准 MySQL 用户格式：`DB_USER=root`
- OceanBase 用户格式：`DB_USER=用户名@租户名#集群名`

### 4. 初始化数据库

运行数据库初始化脚本创建表结构：

```bash
# 确保数据库初始化脚本有执行权限
chmod +x scripts/init-database.sh

# 执行初始化
./scripts/init-database.sh
```

或者手动执行 SQL 脚本：

```bash
# 方法1：使用 MySQL 客户端
mysql -h 192.168.1.70 -P 2883 -u 用户名 -p数据库名 < scripts/init-mysql-database.sql

# 方法2：使用 OceanBase 客户端（如果使用 OceanBase）
obclient -h 192.168.1.70 -P 2883 -u root@租户名#集群名 -p密码 数据库名 < scripts/init-mysql-database.sql
```

### 5. 启动后端服务器

MySQL 模式需要运行后端 API 服务器来处理数据库操作：

```bash
npm run server
```

后端服务器将在 `http://localhost:3000` 启动。

**保持这个终端窗口运行！**

### 6. 启动前端开发服务器

打开新的终端窗口，启动前端：

```bash
npm run dev
```

前端开发服务器将在 `http://localhost:5173` 启动。

### 7. 验证部署

1. 打开浏览器访问 `http://localhost:5173`
2. 使用注册功能创建新用户
3. 登录系统
4. 测试创建场景、工作流等功能

## 生产环境部署

### 构建生产版本

```bash
# 构建前端
npm run build

# 构建后端
npm run server:build
```

### 使用 PM2 部署

```bash
# 安装 PM2
npm install -g pm2

# 启动后端服务
pm2 start ecosystem.config.cjs --only api-server

# 启动前端服务（如果需要）
pm2 start ecosystem.config.cjs --only web-server

# 查看状态
pm2 status

# 查看日志
pm2 logs

# 保存 PM2 配置
pm2 save

# 设置开机自启动
pm2 startup
```

### 使用 Docker 部署

```bash
# 构建 Docker 镜像
docker build -t ops-workflow-center .

# 运行容器
docker run -d \
  --name ops-workflow \
  -p 3000:3000 \
  -p 5173:5173 \
  --env-file .env \
  ops-workflow-center

# 查看日志
docker logs -f ops-workflow
```

## 切换回 Supabase

如果需要切换回 Supabase 模式：

**Windows：**
```bash
.\switch-to-supabase.bat
```

**Linux/Mac：**
```bash
./switch-to-supabase.sh
```

## 故障排除

### 无法连接数据库

1. 检查数据库服务是否运行
2. 验证 `.env` 中的连接配置是否正确
3. 确认网络能够访问数据库服务器
4. 检查防火墙设置

### 后端服务器无法启动

1. 确认端口 3000 没有被占用
2. 检查 `.env` 文件中的配置
3. 查看终端错误信息
4. 确认 `node_modules` 已正确安装

### 数据库表不存在

重新运行初始化脚本：
```bash
./scripts/init-database.sh
```

### 登录/注册失败

1. 确认后端服务器正在运行
2. 检查浏览器控制台的网络请求
3. 验证 API URL 配置正确（默认 `http://localhost:3000`）
4. 查看后端服务器日志

## 数据迁移

### 从 Supabase 导出数据

1. 登录 Supabase Dashboard
2. 进入 Table Editor
3. 选择要导出的表
4. 点击 Export -> CSV

### 导入到 MySQL

```bash
# 使用 mysqlimport 或编写导入脚本
mysqlimport --local \
  -h 192.168.1.70 -P 2883 \
  -u 用户名 -p密码 \
  数据库名 \
  数据文件.csv
```

## 性能优化建议

1. **数据库索引**：为常用查询字段添加索引
2. **连接池配置**：调整 `server/index.ts` 中的连接池参数
3. **缓存策略**：考虑使用 Redis 缓存热数据
4. **负载均衡**：生产环境使用 Nginx 进行负载均衡

## 备份建议

定期备份数据库：

```bash
# MySQL 备份
mysqldump -h 192.168.1.70 -P 2883 \
  -u 用户名 -p密码 \
  ops_workflow_center > backup_$(date +%Y%m%d).sql

# 恢复
mysql -h 192.168.1.70 -P 2883 \
  -u 用户名 -p密码 \
  ops_workflow_center < backup_20260118.sql
```

## 技术支持

如遇到问题，请查看：
- 项目 README.md
- DEPLOYMENT_GUIDE.md
- GitHub Issues

---

**注意**：所有修复（包括退出登录、流程图编辑、Playwright 配置等）在 MySQL 模式下同样有效，无需额外配置。
