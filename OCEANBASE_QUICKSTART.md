# OceanBase 快速部署指南（5 分钟）

## ✅ 您的 OceanBase 配置

根据您提供的连接信息：

```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__
```

**配置信息**：
- 数据库地址: `192.168.1.70`
- 端口: `2883`
- 用户名: `root@Tianji4_MySQL#Tianji4`
- 密码: `aaAA11__`
- 数据库名: `ops_workflow_center`

---

## 🎯 部署步骤

### ✅ 第一步：数据库已初始化

您已经完成了数据库初始化，创建了 5 个表：
- users
- modules
- workflows
- scenarios
- execution_logs

### ✅ 第二步：配置已更新

.env 文件已经配置完成：

```bash
VITE_SERVICE_PROVIDER=custom
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center
JWT_SECRET=change-this-to-a-random-secret-key-in-production
```

---

## 🚀 现在可以部署了！

### 方案 1: Docker 部署（推荐）

```bash
# 一键部署
sudo bash docker-deploy.sh
```

等待部署完成（首次约 5-10 分钟），然后访问：
- 前端: `http://服务器IP:5173`
- 后端: `http://服务器IP:3000`

### 方案 2: 本地开发测试

```bash
# 安装依赖
npm install

# 启动后端 API（新终端）
npm run api-server

# 启动前端（新终端）
npm run dev
```

---

## 🔍 验证部署

### 1. 检查容器状态

```bash
sudo docker-compose ps

# 应该看到容器在运行：
# NAME                    STATUS          PORTS
# ops-workflow-center     Up 2 minutes    0.0.0.0:3000->3000/tcp, 0.0.0.0:5173->5173/tcp
```

### 2. 查看数据库连接日志

```bash
sudo docker-compose logs | grep -i "DB_HOST"

# 应该看到：
# API Server running on port 3000
# Environment:
#   - DB_HOST: 192.168.1.70
#   - DB_PORT: 2883
#   - DB_DATABASE: ops_workflow_center
```

### 3. 测试后端 API

```bash
curl http://localhost:3000/health

# 应该返回：
# {"status":"ok","timestamp":"2024-01-18T12:34:56.789Z"}
```

### 4. 浏览器访问

打开浏览器：`http://服务器IP:5173`

尝试注册一个账号，验证数据能正常写入 OceanBase。

---

## 🛠️ 常用命令

### 服务管理

```bash
# 启动服务
sudo docker-compose up -d

# 停止服务
sudo docker-compose down

# 重启服务
sudo docker-compose restart

# 查看日志
sudo docker-compose logs -f

# 查看实时状态
sudo docker stats ops-workflow-center
```

### 数据库操作

```bash
# 连接数据库
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__

# 查看表
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "USE ops_workflow_center; SHOW TABLES;"

# 查看用户数据
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "USE ops_workflow_center; SELECT * FROM users;"

# 备份数据库
mysqldump -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ ops_workflow_center > backup-$(date +%Y%m%d).sql
```

---

## ⚠️ 防火墙配置

### CentOS/Rocky Linux

```bash
sudo firewall-cmd --permanent --add-port=5173/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### Ubuntu/Debian

```bash
sudo ufw allow 5173/tcp
sudo ufw allow 3000/tcp
sudo ufw reload
```

### 云服务器安全组

如果使用阿里云/腾讯云，记得在控制台添加安全组规则：
- 端口 5173 (前端)
- 端口 3000 (后端)

---

## 🔧 故障排查

### 问题：容器无法启动

```bash
# 查看详细日志
sudo docker-compose logs

# 检查端口占用
sudo netstat -tulpn | grep -E "5173|3000"

# 如果端口被占用，停止占用的进程或修改端口
```

### 问题：无法连接数据库

```bash
# 从宿主机测试连接
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "SELECT 1;"

# 检查网络
ping 192.168.1.70
telnet 192.168.1.70 2883

# 查看容器内的网络
sudo docker exec -it ops-workflow-center ping 192.168.1.70
```

### 问题：前端无法访问

```bash
# 检查容器状态
sudo docker ps

# 检查防火墙
sudo firewall-cmd --list-all

# 测试本地访问
curl http://localhost:5173
```

---

## 📊 性能监控

### 容器资源使用

```bash
sudo docker stats ops-workflow-center

# 输出示例：
# CONTAINER ID   NAME                    CPU %     MEM USAGE / LIMIT
# abc123def456   ops-workflow-center     2.5%      256MiB / 2GiB
```

### 数据库连接状态

```sql
-- 查看当前连接
SHOW PROCESSLIST;

-- 查看表大小
SELECT
  table_name,
  table_rows,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'ops_workflow_center';
```

---

## 📚 完整文档

- **[OCEANBASE_CONFIG.md](OCEANBASE_CONFIG.md)** - OceanBase 配置详解
- **[MySQL部署操作手册.md](MySQL部署操作手册.md)** - 详细操作步骤
- **[MYSQL_DEPLOYMENT.md](MYSQL_DEPLOYMENT.md)** - 完整技术文档

---

## 🎉 部署完成！

如果一切正常，您现在可以：

1. ✅ 访问前端页面
2. ✅ 注册新用户
3. ✅ 登录系统
4. ✅ 创建工作流
5. ✅ 执行自动化任务

数据将安全地存储在您的 OceanBase 数据库中。

---

## 💡 下一步

### 安全加固

1. 修改 JWT_SECRET 为随机字符串：
```bash
vi .env
# 修改 JWT_SECRET=随机生成的长字符串
sudo docker-compose restart
```

2. 创建专用数据库用户（可选）：
```sql
CREATE USER 'ops_app'@'%' IDENTIFIED BY '强密码';
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_workflow_center.* TO 'ops_app'@'%';
FLUSH PRIVILEGES;
```

然后更新 .env：
```bash
DB_USER=ops_app@Tianji4_MySQL#Tianji4
DB_PASSWORD=强密码
```

### 定期维护

```bash
# 每天备份数据库（添加到 crontab）
0 2 * * * mysqldump -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ ops_workflow_center > /backup/ops-$(date +\%Y\%m\%d).sql

# 清理旧日志
find logs/ -name "*.log" -mtime +7 -delete
```

---

**祝您使用愉快！**

更新时间: 2024-01-18
