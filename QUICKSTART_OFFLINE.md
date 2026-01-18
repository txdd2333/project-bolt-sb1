# 离线部署快速开始（5 分钟）

## ⚠️ CentOS 7 用户必读

**您的系统**: CentOS 7
**Node.js 要求**: 必需（这是 Node.js 应用）
**推荐版本**: Node.js 16.20.2（完全兼容 CentOS 7）

### 快速安装 Node.js

```bash
# 方法1: 使用一键脚本
sudo bash install-nodejs-centos7.sh

# 方法2: 手动安装（需要先下载安装包）
# 在有网络的机器上：
wget https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.gz
scp node-v16.20.2-linux-x64.tar.gz root@服务器IP:/tmp/

# 在 CentOS 7 上：
cd /usr/local
tar -xzf /tmp/node-v16.20.2-linux-x64.tar.gz
ln -s /usr/local/node-v16.20.2-linux-x64 /usr/local/node
echo 'export PATH=/usr/local/node/bin:$PATH' >> /etc/profile.d/nodejs.sh
source /etc/profile.d/nodejs.sh
node --version  # 验证
```

📖 **详细文档**: [CENTOS7_NODEJS_INSTALL.md](CENTOS7_NODEJS_INSTALL.md)

---

## ✅ 您的环境

根据之前的输出，您的服务器：
- ✅ Docker 已安装（但无法访问 Docker Hub）
- ✅ Docker Compose 已安装
- ✅ 数据库已初始化（OceanBase）
- ✅ .env 已配置
- ❌ Node.js 未安装 ← **需要先安装**

---

## 🚀 立即部署（三种方式任选）

### 方式 1: 使用 PM2 部署（最推荐）

```bash
# 确保在项目目录
cd /tmp/cc-agent/62691514/project

# 一键部署
sudo bash deploy-without-docker.sh
```

这个脚本会自动：
1. 检查 Node.js 环境
2. 检查数据库连接
3. 安装依赖（如果需要）
4. 构建项目
5. 启动服务（使用 PM2 或 nohup）

完成后访问：`http://服务器IP:5173`

---

### 方式 2: 手动启动（最快）

如果您已经有构建好的项目：

```bash
# 快速启动
sudo bash start.sh

# 查看状态
pm2 status   # 如果使用 PM2
# 或
ps aux | grep node   # 如果使用 nohup
```

---

### 方式 3: 逐步部署（理解流程）

#### 步骤 1: 检查 Node.js

```bash
node --version
# 需要 v18 或更高版本
```

#### 步骤 2: 安装依赖（如果没有 node_modules）

```bash
npm install
```

#### 步骤 3: 构建项目

```bash
# 构建前端
npm run build

# 构建后端
npm run server:build
```

#### 步骤 4: 启动服务

**使用 PM2（推荐）**：
```bash
# 安装 PM2
npm install -g pm2

# 启动
pm2 start ecosystem.config.cjs

# 查看状态
pm2 status
pm2 logs

# 设置开机自启
pm2 startup
pm2 save
```

**或使用 nohup**：
```bash
# 加载环境变量
export $(cat .env | grep -v '^#' | xargs)

# 创建日志目录
mkdir -p logs uploads

# 启动后端
nohup node server/api-server.js > logs/api-out.log 2> logs/api-error.log &
echo $! > logs/api.pid

# 启动前端
nohup npx vite preview --host 0.0.0.0 --port 5173 > logs/frontend-out.log 2> logs/frontend-error.log &
echo $! > logs/frontend.pid

# 查看 PID
cat logs/api.pid
cat logs/frontend.pid
```

#### 步骤 5: 配置防火墙

```bash
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=5173/tcp
sudo firewall-cmd --reload
```

#### 步骤 6: 验证部署

```bash
# 测试后端
curl http://localhost:3000/health

# 测试前端
curl http://localhost:5173

# 获取服务器 IP
hostname -I

# 浏览器访问
# http://服务器IP:5173
```

---

## 📊 服务管理

### PM2 方式

```bash
# 查看状态
pm2 status

# 查看日志
pm2 logs

# 重启服务
pm2 restart all

# 停止服务
pm2 stop all

# 删除进程
pm2 delete all

# 监控资源
pm2 monit
```

### nohup 方式

