import {
  Undo2,
  Redo2,
  ZoomIn,
  ZoomOut,
  Maximize,
  Save,
  Download,
  Trash2,
  Copy,
  AlignHorizontalJustifyCenter,
  AlignVerticalJustifyCenter,
  Grid3x3,
  Move,
  Image as ImageIcon,
  Network
} from 'lucide-react';

interface ToolbarProps {
  onUndo: () => void;
  onRedo: () => void;
  onZoomIn: () => void;
  onZoomOut: () => void;
  onFitView: () => void;
  onSave: () => void;
  onExportPNG: () => void;
  onExportSVG: () => void;
  onExportJSON: () => void;
  onDelete: () => void;
  onCopy: () => void;
  onAlignHorizontal: () => void;
  onAlignVertical: () => void;
  onAutoLayout: () => void;
  onToggleGrid: () => void;
  showGrid: boolean;
  canUndo: boolean;
  canRedo: boolean;
  hasSelection: boolean;
}

export const Toolbar = ({
  onUndo,
  onRedo,
  onZoomIn,
  onZoomOut,
  onFitView,
  onSave,
  onExportPNG,
  onExportSVG,
  onExportJSON,
  onDelete,
  onCopy,
  onAlignHorizontal,
  onAlignVertical,
  onAutoLayout,
  onToggleGrid,
  showGrid,
  canUndo,
  canRedo,
  hasSelection,
}: ToolbarProps) => {
  return (
    <div className="absolute top-4 left-1/2 transform -translate-x-1/2 z-10 bg-white rounded-lg shadow-lg border border-gray-200 p-2 flex items-center gap-1">
      <div className="flex items-center gap-1 pr-2 border-r border-gray-200">
        <button
          onClick={onUndo}
          disabled={!canUndo}
          className="p-2 hover:bg-gray-100 rounded transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
          title="撤销 (Ctrl+Z)"
        >
          <Undo2 className="w-4 h-4" />
        </button>
        <button
          onClick={onRedo}
          disabled={!canRedo}
          className="p-2 hover:bg-gray-100 rounded transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
          title="重做 (Ctrl+Y)"
        >
          <Redo2 className="w-4 h-4" />
        </button>
      </div>

      <div className="flex items-center gap-1 px-2 border-r border-gray-200">
        <button
          onClick={onZoomIn}
          className="p-2 hover:bg-gray-100 rounded transition-colors"
          title="放大"
        >
          <ZoomIn className="w-4 h-4" />
        </button>
        <button
          onClick={onZoomOut}
          className="p-2 hover:bg-gray-100 rounded transition-colors"
          title="缩小"
        >
          <ZoomOut className="w-4 h-4" />
        </button>
        <button
          onClick={onFitView}
          className="p-2 hover:bg-gray-100 rounded transition-colors"
          title="适应画布"
        >
          <Maximize className="w-4 h-4" />
        </button>
      </div>

      <div className="flex items-center gap-1 px-2 border-r border-gray-200">
        <button
          onClick={onCopy}
          disabled={!hasSelection}
          className="p-2 hover:bg-gray-100 rounded transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
          title="复制 (Ctrl+C)"
        >
          <Copy className="w-4 h-4" />
        </button>
        <button
          onClick={onDelete}
          disabled={!hasSelection}
          className="p-2 hover:bg-gray-100 rounded transition-colors disabled:opacity-30 disabled:cursor-not-allowed text-red-600 hover:bg-red-50"
          title="删除 (Delete)"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>

      <div className="flex items-center gap-1 px-2 border-r border-gray-200">
        <button
          onClick={onAlignHorizontal}
          disabled={!hasSelection}
          className="p-2 hover:bg-gray-100 rounded transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
          title="水平对齐"
        >
          <AlignHorizontalJustifyCenter className="w-4 h-4" />
        </button>
        <button
          onClick={onAlignVertical}
          disabled={!hasSelection}
          className="p-2 hover:bg-gray-100 rounded transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
          title="垂直对齐"
        >
          <AlignVerticalJustifyCenter className="w-4 h-4" />
        </button>
        <button
          onClick={onAutoLayout}
          className="p-2 hover:bg-gray-100 rounded transition-colors"
          title="自动排版"
        >
          <Network className="w-4 h-4" />
        </button>
        <button
          onClick={onToggleGrid}
          className={`p-2 rounded transition-colors ${showGrid ? 'bg-blue-100 text-blue-600' : 'hover:bg-gray-100'}`}
          title="切换网格"
        >
          <Grid3x3 className="w-4 h-4" />
        </button>
      </div>

      <div className="flex items-center gap-1 px-2 border-r border-gray-200">
        <button
          onClick={onSave}
          className="px-3 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors flex items-center gap-1.5 text-sm font-medium"
          title="保存"
        >
          <Save className="w-4 h-4" />
          保存
        </button>
      </div>

      <div className="flex items-center gap-1 pl-2">
        <div className="relative group">
          <button
            className="p-2 hover:bg-gray-100 rounded transition-colors flex items-center gap-1.5"
            title="导出"
          >
            <Download className="w-4 h-4" />
            <span className="text-sm">导出</span>
          </button>
          <div className="absolute top-full right-0 mt-1 bg-white rounded-lg shadow-lg border border-gray-200 py-1 min-w-[120px] hidden group-hover:block">
            <button
              onClick={onExportPNG}
              className="w-full px-4 py-2 text-left text-sm hover:bg-gray-100 flex items-center gap-2"
            >
              <ImageIcon className="w-4 h-4" />
              PNG 图片
            </button>
            <button
              onClick={onExportSVG}
              className="w-full px-4 py-2 text-left text-sm hover:bg-gray-100 flex items-center gap-2"
            >
              <ImageIcon className="w-4 h-4" />
              SVG 矢量图
            </button>
            <button
              onClick={onExportJSON}
              className="w-full px-4 py-2 text-left text-sm hover:bg-gray-100 flex items-center gap-2"
            >
              <Move className="w-4 h-4" />
              JSON 数据
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
