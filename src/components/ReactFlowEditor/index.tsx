import {
  useCallback,
  useRef,
  useState,
  DragEvent,
  forwardRef,
  useImperativeHandle,
  useEffect,
} from 'react';
import ReactFlow, {
  ReactFlowProvider,
  Node,
  Edge,
  Connection,
  addEdge,
  useNodesState,
  useEdgesState,
  Controls,
  MiniMap,
  Background,
  BackgroundVariant,
  ReactFlowInstance,
  NodeChange,
  EdgeChange,
  applyNodeChanges,
  applyEdgeChanges,
  MarkerType,
  ConnectionMode,
  ConnectionLineType,
  reconnectEdge,
} from 'reactflow';
import 'reactflow/dist/style.css';
import dagre from 'dagre';

import { nodeTypes, CustomNodeData } from './nodes/CustomNodes';
import { Toolbar } from './Toolbar';
import { ElementPanel } from './ElementPanel';
import { PropertiesPanel } from './PropertiesPanel';
import { toPng, toSvg } from 'html-to-image';

export interface ReactFlowEditorRef {
  getData: () => Promise<string | null>;
  loadData: (data: string) => void;
  exportImage: (format: 'png' | 'svg') => void;
}

interface ReactFlowEditorProps {
  initialData?: string;
  onDataChange?: (data: string) => void;
  onSave?: (data: string) => void;
}