```bash
# 启动
bash start.sh

# 停止
bash stop.sh

# 重启
bash restart.sh

# 查看日志
tail -f logs/api-out.log
tail -f logs/frontend-out.log

# 查看进程
ps aux | grep node

# 手动停止
kill $(cat logs/api.pid)
kill $(cat logs/frontend.pid)
```

---

## 🔍 故障排查

### 问题 1: 端口被占用

```bash
# 查看端口占用
sudo netstat -tulpn | grep -E "3000|5173"

# 杀掉占用进程
sudo kill -9 <PID>
```

### 问题 2: 权限不足

```bash
# 检查文件权限
ls -la

# 修改权限
sudo chown -R $USER:$USER .
chmod +x *.sh
```

### 问题 3: 数据库连接失败

```bash
# 测试连接
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "SELECT 1;"

# 检查 .env 配置
cat .env | grep DB_
```

### 问题 4: npm install 卡住

```bash
# 使用国内镜像
npm config set registry https://registry.npmmirror.com
npm install

# 或使用淘宝镜像
npm config set registry https://registry.npm.taobao.org
npm install
```

### 问题 5: 无法访问外网

这正是我们使用离线部署的原因！

**解决方案**：在有网络的机器上准备：

```bash
# 在有网络的机器上
cd /path/to/project
npm install
npm run build
npm run server:build

# 打包（包含 node_modules）
tar -czf ops-offline.tar.gz \
  dist/ \
  server/ \
  node_modules/ \
  package.json \
  ecosystem.config.cjs \
  .env.example \
  scripts/ \
  *.sh

# 传输到目标服务器
scp ops-offline.tar.gz user@192.168.1.100:/tmp/

# 在目标服务器上解压
cd /opt/ops-workflow-center
tar -xzf /tmp/ops-offline.tar.gz

# 配置 .env 后直接启动
bash start.sh
```

---

## ✅ 验证清单

部署完成后检查：

- [ ] 后端进程正在运行
  ```bash
  pm2 status | grep ops-workflow
  # 或
  ps aux | grep api-server
  ```

- [ ] 前端进程正在运行
  ```bash
  pm2 status | grep ops-workflow
  # 或
  ps aux | grep vite
  ```

- [ ] 端口正在监听
  ```bash
  sudo netstat -tulpn | grep -E "3000|5173"
  ```

- [ ] 后端健康检查通过
  ```bash
  curl http://localhost:3000/health
  # 应返回: {"status":"ok","timestamp":"..."}
  ```

- [ ] 前端可访问
  ```bash
  curl http://localhost:5173
  # 应返回 HTML 内容
  ```

- [ ] 防火墙已配置
  ```bash
  sudo firewall-cmd --list-ports
  # 应包含 3000/tcp 和 5173/tcp
  ```

- [ ] 可以从浏览器访问
  - 打开 `http://服务器IP:5173`
  - 能看到登录/注册页面

- [ ] 功能正常
  - 可以注册新用户
  - 可以登录
  - 可以创建工作流

---

## 📚 相关文档

- **[OFFLINE_DEPLOYMENT.md](OFFLINE_DEPLOYMENT.md)** - 完整离线部署指南
- **[OCEANBASE_CONFIG.md](OCEANBASE_CONFIG.md)** - OceanBase 配置
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - 部署检查清单

---

## 🎯 下一步

部署成功后：

1. 修改 JWT_SECRET 为随机字符串
   ```bash
   vi .env
   # 修改 JWT_SECRET
   bash restart.sh
   ```

2. 创建管理员账号
   - 访问 `http://服务器IP:5173`
   - 注册第一个用户

3. 设置定期备份
   ```bash
   # 添加到 crontab
   crontab -e
   # 添加：
   0 2 * * * mysqldump -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ ops_workflow_center > /backup/ops-$(date +\%Y\%m\%d).sql
   ```

4. 监控日志
   ```bash
   pm2 logs
   # 或
   tail -f logs/api-out.log
   ```

---

**部署完成！开始使用吧！** 🎉

有问题查看：
- 日志文件：`logs/api-out.log` 和 `logs/frontend-out.log`
- 完整文档：[OFFLINE_DEPLOYMENT.md](OFFLINE_DEPLOYMENT.md)

更新时间: 2024-01-18
