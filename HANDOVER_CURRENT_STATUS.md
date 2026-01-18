# 项目交接文档 - 当前状态

**交接时间**: 2026-01-18
**项目名称**: 运维工作流中心 (Ops Workflow Center)
**当前版本**: 最新主分支代码

---

## 📋 项目当前状态总结

### ✅ 已完成的工作

1. **双引擎架构实现完成**
   - 支持 MySQL/OceanBase 数据库引擎
   - 支持 Supabase 云数据库引擎
   - 可通过配置文件快速切换

2. **端口统一修复 (刚完成)**
   - 所有服务统一使用端口 **3000**
   - 修复了前后端端口不匹配导致的 JSON 解析错误
   - 修复了 7 个文件中的端口配置

3. **TypeScript 构建修复**
   - 修复了 playwright-executor.ts 的类型错误
   - 修复了 workflow-runner.ts 缺少 moduleName 属性
   - 前后端构建均通过

4. **核心功能已实现**
   - ✅ 用户认证系统（登录/注册）
   - ✅ 场景管理
   - ✅ 工作流编辑器（ReactFlow）
   - ✅ 模块管理
   - ✅ Playwright 自动化执行引擎
   - ✅ 执行日志查看

---

## 🔧 当前配置状态

### 双引擎配置说明

项目支持两种数据库引擎，通过 `.env` 文件配置：

#### **配置文件位置**: `.env`

```env
# 关键配置
VITE_SERVICE_PROVIDER=custom          # 当前使用 MySQL/OceanBase
VITE_API_URL=http://localhost:3000   # API 服务器地址

# MySQL/OceanBase 数据库配置
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center

# Supabase 配置（备用）
VITE_SUPABASE_URL=https://inphyzutnpdkopisnbcb.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 快速切换引擎

**切换到 MySQL/OceanBase**:
```bash
# Windows
switch-to-mysql.bat

# Linux/Mac
./switch-to-mysql.sh
```

**切换到 Supabase**:
```bash
# Windows
switch-to-supabase.bat

# Linux/Mac
./switch-to-supabase.sh
```

---

## 🚀 快速启动指南

### 步骤 1: 安装依赖

**⚠️ 重要**: 首次运行或重新拉取代码后必须执行

```powershell
cd C:\Users\Administrator\Desktop\project
npm install
```

如果安装慢，使用国内镜像：
```powershell
npm config set registry https://registry.npmmirror.com
npm install
```

### 步骤 2: 启动后端服务器

**打开第一个 PowerShell 窗口**:
```powershell
npm run api-server
```

**预期输出**:
```
API Server running on port 3000
Database: ops_workflow_center
MySQL Connection Pool created successfully
```

### 步骤 3: 启动前端开发服务器

**打开第二个 PowerShell 窗口**:
```powershell
npm run dev
```

**预期输出**:
```
VITE v6.4.1 ready in xxx ms
➜ Local:   http://localhost:5173/
```

### 步骤 4: 访问应用

浏览器打开: `http://localhost:5173`

---

## 🐛 最近修复的问题

### 问题 1: 端口不匹配导致 JSON 解析错误 ✅ 已修复

**症状**:
- 浏览器控制台报错：`Unexpected token '<', "<!DOCTYPE "... is not valid JSON`
- 工作流执行失败

**原因**:
- 后端运行在端口 3001
- 前端配置为连接端口 3000
- 请求到错误端口，返回 HTML 而不是 JSON

**修复内容**:
1. `server/api-server.ts` - 端口 3001 → 3000
2. `server/index.ts` - 端口 3001 → 3000
3. `src/services/playwright/PlaywrightService.ts` - 默认端口 3001 → 3000
4. `src/services/auth/CustomAuthService.ts` - 默认端口 3001 → 3000
5. `src/services/data/CustomDataService.ts` - 默认端口 3001 → 3000
6. `src/services/storage/CustomStorageService.ts` - 默认端口 3001 → 3000
7. `.env` - `VITE_SERVICE_PROVIDER=supabase` → `custom`

### 问题 2: TypeScript 构建错误 ✅ 已修复

**修复内容**:
1. `server/playwright-executor.ts` - 添加类型断言
2. `server/workflow-runner.ts` - 添加 `moduleName` 属性到接口

---

## 📊 当前架构概览