const ReactFlowEditorInner = forwardRef<ReactFlowEditorRef, ReactFlowEditorProps>(
  ({ initialData, onDataChange, onSave }, ref) => {
    const reactFlowWrapper = useRef<HTMLDivElement>(null);
    const [nodes, setNodes] = useNodesState([]);
    const [edges, setEdges] = useEdgesState([]);
    const [reactFlowInstance, setReactFlowInstance] = useState<ReactFlowInstance | null>(null);
    const [selectedNode, setSelectedNode] = useState<Node<CustomNodeData> | null>(null);
    const [selectedEdge, setSelectedEdge] = useState<Edge | null>(null);
    const [showGrid, setShowGrid] = useState(true);
    const [history, setHistory] = useState<{ nodes: Node[]; edges: Edge[] }[]>([]);
    const [historyIndex, setHistoryIndex] = useState(-1);

    const nodeIdCounter = useRef(1);

    const saveToHistory = useCallback(() => {
      const newHistory = history.slice(0, historyIndex + 1);
      newHistory.push({ nodes: [...nodes], edges: [...edges] });
      if (newHistory.length > 50) {
        newHistory.shift();
      } else {
        setHistoryIndex(historyIndex + 1);
      }
      setHistory(newHistory);
    }, [nodes, edges, history, historyIndex]);

    useEffect(() => {
      if (initialData) {
        try {
          const data = JSON.parse(initialData);
          if (data.nodes) setNodes(data.nodes);
          if (data.edges) setEdges(data.edges);
          if (data.nodeIdCounter) nodeIdCounter.current = data.nodeIdCounter;
        } catch (e) {
          console.error('Failed to load initial data:', e);
        }
      }
    }, []);

    useEffect(() => {
      if (nodes.length > 0 || edges.length > 0) {
        const data = JSON.stringify({
          nodes,
          edges,
          nodeIdCounter: nodeIdCounter.current,
        });
        onDataChange?.(data);
      }
    }, [nodes, edges, onDataChange]);

    const onNodesChange = useCallback(
      (changes: NodeChange[]) => {
        setNodes((nds) => applyNodeChanges(changes, nds));
      },
      [setNodes]
    );

    const onEdgesChange = useCallback(
      (changes: EdgeChange[]) => {
        setEdges((eds) => applyEdgeChanges(changes, eds));
      },
      [setEdges]
    );

    const onConnect = useCallback(
      (params: Connection) => {
        saveToHistory();
        setEdges((eds) =>
          addEdge(
            {
              ...params,
              type: 'smoothstep',
              animated: false,
              markerEnd: { type: MarkerType.ArrowClosed },
              style: { stroke: '#b1b1b7', strokeWidth: 2 },
            },
            eds
          )
        );
      },
      [setEdges, saveToHistory]
    );

    const edgeReconnectSuccessful = useRef(true);

    const onReconnectStart = useCallback(() => {
      edgeReconnectSuccessful.current = false;
    }, []);

    const onReconnect = useCallback(
      (oldEdge: Edge, newConnection: Connection) => {
        edgeReconnectSuccessful.current = true;
        saveToHistory();
        setEdges((els) => reconnectEdge(oldEdge, newConnection, els));
      },
      [saveToHistory]
    );

    const onReconnectEnd = useCallback(
      (_: any, edge: Edge) => {
        if (!edgeReconnectSuccessful.current) {
          setEdges((eds) => eds.filter((e) => e.id !== edge.id));
        }
        edgeReconnectSuccessful.current = true;
      },
      []
    );

    const onDragOver = useCallback((event: DragEvent) => {
      event.preventDefault();
      event.dataTransfer.dropEffect = 'move';
    }, []);

    const onDrop = useCallback(
      (event: DragEvent) => {
        event.preventDefault();

        const type = event.dataTransfer.getData('application/reactflow-type');
        const defaultDataStr = event.dataTransfer.getData('application/reactflow-data');

        if (!type || !reactFlowInstance) {
          return;
        }

        const defaultData = defaultDataStr ? JSON.parse(defaultDataStr) : {};
        const position = reactFlowInstance.screenToFlowPosition({
          x: event.clientX,
          y: event.clientY,
        });

        const newNode: Node<CustomNodeData> = {
          id: `node_${nodeIdCounter.current++}`,
          type,
          position,
          data: defaultData,
        };

        saveToHistory();
        setNodes((nds) => nds.concat(newNode));
      },
      [reactFlowInstance, setNodes, saveToHistory]
    );

    const onDragStart = (event: DragEvent, nodeType: string, defaultData: any) => {
      event.dataTransfer.setData('application/reactflow-type', nodeType);
      event.dataTransfer.setData('application/reactflow-data', JSON.stringify(defaultData));
      event.dataTransfer.effectAllowed = 'move';
    };

    const handleUndo = () => {
      if (historyIndex > 0) {
        const newIndex = historyIndex - 1;
        setHistoryIndex(newIndex);
        const state = history[newIndex];
        setNodes(state.nodes);
        setEdges(state.edges);
      }
    };

    const handleRedo = () => {
      if (historyIndex < history.length - 1) {
        const newIndex = historyIndex + 1;
        setHistoryIndex(newIndex);
        const state = history[newIndex];
        setNodes(state.nodes);
        setEdges(state.edges);
      }
    };

    const handleZoomIn = () => {
      reactFlowInstance?.zoomIn();
    };

    const handleZoomOut = () => {
      reactFlowInstance?.zoomOut();
    };

    const handleFitView = () => {
      reactFlowInstance?.fitView();
    };

    const handleSave = () => {
      const data = JSON.stringify({
        nodes,
        edges,
        nodeIdCounter: nodeIdCounter.current,
      });
      onSave?.(data);
    };

    const handleExportPNG = () => {
      if (reactFlowWrapper.current) {
        const viewport = reactFlowWrapper.current.querySelector('.react-flow__viewport');
        if (viewport) {
          toPng(viewport as HTMLElement, {
            backgroundColor: '#ffffff',
            width: viewport.clientWidth,
            height: viewport.clientHeight,
          })
            .then((dataUrl) => {
              const link = document.createElement('a');
              link.download = 'flowchart.png';
              link.href = dataUrl;
              link.click();
            })
            .catch((err) => {
              console.error('Failed to export PNG:', err);
            });
        }
      }
    };

    const handleExportSVG = () => {
      if (reactFlowWrapper.current) {
        const viewport = reactFlowWrapper.current.querySelector('.react-flow__viewport');
        if (viewport) {
          toSvg(viewport as HTMLElement, {
            backgroundColor: '#ffffff',
            width: viewport.clientWidth,
            height: viewport.clientHeight,
          })
            .then((dataUrl) => {
              const link = document.createElement('a');
              link.download = 'flowchart.svg';
              link.href = dataUrl;
              link.click();
            })
            .catch((err) => {
              console.error('Failed to export SVG:', err);
            });
        }
      }
    };

    const handleExportJSON = () => {
      const data = JSON.stringify(
        {
          nodes,
          edges,
          nodeIdCounter: nodeIdCounter.current,
        },
        null,
        2
      );
      const blob = new Blob([data], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.download = 'flowchart.json';
      link.href = url;
      link.click();
      URL.revokeObjectURL(url);
    };

    const handleDelete = () => {
      saveToHistory();
      if (selectedNode) {
        setNodes((nds) => nds.filter((n) => n.id !== selectedNode.id));
        setSelectedNode(null);
      }
      if (selectedEdge) {
        setEdges((eds) => eds.filter((e) => e.id !== selectedEdge.id));
        setSelectedEdge(null);
      }
    };

    const handleCopy = () => {
      if (selectedNode) {
        const newNode: Node<CustomNodeData> = {
          ...selectedNode,
          id: `node_${nodeIdCounter.current++}`,
          position: {
            x: selectedNode.position.x + 50,
            y: selectedNode.position.y + 50,
          },
        };
        saveToHistory();
        setNodes((nds) => [...nds, newNode]);
      }
    };

    const handleAlignHorizontal = () => {
      if (selectedNode && nodes.length > 1) {
        const avgY = nodes.reduce((sum, n) => sum + n.position.y, 0) / nodes.length;
        saveToHistory();
        setNodes((nds) =>
          nds.map((n) =>
            n.selected ? { ...n, position: { ...n.position, y: avgY } } : n
          )
        );
      }
    };

    const handleAlignVertical = () => {
      if (selectedNode && nodes.length > 1) {
        const avgX = nodes.reduce((sum, n) => sum + n.position.x, 0) / nodes.length;
        saveToHistory();
        setNodes((nds) =>
          nds.map((n) =>
            n.selected ? { ...n, position: { ...n.position, x: avgX } } : n
          )
        );
      }
    };

    const handleAutoLayout = () => {
      const dagreGraph = new dagre.graphlib.Graph();
      dagreGraph.setDefaultEdgeLabel(() => ({}));
      dagreGraph.setGraph({
        rankdir: 'TB',
        nodesep: 100,
        ranksep: 100,
        marginx: 50,
        marginy: 50
      });

      nodes.forEach((node) => {
        dagreGraph.setNode(node.id, {
          width: node.width || 120,
          height: node.height || 60
        });
      });

      edges.forEach((edge) => {
        dagreGraph.setEdge(edge.source, edge.target);
      });

      dagre.layout(dagreGraph);

      saveToHistory();
      setNodes((nds) =>
        nds.map((node) => {
          const nodeWithPosition = dagreGraph.node(node.id);
          return {
            ...node,
            position: {
              x: nodeWithPosition.x - (node.width || 120) / 2,
              y: nodeWithPosition.y - (node.height || 60) / 2,
            },
          };
        })
      );

      setTimeout(() => {
        reactFlowInstance?.fitView({ padding: 0.2 });
      }, 0);
    };

    const handleToggleGrid = () => {
      setShowGrid(!showGrid);
    };

    const handleNodeUpdate = (nodeId: string, data: Partial<CustomNodeData>) => {
      saveToHistory();
      setNodes((nds) =>
        nds.map((n) => {
          if (n.id === nodeId) {
            return { ...n, data: { ...n.data, ...data } };
          }
          return n;
        })
      );
    };

    const handleEdgeUpdate = (edgeId: string, updates: any) => {
      saveToHistory();
      setEdges((eds) =>
        eds.map((e) => {
          if (e.id === edgeId) {
            const newEdge = { ...e };
            if (updates.label !== undefined) newEdge.label = updates.label;
            if (updates.type !== undefined) newEdge.type = updates.type;
            if (updates.animated !== undefined) newEdge.animated = updates.animated;
            if (updates.stroke !== undefined || updates.strokeWidth !== undefined) {
              newEdge.style = {
                ...newEdge.style,
                ...(updates.stroke && { stroke: updates.stroke }),
                ...(updates.strokeWidth && { strokeWidth: updates.strokeWidth }),
              };
            }
            return newEdge;
          }
          return e;
        })
      );
    };

    const onNodeClick = useCallback((_: any, node: Node<CustomNodeData>) => {
      setSelectedNode(node);
      setSelectedEdge(null);
    }, []);

    const onEdgeClick = useCallback((_: any, edge: Edge) => {
      setSelectedEdge(edge);
      setSelectedNode(null);
    }, []);

    const onPaneClick = useCallback(() => {
      setSelectedNode(null);
      setSelectedEdge(null);
    }, []);

    useImperativeHandle(ref, () => ({
      getData: async () => {
        return JSON.stringify({
          nodes,
          edges,
          nodeIdCounter: nodeIdCounter.current,
        });
      },
      loadData: (data: string) => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.nodes) setNodes(parsed.nodes);
          if (parsed.edges) setEdges(parsed.edges);
          if (parsed.nodeIdCounter) nodeIdCounter.current = parsed.nodeIdCounter;
        } catch (e) {
          console.error('Failed to load data:', e);
        }
      },
      exportImage: (format: 'png' | 'svg') => {
        if (format === 'png') {
          handleExportPNG();
        } else {
          handleExportSVG();
        }
      },
    }));

    useEffect(() => {
      const handleKeyDown = (e: KeyboardEvent) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) {
          e.preventDefault();
          handleUndo();
        }
        if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || (e.key === 'z' && e.shiftKey))) {
          e.preventDefault();
          handleRedo();
        }
        if ((e.ctrlKey || e.metaKey) && e.key === 'c' && selectedNode) {
          e.preventDefault();
          handleCopy();
        }
        if (e.key === 'Delete' && (selectedNode || selectedEdge)) {
          e.preventDefault();
          handleDelete();
        }
      };

      window.addEventListener('keydown', handleKeyDown);
      return () => window.removeEventListener('keydown', handleKeyDown);
    }, [selectedNode, selectedEdge, historyIndex, history]);

    return (
      <div className="w-full h-full relative bg-gray-50" ref={reactFlowWrapper}>
        <Toolbar
          onUndo={handleUndo}
          onRedo={handleRedo}
          onZoomIn={handleZoomIn}
          onZoomOut={handleZoomOut}
          onFitView={handleFitView}
          onSave={handleSave}
          onExportPNG={handleExportPNG}
          onExportSVG={handleExportSVG}
          onExportJSON={handleExportJSON}
          onDelete={handleDelete}
          onCopy={handleCopy}
          onAlignHorizontal={handleAlignHorizontal}
          onAlignVertical={handleAlignVertical}
          onAutoLayout={handleAutoLayout}
          onToggleGrid={handleToggleGrid}
          showGrid={showGrid}
          canUndo={historyIndex > 0}
          canRedo={historyIndex < history.length - 1}
          hasSelection={!!selectedNode || !!selectedEdge}
        />

        <ElementPanel onDragStart={onDragStart} />

        <PropertiesPanel
          selectedNode={selectedNode}
          selectedEdge={selectedEdge}
          onNodeUpdate={handleNodeUpdate}
          onEdgeUpdate={handleEdgeUpdate}
          onClose={() => {
            setSelectedNode(null);
            setSelectedEdge(null);
          }}
        />

        <ReactFlow
          nodes={nodes}
          edges={edges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onConnect={onConnect}
          onReconnect={onReconnect}
          onReconnectStart={onReconnectStart}
          onReconnectEnd={onReconnectEnd}
          onInit={setReactFlowInstance}
          onDrop={onDrop}
          onDragOver={onDragOver}
          onNodeClick={onNodeClick}
          onEdgeClick={onEdgeClick}
          onPaneClick={onPaneClick}
          nodeTypes={nodeTypes}
          connectionMode={ConnectionMode.Loose}
          connectionLineType={ConnectionLineType.SmoothStep}
          defaultEdgeOptions={{
            type: 'smoothstep',
            animated: false,
            markerEnd: { type: MarkerType.ArrowClosed },
            style: { stroke: '#b1b1b7', strokeWidth: 2 },
          }}
          fitView
          attributionPosition="bottom-right"
        >
          <Controls position="bottom-left" />
          <MiniMap
            position="bottom-right"
            nodeColor={(node) => {
              const data = node.data as CustomNodeData;
              return data.bgColor || '#ffffff';
            }}
            style={{
              backgroundColor: '#f9fafb',
              border: '1px solid #e5e7eb',
            }}
          />
          {showGrid && <Background variant={BackgroundVariant.Dots} gap={16} size={1} />}
        </ReactFlow>
      </div>
    );
  }
);

ReactFlowEditorInner.displayName = 'ReactFlowEditorInner';

const ReactFlowEditor = forwardRef<ReactFlowEditorRef, ReactFlowEditorProps>((props, ref) => {
  return (
    <ReactFlowProvider>
      <ReactFlowEditorInner {...props} ref={ref} />
    </ReactFlowProvider>
  );
});

ReactFlowEditor.displayName = 'ReactFlowEditor';

export default ReactFlowEditor;
