# 已知问题和待办事项

> 本文档详细记录所有已知问题、修复建议和待实现功能

---

## 🔴 P0 - 阻塞性问题（必须立即解决）

### Issue #1: X6 编辑器画布白屏 ✅ 已解决

**严重程度**: 🔴 Critical
**影响范围**: 场景详情页 → 流程图标签页
**发现时间**: 2026-01-16
**解决时间**: 2026-01-18

#### 症状
1. 打开场景详情页
2. 点击"流程图"标签
3. 显示"初始化画布中..." 几秒后消失
4. 画布区域完全白屏，无任何内容
5. 工具栏和侧边栏正常显示

#### 错误日志
```
⚠ X6Editor container has no size (attempt 1/10) {width: 0, height: 0}
⚠ X6Editor container has no size (attempt 2/10) {width: 0, height: 0}
...
⚠ X6Editor container has no size (attempt 10/10) {width: 0, height: 0}
```

#### 根本原因分析
X6 画布初始化时，容器 `.x6-graph-container` 的尺寸为 0，导致 X6.Graph 实例无法正确创建画布。

可能的原因：
1. **CSS 布局问题**: 父容器的高度没有正确传递到 X6 容器
2. **渲染时序问题**: 组件挂载时，DOM 尚未完成布局计算
3. **Flex 布局链断裂**: 从 Layout → ScenarioDetailPage → X6Editor 的高度继承链中某处断裂

#### 已尝试的修复
✅ 添加延迟初始化（100ms）
✅ 添加重试机制（最多 10 次，每次间隔 200ms）
✅ 设置容器 `min-height: 500px`
✅ 添加明确的 `width: 100%` 和 `height: 100%`
✅ 添加详细的调试日志

❌ 问题仍然存在

#### 修复建议（按优先级排序）

##### 方案 A: 使用固定高度（最快，5 分钟）
```typescript
// 文件: src/pages/ScenarioDetailPage.tsx
// 位置: 第 350 行

{activeTab === 'flowchart' && (
  <div style={{
    width: '100%',
    height: 'calc(100vh - 160px)',  // 减去 header 和 tabs 的高度
    minHeight: '500px'
  }}>
    <X6Editor
      ref={x6EditorRef}
      initialData={flowchartData || undefined}
      onDataChange={handleFlowchartChange}
    />
  </div>
)}
```

**优点**: 简单直接，立即可用
**缺点**: 不够优雅，响应式支持欠佳

##### 方案 B: 使用 ResizeObserver（推荐，30 分钟）
```typescript
// 文件: src/components/X6Editor/index.tsx
// 在 useEffect 中添加

useEffect(() => {
  if (!containerRef.current) return

  const container = containerRef.current

  // 使用 ResizeObserver 监听容器尺寸变化
  const resizeObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
      const { width, height } = entry.contentRect

      if (width > 0 && height > 0 && !graphRef.current) {
        console.log('Container sized, initializing X6:', { width, height })
        initializeGraph(container, width, height)
      }
    }
  })

  resizeObserver.observe(container)

  return () => {
    resizeObserver.disconnect()
    if (graphRef.current) {
      graphRef.current.dispose()
    }
  }
}, [])

const initializeGraph = (container: HTMLElement, width: number, height: number) => {
  const graph = new Graph({
    container,
    width,
    height,
    autoResize: true,
    // ... 其他配置
  })

  graphRef.current = graph
  setIsReady(true)

  // 加载初始数据
  if (initialData) {
    try {
      graph.fromJSON(JSON.parse(initialData))
    } catch (error) {
      console.error('Failed to load data:', error)
    }
  }
}
```

**优点**: 优雅，响应式，符合最佳实践
**缺点**: 需要重构代码

##### 方案 C: 修复布局链（根本解决，1 小时）
逐层检查并修复高度传递：

**1. 检查 Layout.tsx**
```typescript
// 确保 main 元素有正确的 flex 布局
<main className="flex-1 overflow-auto">
  {children}
</main>
```

**2. 检查 ScenarioDetailPage.tsx**
```typescript
// 确保页面容器高度正确
return (
  <div className="h-full flex flex-col">
    {/* Header */}
    <div className="bg-white border-b">...</div>

    {/* Tabs */}
    <div className="bg-white border-b">...</div>

    {/* Content - 关键：这里要使用 flex-1 */}
    <div className="flex-1 overflow-auto">
      {activeTab === 'flowchart' && (
        <div className="h-full w-full">
          <X6Editor ... />
        </div>
      )}
    </div>
  </div>
)
```

