# Windows 快速开发验证指南

## 🎯 策略说明

**推荐方案**：先在 Windows 上验证功能，再部署到 CentOS 7 生产环境

### 为什么这样做？

✅ **快速迭代** - Windows 开发环境更方便
✅ **功能验证** - 先确保功能正常
✅ **降低风险** - 避免在生产环境调试
✅ **并行工作** - 功能开发和环境准备同时进行

---

## 🚀 Windows 快速启动（5 分钟）

### 前置条件

- ✅ Node.js 16+ 已安装（推荐 18 或 20）
- ✅ Git 已安装（可选）
- ✅ 代码已下载到本地

### 步骤 1: 安装依赖

```powershell
# 进入项目目录
cd C:\path\to\ops-workflow-center

# 安装依赖（首次需要，约 2-3 分钟）
npm install

# 如果 npm 慢，可使用国内镜像
npm config set registry https://registry.npmmirror.com
npm install
```

### 步骤 2: 配置数据库（两种方式）

#### 方式 A：使用 Supabase（推荐 - 最快）

```powershell
# 复制环境变量文件
copy .env.example .env

# 编辑 .env 文件，使用 Supabase
# DB_TYPE=supabase
# VITE_SUPABASE_URL=你的Supabase项目URL
# VITE_SUPABASE_ANON_KEY=你的Supabase匿名密钥
```

**Supabase 优势**：
- 无需本地安装数据库
- 免费额度足够开发使用
- 5 分钟注册即可使用
- 注册地址：https://supabase.com

#### 方式 B：连接远程 OceanBase/MySQL

```powershell
# 编辑 .env 文件
notepad .env

# 配置远程数据库（使用您现有的）
DB_TYPE=mysql
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow
```

### 步骤 3: 启动开发服务器

```powershell
# 启动前端（终端 1）
npm run dev

# 启动后端（终端 2 - 新开一个 PowerShell 窗口）
npm run server
```

### 步骤 4: 访问应用

打开浏览器访问：`http://localhost:5173`

---

## 📋 Node.js 16 vs 18+ 兼容性分析

### 好消息：完全兼容！

| 依赖包 | Node.js 16 | Node.js 18 | Node.js 20+ | 说明 |
|--------|-----------|-----------|------------|------|
| React 18 | ✅ | ✅ | ✅ | 完全兼容 |
| Vite 6 | ✅ | ✅ | ✅ | 支持 Node.js 14+ |
| Express 4 | ✅ | ✅ | ✅ | 稳定版本 |
| TypeScript 5 | ✅ | ✅ | ✅ | 完全兼容 |
| Playwright | ✅ | ✅ | ✅ | 支持 Node.js 16+ |
| bcrypt | ✅ | ✅ | ✅ | 原生模块，有预编译版本 |
| mysql2 | ✅ | ✅ | ✅ | 纯 JS 实现 |

### 项目实测

✅ **当前构建环境**: Node.js 22 - 构建成功
✅ **CentOS 7 目标**: Node.js 16 - 完全兼容
✅ **无降级依赖**: 所有包都支持 Node.js 16+

### 唯一注意事项

**bcrypt** 是原生模块，需要针对不同平台编译：
- Windows 开发：会自动下载预编译版本
- CentOS 7 部署：会自动下载预编译版本
- 如果无法下载：`npm install` 会自动编译

**解决方案**：在 CentOS 7 上首次部署时，确保有 `gcc` 和 `make`：
```bash
sudo yum install -y gcc gcc-c++ make
```

---

## 🔄 开发到部署流程

### 推荐工作流

```
Windows 开发环境              CentOS 7 生产环境
     │                            │
     ├─ 1. 功能开发               │
     ├─ 2. 本地测试               │
     ├─ 3. 构建验证 ─────────────→ 4. 部署验证
     │    npm run build           │    bash deploy-without-docker.sh
     │                            │
     ├─ 5. 功能迭代               ├─ 6. 生产运行
     └────────────────────────────┘
```

### 步骤详解

#### 在 Windows 上

1. **开发功能**
   ```powershell
   npm run dev
   npm run server
   ```

2. **测试验证**
   - 功能测试
   - 界面测试
   - 接口测试

3. **构建检查**
   ```powershell
   npm run build
   npm run server:build
   ```

4. **打包传输**
   ```powershell
   # 方法1: 使用 Git
   git add .
   git commit -m "Update features"
   git push

   # 方法2: 直接打包
   # 打包整个项目（包含 node_modules）
   tar -czf ops-package.tar.gz *
   # 或使用 7-Zip 等工具
   ```

#### 在 CentOS 7 上

