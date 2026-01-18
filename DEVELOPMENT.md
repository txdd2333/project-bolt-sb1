# 开发规范和最佳实践

> 本文档定义项目的代码规范、开发流程和最佳实践

---

## 🎯 核心原则

### 1. 数据安全第一
- **永远不要**使用 `DROP TABLE` 或 `DELETE FROM table` 删除所有数据
- **始终**使用 RLS（行级安全）保护数据
- **始终**验证用户权限
- **始终**备份重要数据

### 2. 用户体验优先
- 加载状态要明显（loading spinners）
- 错误信息要友好（不要直接展示技术错误）
- 操作要有反馈（成功/失败提示）
- 避免长时间阻塞 UI

### 3. 代码质量
- 遵循 TypeScript 类型安全
- 使用有意义的变量名
- 添加必要的注释
- 保持函数简短（< 50 行）

---

## 📁 文件组织规范

### 目录结构

```
src/
├── components/          # 可复用组件
│   ├── shared/         # 通用组件（Button, Input 等）
│   ├── X6Editor/       # 复杂业务组件
│   └── ...
├── pages/              # 页面组件（对应路由）
├── contexts/           # React Context
├── hooks/              # 自定义 Hooks
├── lib/                # 工具库和配置
├── types/              # 类型定义（如需要）
└── utils/              # 工具函数（如需要）
```

### 文件命名

**组件文件**（PascalCase）:
```
✅ UserProfile.tsx
✅ X6Editor/index.tsx
❌ user-profile.tsx
❌ userProfile.tsx
```

**工具文件**（camelCase）:
```
✅ documentUtils.ts
✅ dateFormatter.ts
❌ DocumentUtils.ts
```

**样式文件**（kebab-case 或与组件同名）:
```
✅ styles.css
✅ X6Editor.module.css
✅ user-profile.css
```

---

## 💻 代码规范

### TypeScript

#### 1. 显式类型声明
```typescript
// ✅ 好的做法
interface User {
  id: string
  email: string
  createdAt: Date
}

function getUser(id: string): Promise<User | null> {
  // ...
}

// ❌ 避免
function getUser(id) {  // 缺少类型
  // ...
}
```

#### 2. 使用可选链和空值合并
```typescript
// ✅ 好的做法
const userName = user?.profile?.name ?? '未知用户'

// ❌ 避免
const userName = user && user.profile && user.profile.name || '未知用户'
```

#### 3. 避免 any 类型
```typescript
// ✅ 好的做法
function processData(data: unknown) {
  if (typeof data === 'string') {
    return data.toUpperCase()
  }
  // ...
}

// ❌ 避免
function processData(data: any) {  // 失去类型安全
  return data.toUpperCase()  // 可能运行时错误
}
```

### React

#### 1. 组件结构
```typescript
// 推荐的组件结构顺序：
import { useState, useEffect } from 'react'  // 1. 外部依赖
import { supabase } from '@/lib/supabase'    // 2. 内部依赖

// 3. 类型定义
interface Props {
  userId: string
  onSave: () => void
}

// 4. 组件
export function UserProfile({ userId, onSave }: Props) {
  // 4.1 状态
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // 4.2 副作用
  useEffect(() => {
    loadUser()
  }, [userId])

  // 4.3 事件处理函数
  const loadUser = async () => {
    // ...
  }

  const handleSave = async () => {
    // ...
  }

  // 4.4 渲染
  if (loading) return <div>加载中...</div>
  if (!user) return <div>用户不存在</div>

  return (
    <div>
      {/* ... */}
    </div>
  )
}
```

#### 2. 使用自定义 Hooks 提取逻辑
```typescript
// ✅ 好的做法：提取为 Hook
function useUser(userId: string) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadUser()
  }, [userId])

  const loadUser = async () => {
    // ...
  }

  return { user, loading, loadUser }
}

// 在组件中使用
function UserProfile({ userId }: Props) {
  const { user, loading } = useUser(userId)
  // ...
}
```

#### 3. 避免内联函数（性能敏感场景）
```typescript
// ❌ 避免（每次渲染都创建新函数）
<button onClick={() => handleClick(id)}>
  点击
</button>

// ✅ 好的做法
const handleButtonClick = useCallback(() => {
  handleClick(id)
}, [id])

<button onClick={handleButtonClick}>
  点击
</button>

// 或者对于简单场景（性能影响不大）
<button onClick={() => handleClick(id)}>  {/* 可接受 */}
  点击
</button>
```

#### 4. 条件渲染
```typescript
// ✅ 好的做法
{isVisible && <Component />}
{count > 0 ? <List items={items} /> : <EmptyState />}

// ❌ 避免（容易出错）
{count && <span>{count}</span>}  // count=0 时会显示 0
{someText || <Fallback />}       // someText='' 时意外显示 Fallback
```

