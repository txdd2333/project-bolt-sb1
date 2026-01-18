# CentOS 7 部署快速指南

## 当前状态

- ✅ 系统：CentOS 7
- ✅ 数据库：OceanBase 已配置
- ✅ Docker：已安装（但无法访问外网）
- ❌ Node.js：**未安装（必需）**

---

## 🚀 两步完成部署

### 第一步：安装 Node.js（5 分钟）

#### 方法 A：使用一键脚本（推荐）

```bash
cd /tmp/cc-agent/62691514/project

# 先下载 Node.js 安装包（在有网络的机器上）
wget https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.gz

# 传输到服务器
scp node-v16.20.2-linux-x64.tar.gz root@服务器IP:/tmp/

# 在服务器上安装
sudo bash install-nodejs-centos7.sh
```

#### 方法 B：手动安装（3 分钟）

```bash
# 解压
cd /usr/local
tar -xzf /tmp/node-v16.20.2-linux-x64.tar.gz

# 创建软链接
ln -s /usr/local/node-v16.20.2-linux-x64 /usr/local/node

# 配置环境变量
echo 'export PATH=/usr/local/node/bin:$PATH' >> /etc/profile.d/nodejs.sh
source /etc/profile.d/nodejs.sh

# 验证
node --version
```

---

### 第二步：部署应用（2 分钟）

```bash
cd /tmp/cc-agent/62691514/project

# 一键部署
sudo bash deploy-without-docker.sh
```

完成！访问 `http://服务器IP:5173`

---

## 📋 常用命令

```bash
# 启动服务
sudo bash start.sh

# 停止服务
sudo bash stop.sh

# 重启服务
sudo bash restart.sh

# 查看日志
pm2 logs
# 或
tail -f logs/api-out.log
```

---

## 🔍 故障排查

### 问题：找不到 node 命令

```bash
# 重新加载环境变量
source /etc/profile.d/nodejs.sh

# 或手动设置
export PATH=/usr/local/node/bin:$PATH
```

### 问题：端口被占用

```bash
# 查看占用
sudo netstat -tulpn | grep -E "3000|5173"

# 停止进程
sudo kill -9 <PID>
```

### 问题：数据库连接失败

```bash
# 测试连接
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__

# 检查配置
cat .env | grep DB_
```

---

## 📚 详细文档

- **[CENTOS7_NODEJS_INSTALL.md](CENTOS7_NODEJS_INSTALL.md)** - Node.js 安装详细指南
- **[QUICKSTART_OFFLINE.md](QUICKSTART_OFFLINE.md)** - 离线部署快速开始
- **[OFFLINE_DEPLOYMENT.md](OFFLINE_DEPLOYMENT.md)** - 完整离线部署指南
- **[OCEANBASE_QUICKSTART.md](OCEANBASE_QUICKSTART.md)** - OceanBase 配置

---

## ❓ 常见问题

**Q: Node.js 是必需的吗？**
A: 是的，这是一个 Node.js 应用，前端使用 Vite，后端使用 Express。

**Q: CentOS 7 可以运行吗？**
A: 可以！使用 Node.js 16.20.2 完全兼容 CentOS 7。

**Q: 必须用 Docker 吗？**
A: 不必须。推荐使用离线部署方式（PM2 或 systemd）。

**Q: 内网环境如何安装？**
A: 在有网络的机器上下载 Node.js 安装包，然后传输到服务器。

**Q: 需要多大的服务器？**
A: 最低 2 核 4GB 内存，推荐 4 核 8GB。

---

**开始部署吧！只需 7 分钟！**

更新时间：2024-01-18
