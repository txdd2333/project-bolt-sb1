# 🚀 系统启动指南

本文档介绍如何在本地启动和验证 Playwright 浏览器自动化工作流系统。

---

## 📋 前置准备

### 1. 安装 Node.js
确保已安装 Node.js (推荐版本 18 或更高)

验证安装：
```bash
node --version
npm --version
```

### 2. 克隆项目
```bash
cd /path/to/project
```

---

## 🔧 安装依赖

### 步骤 1：安装项目依赖

```bash
npm install
```

这将安装所有前端和后端依赖，包括：
- React、Vite（前端）
- Express、Playwright（后端）
- LogicFlow（工作流编辑器）
- Supabase（数据库）

### 步骤 2：安装 Playwright 浏览器

**⚠️ 重要：** 首次使用必须执行此步骤！

```bash
npx playwright install
```

这将下载 Chromium、Firefox 和 WebKit 浏览器（约 300MB）

---

## 🗄️ 配置数据库

### 检查环境变量

确认 `.env` 文件已配置 Supabase 连接信息：

```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

数据库表已通过 migration 自动创建，无需手动操作。

---

## 🚀 启动服务

需要同时启动 **后端服务** 和 **前端服务**。

### 方式 1：使用两个终端（推荐）

**终端 1 - 启动后端服务：**
```bash
npm run server
```

输出示例：
```
🚀 Playwright Backend Server running on http://localhost:3001
📊 Health check: http://localhost:3001/health
```

**终端 2 - 启动前端服务：**
```bash
npm run dev
```

输出示例：
```
VITE v6.0.7  ready in 1234 ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
```

### 方式 2：使用 tmux 或 screen（可选）

如果熟悉 tmux：
```bash
# 创建新会话
tmux new -s workflow

# 启动后端
npm run server

# 按 Ctrl+B 然后 C 创建新窗口
npm run dev

# 按 Ctrl+B 然后 0/1 切换窗口
```

---

## ✅ 验证服务

### 1. 验证后端服务

在浏览器或终端访问：
```bash
curl http://localhost:3001/health
```

预期响应：
```json
{"status":"ok","service":"playwright-backend"}
```

### 2. 验证前端服务

在浏览器打开：
```
http://localhost:5173
```

应该看到登录页面。

### 3. 登录系统

使用注册的账号登录，或点击"注册"创建新账号。

---

## 🎯 快速验证 Playwright 功能

### 步骤 1：创建测试工作流

1. 登录后，导航到 **工作流管理**
2. 点击 **新建工作流**，输入名称："测试打开标签页"
3. 点击编辑按钮进入编辑器

### 步骤 2：构建简单工作流

1. 拖拽 **开始** 节点到画布
2. 拖拽 **浏览器** 节点到画布
3. 拖拽 **结束** 节点到画布
4. 连接节点：开始 → 浏览器 → 结束

### 步骤 3：配置浏览器节点

1. 点击浏览器节点
2. 在右侧配置面板中：
   - 操作类型：打开标签页
   - 标签页数量：3
   - URL列表：`https://google.com, https://github.com, https://stackoverflow.com`

### 步骤 4：保存并执行

1. 点击右上角 **保存工作流**
2. 点击 **执行工作流** 按钮
3. 观察：浏览器窗口会自动打开，并打开 3 个标签页！

### 步骤 5：查看执行日志

在后端终端（运行 `npm run server` 的窗口）查看执行日志：

```
Workflow exec_1234567890_abc started
✅ Node: start - Workflow started
✅ Node: playwright - Successfully executed open_tabs
   Result: { pagesCreated: 3, totalPages: 3 }
✅ Node: end - Workflow completed
```

---

## 🐛 故障排查

### 问题 1：后端服务启动失败

**错误信息：** `Error: Cannot find module 'express'`

**解决方案：**
```bash
npm install
```

### 问题 2：Playwright 浏览器未安装

**错误信息：** `Error: Executable doesn't exist at ...`

