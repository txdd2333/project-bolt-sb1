import { PlaywrightExecutor, ExecutionContext, PlaywrightAction } from './playwright-executor.js'
import { EventEmitter } from 'events'

export interface WorkflowNode {
  id: string
  type: string
  properties?: {
    action?: string
    browserType?: string
    count?: number
    urls?: string
    url?: string
    selector?: string
    text?: string
    milliseconds?: number
    pageIndex?: number
    moduleName?: string
  }
}

export interface WorkflowEdge {
  id: string
  sourceNodeId: string
  targetNodeId: string
}

export interface Workflow {
  nodes: WorkflowNode[]
  edges: WorkflowEdge[]
}

export interface ExecutionStatus {
  id: string
  status: 'running' | 'completed' | 'failed'
  currentNodeId?: string
  completedNodes: string[]
  logs: ExecutionLog[]
  startTime: number
  endTime?: number
  error?: string
}

export interface ExecutionLog {
  timestamp: number
  nodeId: string
  nodeName: string
  action: string
  status: 'success' | 'error'
  message: string
  details?: any
}

export class WorkflowRunner {
  private executor: PlaywrightExecutor
  private executions: Map<string, ExecutionStatus> = new Map()
  private eventEmitters: Map<string, EventEmitter> = new Map()

  constructor(executor: PlaywrightExecutor) {
    this.executor = executor
  }

  async startExecution(workflow: Workflow, variables: Record<string, any> = {}): Promise<string> {
    const executionId = `exec_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

    const status: ExecutionStatus = {
      id: executionId,
      status: 'running',
      completedNodes: [],
      logs: [],
      startTime: Date.now()
    }

    this.executions.set(executionId, status)
    const emitter = new EventEmitter()
    this.eventEmitters.set(executionId, emitter)

    this.executeWorkflow(executionId, workflow, variables).catch((error) => {
      console.error(`Workflow ${executionId} failed:`, error)
      const currentStatus = this.executions.get(executionId)
      if (currentStatus) {
        currentStatus.status = 'failed'
        currentStatus.error = error.message
        currentStatus.endTime = Date.now()
        this.emitUpdate(executionId, currentStatus)
      }
    })

    return executionId
  }

  private async executeWorkflow(
    executionId: string,
    workflow: Workflow,
    variables: Record<string, any>
  ) {
    const status = this.executions.get(executionId)
    if (!status) return

    let context: ExecutionContext | null = null

    try {
      const firstPlaywrightNode = workflow.nodes.find(n =>
        n.type === 'playwright-node' || n.type === 'playwright' || n.type === 'task'
      )
      const browserType = firstPlaywrightNode?.properties?.browserType || 'chromium'

      context = await this.executor.createExecutionContext(browserType)
      context.variables = variables

      const startNode = workflow.nodes.find(n => n.type === 'start' || n.type === 'start-node')
      if (!startNode) {
        throw new Error('No start node found in workflow')
      }

      await this.executeNode(executionId, startNode, workflow, context)

      status.status = 'completed'
      status.endTime = Date.now()
      this.emitUpdate(executionId, status)
    } catch (error: any) {
      status.status = 'failed'
      status.error = error.message
      status.endTime = Date.now()
      this.emitUpdate(executionId, status)
    } finally {
      if (context) {
        await this.executor.cleanup(context)
      }
    }
  }

  private async executeNode(
    executionId: string,
    node: WorkflowNode,
    workflow: Workflow,
    context: ExecutionContext
  ) {
    const status = this.executions.get(executionId)
    if (!status) return

    status.currentNodeId = node.id
    this.emitUpdate(executionId, status)

    const log: ExecutionLog = {
      timestamp: Date.now(),
      nodeId: node.id,
      nodeName: node.type,
      action: node.properties?.action || node.type,
      status: 'success',
      message: ''
    }

    try {
      if (node.type === 'playwright-node' || node.type === 'playwright') {
        const action = this.nodeToAction(node)
        const result = await this.executor.executeAction(action, context)

        if (!result.success) {
          throw new Error(result.error || 'Action failed')
        }

        log.message = `Successfully executed ${action.type}`
        log.details = result.result
      } else if (node.type === 'task') {
        const props = node.properties || {}

        if (props.action) {
          const action = this.nodeToAction(node)
          const result = await this.executor.executeAction(action, context)

          if (!result.success) {
            throw new Error(result.error || 'Module action failed')
          }

          log.message = `Successfully executed module action: ${action.type}`
          log.details = result.result
        } else {
          log.message = `Executed module: ${props.moduleName || 'Unknown'}`
        }
      } else if (node.type === 'start' || node.type === 'start-node') {
        log.message = 'Workflow started'
      } else if (node.type === 'end' || node.type === 'end-node') {
        log.message = 'Workflow completed'
      } else {
        log.message = `Executed node type: ${node.type}`
      }

      log.status = 'success'
    } catch (error: any) {
      log.status = 'error'
      log.message = error.message
      status.logs.push(log)
      this.emitUpdate(executionId, status)
      throw error
    }

    status.completedNodes.push(node.id)
    status.logs.push(log)
    this.emitUpdate(executionId, status)

    if (node.type !== 'end' && node.type !== 'end-node') {
      const nextEdge = workflow.edges.find(e => e.sourceNodeId === node.id)
      if (nextEdge) {
        const nextNode = workflow.nodes.find(n => n.id === nextEdge.targetNodeId)
        if (nextNode) {
          await this.executeNode(executionId, nextNode, workflow, context)
        }
      }
    }
  }

  private nodeToAction(node: WorkflowNode): PlaywrightAction {
    const props = node.properties || {}
    const action = props.action || 'open_tabs'

    const params: Record<string, any> = {}

    switch (action) {
      case 'open_tabs':
        params.count = props.count || 1
        if (props.urls) {
          params.urls = props.urls.split(',').map((u: string) => u.trim())
        }
        break

      case 'navigate':
        params.url = props.url || ''
        params.pageIndex = props.pageIndex || 0
        break

      case 'click':
        params.selector = props.selector || ''
        params.pageIndex = props.pageIndex || 0
        break

      case 'fill':
        params.selector = props.selector || ''
        params.text = props.text || ''
        params.pageIndex = props.pageIndex || 0
        break

      case 'wait':
        if (props.selector) {
          params.selector = props.selector
        }
        if (props.milliseconds) {
          params.milliseconds = props.milliseconds
        }
        params.pageIndex = props.pageIndex || 0
        break

      case 'screenshot':
        params.pageIndex = props.pageIndex || 0
        params.fullPage = true
        break

      case 'extract_text':
        params.selector = props.selector || ''
        params.pageIndex = props.pageIndex || 0
        break

      case 'close_tab':
        params.pageIndex = props.pageIndex || 0
        break
    }

    return { type: action, params }
  }

  getExecutionStatus(executionId: string): ExecutionStatus | undefined {
    return this.executions.get(executionId)
  }

  onExecutionUpdate(executionId: string, callback: (status: ExecutionStatus) => void) {
    const emitter = this.eventEmitters.get(executionId)
    if (emitter) {
      emitter.on('update', callback)
    }
  }

  offExecutionUpdate(executionId: string, callback: (status: ExecutionStatus) => void) {
    const emitter = this.eventEmitters.get(executionId)
    if (emitter) {
      emitter.off('update', callback)
    }
  }

  private emitUpdate(executionId: string, status: ExecutionStatus) {
    const emitter = this.eventEmitters.get(executionId)
    if (emitter) {
      emitter.emit('update', status)
    }
  }
}