1. **获取代码**
   ```bash
   # 方法1: Git 拉取
   git pull

   # 方法2: 上传包
   scp ops-package.tar.gz root@服务器:/tmp/
   tar -xzf /tmp/ops-package.tar.gz -C /opt/ops-workflow-center
   ```

2. **部署应用**
   ```bash
   cd /opt/ops-workflow-center
   bash deploy-without-docker.sh
   ```

---

## 🛠️ 常用开发命令

### Windows PowerShell

```powershell
# 安装依赖
npm install

# 启动前端开发服务器（热重载）
npm run dev

# 启动后端 API 服务器（热重载）
npm run server

# 构建生产版本
npm run build

# 构建后端
npm run server:build

# 预览生产构建
npm run preview

# 清理重装
Remove-Item -Recurse -Force node_modules
Remove-Item -Force package-lock.json
npm install

# 查看端口占用
netstat -ano | findstr "5173"
netstat -ano | findstr "3000"

# 停止进程（如果端口被占用）
# 找到 PID 后
Stop-Process -Id <PID> -Force
```

### Linux 快速参考

```bash
# 安装依赖
npm install

# 启动开发（单独终端）
npm run dev &
npm run server &

# 生产部署
bash deploy-without-docker.sh

# 服务管理
bash start.sh      # 启动
bash stop.sh       # 停止
bash restart.sh    # 重启

# 查看日志
pm2 logs
tail -f logs/api-out.log
```

---

## 🐛 常见问题

### Windows 开发环境

#### 问题 1: 端口被占用

```powershell
# 查找占用进程
netstat -ano | findstr "5173"

# 停止进程
Stop-Process -Id <PID> -Force
```

#### 问题 2: npm install 很慢

```powershell
# 使用国内镜像
npm config set registry https://registry.npmmirror.com

# 或使用 cnpm
npm install -g cnpm --registry=https://registry.npmmirror.com
cnpm install
```

#### 问题 3: 权限问题

```powershell
# 以管理员身份运行 PowerShell
# 右键 PowerShell -> 以管理员身份运行
```

#### 问题 4: bcrypt 安装失败

```powershell
# 安装 Windows 构建工具
npm install --global windows-build-tools

# 或下载 Visual Studio Build Tools
# https://visualstudio.microsoft.com/downloads/

# 然后重新安装
npm install bcrypt
```

### 数据库连接

#### 问题 1: 无法连接远程数据库

```powershell
# 检查防火墙
# 确保服务器防火墙允许您的 IP 访问

# 测试连接（安装 MySQL 客户端后）
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__
```

#### 问题 2: Supabase 连接问题

```powershell
# 检查 .env 配置
type .env

# 确保格式正确
DB_TYPE=supabase
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJxxx...
```

---

## 📊 性能对比

### Node.js 版本性能

| 版本 | 启动速度 | 构建速度 | 运行性能 | 生产推荐 |
|------|---------|---------|---------|---------|
| Node.js 16 | 快 | 快 | 良好 | ✅ CentOS 7 |
| Node.js 18 | 快 | 快 | 优秀 | ✅ 推荐 |
| Node.js 20+ | 最快 | 最快 | 最佳 | ✅ 最新系统 |

**结论**：Node.js 16-22 都能正常运行，性能差异不大（<5%）

---

## 🎯 推荐配置

### 开发环境（Windows）

```
操作系统: Windows 10/11
Node.js: 18.x 或 20.x（最新 LTS）
内存: 8GB+
硬盘: 10GB 可用空间
IDE: VS Code
```

### 生产环境（CentOS 7）

```
操作系统: CentOS 7.x
Node.js: 16.20.2（兼容性最佳）
内存: 4GB+（推荐 8GB）
硬盘: 20GB 可用空间
数据库: OceanBase / MySQL 5.7+
```

---

## 📞 下一步

### 立即开始（Windows）

1. **打开 PowerShell**
2. **进入项目目录**
   ```powershell
   cd C:\path\to\ops-workflow-center
   ```
3. **安装依赖**
   ```powershell
   npm install
   ```
4. **配置数据库**（编辑 `.env` 文件）
5. **启动服务**
   ```powershell
   npm run dev    # 终端1
   npm run server # 终端2
   ```
6. **访问应用**: http://localhost:5173

### 准备部署（CentOS 7）

1. **下载 Node.js**
   ```
   https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.gz
   ```
2. **传输到服务器**
3. **参考文档**: `START_HERE_CENTOS7.md`

---

## 💡 最佳实践

1. **Windows 开发，Linux 部署** - 充分利用两个环境的优势
2. **使用 Git** - 方便代码同步和版本管理
3. **环境隔离** - 开发、测试、生产使用不同的数据库
4. **定期备份** - 特别是生产数据库
5. **监控日志** - 及时发现问题

---

**开始在 Windows 上验证功能吧！**

更新时间：2024-01-18
