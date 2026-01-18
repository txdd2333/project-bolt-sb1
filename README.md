# 运维工作流中心

> 企业级运维工作流管理平台，支持 MySQL/OceanBase 数据库

---

## 🚀 快速开始

### 🎯 双引擎架构 - 灵活切换数据库

**一套代码，两种引擎，随意切换！**

```
Supabase（云端）        MySQL/OceanBase（本地）
     ↓                         ↓
快速开发、多人协作        生产部署、内网隔离
```

👉 **双引擎快速上手**: [QUICKSTART_DUAL_ENGINE.md](QUICKSTART_DUAL_ENGINE.md) ⭐ 30 秒理解
👉 **详细架构说明**: [DUAL_ENGINE_GUIDE.md](DUAL_ENGINE_GUIDE.md)

**快速切换**：
```bash
# 切换到 Supabase（云端开发）
bash switch-to-supabase.sh  # Windows: switch-to-supabase.bat
npm run dev

# 切换到 MySQL/OceanBase（本地部署）
bash switch-to-mysql.sh     # Windows: switch-to-mysql.bat
npm run server              # 终端 1
npm run dev                 # 终端 2
```

---

### 开发验证（推荐先在 Windows 上验证功能）

👉 **Windows 开发**: [WINDOWS_QUICKSTART.md](WINDOWS_QUICKSTART.md) ⭐ 5 分钟启动

```powershell
# Windows PowerShell
npm install

# 选择引擎（二选一）
.\switch-to-supabase.bat   # 云端开发（推荐先试）
.\switch-to-mysql.bat      # 本地开发

npm run dev
# 访问 http://localhost:5173
```

**优势**：快速迭代、功能验证、并行准备生产环境

---

## 🎯 生产环境部署（使用 MySQL/OceanBase）

### ⚠️ CentOS 7 用户必读

本项目是 **Node.js 应用**，需要先���装 Node.js。

👉 **CentOS 7 部署**: [START_HERE_CENTOS7.md](START_HERE_CENTOS7.md) ⭐ 7 分钟完成部署

**Node.js 版本说明**：
- ✅ **Node.js 16-22 全部兼容** - 无需降级
- ✅ **功能完全一致** - 无任何影响
- ✅ **性能差异 <5%** - 用户无感知
- 📖 [兼容性详情](NODEJS_VERSION_COMPATIBILITY.md)

**快速安装**：
```bash
# 下载 Node.js 16（在有网络的机器上）
wget https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.gz
scp node-v16.20.2-linux-x64.tar.gz root@服务器IP:/tmp/

# 在 CentOS 7 上安装
sudo bash install-nodejs-centos7.sh
```

📖 **详细指南**: [CENTOS7_NODEJS_INSTALL.md](CENTOS7_NODEJS_INSTALL.md)

---

### 部署方式选择

| 部署方式 | 适用场景 | 部署时间 | 推荐指数 |
|---------|---------|---------|---------|
| **离线部署** | 内网环境、无法访问外网 | 5 分钟 | ⭐⭐⭐⭐⭐ |
| **Docker 部署** | 有外网访问、容器化环境 | 10 分钟 | ⭐⭐⭐⭐ |

---

### 🚀 方式1: 离线部署（推荐 - 无需 Docker）

**适合内网环境、无法访问 Docker Hub 的情况**

**前置要求**: Node.js 16+ 已安装

```bash
# 一键部署（使用 PM2 或 systemd）
sudo bash deploy-without-docker.sh
```

📖 **详细文档**: [OFFLINE_DEPLOYMENT.md](OFFLINE_DEPLOYMENT.md)
📖 **快速开始**: [QUICKSTART_OFFLINE.md](QUICKSTART_OFFLINE.md)

**快速管理命令**：
```bash
sudo bash start.sh      # 启动服务
sudo bash stop.sh       # 停止服务
sudo bash restart.sh    # 重启服务
```

---

### 🐳 方式2: Docker 部署

**需要能访问 Docker Hub 或有离线镜像**