**3. 检查 X6Editor 组件**
```css
/* 文件: src/components/X6Editor/styles.css */
.x6-editor-container {
  display: flex;
  width: 100%;
  height: 100%;
  min-height: 0; /* 重要：允许 flex 子元素收缩 */
}

.x6-graph-wrapper {
  flex: 1;
  min-height: 0;
  min-width: 0;
  display: flex;
}

.x6-graph-container {
  flex: 1;
  min-height: 0;
  min-width: 0;
}
```

**优点**: 从根本上解决问题，布局正确
**缺点**: 需要仔细调试，可能影响其他页面

#### 调试步骤

**步骤 1: 定位问题层级**
```javascript
// 在浏览器控制台执行
const elements = [
  document.querySelector('main'),
  document.querySelector('.flex-1.overflow-auto'),  // ScenarioDetailPage 容器
  document.querySelector('.x6-editor-container'),
  document.querySelector('.x6-graph-wrapper'),
  document.querySelector('.x6-graph-container')
]

elements.forEach((el, i) => {
  if (el) {
    const rect = el.getBoundingClientRect()
    console.log(`Level ${i}:`, el.className, {
      width: rect.width,
      height: rect.height,
      computedHeight: window.getComputedStyle(el).height
    })
  }
})
```

**步骤 2: 查找第一个高度为 0 的元素**
这个元素就是问题所在，需要修复它的 CSS。

**步骤 3: 应用修复**
根据定位结果，应用上述方案 A、B 或 C。

#### 相关文件
- `src/pages/ScenarioDetailPage.tsx` (第 349-357 行)
- `src/components/X6Editor/index.tsx` (第 59-207 行)
- `src/components/X6Editor/styles.css` (第 1-88 行)
- `src/components/Layout.tsx` (检查 main 元素)

#### 最终修复方案
采用**方案 A**：使用计算高度解决
- 将流程图容器高度设置为 `calc(100vh - 160px)`，减去页面头部和标签栏高度
- 添加 `minHeight: 500px` 确保最小可用空间
- 修改文件：`src/pages/ScenarioDetailPage.tsx` 第 350 行

#### 验收标准
- ✅ 打开场景详情页 → 流程图标签页，立即看到画布
- ✅ 画布显示网格背景
- ✅ 可以从左侧工具栏点击添加节点到画布
- ✅ 节点可以连线
- ✅ 保存后刷新页面，数据正确加载

---

## 🟠 P1 - 高优先级问题（影响核心功能）

### Issue #2: 场景工作流关联功能缺失

**严重程度**: 🟠 High
**影响范围**: 场景详情页 → 关联工作流标签页
**状态**: 待实现

#### 当前状态
- 数据库支持：✅ `scenarios.workflow_ids` JSONB 数组
- UI 界面：✅ "关联工作流"标签页存在
- 功能实现：❌ 无法选择和关联工作流

#### 实现方案

**1. 创建工作流选择组件**
```typescript
// 新文件: src/components/WorkflowSelector.tsx

interface WorkflowSelectorProps {
  selectedIds: string[]
  onChange: (ids: string[]) => void
}

export function WorkflowSelector({ selectedIds, onChange }: WorkflowSelectorProps) {
  const [workflows, setWorkflows] = useState<Workflow[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadWorkflows()
  }, [])

  const loadWorkflows = async () => {
    const { data } = await supabase
      .from('workflows')
      .select('*')
      .order('created_at', { ascending: false })

    setWorkflows(data || [])
    setLoading(false)
  }

  const toggleWorkflow = (id: string) => {
    if (selectedIds.includes(id)) {
      onChange(selectedIds.filter(x => x !== id))
    } else {
      onChange([...selectedIds, id])
    }
  }

  return (
    <div className="space-y-2">
      {workflows.map(workflow => (
        <label key={workflow.id} className="flex items-center gap-2 p-3 border rounded hover:bg-gray-50 cursor-pointer">
          <input
            type="checkbox"
            checked={selectedIds.includes(workflow.id)}
            onChange={() => toggleWorkflow(workflow.id)}
            className="w-4 h-4"
          />
          <div className="flex-1">
            <div className="font-medium">{workflow.name}</div>
            <div className="text-sm text-gray-500">{workflow.description}</div>
          </div>
        </label>
      ))}
    </div>
  )
}
```