---

## 🗄️ 数据库操作规范

### 1. 始终使用 maybeSingle()
```typescript
// ✅ 好的做法（不会抛出异常）
const { data, error } = await supabase
  .from('scenarios')
  .select('*')
  .eq('id', id)
  .maybeSingle()

if (!data) {
  return null  // 未找到数据
}

// ❌ 避免（没有数据时会抛出异常）
const { data } = await supabase
  .from('scenarios')
  .select('*')
  .eq('id', id)
  .single()  // 可能抛出 "Row not found"
```

### 2. 错误处理
```typescript
// ✅ 好的做法
const { data, error } = await supabase
  .from('scenarios')
  .insert({ name, description, user_id })
  .select()
  .maybeSingle()

if (error) {
  console.error('Failed to create scenario:', error)
  alert('创建场景失败，请重试')
  return null
}

return data

// ❌ 避免（忽略错误）
const { data } = await supabase
  .from('scenarios')
  .insert({ name, description, user_id })
  .select()
  .maybeSingle()

return data  // 可能是 null，但没有错误处理
```

### 3. 使用 select() 获取插入的数据
```typescript
// ✅ 好的做法
const { data } = await supabase
  .from('scenarios')
  .insert({ name })
  .select()       // 返回插入的数据
  .maybeSingle()

console.log(data.id)  // 可以立即使用生成的 ID

// ❌ 避免
const { data } = await supabase
  .from('scenarios')
  .insert({ name })   // 不返回数据

// 需要再次查询
const { data: created } = await supabase
  .from('scenarios')
  .select()
  .eq('name', name)
  .maybeSingle()
```

### 4. 批量操作
```typescript
// ✅ 好的做法（使用事务）
const { data, error } = await supabase
  .from('scenarios')
  .insert([
    { name: 'Scenario 1' },
    { name: 'Scenario 2' },
    { name: 'Scenario 3' }
  ])
  .select()

// 全部成功或全部失败

// ❌ 避免（逐个插入，可能部分成功）
for (const scenario of scenarios) {
  await supabase.from('scenarios').insert(scenario)
}
```

---

## 🎨 样式规范

### 1. 使用 Tailwind CSS 优先
```tsx
// ✅ 好的做法
<div className="flex items-center gap-4 p-6 bg-white rounded-lg shadow">
  <button className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
    保存
  </button>
</div>

// ❌ 避免（除非 Tailwind 无法实现）
<div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
  {/* ... */}
</div>
```

### 2. 提取重复的样式类
```tsx
// ✅ 好的做法
const buttonClass = 'px-4 py-2 rounded font-medium'

<button className={`${buttonClass} bg-blue-500 text-white`}>主按钮</button>
<button className={`${buttonClass} bg-gray-200 text-gray-700`}>次按钮</button>

// 或者使用组件
<Button variant="primary">主按钮</Button>
<Button variant="secondary">次按钮</Button>
```

### 3. 响应式设计
```tsx
// ✅ 使用 Tailwind 的响应式前缀
<div className="
  grid
  grid-cols-1       /* 移动端 1 列 */
  md:grid-cols-2    /* 平板 2 列 */
  lg:grid-cols-3    /* 桌面 3 列 */
  gap-4
">
  {/* ... */}
</div>
```

---

## 🔒 安全规范

### 1. 永远不要在前端暴露敏感信息
```typescript
// ❌ 危险
const API_SECRET = 'sk_live_...'  // 永远不要这样做

// ✅ 使用环境变量（后端）
const API_SECRET = process.env.API_SECRET
```

### 2. 验证用户输入
```typescript
// ✅ 好的做法
function createScenario(name: string) {
  if (!name || name.trim().length === 0) {
    throw new Error('场景名称不能为空')
  }

  if (name.length > 100) {
    throw new Error('场景名称不能超过 100 个字符')
  }

  // XSS 防护：Supabase 和 React 自动处理
  // 但如果使用 dangerouslySetInnerHTML 要小心

  // ...
}
```

### 3. 使用 RLS 而不是前端检查
```typescript
// ❌ 危险（可以被绕过）
if (scenario.user_id !== currentUserId) {
  alert('无权访问')
  return
}

// ✅ 好的做法（在数据库层面保护）
// RLS 策略会自动过滤不属于当前用户的数据
const { data } = await supabase
  .from('scenarios')
  .select('*')
  .eq('id', scenarioId)
  .maybeSingle()

// 如果不是当前用户的数据，data 会是 null
```

---

## 🧪 测试建议

### 1. 手动测试清单
每次修改后应测试：

