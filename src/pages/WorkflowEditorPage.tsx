import { useEffect, useState, useRef } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Save, Play } from 'lucide-react'
import { dataService } from '../services'
import type { Workflow } from '../lib/database.types'
import LogicFlowEditor, {
  LogicFlowEditorRef,
} from '../components/LogicFlowEditor'
import PlaywrightPropertiesPanel from '../components/PlaywrightPropertiesPanel'
import { playwrightService } from '../services/playwright/PlaywrightService'

export default function WorkflowEditorPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const editorRef = useRef<LogicFlowEditorRef>(null)
  const [workflow, setWorkflow] = useState<Workflow | null>(null)
  const [initialData, setInitialData] = useState<{ nodes: any[]; edges: any[] } | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [hasChanges, setHasChanges] = useState(false)
  const [selectedNode, setSelectedNode] = useState<any>(null)
  const [executing, setExecuting] = useState(false)

  useEffect(() => {
    if (id) {
      loadWorkflow()
    }
  }, [id])

  const loadWorkflow = async () => {
    try {
      const { data: workflowData, error: workflowError } = await dataService.queryOne('workflows', {
        filter: { id: id! }
      })

      if (workflowError) throw workflowError
      if (!workflowData) {
        alert('工作流不存在')
        navigate('/workflows')
        return
      }

      setWorkflow(workflowData)

      if ((workflowData as any).definition) {
        try {
          const parsed = JSON.parse((workflowData as any).definition)
          setInitialData(parsed)
        } catch {
          // If parsing fails, use default empty data
          setInitialData({ nodes: [], edges: [] })
        }
      }
    } catch (error) {
      console.error('Error loading workflow:', error)
      alert('加载工作流失败')
    } finally {
      setLoading(false)
    }
  }

  const handleDataChange = () => {
    setHasChanges(true)
  }

  const saveWorkflow = async () => {
    if (!id || !editorRef.current) return

    setSaving(true)
    try {
      const graphData = editorRef.current.getData()

      const { error } = await dataService.update('workflows', id, {
        definition: JSON.stringify(graphData)
      } as any)

      if (error) throw error

      setHasChanges(false)
      alert('保存成功！')
    } catch (error) {
      console.error('Error saving workflow:', error)
      alert('保存失败：' + (error as Error).message)
    } finally {
      setSaving(false)
    }
  }

  const executeWorkflow = async () => {
    if (!editorRef.current) return

    setExecuting(true)
    try {
      const graphData = editorRef.current.getData()

      const workflowData = {
        nodes: graphData.nodes.map((n: any) => ({
          id: n.id,
          type: n.type,
          properties: n.properties
        })),
        edges: graphData.edges.map((e: any) => ({
          id: e.id,
          sourceNodeId: e.sourceNodeId,
          targetNodeId: e.targetNodeId
        }))
      }

      const { executionId } = await playwrightService.executeWorkflow(workflowData)

      alert(`工作流开始执行！\n执行ID: ${executionId}\n\n请查看后端终端查看执行日志。`)
    } catch (error: any) {
      console.error('Error executing workflow:', error)
      alert(`执行失败：${error.message}\n\n请确保后端服务已启动（npm run server）`)
    } finally {
      setExecuting(false)
    }
  }

  const handleNodeClick = (node: any) => {
    setSelectedNode(node)
  }

  const handlePropertiesUpdate = (properties: any) => {
    if (!editorRef.current || !selectedNode) return

    const lf = editorRef.current.getLogicFlowInstance()
    if (lf) {
      lf.setProperties(selectedNode.id, properties)
      setHasChanges(true)
    }
  }

  useEffect(() => {
    if (editorRef.current) {
      const lf = editorRef.current.getLogicFlowInstance()
      if (lf) {
        lf.on('node:click', ({ data }: any) => {
          handleNodeClick(data)
        })

        lf.on('blank:click', () => {
          setSelectedNode(null)
        })
      }
    }
  }, [editorRef.current])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <div className="text-gray-600">加载中...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="flex h-full flex-col bg-gray-50">
      <div className="flex items-center justify-between px-6 py-4 bg-white border-b border-gray-200 shadow-sm">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate('/workflows')}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
            title="返回工作流列表"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-gray-900">{workflow?.name}</h1>
            <p className="text-sm text-gray-500">
              从左侧拖拽节点到画布中构建工作流
              {hasChanges && (
                <span className="ml-2 text-orange-600 font-medium">• 有未保存的更改</span>
              )}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={executeWorkflow}
            disabled={executing}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-green-600 rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed shadow-sm"
          >
            <Play className="w-4 h-4" />
            {executing ? '执行中...' : '执行工作流'}
          </button>
          <button
            onClick={saveWorkflow}
            disabled={saving}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed shadow-sm"
          >
            <Save className="w-4 h-4" />
            {saving ? '保存中...' : '保存工作流'}
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-hidden flex">
        <div className="flex-1">
          <LogicFlowEditor
            ref={editorRef}
            initialData={initialData || undefined}
            onDataChange={handleDataChange}
          />
        </div>
        {selectedNode && (
          <PlaywrightPropertiesPanel
            node={selectedNode}
            onUpdate={handlePropertiesUpdate}
          />
        )}
      </div>
    </div>
  )
}
