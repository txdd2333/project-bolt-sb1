# MySQL 数据库 Docker 部署操作手册

## 📋 完整部署步骤（按顺序执行）

---

### ✅ 前置准备

在开始部署前，请确保：

1. ✓ 已有可用的 MySQL/OceanBase 数据库
2. ✓ 数据库网络可访问
3. ✓ 有数据库管理员权限
4. ✓ CentOS 7+ 或 Rocky Linux 8+ 系统
5. ✓ 有服务器 root 权限

---

## 🚀 第一步：初始化数据库

### 1.1 连接到数据库

**标准 MySQL**：
```bash
mysql -h 数据库地址 -u root -p
# 例如：
mysql -h 192.168.1.100 -u root -p
```

**OceanBase MySQL 模式**：
```bash
mysql -h数据库地址 -P端口 -u用户名@租户名#集群名 -p密码
# 例如：
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__
```

**重要**: OceanBase 的用户名格式为：`用户名@租户名#集群名`

### 1.2 创建数据库和表

有两种方式：

**方式 A：直接执行 SQL 文件（推荐）**

```bash
# 下载初始化脚本到本地
# 然后执行：
mysql -h 数据库地址 -u root -p < scripts/init-mysql-database.sql
```

**方式 B：登录后执行**

```sql
-- 创建数据库
CREATE DATABASE IF NOT EXISTS ops_workflow_center CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 使用数据库
USE ops_workflow_center;

-- 执行初始化脚本
source /path/to/scripts/init-mysql-database.sql;
```

### 1.3 验证数据库

```sql
USE ops_workflow_center;
SHOW TABLES;

-- 应该看到 5 个表：
-- execution_logs
-- modules
-- scenarios
-- users
-- workflows
```

---

## 🚀 第二步：上传项目到服务器

### 2.1 本地打包

在你的开发机器上：

```bash
cd ops-workflow-center
bash pack-for-deploy.sh
```

会生成一个类似 `ops-workflow-center-20240118-143000.tar.gz` 的文件。

### 2.2 上传到服务器

```bash
# 使用 SCP 上传
scp ops-workflow-center-*.tar.gz root@服务器IP:/opt/
```

或使用 FTP 工具（FileZilla）上传到 `/opt/` 目录。

---

## 🚀 第三步：解压项目

SSH 登录到服务器：

```bash
# 进入目录
cd /opt

# 解压项目
tar -xzf ops-workflow-center-*.tar.gz

# 进入项目目录
cd ops-workflow-center

# 查看文件
ls -la
```

---

## 🚀 第四步：配置环境变量

### 4.1 复制配置模板

```bash
cp .env.example .env
```

### 4.2 编辑配置

```bash
vi .env
```

按 `i` 进入编辑模式，配置如下内容：

```bash
# 服务提供商（必须设置为 custom）
VITE_SERVICE_PROVIDER=custom

# API 服务器地址（如果前后端在同一服务器，用 localhost）
VITE_API_URL=http://localhost:3000

# ========== MySQL 数据库配置（重点！） ==========
DB_HOST=192.168.1.100              # 改为您的数据库地址
DB_PORT=3306                       # 数据库端口
DB_USER=root                       # 数据库用户名
DB_PASSWORD=your_password          # 改为您的数据库密码
DB_DATABASE=ops_workflow_center    # 数据库名称

# JWT 密钥（用于用户认证，请改为随机字符串）
JWT_SECRET=abc123xyz456def789ghi   # 改为随机字符串

# 文件上传目录
UPLOAD_DIR=./uploads
```

**重要说明：**
- `VITE_SERVICE_PROVIDER` 必须是 `custom`
- `DB_HOST` 填写数据库服务器地址
- `DB_PORT` OceanBase 默认 2883，标准 MySQL 默认 3306
- `DB_USER` **标准 MySQL**: `root`，**OceanBase**: `用户名@租户名#集群名`
- `DB_PASSWORD` 填写实际密码
- `JWT_SECRET` 建议使用随机字符串

保存并退出（按 `Esc`，输入 `:wq`，按回车）

### 4.3 验证配置

```bash
# 查看配置
cat .env

# 测试数据库连接
# 标准 MySQL:
mysql -h 192.168.1.100 -u root -p -e "USE ops_workflow_center; SELECT COUNT(*) FROM users;"

# OceanBase (您的配置):
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "USE ops_workflow_center; SELECT COUNT(*) FROM users;"
```

如果能正常连接并返回结果，说明配置正确。

---

## 🚀 第五步：一键部署

```bash
# 执行部署脚本（会自动安装 Docker）
sudo bash docker-deploy.sh
```

脚本会自动完成：

1. ✅ 检查并安装 Docker
2. ✅ 检查并安装 Docker Compose
3. ✅ 验证环境配置
4. ✅ 构建 Docker 镜像（首次需要 5-10 分钟）
5. ✅ 启动服务