**功能测试**:
- [ ] 创建数据（场景、工作流等）
- [ ] 读取数据（列表、详情）
- [ ] 更新数据
- [ ] 删除数据

**边界条件**:
- [ ] 空输入
- [ ] 超长输入
- [ ] 特殊字符输入
- [ ] 并发操作

**权限测试**:
- [ ] 未登录用户访问
- [ ] 登录用户访问自己的数据
- [ ] 尝试访问他人数据（应该失败）

### 2. 调试技巧
```typescript
// 添加调试日志
console.log('Loading scenario:', scenarioId)
console.log('Supabase response:', { data, error })

// 使用 React DevTools 查看组件状态
// 使用 Chrome Network 标签查看 API 请求
// 使用 Supabase Dashboard 查看数据库数据
```

---

## 🚀 性能优化

### 1. 避免不必要的重新渲染
```typescript
// ✅ 使用 memo（对于重组件）
const HeavyComponent = memo(function HeavyComponent({ data }: Props) {
  // ...
})

// ✅ 使用 useMemo（对于昂贵的计算）
const sortedList = useMemo(() => {
  return items.sort((a, b) => a.name.localeCompare(b.name))
}, [items])

// ✅ 使用 useCallback（对于传递给子组件的函数）
const handleClick = useCallback(() => {
  // ...
}, [dependency])
```

### 2. 懒加载和代码分割
```typescript
// ✅ 路由级别的懒加载
const ScenariosPage = lazy(() => import('./pages/ScenariosPage'))

<Suspense fallback={<div>加载中...</div>}>
  <ScenariosPage />
</Suspense>
```

### 3. 分页和虚拟滚动
```typescript
// ✅ 对于长列表使用分页
const PAGE_SIZE = 20

const { data } = await supabase
  .from('scenarios')
  .select('*')
  .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1)
```

---

## 📝 注释规范

### 1. 何时添加注释
```typescript
// ✅ 解释"为什么"，而不是"做什么"
// 使用 setTimeout 延迟初始化，因为容器需要完成布局计算
setTimeout(() => initGraph(), 100)

// ❌ 不必要的注释
// 设置 loading 为 true
setLoading(true)
```

### 2. TODO 注释
```typescript
// TODO: 添加分页功能
// TODO(username): 优化查询性能
// FIXME: 偶尔会出现重复数据
// HACK: 临时解决方案，等待上游库修复
```

### 3. 文档注释
```typescript
/**
 * 加载场景详情
 * @param scenarioId - 场景 ID
 * @returns 场景对象，如果不存在返回 null
 */
async function loadScenario(scenarioId: string): Promise<Scenario | null> {
  // ...
}
```

---

## 🔄 Git 工作流（如果使用）

### 提交信息格式
```bash
# 格式：<type>: <description>

# 示例：
git commit -m "feat: 添加场景工作流关联功能"
git commit -m "fix: 修复 X6 编辑器白屏问题"
git commit -m "docs: 更新 API 文档"
git commit -m "refactor: 重构场景详情页组件"
git commit -m "perf: 优化列表查询性能"
git commit -m "style: 调整按钮样式"
git commit -m "test: 添加单元测试"
```

### 分支策略
```bash
main          # 主分支（稳定版本）
├── develop   # 开发分支
│   ├── feature/x6-editor-fix      # 功能分支
│   ├── feature/workflow-selector  # 功能分支
│   └── bugfix/login-error         # 修复分支
```

---

## ✅ 代码审查清单

提交代码前检查：

**基础**:
- [ ] 代码可以正常编译（`npm run build`）
- [ ] 没有 TypeScript 类型错误
- [ ] 没有控制台错误或警告
- [ ] 功能正常工作

**代码质量**:
- [ ] 变量名有意义
- [ ] 函数职责单一
- [ ] 没有重复代码
- [ ] 添加了必要的注释

**安全**:
- [ ] 没有暴露敏感信息
- [ ] 输入已验证
- [ ] RLS 策略正确

**性能**:
- [ ] 没有不必要的重新渲染
- [ ] 大列表使用了分页
- [ ] 图片已优化

**用户体验**:
- [ ] 加载状态清晰
- [ ] 错误信息友好
- [ ] 操作有反馈

---

## 📚 推荐学习资源

### 官方文档
- [React 文档](https://react.dev/)
- [TypeScript 文档](https://www.typescriptlang.org/docs/)
- [Supabase 文档](https://supabase.com/docs)
- [Tailwind CSS 文档](https://tailwindcss.com/docs)

### 最佳实践
- [React TypeScript Cheatsheet](https://react-typescript-cheatsheet.netlify.app/)
- [Supabase 最佳实践](https://supabase.com/docs/guides/platform/performance)

---

**最后更新**: 2026-01-16
**维护者**: 开发团队
