# CentOS 7 安装 Node.js 18+ 指南

## 🎯 方案选择

| 方案 | 优点 | 缺点 | 推荐指数 |
|------|------|------|----------|
| **离线二进制包** | 最简单、无需编译 | 需要从外网下载 | ⭐⭐⭐⭐⭐ |
| **NodeSource 仓库** | 自动安装依赖 | 需要网络访问 | ⭐⭐⭐⭐ |
| **手动编译** | 完全离线 | 耗时长、复杂 | ⭐⭐ |

---

## 🚀 方案1: 离线二进制包安装（推荐）

### 步骤 1: 在有网络的机器上下载

访问 Node.js 官网下载 **Linux x64 二进制包**：
- **下载地址**: https://nodejs.org/dist/v18.19.0/node-v18.19.0-linux-x64.tar.gz
- **版本**: v18.19.0 (LTS 长期支持版本)

或使用命令下载：
```bash
# 在有网络的机器上
wget https://nodejs.org/dist/v18.19.0/node-v18.19.0-linux-x64.tar.gz

# 传输到目标服务器
scp node-v18.19.0-linux-x64.tar.gz root@192.168.1.100:/tmp/
```

### 步骤 2: 在 CentOS 7 服务器上安装

```bash
# 解压到 /usr/local
cd /usr/local
sudo tar -xzf /tmp/node-v18.19.0-linux-x64.tar.gz

# 创建软链接
sudo ln -s /usr/local/node-v18.19.0-linux-x64 /usr/local/node

# 配置环境变量
sudo tee -a /etc/profile.d/nodejs.sh > /dev/null <<EOF
export NODE_HOME=/usr/local/node
export PATH=\$NODE_HOME/bin:\$PATH
EOF

# 使环境变量生效
source /etc/profile.d/nodejs.sh

# 验证安装
node --version
npm --version
```

**预期输出**：
```
v18.19.0
9.2.0
```

### 步骤 3: 配置 npm 镜像（可选，用于将来安装包）

```bash
# 使用淘宝镜像（如果有网络）
npm config set registry https://registry.npmmirror.com

# 或者使用国内其他镜像
npm config set registry https://registry.npm.taobao.org
```

---

## 🚀 方案2: 在有网络的机器上打包完整环境

如果目标服务器完全没有网络，可以在有网络的机器上准备一切。

### 在有网络的机器上（与目标服务器系统版本相同）

```bash
# 1. 安装 Node.js（如上）
cd /usr/local
wget https://nodejs.org/dist/v18.19.0/node-v18.19.0-linux-x64.tar.gz
tar -xzf node-v18.19.0-linux-x64.tar.gz
ln -s /usr/local/node-v18.19.0-linux-x64 /usr/local/node
export PATH=/usr/local/node/bin:$PATH

# 2. 准备项目
cd /path/to/ops-workflow-center
npm install
npm run build
npm run server:build

# 3. 打包 Node.js + 项目
tar -czf ops-full-package.tar.gz \
  /usr/local/node-v18.19.0-linux-x64 \
  -C /path/to/ops-workflow-center \
  dist/ \
  server/ \
  node_modules/ \
  package.json \
  ecosystem.config.cjs \
  .env.example \
  *.sh \
  scripts/

# 4. 传输到目标服务器
scp ops-full-package.tar.gz root@192.168.1.100:/tmp/
```

### 在目标服务器上

```bash
# 1. 解压
cd /
sudo tar -xzf /tmp/ops-full-package.tar.gz

# 2. 配置环境变量
sudo tee /etc/profile.d/nodejs.sh > /dev/null <<EOF
export NODE_HOME=/usr/local/node
export PATH=\$NODE_HOME/bin:\$PATH
EOF

source /etc/profile.d/nodejs.sh

# 3. 验证
node --version
npm --version

# 4. 进入项目目录并启动
cd /opt/ops-workflow-center
cp .env.example .env
vi .env  # 配置数据库

# 安装 PM2
npm install -g pm2

# 启动服务
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup
```

---

## 🚀 方案3: 使用 NodeSource 仓库（需要网络）

如果服务器有网络访问：

```bash
# 安装 Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 验证
node --version
npm --version
```

---

## 🚀 方案4: 使用 nvm（需要网络）

```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 重新加载环境
source ~/.bashrc

# 安装 Node.js 18
nvm install 18
nvm use 18
nvm alias default 18

# 验证
node --version
```

---

## ✅ 安装完成后的验证

```bash
# 检查 Node.js 版本
node --version
# 应输出: v18.x.x

# 检查 npm 版本
npm --version
# 应输出: 9.x.x 或更高

# 检查全局安装位置
which node
# 应输出: /usr/local/node/bin/node

# 测试运行
node -e "console.log('Node.js works!')"
# 应输出: Node.js works!
```

