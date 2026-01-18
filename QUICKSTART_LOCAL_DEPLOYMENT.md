# 快速部署手册 - 本地 CentOS 服务器

> 本文档提供最简化的部署流程，适合快速上手

---

## 📦 准备工作

### 1. 打包项目（在本地执行）

```bash
# 进入项目目录
cd /path/to/ops-workflow-center

# 打包整个项目
tar -czf ops-workflow-center.tar.gz \
  --exclude=node_modules \
  --exclude=dist \
  --exclude=.git \
  --exclude=uploads \
  .

# 文件将生成在当前目录：ops-workflow-center.tar.gz
```

### 2. 上传到服务器

```bash
# 使用 SCP 上传
scp ops-workflow-center.tar.gz root@your-server-ip:/root/

# 或使用其他工具（FTP、WinSCP 等）
```

---

## 🚀 服务器端部署（CentOS 7/8）

### 步骤 1: 连接服务器

```bash
ssh root@your-server-ip
```

### 步骤 2: 一键安装依赖

```bash
# 安装 Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# 安装 MySQL 客户端
yum install -y mysql

# 安装 PM2
npm install -g pm2

# 安装 Nginx
yum install -y nginx

# 验证安装
node -v    # 应该显示 v18.x.x
mysql --version
pm2 -v
nginx -v
```

### 步骤 3: 解压项目

```bash
# 创建部署目录
mkdir -p /opt/ops-workflow-center
cd /opt/ops-workflow-center

# 解压项目
tar -xzf /root/ops-workflow-center.tar.gz -C /opt/ops-workflow-center/

# 检查文件
ls -la
```

### 步骤 4: 配置数据库连接

```bash
cd /opt/ops-workflow-center

# 编辑服务器配置
vi .env.server
```

**内容：**
```bash
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center
JWT_SECRET=请用openssl生成一个随机密钥
PORT=3001
UPLOAD_DIR=/opt/ops-workflow-center/uploads
```

**生成安全的 JWT_SECRET：**
```bash
openssl rand -base64 64
# 将输出的字符串复制到 JWT_SECRET
```

### 步骤 5: 初始化数据库

```bash
# 测试数据库连接
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "SELECT 1"

# 执行数据库初始化脚本
chmod +x scripts/init-database.sh
./scripts/init-database.sh
```

**预期输出：**
```
✓ 数据库创建成功
✓ 表结构创建成功
✓ 成功创建 8 个表
```

### 步骤 6: 安装项目依赖

```bash
# 使用淘宝镜像加速（可选但推荐）
npm config set registry https://registry.npmmirror.com

# 安装依赖（需要 5-10 分钟）
npm install

# 如果遇到错误，清除缓存重试
npm cache clean --force
npm install
```

### 步骤 7: 构建前端

```bash
# 构建前端代码
npm run build

# 检查构建结果
ls -la dist/
```

### 步骤 8: 安装 Playwright 浏览器

```bash
# 安装系统依赖
yum install -y \
    alsa-lib atk cups-libs gtk3 \
    libXcomposite libXcursor libXdamage \
    libXext libXi libXrandr libXScrnSaver \
    libXtst pango

# 安装 Playwright 浏览器
npx playwright install chromium

# 测试安装
npx playwright --version
```

### 步骤 9: 启动服务

```bash
# 创建日志目录
mkdir -p logs uploads

# 使用 PM2 启动服务
pm2 start ecosystem.config.cjs

# 查看状态
pm2 status

# 查看日志
pm2 logs --lines 50
```

**预期输出：**
```
┌─────┬───────────────────────────┬──────────┬──────┬───────────┬──────────┐
│ id  │ name                      │ mode     │ ↺    │ status    │ cpu      │
├─────┼───────────────────────────┼──────────┼──────┼───────────┼──────────┤
│ 0   │ ops-api-server            │ fork     │ 0    │ online    │ 0%       │
│ 1   │ ops-playwright-server     │ fork     │ 0    │ online    │ 0%       │
└─────┴───────────────────────────┴──────────┴──────┴───────────┴──────────┘
```