```bash
sudo bash docker-deploy.sh
```

📖 **详细文档**: [MYSQL_DEPLOYMENT.md](MYSQL_DEPLOYMENT.md)

---

### 数据库配置

#### 使用 OceanBase 数据库

👉 **[OceanBase 快速部署指南](OCEANBASE_QUICKSTART.md)** ⭐

您的配置：
```bash
数据库地址: 192.168.1.70:2883
用户名: root@Tianji4_MySQL#Tianji4
数据库: ops_workflow_center
```

#### 使用标准 MySQL

👉 **[MySQL 部署操作手册](MySQL部署操作手册.md)**

#### 配置文档

- **[OFFLINE_DEPLOYMENT.md](OFFLINE_DEPLOYMENT.md)** - 离线部署完整指南 ⭐
- **[OCEANBASE_CONFIG.md](OCEANBASE_CONFIG.md)** - OceanBase 配置详解
- **[MYSQL_DEPLOYMENT.md](MYSQL_DEPLOYMENT.md)** - Docker 部署技术文档
- **[START_HERE_MYSQL.md](START_HERE_MYSQL.md)** - MySQL 部署总览
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - 部署检查清单

---

## 🎯 开发环境（首次接手项目）

> **新工程师请注意**：如果你是第一次接触这个项目，建议按以下顺序阅读：
>
> 1. **[QUICKSTART_NEW_ENGINEER.md](./QUICKSTART_NEW_ENGINEER.md)** - 5分钟快速启动 🚀
> 2. **[HANDOVER_DOCUMENT.md](./HANDOVER_DOCUMENT.md)** - 完整交接文档 📚
> 3. 开始开发！

---

## 📖 文档导航

本项目包含完整的交接文档，帮助新工程师快速上手：

### 必读文档（按顺序阅读）
| 文档 | 说明 | 阅读时间 |
|------|------|----------|
| **[QUICKSTART_NEW_ENGINEER.md](./QUICKSTART_NEW_ENGINEER.md)** | 新工程师快速上手指南 | 5分钟 |
| **[HANDOVER_DOCUMENT.md](./HANDOVER_DOCUMENT.md)** | 完整项目交接文档 | 20分钟 |

### 参考文档
| 文档 | 说明 | 适用场景 |
|------|------|----------|
| **[DATABASE.md](./DATABASE.md)** | 数据库文档 | 操作数据库时参考 |
| **[DEVELOPMENT.md](./DEVELOPMENT.md)** | 开发规范 | 编写代码时遵循 |
| **[PLAYWRIGHT_GUIDE.md](./PLAYWRIGHT_GUIDE.md)** | Playwright 使用指南 | 开发自动化功能时参考 |

### 快速脚本
| 脚本 | 说明 |
|------|------|
| **[scripts/setup-database.sql](./scripts/setup-database.sql)** | 一键初始化数据库 |
| **[scripts/create-test-data.sql](./scripts/create-test-data.sql)** | 创建测试数据 |

---

## 🚀 快速开始

### 1. 安装依赖
```bash
npm install
```

### 2. 配置环境变量
创建 `.env` 文件：
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 3. 启动开发服务器
```bash
npm run dev
```

浏览器打开 `http://localhost:5173`

---

## 🎯 项目概览

### 核心功能
- **场景管理**: 创建和管理运维场景
- **SOP 文档**: Markdown 富文本编辑器
- **流程图**: 可视化流程设计器（X6）
- **工作流**: 可执行的自动化流程
- **执行日志**: 追踪工作流执行历史

### 技术栈
- **前端**: React 18 + TypeScript + Vite
- **UI**: Tailwind CSS
- **图形编辑器**: AntV X6
- **数据库**: Supabase (PostgreSQL)
- **认证**: Supabase Auth

---

## ⚠️ 当前状态（最后更新：2026-01-18）

