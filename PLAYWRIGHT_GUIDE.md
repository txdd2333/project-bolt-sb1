# Playwright 浏览器自动化使用指南

本文档介绍如何使用 Playwright 功能进行浏览器自动化操作。

## 🚀 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 安装 Playwright 浏览器

首次使用需要安装 Playwright 浏览器（仅需一次）：

```bash
npx playwright install
```

### 3. 启动服务

需要同时启动前端和后端服务：

**终端 1 - 启动后端服务：**
```bash
npm run server
```

后端服务将在 `http://localhost:3001` 运行

**终端 2 - 启动前端服务：**
```bash
npm run dev
```

前端服务将在 `http://localhost:5173` 运行

### 4. 访问应用

在浏览器中打开：`http://localhost:5173`

---

## 📝 创建 Playwright 工作流

### 步骤 1：创建工作流

1. 登录系统
2. 导航到 **工作流管理** 页面
3. 点击 **新建工作流** 按钮
4. 输入工作流名称，例如："批量打开标签页测试"

### 步骤 2：编辑工作流

1. 从左侧拖拽 **开始** 节点到画布
2. 拖拽 **浏览器** 节点（Playwright 节点）到画布
3. 拖拽 **结束** 节点到画布
4. 连接节点：开始 → 浏览器 → 结束

### 步骤 3：配置 Playwright 节点

点击浏览器节点，右侧会出现配置面板：

#### 操作类型：

1. **打开标签页 (open_tabs)**
   - 标签页数量：设置要打开的标签页数量
   - URL列表：可选，填写逗号分隔的 URL，例如：`https://google.com, https://github.com`

2. **导航到URL (navigate)**
   - 目标URL：要访问的网址
   - 标签页索引：在哪个标签页执行（0 表示第一个）

3. **点击元素 (click)**
   - CSS选择器：要点击的元素，例如：`#button-id` 或 `.button-class`
   - 标签页索引：在哪个标签页执行

4. **填充输入框 (fill)**
   - CSS选择器：输入框的选择器
   - 填充文本：要输入的文本
   - 标签页索引：在哪个标签页执行

5. **等待 (wait)**
   - 等待时间：毫秒数
   - 等待选择器：可选，等待某个元素出现
   - 标签页索引：在哪个标签页执行

6. **截图 (screenshot)**
   - 标签页索引：对哪个标签页截图

7. **提取文本 (extract_text)**
   - CSS选择器：要提取文本的元素
   - 标签页索引：从哪个标签页提取

8. **关闭标签页 (close_tab)**
   - 标签页索引：要关闭的标签页

### 步骤 4：保存工作流

点击右上角 **保存工作流** 按钮

---

## ▶️ 执行工作流

### 方式 1：从工作流编辑器执行

1. 在工作流编辑页面
2. 点击 **执行工作流** 按钮
3. 浏览器窗口会自动打开并执行操作

### 方式 2：从应急场景执行

1. 进入 **应急场景** 页面
2. 选择一个场景，点击 **查看详情**
3. 切换到 **关联工作流** 选项卡
4. 选择要关联的工作流
5. 点击 **保存**
6. 点击右上角 **启动执行** 按钮

---

## 📊 查看执行日志

执行时，可以在后端终端查看实时日志：

```
🚀 Playwright Backend Server running on http://localhost:3001
📊 Health check: http://localhost:3001/health

Workflow exec_1234567890_abc started
✅ Node: start - Workflow started
✅ Node: playwright - Successfully executed open_tabs
   Result: { pagesCreated: 3, totalPages: 3 }
✅ Node: end - Workflow completed
```

---

## 🎯 示例工作流

### 示例 1：打开多个标签页

**节点配置：**
1. 开始节点
2. Playwright 节点
   - 操作类型：打开标签页
   - 标签页数量：3
   - URL列表：`https://google.com, https://github.com, https://stackoverflow.com`
3. 结束节点

### 示例 2：自动化搜索

**节点配置：**
1. 开始节点
2. Playwright 节点 1 - 打开标签页
   - 操作类型：打开标签页
   - 标签页数量：1
   - URL列表：`https://google.com`
3. Playwright 节点 2 - 等待页面加载
   - 操作类型：等待
   - 等待时间：2000
   - 等待选择器：`input[name="q"]`
4. Playwright 节点 3 - 填充搜索框
   - 操作类型：填充输入框
   - CSS选择器：`input[name="q"]`
   - 填充文本：`Playwright automation`
5. Playwright 节点 4 - 点击搜索按钮
   - 操作类型：点击元素
   - CSS选择器：`input[type="submit"]`
6. 结束节点

---

## 🔧 故障排查

### 问题 1：执行失败，提示后端服务未启动

**解决方案：**
确保后端服务正在运行：
```bash
npm run server
```

### 问题 2：浏览器未打开

**解决方案：**
1. 确认已安装 Playwright 浏览器：
   ```bash
   npx playwright install
   ```
2. 检查后端终端是否有错误日志

### 问题 3：找不到元素（CSS选择器错误）

**解决方案：**
1. 使用浏览器开发者工具（F12）检查元素
2. 右键点击元素 → 检查 → 复制选择器
3. 常用选择器格式：
   - ID: `#element-id`
   - Class: `.element-class`
   - 属性: `[name="fieldname"]`
   - 组合: `div.container button.submit`

---

## 🎓 进阶用法

### 多步骤自动化流程

可以组合多个 Playwright 节点实现复杂的自动化流程：

1. 打开标签页
2. 导航到登录页面
3. 填充用户名
4. 填充密码
5. 点击登录按钮
6. 等待页面加载
7. 提取用户信息
8. 截图保存

### 使用决策节点

结合决策节点可以实现条件判断：

1. Playwright 节点 - 提取文本
2. 决策节点 - 判断文本内容
3. 分支 A - 如果包含"成功"
4. 分支 B - 如果包含"失败"

---

## 📚 API 文档

### 后端 API 端点

#### 执行工作流
```
POST http://localhost:3001/api/playwright/execute
Content-Type: application/json

{
  "workflow": {
    "nodes": [...],
    "edges": [...]
  },
  "variables": {}
}
```

#### 查询执行状态
```
GET http://localhost:3001/api/playwright/execution/:id
```

#### 实时流式更新
```
GET http://localhost:3001/api/playwright/execution/:id/stream
```

---

## ⚠️ 注意事项

1. **浏览器资源占用**：Playwright 会打开真实的浏览器窗口，占用较多内存
2. **并发限制**：建议同时执行的工作流数量不超过 3 个
3. **选择器稳定性**：网页结构变化可能导致选择器失效，需定期维护
4. **执行时间**：复杂的自动化流程可能需要较长时间
5. **网络依赖**：需要稳定的网络连接

---

## 🤝 技术支持

遇到问题？
1. 检查后端终端的错误日志
2. 查看浏览器控制台的错误信息
3. 参考本文档的故障排查部分

---

**祝您使用愉快！** 🎉