---

## 🔧 常见问题

### 问题 1: node: command not found

**原因**: 环境变量未生效

**解决**:
```bash
# 检查是否存在
ls -la /usr/local/node/bin/node

# 手动设置环境变量
export PATH=/usr/local/node/bin:$PATH

# 或重新加载配置
source /etc/profile.d/nodejs.sh

# 永久生效（添加到 ~/.bashrc）
echo 'export PATH=/usr/local/node/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### 问题 2: npm install 很慢或失败

**解决**:
```bash
# 使用国内镜像
npm config set registry https://registry.npmmirror.com

# 或使用 cnpm
npm install -g cnpm --registry=https://registry.npmmirror.com
cnpm install
```

### 问题 3: 权限问题

**解决**:
```bash
# 修改 Node.js 目录权限
sudo chown -R root:root /usr/local/node-v18.19.0-linux-x64

# 或使用 sudo
sudo npm install -g pm2
```

### 问题 4: GLIBC 版本不兼容

**症状**: `/lib64/libc.so.6: version 'GLIBC_2.27' not found`

**原因**: CentOS 7 默认 GLIBC 是 2.17，Node.js 18 需要 2.27+

**解决方案 A - 使用 Node.js 16** (不推荐，但能用):
```bash
# 下载 Node.js 16（兼容 CentOS 7）
wget https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.gz
```

**解决方案 B - 升级系统** (推荐):
```bash
# 检查当前 GLIBC 版本
ldd --version

# 如果版本低于 2.27，建议升级到 CentOS 8 或更高
# 或使用 Rocky Linux 8 / AlmaLinux 8
```

**解决方案 C - 使用 Docker**:
```bash
# 使用 Docker 容器运行（容器内有新版 GLIBC）
# 参考 OFFLINE_DEPLOYMENT.md 中的 Docker 离线镜像部署
```

---

## 📋 快速参考

### Node.js 版本选择

| 版本 | CentOS 7 兼容性 | 推荐指数 | 说明 |
|------|----------------|---------|------|
| Node.js 16.x | ✅ 完全兼容 | ⭐⭐⭐⭐ | GLIBC 2.17+ |
| Node.js 18.x | ⚠️ 需要 GLIBC 2.27+ | ⭐⭐⭐⭐⭐ | 需要新版 GLIBC |
| Node.js 20.x | ⚠️ 需要 GLIBC 2.28+ | ⭐⭐⭐⭐⭐ | 需要新版 GLIBC |

### 推荐配置

**对于 CentOS 7**：
- **推荐**: Node.js 16.20.2 (最安全)
- **或**: 升级到 CentOS 8 / Rocky Linux 8 后使用 Node.js 18+

**下载链接**：
```bash
# Node.js 16 (兼容 CentOS 7)
https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.gz

# Node.js 18 (需要新版 GLIBC)
https://nodejs.org/dist/v18.19.0/node-v18.19.0-linux-x64.tar.gz
```

---

## 🎯 推荐部署流程（CentOS 7）

### 方案 A: 使用 Node.js 16（最稳妥）

```bash
# 1. 在有网络的机器上下载 Node.js 16
wget https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.gz

# 2. 传输到 CentOS 7 服务器
scp node-v16.20.2-linux-x64.tar.gz root@服务器IP:/tmp/

# 3. 在 CentOS 7 上安装
cd /usr/local
tar -xzf /tmp/node-v16.20.2-linux-x64.tar.gz
ln -s /usr/local/node-v16.20.2-linux-x64 /usr/local/node
echo 'export PATH=/usr/local/node/bin:$PATH' >> /etc/profile.d/nodejs.sh
source /etc/profile.d/nodejs.sh

# 4. 验证
node --version  # 应显示 v16.20.2

# 5. 部署应用
cd /path/to/ops-workflow-center
bash deploy-without-docker.sh
```

### 方案 B: 升级到 Rocky Linux 8（推荐长期使用）

```bash
# Rocky Linux 8 是 CentOS 8 的替代品
# 完全兼容 Node.js 18+
# 迁移指南: https://docs.rockylinux.org/guides/migrate2rocky/
```

---

## 📞 需要帮助？

如果遇到问题：

1. **检查系统版本**:
   ```bash
   cat /etc/redhat-release
   ldd --version
   ```

2. **检查 Node.js**:
   ```bash
   node --version
   which node
   ```

3. **查看详细日志**:
   ```bash
   node --version
   npm --version
   ldd /usr/local/node/bin/node
   ```

---

**更新时间**: 2024-01-18

**推荐**: 使用 Node.js 16.20.2 在 CentOS 7 上部署
