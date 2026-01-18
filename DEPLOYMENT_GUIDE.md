# 运维工作流中心 - CentOS 本地部署指南

> 本指南详细说明如何在 CentOS 服务器上部署运维工作流中心（使用 OceanBase MySQL 租户）

---

## 📋 目录

1. [系统要求](#系统要求)
2. [前置准备](#前置准备)
3. [安装依赖](#安装依赖)
4. [数据库配置](#数据库配置)
5. [项目部署](#项目部署)
6. [服务启动](#服务启动)
7. [Nginx 配置](#nginx-配置)
8. [验证测试](#验证测试)
9. [常见问题](#常见问题)
10. [维护管理](#维护管理)

---

## 系统要求

### 硬件要求
- CPU: 4核+
- 内存: 8GB+
- 磁盘: 50GB+

### 软件要求
- 操作系统: CentOS 7/8 或 RHEL 7/8
- Node.js: 18.x 或更高
- MySQL 客户端: 5.7+ 或 8.0+
- PM2: 最新版本（用于进程管理）

### 网络要求
- 服务器能够访问 OceanBase 数据库（192.168.1.70:2883）
- 开放端口: 3001 (API), 3002 (Playwright), 80/443 (Nginx)

---

## 前置准备

### 1. 连接到服务器

```bash
ssh your-user@your-server-ip
```

### 2. 创建部署目录

```bash
sudo mkdir -p /opt/ops-workflow-center
sudo chown $USER:$USER /opt/ops-workflow-center
cd /opt/ops-workflow-center
```

### 3. 上传项目文件

**方式一：使用 SCP**
```bash
# 在本地执行
scp -r /path/to/project/* your-user@your-server-ip:/opt/ops-workflow-center/
```

**方式二：使用 Git**
```bash
# 在服务器上执行
git clone <your-repository-url> /opt/ops-workflow-center
cd /opt/ops-workflow-center
```

**方式三：使用压缩包**
```bash
# 在本地打包
tar -czf ops-workflow-center.tar.gz .

# 上传到服务器
scp ops-workflow-center.tar.gz your-user@your-server-ip:/opt/ops-workflow-center/

# 在服务器上解压
cd /opt/ops-workflow-center
tar -xzf ops-workflow-center.tar.gz
```

---

## 安装依赖

### 1. 安装 Node.js 18.x

```bash
# 添加 NodeSource 仓库
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -

# 安装 Node.js
sudo yum install -y nodejs

# 验证安装
node -v  # 应该显示 v18.x.x
npm -v   # 应该显示 9.x.x 或更高
```

**如果已安装旧版本 Node.js，需要先卸载：**
```bash
sudo yum remove -y nodejs npm
sudo rm -rf /usr/local/lib/node_modules
```

### 2. 安装 MySQL 客户端

```bash
# CentOS 7
sudo yum install -y mysql

# CentOS 8 / RHEL 8
sudo yum install -y mysql-community-client

# 或者安装 MariaDB 客户端（兼容 MySQL）
sudo yum install -y mariadb

# 验证安装
mysql --version
```

### 3. 安装 PM2（进程管理器）

```bash
sudo npm install -g pm2

# 验证安装
pm2 -v
```

### 4. 安装 Playwright 依赖

```bash
# 安装系统依赖（Playwright 浏览器需要）
sudo yum install -y \
    alsa-lib.x86_64 \
    atk.x86_64 \
    cups-libs.x86_64 \
    gtk3.x86_64 \
    ipa-gothic-fonts \
    libXcomposite.x86_64 \
    libXcursor.x86_64 \
    libXdamage.x86_64 \
    libXext.x86_64 \
    libXi.x86_64 \
    libXrandr.x86_64 \
    libXScrnSaver.x86_64 \
    libXtst.x86_64 \
    pango.x86_64 \
    xorg-x11-fonts-100dpi \
    xorg-x11-fonts-75dpi \
    xorg-x11-fonts-cyrillic \
    xorg-x11-fonts-misc \
    xorg-x11-fonts-Type1 \
    xorg-x11-utils
```

---

## 数据库配置

### 1. 测试数据库连接

```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__
```

如果连接成功，会进入 MySQL 命令行界面。输入 `exit` 退出。

### 2. 配置环境变量

编辑服务器端环境变量文件：

```bash
cd /opt/ops-workflow-center
vi .env.server
```

内容如下（**根据实际情况修改**）：

```bash
# 数据库配置
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center

# JWT 配置（务必修改为安全的密钥）
JWT_SECRET=请-替换-为-你-的-超级-安全-密钥-128位以上

# 服务器端口
PORT=3001

# 文件上传目录
UPLOAD_DIR=/opt/ops-workflow-center/uploads
```

**重要安全提示：**
- `JWT_SECRET` 必须修改为复杂的随机字符串
- 生成安全密钥的方法：`openssl rand -base64 64`

### 3. 初始化数据库

```bash
cd /opt/ops-workflow-center

# 给脚本添加执行权限
chmod +x scripts/init-database.sh

# 执行数据库初始化
./scripts/init-database.sh
```

**预期输出：**
```
======================================
运维工作流中心 - 数据库初始化脚本
======================================

数据库连接信息:
  主机: 192.168.1.70
  端口: 2883
  用户: root@Tianji4_MySQL#Tianji4
  数据库: ops_workflow_center

步骤 1/3: 创建数据库...
✓ 数据库创建成功

步骤 2/3: 创建表结构...
✓ 表结构创建成功

步骤 3/3: 验证表结构...
✓ 成功创建 8 个表

+------------------+
| Tables_in_ops_workflow_center |
+------------------+
| execution_logs   |
| modules          |
| scenarios        |
| sessions         |
| users            |
| workflow_edges   |
| workflow_nodes   |
| workflows        |
+------------------+

======================================
数据库初始化完成！
======================================
```

---

## 项目部署

### 1. 安装项目依赖

```bash
cd /opt/ops-workflow-center

# 安装 npm 依赖（需要 5-10 分钟）
npm install
```

**如果遇到网络问题，使用国内镜像：**
```bash
npm config set registry https://registry.npmmirror.com
npm install
```

### 2. 构建前端

```bash
npm run build
```

**预期输出：**
```
vite v6.0.7 building for production...
✓ 1234 modules transformed.
dist/index.html                   1.23 kB │ gzip: 0.56 kB
dist/assets/index-abc123.css     45.67 kB │ gzip: 12.34 kB
dist/assets/index-def456.js     234.56 kB │ gzip: 78.90 kB
✓ built in 12.34s
```

### 3. 安装 Playwright 浏览器

```bash
npx playwright install chromium firefox webkit
```

### 4. 创建必要的目录

```bash
mkdir -p logs
mkdir -p uploads
mkdir -p uploads/sop-images
```

### 5. 配置前端环境变量

```bash
vi .env.production
```

内容：
```bash
# 服务提供商 (custom = 使用 MySQL 本地部署)
VITE_SERVICE_PROVIDER=custom

# API 服务器地址（根据实际情况修改）
VITE_API_URL=http://your-server-ip:3001
```

**注意：** 如果使用域名或 Nginx 代理，需要相应修改 `VITE_API_URL`

---

## 服务启动

### 1. 使用 PM2 启动服务

```bash
cd /opt/ops-workflow-center

# 启动服务
pm2 start ecosystem.config.cjs

# 查看状态
pm2 status

# 查看日志
pm2 logs
```

**预期输出：**
```
┌─────┬───────────────────────────┬─────────────┬─────────┬─────────┬──────────┐
│ id  │ name                      │ mode        │ ↺       │ status  │ cpu      │
├─────┼───────────────────────────┼─────────────┼─────────┼─────────┼──────────┤
│ 0   │ ops-api-server            │ fork        │ 0       │ online  │ 0%       │
│ 1   │ ops-playwright-server     │ fork        │ 0       │ online  │ 0%       │
└─────┴───────────────────────────┴─────────────┴─────────┴─────────┴──────────┘
```

### 2. 设置开机自启动

```bash
# 保存 PM2 配置
pm2 save

# 生成开机启动脚本
pm2 startup

# 按照输出的提示执行命令（类似下面的命令）
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u your-user --hp /home/your-user
```

### 3. PM2 常用命令

```bash
# 查看所有进程
pm2 list

# 查看详细信息
pm2 show ops-api-server

# 查看日志
pm2 logs                          # 所有日志
pm2 logs ops-api-server           # API 服务器日志
pm2 logs ops-playwright-server    # Playwright 服务器日志

# 重启服务
pm2 restart ops-api-server
pm2 restart all

# 停止服务
pm2 stop ops-api-server
pm2 stop all

# 删除服务
pm2 delete ops-api-server
pm2 delete all

# 监控
pm2 monit
```

---

## Nginx 配置

### 1. 安装 Nginx

```bash
sudo yum install -y nginx

# 启动 Nginx
sudo systemctl start nginx

# 设置开机自启动
sudo systemctl enable nginx
```

### 2. 配置反向代理

创建配置文件：

```bash
sudo vi /etc/nginx/conf.d/ops-workflow-center.conf
```

内容：

```nginx
# 运维工作流中心 Nginx 配置

upstream api_backend {
    server 127.0.0.1:3001;
}

upstream playwright_backend {
    server 127.0.0.1:3002;
}

server {
    listen 80;
    server_name your-domain.com;  # 替换为你的域名或服务器 IP

    # 前端静态文件
    location / {
        root /opt/ops-workflow-center/dist;
        try_files $uri $uri/ /index.html;
        index index.html;

        # 缓存静态资源
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API 接口代理
    location /api/ {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Playwright 接口代理
    location /playwright/ {
        proxy_pass http://playwright_backend/api/playwright/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;

        # 超时设置（Playwright 可能需要更长时间）
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    # 文件上传大小限制
    client_max_body_size 50M;

    # 日志
    access_log /var/log/nginx/ops-workflow-center-access.log;
    error_log /var/log/nginx/ops-workflow-center-error.log;
}
```

### 3. 测试并重启 Nginx

```bash
# 测试配置文件
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

### 4. 配置防火墙

```bash
# 开放 HTTP 端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# 重载防火墙
sudo firewall-cmd --reload

# 查看已开放的端口
sudo firewall-cmd --list-all
```

---

## 验证测试

### 1. 健康检查

```bash
# API 服务器
curl http://localhost:3001/health

# 预期输出:
# {"status":"ok","timestamp":"2026-01-18T10:00:00.000Z"}

# Playwright 服务器
curl http://localhost:3002/health

# 预期输出:
# {"status":"ok"}
```

### 2. 数据库连接测试

```bash
# 在服务器上执行
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ ops_workflow_center -e "SELECT COUNT(*) FROM users;"
```

### 3. Web 访问测试

打开浏览器访问：

```
http://your-server-ip/
```

或（如果配置了域名）：

```
http://your-domain.com/
```

应该能看到登录页面。

### 4. 注册测试账号

1. 点击"注册"
2. 输入邮箱和密码
3. 点击"注册"
4. 如果成功，会自动跳转到主页面

### 5. 功能测试清单

- [ ] 用户注册
- [ ] 用户登录
- [ ] 创建场景
- [ ] 编辑 SOP 文档
- [ ] 上传图片
- [ ] 创建工作流
- [ ] 拖拽节点
- [ ] 保存工作流
- [ ] 执行工作流
- [ ] 查看执行日志

---

## 常见问题

### Q1: npm install 失败

**问题：** 网络超时或依赖下载失败

**解决方案：**
```bash
# 使用淘宝镜像
npm config set registry https://registry.npmmirror.com

# 清除缓存重试
npm cache clean --force
npm install
```

### Q2: 数据库连接失败

**问题：** `Error: connect ETIMEDOUT` 或 `Access denied`

**解决方案：**
1. 检查网络连接：`ping 192.168.1.70`
2. 检查端口开放：`telnet 192.168.1.70 2883`
3. 验证用户名和密码
4. 检查 OceanBase 租户状态

### Q3: PM2 启动失败

**问题：** 服务无法启动

**解决方案：**
```bash
# 查看详细日志
pm2 logs --lines 100

# 手动启动测试
cd /opt/ops-workflow-center
tsx server/api-server.ts

# 查看错误信息
```

### Q4: Playwright 浏览器无法启动

**问题：** `browserType.launch: Executable doesn't exist`

**解决方案：**
```bash
# 重新安装 Playwright 浏览器
npx playwright install

# 安装系统依赖
npx playwright install-deps
```

### Q5: Nginx 403 错误

**问题：** 访问网站显示 403 Forbidden

**解决方案：**
```bash
# 检查 SELinux 状态
getenforce

# 如果是 Enforcing，临时关闭测试
sudo setenforce 0

# 或者配置 SELinux 策略
sudo setsebool -P httpd_can_network_connect 1
sudo chcon -R -t httpd_sys_content_t /opt/ops-workflow-center/dist/
```

### Q6: 文件上传失败

**问题：** 上传图片时报错

**解决方案：**
```bash
# 检查上传目录权限
ls -la /opt/ops-workflow-center/uploads

# 设置正确的权限
chmod 755 /opt/ops-workflow-center/uploads
chown -R $USER:$USER /opt/ops-workflow-center/uploads

# 检查 Nginx 配置中的上传大小限制
# client_max_body_size 50M;
```

---

## 维护管理

### 日志管理

```bash
# PM2 日志
pm2 logs                    # 实时查看
pm2 logs --lines 200        # 查看最近 200 行
pm2 flush                   # 清空日志

# 日志文件位置
/opt/ops-workflow-center/logs/api-out.log
/opt/ops-workflow-center/logs/api-error.log
/opt/ops-workflow-center/logs/playwright-out.log
/opt/ops-workflow-center/logs/playwright-error.log

# Nginx 日志
/var/log/nginx/ops-workflow-center-access.log
/var/log/nginx/ops-workflow-center-error.log
```

### 数据备份

```bash
# 数据库备份
mysqldump -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ \
  ops_workflow_center > backup_$(date +%Y%m%d_%H%M%S).sql

# 文件备份
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz uploads/

# 定期备份（使用 crontab）
crontab -e

# 添加以下行（每天凌晨 2 点备份）
0 2 * * * /path/to/backup-script.sh
```

### 更新部署

```bash
# 停止服务
pm2 stop all

# 拉取最新代码
git pull origin main

# 安装新依赖
npm install

# 构建前端
npm run build

# 重启服务
pm2 restart all
```

### 性能监控

```bash
# PM2 监控
pm2 monit

# 查看资源使用
pm2 list

# 系统资源
top
htop
df -h
free -h
```

### 安全加固

```bash
# 1. 修改 JWT_SECRET 为强密码
vi .env.server

# 2. 配置 HTTPS（推荐使用 Let's Encrypt）
sudo yum install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com

# 3. 配置防火墙只开放必要端口
sudo firewall-cmd --permanent --remove-port=3001/tcp
sudo firewall-cmd --permanent --remove-port=3002/tcp
sudo firewall-cmd --reload

# 4. 设置文件权限
chmod 600 .env.server
chmod 644 .env.production
```

---

## 附录

### A. 完整的部署流程（快速参考）

```bash
# 1. 准备环境
sudo mkdir -p /opt/ops-workflow-center
sudo chown $USER:$USER /opt/ops-workflow-center
cd /opt/ops-workflow-center

# 2. 上传并解压项目
tar -xzf ops-workflow-center.tar.gz

# 3. 安装依赖
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs mysql nginx
sudo npm install -g pm2

# 4. 配置环境变量
vi .env.server       # 配置数据库连接
vi .env.production   # 配置 API 地址

# 5. 初始化数据库
chmod +x scripts/init-database.sh
./scripts/init-database.sh

# 6. 安装项目依赖和构建
npm install
npm run build
npx playwright install chromium

# 7. 启动服务
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup

# 8. 配置 Nginx
sudo vi /etc/nginx/conf.d/ops-workflow-center.conf
sudo nginx -t
sudo systemctl restart nginx

# 9. 配置防火墙
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# 10. 验证
curl http://localhost:3001/health
```

### B. 环境变量清单

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `VITE_SERVICE_PROVIDER` | 服务提供商 | `supabase` | ✅ |
| `VITE_API_URL` | API 地址 | `http://localhost:3001` | ✅ |
| `DB_HOST` | 数据库主机 | `localhost` | ✅ |
| `DB_PORT` | 数据库端口 | `3306` | ✅ |
| `DB_USER` | 数据库用户 | - | ✅ |
| `DB_PASSWORD` | 数据库密码 | - | ✅ |
| `DB_DATABASE` | 数据库名 | `ops_workflow_center` | ✅ |
| `JWT_SECRET` | JWT 密钥 | - | ✅ |
| `PORT` | API 端口 | `3001` | ❌ |
| `UPLOAD_DIR` | 上传目录 | `./uploads` | ❌ |

### C. 端口说明

| 端口 | 服务 | 说明 |
|------|------|------|
| 80 | Nginx | HTTP 访问 |
| 443 | Nginx | HTTPS 访问（可选）|
| 3001 | API Server | RESTful API 服务 |
| 3002 | Playwright Server | 浏览器自动化服务 |
| 2883 | OceanBase | MySQL 租户端口 |

---

**文档版本**: v1.0
**最后更新**: 2026-01-18
**适用版本**: ops-workflow-center v0.1.0

如有疑问，请参考项目其他文档或联系技术支持。