等待完成，看到 "部署成功" 提示即可。

---

## 🚀 第六步：配置防火墙

### CentOS 7 / Rocky Linux 8

```bash
# 开放前端端口
sudo firewall-cmd --permanent --add-port=5173/tcp

# 开放后端端口
sudo firewall-cmd --permanent --add-port=3000/tcp

# 重载防火墙
sudo firewall-cmd --reload

# 查看已开放端口
sudo firewall-cmd --list-ports
```

### Ubuntu / Debian

```bash
sudo ufw allow 5173/tcp
sudo ufw allow 3000/tcp
sudo ufw reload
```

---

## 🚀 第七步：配置云服务器安全组

如果使用阿里云/腾讯云/AWS：

1. 登录云服务器控制台
2. 找到"安全组"或"防火墙规则"
3. 添加入站规则：
   - **规则 1**: 端口 5173，协议 TCP，来源 0.0.0.0/0
   - **规则 2**: 端口 3000，协议 TCP，来源 0.0.0.0/0
4. 保存并应用规则

---

## 🚀 第八步：验证部署

### 8.1 检查容器状态

```bash
sudo docker-compose ps

# 应该看到容器在运行：
# NAME                    STATUS          PORTS
# ops-workflow-center     Up 2 minutes    0.0.0.0:3000->3000/tcp, 0.0.0.0:5173->5173/tcp
```

### 8.2 查看日志

```bash
# 查看实时日志
sudo docker-compose logs -f

# 应该看到类似输出：
# API Server running on port 3000
# Environment:
#   - DB_HOST: 192.168.1.100
#   - DB_PORT: 3306
#   - DB_DATABASE: ops_workflow_center
```

按 `Ctrl+C` 退出日志查看。

### 8.3 测试服务

```bash
# 测试前端
curl http://localhost:5173

# 测试后端
curl http://localhost:3000/health

# 应该返回：
# {"status":"ok","timestamp":"2024-01-18T12:34:56.789Z"}
```

### 8.4 浏览器访问

打开浏览器访问：

- **前端页面**: `http://服务器IP:5173`
- **后端 API**: `http://服务器IP:3000`

尝试注册账号并登录，验证一切正常。

---

## ✅ 部署完成检查清单

部署成功后，请检查以下项：

- [ ] 容器正常运行 (`sudo docker-compose ps`)
- [ ] 前端页面可以访问
- [ ] 后端 API 可以访问
- [ ] 可以注册新用户
- [ ] 可以登录系统
- [ ] 防火墙规则已配置
- [ ] 云安全组已配置（如适用）
- [ ] 数据库连接正常

---

## 🔧 常用管理命令

### 查看日志

```bash
# 实时查看所有日志
sudo docker-compose logs -f

# 只看 API 服务日志
sudo docker-compose logs -f app | grep api-server

# 查看最近 100 行日志
sudo docker-compose logs --tail=100

# 查看日志文件
tail -f logs/api-out.log
tail -f logs/frontend-out.log
```

### 服务控制

```bash
# 启动服务
sudo docker-compose up -d

# 停止服务
sudo docker-compose down

# 重启服务
sudo docker-compose restart

# 查看状态
sudo docker-compose ps

# 进入容器
sudo docker exec -it ops-workflow-center bash
```

### 数据库操作

```bash
# 备份数据库
mysqldump -h 192.168.1.100 -u root -p ops_workflow_center > backup-$(date +%Y%m%d).sql

# 查看数据
mysql -h 192.168.1.100 -u root -p -e "USE ops_workflow_center; SELECT * FROM users;"

# 查看表大小
mysql -h 192.168.1.100 -u root -p -e "
  SELECT table_name, table_rows,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
  FROM information_schema.TABLES
  WHERE table_schema = 'ops_workflow_center';
"
```

---

## ⚠️ 故障排查

### 问题 1: 容器无法启动

```bash
# 查看详细错误
sudo docker-compose logs

# 检查环境变量
cat .env

# 检查端口占用
sudo netstat -tulpn | grep 5173
sudo netstat -tulpn | grep 3000
```

### 问题 2: 无法连接数据库

```bash
# 测试数据库连接
mysql -h 数据库地址 -u root -p -e "SELECT 1;"

# 检查网络
ping 数据库地址
telnet 数据库地址 3306

# 查看应用日志中的数据库错误
sudo docker-compose logs | grep -i "database\|mysql\|connection"
```

**常见错误：**
- `Access denied` - 用户名或密码错误
- `Host not allowed` - 数据库未授权远程访问
- `Unknown database` - 数据库不存在
- `Connection refused` - 无法连接到数据库

### 问题 3: 无法访问前端

```bash
# 检查容器状态
sudo docker ps

# 检查防火墙
sudo firewall-cmd --list-all

# 测试本地访问
curl http://localhost:5173

# 在容器内测试
sudo docker exec -it ops-workflow-center curl http://localhost:5173
```