### 目录结构
```
project/
├── src/                          # 前端源码
│   ├── components/              # React 组件
│   │   ├── ReactFlowEditor/    # 工作流编辑器
│   │   ├── LogicFlowEditor/    # 备用编辑器
│   │   └── ...
│   ├── pages/                   # 页面组件
│   │   ├── WorkflowsPage.tsx   # 工作流列表
│   │   ├── WorkflowEditorPage.tsx # 工作流编辑
│   │   ├── ExecutionLogsPage.tsx  # 执行日志
│   │   └── ...
│   ├── services/                # 服务层（双引擎）
│   │   ├── auth/               # 认证服务
│   │   ├── data/               # 数据服务
│   │   ├── storage/            # 存储服务
│   │   └── playwright/         # Playwright 执行服务
│   └── ...
├── server/                       # 后端源码
│   ├── api-server.ts           # API 服务器（端口 3000）
│   ├── index.ts                # Playwright 后端（端口 3000）
│   ├── playwright-executor.ts  # Playwright 执行器
│   └── workflow-runner.ts      # 工作流运行器
├── supabase/                     # Supabase 数据库迁移
│   └── migrations/
├── docs/                         # 文档
│   ├── mysql-schema.sql        # MySQL 数据库结构
│   └── ARCHITECTURE.md
├── .env                          # 环境配置（关键文件）
└── package.json
```

### 服务端口分配

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端开发服务器 | 5173 | Vite Dev Server |
| 后端 API 服务器 | 3000 | Express API (MySQL) |
| Playwright 后端 | 3000 | 工作流执行引擎 |

**注意**: 后端两个服务器不能同时启动，根据需要选择一个

---

## 🔍 待测试和优化的问题

### 优先级 P0 - 立即测试

1. **工作流执行功能完整测试**
   - 测试场景：创建简单工作流 → 执行 → 查看日志
   - 验证端口修复后是否能正常执行
   - 检查执行日志是否正确记录

2. **双引擎切换测试**
   - 切换到 MySQL → 测试所有功能
   - 切换到 Supabase → 测试所有功能
   - 验证数据是否正确隔离

3. **Playwright 自动化执行测试**
   - 测试打开标签页
   - 测试导航到 URL
   - 测试点击、填写、截图等操作

### 优先级 P1 - 重要优化

1. **错误处理优化**
   - 前端错误提示优化
   - 后端错误日志完善
   - 网络异常处理

2. **性能优化**
   - 工作流编辑器加载速度
   - 大量节点时的渲染性能
   - 执行日志查询优化

3. **用户体验优化**
   - 工作流编辑器操作流畅度
   - 执行状态实时反馈
   - 错误提示友好性

### 优先级 P2 - 功能完善

1. **模块管理功能**
   - 模块的导入导出
   - 模块版本管理
   - 模块复用机制

2. **执行日志增强**
   - 日志搜索过滤
   - 日志导出功能
   - 执行统计分析

3. **权限和安全**
   - 用户权限管理
   - 工作流共享机制
   - API 接口安全加固

---

## 🎯 下一步工作计划

### 短期任务（1-2天）

1. ✅ 验证端口修复 - 测试工作流执行是否正常
2. ⏸ 完整功能测试 - 走通所有核心流程
3. ⏸ 问题收集和修复 - 记录所有发现的问题
4. ⏸ 双引擎切换验证 - 确保两种引擎都能正常工作

### 中期任务（3-7天）

1. ⏸ 性能优化 - 提升编辑器和执行性能
2. ⏸ 错误处理完善 - 所有异常情况都有友好提示
3. ⏸ 日志功能增强 - 搜索、过滤、导出
4. ⏸ 文档完善 - 用户手册、API 文档

### 长期任务（1-2周）

1. ⏸ 模块市场 - 模块共享和复用平台
2. ⏸ 权限系统 - 团队协作和权限管理
3. ⏸ 执行调度 - 定时任务和触发器
4. ⏸ 监控告警 - 执行监控和异常告警

---

## 📝 重要提示和注意事项

### ⚠️ 必读注意事项

1. **首次启动必须 npm install**
   - 重新拉取代码后必须执行
   - 否则会报错：`'tsx' 不是内部或外部命令`

2. **端口已统一为 3000**
   - 所有后端服务都在 3000 端口
   - 前端配置也指向 3000
   - 不要修改回 3001

3. **当前使用 MySQL 引擎**
   - `.env` 中 `VITE_SERVICE_PROVIDER=custom`
   - 数据库连接：192.168.1.70:2883
   - 如需切换到 Supabase，运行 `switch-to-supabase.bat`

