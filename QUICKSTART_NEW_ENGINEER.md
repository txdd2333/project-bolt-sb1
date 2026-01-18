# 🚀 新工程师快速上手指南

> 5分钟让你从零到运行项目！

## ⚡ 最快速启动（3步走）

### 第1步：安装依赖（2分钟）
```bash
cd /path/to/ops-workflow-center
npm install
```

### 第2步：配置数据库（1分钟）
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，填入你的 Supabase 凭证
# VITE_SUPABASE_URL=https://xxx.supabase.co
# VITE_SUPABASE_ANON_KEY=eyJxxx...
```

**获取 Supabase 凭证**：
1. 打开 [Supabase 控制台](https://supabase.com/dashboard)
2. 选择项目 → Settings → API
3. 复制 URL 和 anon public key

### 第3步：启动服务（1分钟）
```bash
# 终端1 - 启动前端
npm run dev

# 终端2 - 启动后端
npm run server
```

**访问**：http://localhost:5173

---

## 🗄️ 数据库初始化（首次使用必做）

### 方式一：一键脚本（推荐）
```bash
# 在 Supabase SQL Editor 中运行
# 复制 scripts/setup-database.sql 的全部内容
# 粘贴到 SQL Editor → 点击 Run
```

### 方式二：逐个运行迁移
```bash
# 按顺序在 Supabase SQL Editor 中执行这些文件：
supabase/migrations/*.sql
```

**验证数据库**：
```sql
-- 在 SQL Editor 中运行
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';

-- 应该看到：modules, workflows, scenarios, execution_logs
```

---

## ✅ 验证安装

### 1. 前端验证
```bash
# 访问 http://localhost:5173
# 应该看到登录页面
# 能注册新用户
# 能登录进入系统
```

### 2. 后端验证
```bash
# 访问 http://localhost:3001/health
# 应该返回：{"status":"ok","service":"playwright-backend"}
```

### 3. Playwright 验证
```bash
# 安装浏览器（首次运行）
npx playwright install

# 测试 Chromium
node -e "require('playwright').chromium.launch({headless:false}).then(b=>setTimeout(()=>b.close(),3000))"
```

---

## 🎯 快速测试流程

### 创建第一个工作流
1. 登录系统
2. 点击"工作流" → "新建工作流"
3. 输入名称："测试百度"
4. 从左侧拖拽：开始 → 浏览器自动化 → 结束
5. 点击"浏览器自动化"节点
6. 配置：
   - 操作类型：导航到URL
   - URL：https://www.baidu.com
   - 浏览器类型：Chromium
7. 点击"保存"
8. 点击"执行" → 观察浏览器自动打开百度

---

## 🐛 常见问题快速解决

### 问题1: npm install 失败
```bash
# 清理缓存重试
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### 问题2: 无法连接 Supabase
```bash
# 检查 .env 文件
cat .env

# 测试连接
curl https://your-project.supabase.co
```

### 问题3: Playwright 报错
```bash
# 重新安装浏览器
npx playwright install
npx playwright install-deps
```

### 问题4: 端口被占用
```bash
# 查看占用端口的进程
# Windows
netstat -ano | findstr :5173
netstat -ano | findstr :3001

# Mac/Linux
lsof -i :5173
lsof -i :3001

# 杀掉进程或修改端口
# 修改 vite.config.ts 和 server/index.ts 中的 PORT
```

### 问题5: 模块测试失败
```bash
# 1. 确保后端已启动
curl http://localhost:3001/health

# 2. 查看后端日志
# 在运行 npm run server 的终端查看错误信息

# 3. 确保有测试数据
# 在数据库中至少要有一个模块
```

---

## 📦 创建测试数据

### 手动创建测试模块
```sql
-- 在 Supabase SQL Editor 中运行
INSERT INTO modules (name, description, type, config, icon, color, user_id)
VALUES (
  '打开百度',
  '自动打开百度首页',
  'playwright',
  '{"action":"navigate","url":"https://www.baidu.com","browserType":"chromium"}'::jsonb,
  '🌐',
  '#3b82f6',
  (SELECT id FROM auth.users LIMIT 1)
);
```

### 创建测试工作流
```sql
INSERT INTO workflows (name, description, definition, user_id)
VALUES (
  '百度搜索测试',
  '打开百度并搜索关键词',
  '{"nodes":[{"id":"start-1","type":"start","properties":{}},{"id":"nav-1","type":"playwright","properties":{"action":"navigate","url":"https://www.baidu.com"}},{"id":"end-1","type":"end","properties":{}}],"edges":[{"id":"e1","sourceNodeId":"start-1","targetNodeId":"nav-1"},{"id":"e2","sourceNodeId":"nav-1","targetNodeId":"end-1"}]}'::jsonb,
  (SELECT id FROM auth.users LIMIT 1)
);
```

---

## 🔍 调试技巧

### 查看前端日志
```bash
# 打开浏览器开发者工具
F12 或 Ctrl+Shift+I

# 查看 Console 标签
# 查看 Network 标签（检查 API 请求）
```

### 查看后端日志
```bash
# 后端日志会直接输出到运行 npm run server 的终端
# 如果需要保存日志：
npm run server > server.log 2>&1
```

### 查看数据库内容
```sql
-- 查看用户
SELECT * FROM auth.users;

-- 查看模块
SELECT id, name, type FROM modules;

-- 查看工作流
SELECT id, name FROM workflows;

-- 查看执行日志
SELECT id, status, created_at FROM execution_logs ORDER BY created_at DESC LIMIT 10;
```

---

## 📱 关键功能测试清单

复制这个清单，逐项测试：

```
[ ] 用户注册
[ ] 用户登录
[ ] 创建场景
[ ] 编辑 SOP 文档
[ ] 上传图片到 SOP
[ ] 创建工作流
[ ] 编辑工作流（拖拽节点）
[ ] 保存工作流
[ ] 执行工作流
[ ] 查看"我的模块"分组
[ ] 测试模块（绿色播放按钮）
[ ] 选择不同浏览器类型
[ ] 查看执行日志
[ ] 删除模块
[ ] 删除工作流
```

---

## 🎓 代码导航

### 关键文件位置

**前端核心**：
- 路由配置：`src/App.tsx`
- 认证逻辑：`src/contexts/AuthContext.tsx`
- 数据服务：`src/services/data/SupabaseDataService.ts`

**页面文件**：
- 模块管理：`src/pages/ModulesPage.tsx` ← **有测试功能**
- 工作流编辑：`src/pages/WorkflowEditorPage.tsx`
- 场景详情：`src/pages/ScenarioDetailPage.tsx`

**后端核心**：
- 主服务：`server/index.ts` ← **有测试接口**
- 执行引擎：`server/workflow-runner.ts`
- Playwright：`server/playwright-executor.ts` ← **支持3种浏览器**

**编辑器**：
- LogicFlow：`src/components/LogicFlowEditor/index.tsx` ← **主编辑器**
- 样式：`src/components/LogicFlowEditor/styles.css` ← **有模块分组样式**

---

## 💡 最佳实践

### 开发流程
1. 先看数据库结构（`DATABASE.md`）
2. 理解服务层架构（`src/services/`）
3. 从页面入手（`src/pages/`）
4. 修改前先跑测试

### Git 工作流
```bash
# 拉取最新代码
git pull origin main

# 创建功能分支
git checkout -b feature/xxx

# 提交代码
git add .
git commit -m "feat: add xxx"
git push origin feature/xxx
```

### 代码规范
- 组件使用函数式组件
- 使用 TypeScript 类型
- 遵循现有代码风格
- 添加必要注释

---

## 🆘 紧急联系

### 自助排查顺序
1. 查看终端错误日志
2. 查看浏览器 Console
3. 查看 `HANDOVER_DOCUMENT.md` 的"已知问题"章节
4. 查看 `DEVELOPMENT.md`
5. 搜索项目 Issues

### 关键命令速查
```bash
# 重启一切
Ctrl+C (停止前端)
Ctrl+C (停止后端)
npm run dev
npm run server

# 重新构建
npm run build

# 清理重装
rm -rf node_modules package-lock.json
npm install

# 查看版本
node --version  # 需要 18+
npm --version
```

---

## 🎉 你已经准备好了！

完成上述步骤后，你应该能够：
- ✅ 运行项目
- ✅ 看到界面
- ✅ 执行工作流
- ✅ 测试模块

**下一步建议**：
1. 阅读 `HANDOVER_DOCUMENT.md` 了解完整项目
2. 浏览代码结构熟悉架构
3. 实现一个简单功能练手（如模块创建对话框）

**祝开发愉快！** 🚀

---

**问题反馈**: 如遇到文档未覆盖的问题，请更新此文档并提交 PR。
