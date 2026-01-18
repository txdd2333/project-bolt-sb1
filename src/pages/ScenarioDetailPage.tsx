import { useEffect, useState, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { dataService } from '../services';
import { FileText, GitBranch, Workflow, Play, Save, ArrowLeft, Upload, Download, ChevronDown } from 'lucide-react';
import { importDocument, exportDocument, getAcceptedFileTypes, type ExportFormat } from '../lib/documentUtils';
import type { Scenario as DbScenario } from '../lib/database.types';
import MarkdownEditor from '../components/MarkdownEditor';
import ReactFlowEditor, { ReactFlowEditorRef } from '../components/ReactFlowEditor';
import { playwrightService } from '../services/playwright/PlaywrightService';

interface Workflow {
  id: string;
  name: string;
  description: string;
}

type TabType = 'sop' | 'flowchart' | 'workflow';

export default function ScenarioDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [scenario, setScenario] = useState<DbScenario | null>(null);
  const [workflows, setWorkflows] = useState<Workflow[]>([]);
  const [activeTab, setActiveTab] = useState<TabType>('sop');
  const [sopContent, setSopContent] = useState('');
  const [flowchartData, setFlowchartData] = useState<string>('');
  const [selectedWorkflowId, setSelectedWorkflowId] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showExportMenu, setShowExportMenu] = useState(false);
  const [importing, setImporting] = useState(false);
  const [executing, setExecuting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const exportMenuRef = useRef<HTMLDivElement>(null);
  const flowEditorRef = useRef<ReactFlowEditorRef>(null);

  useEffect(() => {
    loadScenario();
    loadWorkflows();
  }, [id]);

  const loadScenario = async () => {
    if (!id) {
      navigate('/scenarios');
      return;
    }

    try {
      const { data, error } = await dataService.queryOne('scenarios', {
        filter: { id }
      });

      if (error) throw error;
      if (!data) {
        navigate('/scenarios');
        return;
      }

      setScenario(data);
      setSopContent(data.sop_content || '');
      setSelectedWorkflowId(data.workflow_id || '');

      if (data.flowchart_data && typeof data.flowchart_data === 'string') {
        setFlowchartData(data.flowchart_data);
      }
    } catch (error) {
      console.error('Error loading scenario:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadWorkflows = async () => {
    try {
      const { data, error } = await dataService.query('workflows', {
        select: 'id, name, description',
        order: { column: 'created_at', ascending: false }
      });

      if (error) throw error;
      setWorkflows(data || []);
    } catch (error) {
      console.error('Error loading workflows:', error);
    }
  };

  const handleSave = async () => {
    if (!scenario) return;
    setSaving(true);

    try {
      const updates: any = {};

      if (activeTab === 'sop') {
        updates.sop_content = sopContent;
      } else if (activeTab === 'flowchart') {
        const data = await flowEditorRef.current?.getData();
        if (data) {
          updates.flowchart_data = data;
          setFlowchartData(data);
        }
      } else if (activeTab === 'workflow') {
        updates.workflow_id = selectedWorkflowId || null;
      }

      updates.updated_at = new Date().toISOString();

      const { error } = await dataService.update('scenarios', scenario.id, updates);

      if (error) throw error;

      setScenario({ ...scenario, ...updates });
      alert('保存成功！');
    } catch (error) {
      console.error('Error saving:', error);
      alert('保存失败，请重试');
    } finally {
      setSaving(false);
    }
  };

  const handleExecute = async () => {
    if (!selectedWorkflowId) {
      alert('请先在"关联工作流"选项卡中选择一个工作流');
      return;
    }

    setExecuting(true);
    try {
      const { data: workflowData, error: workflowError } = await dataService.queryOne('workflows', {
        filter: { id: selectedWorkflowId }
      });

      if (workflowError) throw workflowError;
      if (!workflowData) {
        alert('工作流不存在');
        return;
      }

      const definition = (workflowData as any).definition;
      if (!definition) {
        alert('工作流未定义，请先编辑工作流');
        return;
      }

      let workflow;
      try {
        workflow = JSON.parse(definition);
      } catch {
        alert('工作流数据格式错误');
        return;
      }

      const workflowPayload = {
        nodes: workflow.nodes.map((n: any) => ({
          id: n.id,
          type: n.type,
          properties: n.properties
        })),
        edges: workflow.edges.map((e: any) => ({
          id: e.id,
          sourceNodeId: e.sourceNodeId,
          targetNodeId: e.targetNodeId
        }))
      };

      const { executionId } = await playwrightService.executeWorkflow(workflowPayload, {
        scenarioId: scenario?.id,
        scenarioName: scenario?.name
      });

      await dataService.insert('execution_logs', {
        workflow_id: selectedWorkflowId,
        scenario_id: scenario?.id,
        status: 'running',
        execution_id: executionId,
        started_at: new Date().toISOString()
      });

      alert(`工作流开始执行！\n执行ID: ${executionId}\n\n请查看后端终端查看执行日志。`);
    } catch (error: any) {
      console.error('Error executing workflow:', error);
      alert(`执行失败：${error.message}\n\n请确保后端服务已启动（npm run server）`);
    } finally {
      setExecuting(false);
    }
  };

  const handleImportClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileImport = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setImporting(true);
    try {
      const html = await importDocument(file);
      setSopContent(html);
      alert('导入成功！');
    } catch (error) {
      console.error('Import error:', error);
      alert(error instanceof Error ? error.message : '导入失败，请重试');
    } finally {
      setImporting(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const handleExport = (format: ExportFormat) => {
    const baseName = scenario?.name || 'SOP文档';
    try {
      exportDocument(sopContent, format, baseName);
      setShowExportMenu(false);
    } catch (error) {
      console.error('Export error:', error);
      alert('导出失败，请重试');
    }
  };

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (exportMenuRef.current && !exportMenuRef.current.contains(event.target as globalThis.Node)) {
        setShowExportMenu(false);
      }
    };

    if (showExportMenu) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showExportMenu]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-gray-500">加载中...</div>
      </div>
    );
  }

  if (!scenario) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-gray-500">场景不存在</div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center justify-between p-6 border-b border-gray-200">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate('/scenarios')}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-gray-600" />
          </button>
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">{scenario.name}</h1>
            <p className="text-sm text-gray-500 mt-1">{scenario.description}</p>
          </div>
        </div>
        <div className="flex gap-3">
          <button
            onClick={handleSave}
            disabled={saving}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2 disabled:opacity-50"
          >
            <Save className="w-4 h-4" />
            {saving ? '保存中...' : '保存'}
          </button>
          <button
            onClick={handleExecute}
            disabled={executing || !selectedWorkflowId}
            className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            title={!selectedWorkflowId ? '请先关联一个工作流' : ''}
          >
            <Play className="w-4 h-4" />
            {executing ? '执行中...' : '启动执行'}
          </button>
        </div>
      </div>

      <div className="flex border-b border-gray-200">
        <button
          onClick={() => setActiveTab('sop')}
          className={`px-6 py-3 font-medium transition-colors flex items-center gap-2 ${
            activeTab === 'sop'
              ? 'text-blue-600 border-b-2 border-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <FileText className="w-4 h-4" />
          SOP 文档
        </button>
        <button
          onClick={() => setActiveTab('flowchart')}
          className={`px-6 py-3 font-medium transition-colors flex items-center gap-2 ${
            activeTab === 'flowchart'
              ? 'text-blue-600 border-b-2 border-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <GitBranch className="w-4 h-4" />
          流程图
        </button>
        <button
          onClick={() => setActiveTab('workflow')}
          className={`px-6 py-3 font-medium transition-colors flex items-center gap-2 ${
            activeTab === 'workflow'
              ? 'text-blue-600 border-b-2 border-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <Workflow className="w-4 h-4" />
          关联工作流
        </button>
      </div>

      <div className="flex-1 overflow-hidden bg-slate-50 relative">
        {activeTab === 'sop' && (
          <div className="absolute inset-0 p-6">
            <div className="h-full flex flex-col">
              <div className="mb-4 flex items-start justify-between">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">
                    标准操作程序文档
                  </h3>
                  <p className="text-sm text-gray-500">
                    编写详细的操作步骤、注意事项和应急处理流程。支持标题、列表、代码块、表格、图片等丰富格式。
                  </p>
                </div>
                <div className="flex gap-2">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept={getAcceptedFileTypes()}
                    onChange={handleFileImport}
                    className="hidden"
                  />
                  <button
                    onClick={handleImportClick}
                    disabled={importing}
                    className="px-3 py-1.5 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center gap-1.5 disabled:opacity-50"
                  >
                    <Upload className="w-4 h-4" />
                    {importing ? '导入中...' : '导入'}
                  </button>
                  <div className="relative" ref={exportMenuRef}>
                    <button
                      onClick={() => setShowExportMenu(!showExportMenu)}
                      className="px-3 py-1.5 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center gap-1.5"
                    >
                      <Download className="w-4 h-4" />
                      导出
                      <ChevronDown className="w-3 h-3" />
                    </button>
                    {showExportMenu && (
                      <div className="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-lg shadow-lg py-1 z-10">
                        <button
                          onClick={() => handleExport('txt')}
                          className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-50"
                        >
                          纯文本 (.txt)
                        </button>
                        <button
                          onClick={() => handleExport('md')}
                          className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-50"
                        >
                          Markdown (.md)
                        </button>
                        <button
                          onClick={() => handleExport('docx')}
                          className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-50"
                        >
                          Word (.docx)
                        </button>
                        <button
                          onClick={() => handleExport('html')}
                          className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-50"
                        >
                          HTML (.html)
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>
              <div className="flex-1 min-h-0">
                <MarkdownEditor
                  value={sopContent}
                  onChange={setSopContent}
                  placeholder="在此编写应急处理流程、操作步骤、注意事项等内容..."
                />
              </div>
            </div>
          </div>
        )}

        {activeTab === 'flowchart' && (
          <div className="absolute inset-0">
            <ReactFlowEditor
              ref={flowEditorRef}
              initialData={flowchartData}
              onDataChange={(data) => setFlowchartData(data)}
              onSave={handleSave}
            />
          </div>
        )}

        {activeTab === 'workflow' && (
          <div className="absolute inset-0 p-6 overflow-y-auto">
            <div className="max-w-2xl mx-auto">
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  选择关联工作流
                </label>
                <p className="text-sm text-gray-500 mb-4">
                  将此应急场景关联到一个自动化工作流，可以一键执行预定义的操作步骤
                </p>
              </div>

              <select
                value={selectedWorkflowId}
                onChange={(e) => setSelectedWorkflowId(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">不关联工作流</option>
                {workflows.map((workflow) => (
                  <option key={workflow.id} value={workflow.id}>
                    {workflow.name} {workflow.description && `- ${workflow.description}`}
                  </option>
                ))}
              </select>

              {workflows.length === 0 && (
                <div className="mt-4 p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-600">
                    暂无可用工作流，请先在
                    <button
                      onClick={() => navigate('/workflows')}
                      className="text-blue-600 hover:underline mx-1"
                    >
                      工作流管理
                    </button>
                    中创建工作流
                  </p>
                </div>
              )}

              {selectedWorkflowId && (
                <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg">
                  <p className="text-sm text-green-800">
                    已选择工作流。保存后，您可以直接启动此工作流来处理该应急场景。
                  </p>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