### 问题 4: 数据库远程访问被拒绝

在数据库服务器上执行：

```sql
-- 授权远程访问
GRANT ALL PRIVILEGES ON ops_workflow_center.* TO 'root'@'%' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;

-- 查看授权
SHOW GRANTS FOR 'root'@'%';
```

检查数据库配置文件（如 my.cnf）：

```bash
# 确保没有 bind-address 限制，或设置为：
bind-address = 0.0.0.0
```

---

## 🔄 更新部署

当需要更新代码时：

```bash
# 1. 在本地打包新版本
bash pack-for-deploy.sh

# 2. 上传到服务器
scp ops-workflow-center-*.tar.gz root@服务器IP:/opt/

# 3. 在服务器上操作
cd /opt

# 备份当前版本
mv ops-workflow-center ops-workflow-center.backup

# 解压新版本
tar -xzf ops-workflow-center-*.tar.gz

# 恢复配置和数据
cp ops-workflow-center.backup/.env ops-workflow-center/
cp -r ops-workflow-center.backup/logs ops-workflow-center/
cp -r ops-workflow-center.backup/uploads ops-workflow-center/

# 重新部署
cd ops-workflow-center
sudo docker-compose down
sudo docker-compose build
sudo docker-compose up -d
```

---

## 📊 网络配置说明

### 场景 1: 数据库和应用在同一服务器

```bash
# .env 配置
DB_HOST=localhost
# 或
DB_HOST=127.0.0.1
```

### 场景 2: 数据库在局域网其他服务器

```bash
# .env 配置
DB_HOST=192.168.1.100  # 局域网IP

# 确保网络通畅
ping 192.168.1.100
telnet 192.168.1.100 3306
```

### 场景 3: OceanBase 集群

**重要**: OceanBase MySQL 模式的用户名格式为：`用户名@租户名#集群名`

```bash
# .env 配置
DB_HOST=192.168.1.70                      # OBProxy 地址
DB_PORT=2883                               # OBProxy 端口
DB_USER=root@Tianji4_MySQL#Tianji4        # 用户名@租户名#集群名
DB_PASSWORD=your_password
DB_DATABASE=ops_workflow_center
```

**测试连接**：
```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -p
```

### 场景 4: 云数据库（阿里云 RDS 等）

```bash
# .env 配置
DB_HOST=rm-xxx.mysql.rds.aliyuncs.com  # 云数据库地址
DB_PORT=3306
DB_USER=ops_app
DB_PASSWORD=强密码
DB_DATABASE=ops_workflow_center
```

---

## 📈 性能建议

1. **数据库连接池**: 默认 10 个连接，如需调整，修改 `server/api-server.ts`

2. **数据库索引**: 初始化脚本已包含必要索引

3. **定期备份**: 建议每天自动备份数据库

4. **日志轮转**: 防止日志文件过大
   ```bash
   # 清理 7 天前的日志
   find logs/ -name "*.log" -mtime +7 -delete
   ```

---

## 🔐 安全建议

1. **修改默认密码**: 使用强密码
2. **限制数据库访问**: 只允许应用服务器IP访问
3. **使用专用数据库用户**: 不要使用 root
4. **定期更新**: 及时更新系统和应用
5. **启用防火墙**: 只开放必要端口

---

## 📞 获取帮助

### 文档索引

- **本文档**: MySQL 数据库部署操作手册
- **详细技术文档**: [MYSQL_DEPLOYMENT.md](MYSQL_DEPLOYMENT.md)
- **Docker 部署文档**: [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
- **快速参考**: [DOCKER_QUICKSTART.md](DOCKER_QUICKSTART.md)

### 常见问题

**Q: 支持哪些数据库？**
A: MySQL 5.7+, MySQL 8.0+, OceanBase MySQL 模式, MariaDB 10.3+

**Q: 必须使用 Docker 吗？**
A: 是的，这是推荐的部署方式，简单可靠。

**Q: 数据会存在哪里？**
A: 数据存储在您的 MySQL/OceanBase 数据库中，文件存储在 `./uploads/` 目录。

**Q: 如何修改端口？**
A: 编辑 `docker-compose.yml` 中的 `ports` 配置。

---

## 🎯 总结

完整部署流程：

1. ✅ 初始化数据库（执行 SQL 脚本）
2. ✅ 上传项目到服务器
3. ✅ 解压项目文件
4. ✅ 配置 .env 文件（重点是数据库配置）
5. ✅ 运行一键部署脚本
6. ✅ 配置防火墙和安全组
7. ✅ 验证部署成功
8. ✅ 开始使用

**预计总耗时**: 15-20 分钟（包括首次 Docker 构建）

---

**祝您部署顺利！**

如有问题，请查看详细文档或检查日志排查。

---

更新时间: 2024-01-18

版本: v1.0.0
