# 双引擎快速参考卡片

## 一分钟速查表

### 当前状态

```bash
# 查看当前使用的引擎
cat .env | grep VITE_SERVICE_PROVIDER

# 输出：
# supabase → 使用 Supabase 云端
# custom   → 使用 MySQL/OceanBase 本地
```

---

## 切换命令

### Windows

```powershell
# 切换到 Supabase
.\switch-to-supabase.bat
npm run dev

# 切换到 MySQL
.\switch-to-mysql.bat
npm run server  # 终端 1
npm run dev     # 终端 2
```

### Linux/Mac

```bash
# 切换到 Supabase
bash switch-to-supabase.sh
npm run dev

# 切换到 MySQL
bash switch-to-mysql.sh
npm run server &
npm run dev
```

---

## 快速对比

| 特性 | Supabase | MySQL/OceanBase |
|------|----------|-----------------|
| 启动 | `npm run dev` | `npm run server` + `npm run dev` |
| 配置 | 2 个变量 | 6 个变量 |
| 延迟 | 100ms | 5ms |
| 成本 | 免费/付费 | 硬件 |
| 场景 | 开发/协作 | 生产/内网 |

---

## 故障排除

### Supabase 无法连接

```bash
# 1. 检查配置
cat .env | grep SUPABASE

# 2. 测试连接
curl https://0ec90b57d6e95fcbda19832f.supabase.co

# 3. 检查项目状态
# 访问 https://supabase.com 确认项目未暂停
```

### MySQL 无法连接

```bash
# 1. 检查 API 服务器
ps aux | grep "node.*server"

# 2. 启动 API 服务器
npm run server

# 3. 测试数据库连接
mysql -h192.168.1.70 -P2883 -u'root@Tianji4_MySQL#Tianji4' -p
```

---

## 配置文件

```
.env                  # 当前配置
.env.supabase         # Supabase 预设
.env.mysql            # MySQL 预设
.env.example          # 配置模板
```

---

## 环境变量

### Supabase

```env
VITE_SERVICE_PROVIDER=supabase
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJxxx...
```

### MySQL/OceanBase

```env
VITE_SERVICE_PROVIDER=custom
VITE_API_URL=http://localhost:3000
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center
JWT_SECRET=your-secret-key
```

---

## 常用端口

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端开发 | 5173 | Vite dev server |
| API 服务器 | 3000 | Express API (Custom 引擎) |
| MySQL | 3306 | 标准 MySQL 端口 |
| OceanBase | 2883 | 当前配置端口 |

---

## 一键命令

### 开发环境

```bash
# Supabase（推荐先试）
bash switch-to-supabase.sh && npm run dev

# MySQL（需要数据库）
bash switch-to-mysql.sh && npm run server &
npm run dev
```

### 验证构建

```bash
npm run build
npm run server:build
```

### 查看日志

```bash
# API 服务器日志（Custom 引擎）
npm run server

# Supabase 日志
# 访问 https://supabase.com → Logs
```

---

## 帮助链接

| 文档 | 说明 | 时间 |
|------|------|------|
| [QUICKSTART_DUAL_ENGINE.md](QUICKSTART_DUAL_ENGINE.md) | 快速上手 | 5 分钟 |
| [DUAL_ENGINE_GUIDE.md](DUAL_ENGINE_GUIDE.md) | 完整指南 | 阅读 |
| [ARCHITECTURE_DUAL_ENGINE.md](ARCHITECTURE_DUAL_ENGINE.md) | 架构详解 | 技术 |

---

**打印此页面，贴在显示器旁边！**

更新时间：2024-01-18