**解决方案：**
```bash
npx playwright install
```

### 问题 3：端口被占用

**错误信息：** `Error: listen EADDRINUSE: address already in use :::3001`

**解决方案：**
```bash
# 查找占用端口的进程
lsof -i :3001

# 杀死进程
kill -9 <PID>

# 或者修改端口
PORT=3002 npm run server
```

### 问题 4：前端连接不到后端

**检查：**
1. 确认后端服务正在运行（`http://localhost:3001/health`）
2. 检查浏览器控制台错误信息
3. 确认防火墙未阻止 3001 端口

### 问题 5：数据库连接失败

**检查：**
1. `.env` 文件是否正确配置
2. Supabase 项目是否正常运行
3. 网络连接是否正常

---

## 📊 系统架构

```
┌─────────────────────────────────────────────────┐
│              浏览器 (localhost:5173)            │
│  ┌─────────────────────────────────────────┐   │
│  │         React + Vite 前端              │   │
│  │  - 工作流编辑器 (LogicFlow)            │   │
│  │  - 场景管理                             │   │
│  │  - 属性配置面板                         │   │
│  └─────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────┘
                 │ HTTP/REST API
                 ▼
┌─────────────────────────────────────────────────┐
│        后端服务 (localhost:3001)               │
│  ┌─────────────────────────────────────────┐   │
│  │      Express Server                     │   │
│  │  - Playwright 执行引擎                  │   │
│  │  - 工作流运行器                         │   │
│  │  - 实时日志流                           │   │
│  └─────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────┘
                 │ Playwright API
                 ▼
┌─────────────────────────────────────────────────┐
│           浏览器自动化层                        │
│  - Chromium (Chrome/Edge)                       │
│  - Firefox                                      │
│  - WebKit (Safari)                              │
└─────────────────────────────────────────────────┘
```

---

## 📁 项目结构

```
project/
├── src/                          # 前端源代码
│   ├── components/               # React 组件
│   │   ├── LogicFlowEditor/     # 工作流编辑器
│   │   │   └── nodes/           # 节点定义
│   │   │       └── PlaywrightNode.ts  # Playwright 节点
│   │   └── PlaywrightPropertiesPanel.tsx  # 配置面板
│   ├── pages/                   # 页面组件
│   │   ├── WorkflowEditorPage.tsx    # 工作流编辑
│   │   └── ScenarioDetailPage.tsx    # 场景详情
│   └── services/                # 服务层
│       └── playwright/          # Playwright 服务
│           └── PlaywrightService.ts
│
├── server/                      # 后端源代码
│   ├── index.ts                # Express 服务器
│   ├── playwright-executor.ts  # Playwright 执行引擎
│   └── workflow-runner.ts      # 工作流运行器
│
├── supabase/                   # 数据库迁移
│   └── migrations/             # SQL 迁移文件
│
├── package.json                # 依赖配置
├── STARTUP_GUIDE.md           # 本文档
└── PLAYWRIGHT_GUIDE.md        # Playwright 使用指南
```

---

## 📚 相关文档

- [Playwright 使用指南](./PLAYWRIGHT_GUIDE.md) - 详细的功能使用说明
- [数据库文档](./DATABASE.md) - 数据库结构说明
- [开发文档](./DEVELOPMENT.md) - 开发环境配置

---

## ✨ 下一步

1. ✅ 验证基本功能正常工作
2. 📖 阅读 [Playwright 使用指南](./PLAYWRIGHT_GUIDE.md)
3. 🎯 创建您的第一个自动化工作流
4. 🔗 将工作流关联到应急场景
5. ▶️ 执行工作流并观察浏览器自动化操作

---

## 🆘 获取帮助

遇到问题？
1. 检查终端输出的错误信息
2. 查看浏览器控制台 (F12)
3. 参考本文档的故障排查部分
4. 查看 Playwright 官方文档：https://playwright.dev

---

**祝您使用愉快！** 🎉