**2. 集成到 ScenarioDetailPage**
```typescript
// 文件: src/pages/ScenarioDetailPage.tsx
// 在 "关联工作流" 标签内容中

{activeTab === 'workflow' && (
  <div className="h-full p-6 overflow-auto">
    <div className="max-w-2xl mx-auto">
      <h3 className="text-lg font-semibold mb-4">关联工作流</h3>
      <WorkflowSelector
        selectedIds={scenario.workflow_ids || []}
        onChange={async (ids) => {
          await supabase
            .from('scenarios')
            .update({ workflow_ids: ids })
            .eq('id', scenario.id)

          setScenario({ ...scenario, workflow_ids: ids })
        }}
      />

      <div className="mt-8">
        <h4 className="font-medium mb-2">已关联的工作流 ({scenario.workflow_ids?.length || 0})</h4>
        <WorkflowList workflowIds={scenario.workflow_ids || []} />
      </div>
    </div>
  </div>
)}
```

#### 验收标准
- [ ] 可以看到所有可用工作流列表
- [ ] 可以勾选/取消勾选工作流
- [ ] 勾选后自动保存到数据库
- [ ] 显示已关联工作流的数量
- [ ] 可以查看已关联工作流的详情

---

### Issue #3: 工作流编辑器页面为空

**严重程度**: 🟠 High
**影响范围**: `/workflows/:id/edit` 页面
**状态**: 占位页面，功能未实现

#### 当前状态
页面只显示 "工作流编辑器（占位）"，没有实际编辑功能。

#### 实现方案

**直接复用 X6Editor 组件**
```typescript
// 文件: src/pages/WorkflowEditorPage.tsx

import { useState, useEffect, useRef } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { X6Editor } from '@/components/X6Editor'
import type { X6EditorRef } from '@/components/X6Editor'
import { supabase } from '@/lib/supabase'

export default function WorkflowEditorPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const editorRef = useRef<X6EditorRef>(null)

  const [workflow, setWorkflow] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadWorkflow()
  }, [id])

  const loadWorkflow = async () => {
    const { data } = await supabase
      .from('workflows')
      .select('*')
      .eq('id', id)
      .maybeSingle()

    setWorkflow(data)
    setLoading(false)
  }

  const handleSave = async () => {
    const definition = editorRef.current?.getData()

    await supabase
      .from('workflows')
      .update({ definition })
      .eq('id', id)

    alert('保存成功')
  }

  const handleExport = () => {
    editorRef.current?.exportJSON()
  }

  if (loading) return <div className="p-6">加载中...</div>
  if (!workflow) return <div className="p-6">工作流不存在</div>

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{workflow.name}</h1>
          <p className="text-sm text-gray-500 mt-1">{workflow.description}</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={handleExport}
            className="px-4 py-2 border rounded-lg hover:bg-gray-50"
          >
            导出
          </button>
          <button
            onClick={handleSave}
            className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          >
            保存
          </button>
        </div>
      </div>

      {/* Editor */}
      <div className="flex-1 overflow-hidden">
        <X6Editor
          ref={editorRef}
          initialData={workflow.definition}
          onDataChange={(data) => {
            // 自动保存（可选）
            console.log('Workflow changed:', data)
          }}
        />
      </div>
    </div>
  )
}
```

#### 验收标准
- [ ] 打开 `/workflows/:id/edit` 可以看到编辑器
- [ ] 可以添加、编辑、删除节点
- [ ] 点击"保存"后数据写入数据库
- [ ] 刷新页面后数据正确加载
- [ ] 导出功能正常工作

---

## 🟡 P2 - 中优先级问题（功能增强）

### Issue #4: 缺少数据验证

**严重程度**: 🟡 Medium
**影响范围**: 所有表单
**状态**: 待实现

#### 需要添加的验证
1. **场景名称**：必填，1-100 字符，同一用户下唯一
2. **工作流名称**：必填，1-100 字符
3. **模块名称**：必填，1-50 字符
4. **邮箱**：有效的邮箱格式
5. **密码**：至少 6 位

#### 实现方案
使用 Zod 或手动验证：