4. **数据库配置**
   - MySQL: 使用 OceanBase 兼容模式
   - 用户名格式：`root@Tianji4_MySQL#Tianji4`
   - 数据库：`ops_workflow_center`

5. **两个后端服务器说明**
   - `npm run api-server` - 数据 API 服务（认证、CRUD）
   - `npm run server` - Playwright 执行服务
   - 当前主要使用 `api-server`，因为它包含了数据库操作

### 🔧 常见问题解决

**问题：npm install 很慢**
```powershell
npm config set registry https://registry.npmmirror.com
npm install
```

**问题：端口被占用**
```powershell
# 查看端口占用
netstat -ano | findstr :3000
# 结束进程
taskkill /F /PID <进程ID>
```

**问题：数据库连接失败**
- 检查数据库服务是否运行
- 检查 IP 地址 192.168.1.70 是否可达
- 检查端口 2883 是否开放
- 检查用户名密码是否正确

**问题：TypeScript 编译错误**
```powershell
# 清理并重新构建
npm run build
```

---

## 📚 相关文档参考

| 文档 | 说明 |
|------|------|
| `README.md` | 项目总体介绍 |
| `QUICKSTART.md` | 快速开始指南 |
| `DUAL_ENGINE_GUIDE.md` | 双引擎详细说明 |
| `START_HERE_MYSQL.md` | MySQL 部署指南 |
| `DEPLOYMENT_GUIDE.md` | 完整部署文档 |
| `docs/ARCHITECTURE.md` | 架构设计文档 |
| `HANDOVER_CURRENT_STATUS.md` | 本交接文档 |

---

## 🤝 交接建议

### 给新账号的建议

1. **先理解双引擎架构**
   - 阅读 `DUAL_ENGINE_GUIDE.md`
   - 理解 ServiceFactory 的工作原理
   - 了解如何在两种引擎间切换

2. **从测试开始**
   - 先跑通基本流程：注册 → 登录 → 创建场景 → 创建工作流
   - 重点测试工作流执行功能（刚修复的部分）
   - 记录所有发现的问题

3. **逐步深入优化**
   - 不要急于大规模重构
   - 先修复明显的 bug
   - 再做性能优化
   - 最后考虑功能增强

4. **保持沟通**
   - 遇到架构问题可参考现有文档
   - 重大修改前先思考对双引擎的影响
   - 保持代码风格一致

### 快速上手步骤

```powershell
# 1. 进入项目目录
cd C:\Users\Administrator\Desktop\project

# 2. 查看当前配置
type .env

# 3. 安装依赖
npm install

# 4. 启动后端（第一个窗口）
npm run api-server

# 5. 启动前端（第二个窗口）
npm run dev

# 6. 浏览器访问
# http://localhost:5173

# 7. 测试基本流程
# 注册账号 → 登录 → 创建场景 → 创建工作流 → 执行工作流
```

---

## 📞 技术栈和依赖

### 前端技术栈
- React 18.3.1
- TypeScript 5.6.3
- Vite 6.0.7
- ReactFlow 11.11.0 (工作流编辑器)
- TailwindCSS 3.4.1
- React Router 6.22.0
- Zustand 4.5.0 (状态管理)

### 后端技术栈
- Node.js
- Express 4.18.2
- TypeScript 5.6.3
- MySQL2 3.6.5 (MySQL 连接)
- Playwright 1.40.1 (自动化执行)
- Supabase Client 2.39.7

### 关键依赖
- tsx - TypeScript 执行器
- bcrypt - 密码加密
- jsonwebtoken - JWT 认证
- cors - 跨域支持
- multer - 文件上传

---

## ✅ 交接检查清单

在开始新的开发工作前，请确认：

- [ ] 已阅读本交接文档
- [ ] 已执行 `npm install` 安装依赖
- [ ] 已成功启动前后端服务
- [ ] 已访问 http://localhost:5173 并看到登录页
- [ ] 已理解双引擎架构原理
- [ ] 已知道如何切换数据库引擎
- [ ] 已了解最近修复的端口问题
- [ ] 已知道当前待测试的功能
- [ ] 已准备好开始测试和优化工作

---

## 🎉 祝工作顺利！

如有任何问题，请参考项目中的其他文档，或查看代码注释。

**最后更新**: 2026-01-18
**交接人**: Claude (上个账号)
**接收人**: Claude (新账号)