### 步骤 10: 配置 Nginx

```bash
# 创建 Nginx 配置
vi /etc/nginx/conf.d/ops-workflow-center.conf
```

**配置内容：**
```nginx
upstream api_backend {
    server 127.0.0.1:3001;
}

server {
    listen 80;
    server_name _;  # 接受所有域名

    # 前端静态文件
    location / {
        root /opt/ops-workflow-center/dist;
        try_files $uri $uri/ /index.html;
        index index.html;
    }

    # API 接口代理
    location /api/ {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    client_max_body_size 50M;
}
```

**测试并启动 Nginx：**
```bash
# 测试配置
nginx -t

# 启动 Nginx
systemctl start nginx
systemctl enable nginx

# 配置防火墙
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
```

### 步骤 11: 验证部署

```bash
# 健康检查
curl http://localhost:3001/health
# 应该返回: {"status":"ok","timestamp":"..."}

# 访问前端（在浏览器中打开）
# http://your-server-ip/
```

### 步骤 12: 设置开机自启动

```bash
# PM2 开机自启动
pm2 save
pm2 startup
# 按照输出的提示执行命令

# Nginx 开机自启动（已在步骤 10 中执行）
systemctl enable nginx
```

---

## ✅ 验证清单

完成部署后，请验证以下项目：

- [ ] API 服务器运行正常：`curl http://localhost:3001/health`
- [ ] Playwright 服务器运行正常：`curl http://localhost:3002/health`
- [ ] 可以访问前端页面：`http://your-server-ip/`
- [ ] 可以注册新用户
- [ ] 可以登录系统
- [ ] PM2 进程状态正常：`pm2 status`
- [ ] Nginx 运行正常：`systemctl status nginx`

---

## 🔧 常用命令

### 查看日志
```bash
# PM2 日志
pm2 logs
pm2 logs ops-api-server
pm2 logs --lines 200

# Nginx 日志
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### 重启服务
```bash
# 重启所有 PM2 服务
pm2 restart all

# 重启单个服务
pm2 restart ops-api-server

# 重启 Nginx
systemctl restart nginx
```

### 停止服务
```bash
# 停止 PM2 服务
pm2 stop all

# 停止 Nginx
systemctl stop nginx
```

### 查看状态
```bash
# PM2 状态
pm2 status
pm2 monit

# Nginx 状态
systemctl status nginx

# 端口占用情况
netstat -tuln | grep 3001
netstat -tuln | grep 80
```

---

## ❗ 常见问题

### 问题 1: npm install 很慢或失败

**解决方案：**
```bash
# 使用淘宝镜像
npm config set registry https://registry.npmmirror.com
npm install
```

### 问题 2: 数据库连接失败

**解决方案：**
```bash
# 测试网络连接
ping 192.168.1.70

# 测试数据库连接
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__

# 检查 .env.server 配置是否正确
cat .env.server
```

### 问题 3: 前端无法连接后端

**解决方案：**
```bash
# 检查 API 服务是否运行
pm2 status
curl http://localhost:3001/health

# 检查防火墙
firewall-cmd --list-all

# 查看 API 日志
pm2 logs ops-api-server
```

### 问题 4: Nginx 403 错误

**解决方案：**
```bash
# 检查 SELinux
getenforce

# 临时关闭 SELinux
setenforce 0

# 永久关闭（不推荐，建议配置正确的策略）
vi /etc/selinux/config
# 将 SELINUX=enforcing 改为 SELINUX=disabled

# 重启服务器
reboot
```

---

## 📞 获取帮助

如遇到问题，请：
1. 查看详细部署文档：`DEPLOYMENT_GUIDE.md`
2. 查看项目架构文档：`docs/ARCHITECTURE.md`
3. 查看交接文档：`HANDOVER_DOCUMENT.md`

---

**文档版本**: v1.0
**最后更新**: 2026-01-18