```typescript
// 新文件: src/lib/validation.ts

export const validateScenarioName = (name: string): string | null => {
  if (!name || name.trim().length === 0) {
    return '场景名称不能为空'
  }
  if (name.length > 100) {
    return '场景名称不能超过 100 个字符'
  }
  return null
}

export const checkScenarioNameExists = async (name: string, userId: string, excludeId?: string): Promise<boolean> => {
  const query = supabase
    .from('scenarios')
    .select('id')
    .eq('name', name)
    .eq('user_id', userId)

  if (excludeId) {
    query.neq('id', excludeId)
  }

  const { data } = await query.maybeSingle()
  return !!data
}
```

---

### Issue #5: SOP 图片上传无进度提示

**严重程度**: 🟡 Medium
**影响范围**: MarkdownEditor 组件
**状态**: 待优化

#### 当前问题
图片上传时没有进度条，用户不知道是否在上传，容易误以为卡住。

#### 实现方案
```typescript
// 文件: src/components/MarkdownEditor.tsx
// 修改 customUpload 函数

const customUpload = async (file: File, insertFn: any) => {
  try {
    setUploading(true)  // 新增状态
    setUploadProgress(0)  // 新增状态

    const filePath = `${Date.now()}-${file.name}`

    const { data, error } = await supabase.storage
      .from('sop-images')
      .upload(filePath, file, {
        onUploadProgress: (progress) => {
          const percent = (progress.loaded / progress.total) * 100
          setUploadProgress(percent)  // 更新进度
        }
      })

    if (error) throw error

    const { data: { publicUrl } } = supabase.storage
      .from('sop-images')
      .getPublicUrl(filePath)

    insertFn(publicUrl)
  } catch (error) {
    alert('图片上传失败')
  } finally {
    setUploading(false)
    setUploadProgress(0)
  }
}

// 在编辑器上方显示进度条
{uploading && (
  <div className="absolute top-0 left-0 right-0 h-1 bg-gray-200">
    <div
      className="h-full bg-blue-500 transition-all"
      style={{ width: `${uploadProgress}%` }}
    />
  </div>
)}
```

---

### Issue #6: 执行日志页面功能简陋

**严重程度**: 🟡 Medium
**影响范围**: `/executions` 页面
**状态**: 基本功能已实现，需要增强

#### 需要添加的功能
- [ ] 实时日志流（WebSocket 或轮询）
- [ ] 日志搜索和过滤
- [ ] 按工作流筛选
- [ ] 按状态筛选（运行中/成功/失败）
- [ ] 日志详情展开/收起
- [ ] 重新执行失败的工作流

---

## 🟢 P3 - 低优先级问题（优化和增强）

### Issue #7: 大型流程图性能问题

**严重程度**: 🟢 Low
**影响范围**: X6Editor
**状态**: 未发现问题，预防性优化

#### 优化建议
1. 启用虚拟渲染（超过 100 个节点时）
2. 节点延迟加载
3. 缩略图导航
4. 画布缓存

---

### Issue #8: 缺少工作流模板

**严重程度**: 🟢 Low
**影响范围**: 整体体验
**状态**: 待实现

#### 建议的模板
1. **服务器巡检流程**
2. **应用发布流程**
3. **故障处理流程**
4. **数据备份流程**

---

### Issue #9: 缺少定时触发器

**严重程度**: 🟢 Low
**影响范围**: 工作流执行
**状态**: 待实现

#### 实现建议
使用 Supabase Edge Functions + Cron：
- 每小时检查需要执行的工作流
- 根据 cron 表达式触发执行

---

### Issue #10: 缺少版本管理

**严重程度**: 🟢 Low
**影响范围**: 场景和工作流
**状态**: 待实现

#### 数据库设计
```sql
CREATE TABLE scenario_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id uuid REFERENCES scenarios(id),
  version int NOT NULL,
  sop_content text,
  flowchart_definition text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);
```

---

## 📊 问题统计

| 优先级 | 总数 | 已解决 | 进行中 | 待处理 |
|--------|------|--------|--------|--------|
| P0 🔴  | 1    | 1      | 0      | 0      |
| P1 🟠  | 3    | 0      | 0      | 3      |
| P2 🟡  | 3    | 0      | 0      | 3      |
| P3 🟢  | 3    | 0      | 0      | 3      |
| **总计** | **10** | **1** | **0** | **9** |

---

## 📅 更新日志

| 日期 | Issue | 状态变更 | 操作人 |
|------|-------|----------|--------|
| 2026-01-16 | #1 | 新建 → 进行中 | 初始开发者 |
| 2026-01-18 | #1 | 进行中 → 已解决 | 接任工程师 |
| | | | |

---

**下次更新**: 解决 P1 问题后请更新本文档