### ✅ 已完成
- ✅ 基础页面和路由
- ✅ 用户认证（Supabase Auth）
- ✅ 场景 CRUD 和 SOP 文档编辑
- ✅ 工作流可视化编辑器（LogicFlow）
- ✅ 模块管理（含测试功能）🆕
- ✅ Playwright 自动化引擎（支持3种浏览器）🆕
- ✅ 工作流执行和日志记录
- ✅ 数据库架构和 RLS 策略

### 🆕 最新功能（2026-01-18）
1. **模块测试功能** - 点击绿色播放按钮即可测试单个模块
2. **浏览器类型选择** - 支持 Chromium、Firefox、WebKit
3. **模块分组显示** - 工作流编辑器中"我的模块"单独分组
4. **完整的执行引擎** - 支持模块节点的真实执行

### 📋 待办事项
- [ ] 实现模块创建对话框（P1）
- [ ] 实现模块编辑功能（P1）
- [ ] 添加工作流模板功能（P2）
- [ ] 实现工作流调度（定时执行）（P3）

详见 [HANDOVER_DOCUMENT.md](./HANDOVER_DOCUMENT.md#-待办事项)

---

## 📂 项目结构

```
ops-workflow-center/
├── src/
│   ├── components/          # 可复用组件
│   │   ├── LogicFlowEditor/ # LogicFlow 编辑器（主要编辑器）🆕
│   │   ├── ReactFlowEditor/ # ReactFlow 编辑器（备选）
│   │   ├── BpmnEditor/     # BPMN 编辑器（备选）
│   │   ├── PlaywrightPropertiesPanel.tsx  # 配置面板 🆕
│   │   ├── MarkdownEditor.tsx
│   │   └── Layout.tsx
│   ├── pages/              # 页面组件
│   │   ├── ScenariosPage.tsx
│   │   ├── ScenarioDetailPage.tsx
│   │   ├── ModulesPage.tsx      # 含测试功能 🆕
│   │   ├── WorkflowsPage.tsx
│   │   ├── WorkflowEditorPage.tsx
│   │   └── ExecutionLogsPage.tsx
│   ├── services/           # 服务层 🆕
│   │   ├── auth/          # 认证服务
│   │   ├── data/          # 数据服务
│   │   ├── playwright/    # Playwright 服务
│   │   └── storage/       # 存储服务
│   ├── contexts/           # React Context
│   ├── hooks/              # 自定义 Hooks
│   └── lib/                # 工具库
├── server/                 # 后端服务 🆕
│   ├── index.ts            # Express 服务器
│   ├── playwright-executor.ts  # 执行引擎
│   └── workflow-runner.ts   # 工作流运行器
├── scripts/                # 脚本工具 🆕
│   ├── setup-database.sql    # 数据库初始化
│   └── create-test-data.sql  # 测试数据
├── supabase/
│   └── migrations/         # 数据库迁移文件
├── QUICKSTART_NEW_ENGINEER.md  # 新工程师快速上手 ⭐
├── HANDOVER_DOCUMENT.md    # 完整交接文档 ⭐
├── DATABASE.md             # 数据库文档
├── DEVELOPMENT.md          # 开发规范
├── PLAYWRIGHT_GUIDE.md     # Playwright 指南
└── README.md               # 本文件
```

---

## 🛠️ 常用命令

```bash
# 前端开发
npm run dev              # 启动前端开发服务器（http://localhost:5173）
npm run build            # 构建生产版本
npm run preview          # 预览生产构建

# 后端开发（必需）
npm run server           # 启动后端服务（http://localhost:3001）
npm run server:build     # 构建后端 TypeScript

# Playwright（首次运行）
npx playwright install   # 安装浏览器二进制文件

# 完整启动（需要两个终端）
# 终端1: npm run dev
# 终端2: npm run server
```

---

## 🗄️ 数据库

### 核心表
- `scenarios` - 场景信息
- `workflows` - 工作流定义
- `modules` - 可复用模块
- `execution_logs` - 执行日志

### 迁移
所有迁移已自动应用，无需手动执行。

详见 [DATABASE.md](./DATABASE.md)

---

## 🔐 认证

- 邮箱密码认证（Supabase Auth）
- 无需邮箱验证
- RLS 保护所有表数据

---

## 🆘 遇到问题？

### 常见问题
- **编译错误**: 删除 `node_modules` 重新安装
- **页面白屏**: 检查浏览器控制台（F12）
- **数据库连接失败**: 检查 `.env` 配置
- **后端无法连接**: 确保 `npm run server` 已启动
- **Playwright 报错**: 运行 `npx playwright install`
- **模块测试失败**: 检查后端服务和浏览器安装

详见 [QUICKSTART_NEW_ENGINEER.md](./QUICKSTART_NEW_ENGINEER.md#-常见问题快速解决)

---

## 📞 技术支持

### 官方文档
- [Supabase 文档](https://supabase.com/docs)
- [AntV X6 文档](https://x6.antv.antgroup.com/)
- [React 文档](https://react.dev/)
- [Tailwind CSS 文档](https://tailwindcss.com/docs)

### 项目文档
- 快速上手 → [QUICKSTART_NEW_ENGINEER.md](./QUICKSTART_NEW_ENGINEER.md)
- 完整交接 → [HANDOVER_DOCUMENT.md](./HANDOVER_DOCUMENT.md)
- 数据库操作 → [DATABASE.md](./DATABASE.md)
- 编码规范 → [DEVELOPMENT.md](./DEVELOPMENT.md)
- Playwright → [PLAYWRIGHT_GUIDE.md](./PLAYWRIGHT_GUIDE.md)

---

## 📊 开发进度

| 阶段 | 状态 | 完成情况 |
|------|------|----------|
| 第一阶段：基础架构 | ✅ 已完成 | 100% |
| 第二阶段：核心功能 | ✅ 已完成 | 100% |
| 第三阶段：执行引擎 | ✅ 已完成 | 100% |
| 第四阶段：模块系统 | ✅ 已完成 | 90% (创建/编辑待完善) |
| 第五阶段：功能增强 | 🔄 进行中 | 待定 |

详见 [HANDOVER_DOCUMENT.md](./HANDOVER_DOCUMENT.md#-待办事项)

---

## 👥 贡献指南

1. 阅读 [DEVELOPMENT.md](./DEVELOPMENT.md) 了解代码规范
2. 查看 [HANDOVER_DOCUMENT.md](./HANDOVER_DOCUMENT.md#-待办事项) 选择任务
3. 创建功能分支
4. 编写代码并测试
5. 提交代码（遵循提交信息规范）

---

## 📝 更新日志

### v0.1.0 (2026-01-18)
- ✅ 初始项目搭建
- ✅ 用户认证功能（Supabase Auth）
- ✅ 场景管理和 SOP 文档编辑
- ✅ 工作流可视化编辑器（LogicFlow）
- ✅ 模块管理系统
- ✅ **模块测试功能** 🆕
- ✅ **多浏览器支持** (Chromium/Firefox/WebKit) 🆕
- ✅ Playwright 自动化执行引擎
- ✅ 工作流执行日志系统
- ✅ 数据库架构和 RLS 策略
- ✅ **完整交接文档** 🆕

---

**项目状态**: 功能完善中
**最后更新**: 2026-01-18
**维护者**: 开发团队

---

## 🎯 下一步行动

### 新工程师
1. **阅读** [QUICKSTART_NEW_ENGINEER.md](./QUICKSTART_NEW_ENGINEER.md) - 5分钟快速上手
2. **查看** [HANDOVER_DOCUMENT.md](./HANDOVER_DOCUMENT.md) - 全面了解项目
3. **执行** `scripts/setup-database.sql` - 初始化数据库
4. **运行** `scripts/create-test-data.sql` - 创建测试数据
5. **启动** 项目并验证所有功能
6. **实现** 模块创建/编辑功能（优先级最高）

### 继续开发
- 实现模块创建对话框
- 完善模块编辑功能
- 添加工作流模板
- 实现定时任务调度

祝开发顺利！🚀
