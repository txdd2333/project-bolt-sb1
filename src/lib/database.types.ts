export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      modules: {
        Row: {
          id: string
          name: string
          description: string
          type: string
          config: Json
          icon: string
          color: string
          user_id: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string
          type: string
          config?: Json
          icon?: string
          color?: string
          user_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string
          type?: string
          config?: Json
          icon?: string
          color?: string
          user_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      workflows: {
        Row: {
          id: string
          name: string
          description: string
          definition: Json
          user_id: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string
          definition?: Json
          user_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string
          definition?: Json
          user_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      workflow_nodes: {
        Row: {
          id: string
          workflow_id: string
          module_id: string
          node_id: string
          position: Json
          data: Json
          created_at: string
        }
        Insert: {
          id?: string
          workflow_id: string
          module_id: string
          node_id: string
          position?: Json
          data?: Json
          created_at?: string
        }
        Update: {
          id?: string
          workflow_id?: string
          module_id?: string
          node_id?: string
          position?: Json
          data?: Json
          created_at?: string
        }
        Relationships: []
      }
      workflow_edges: {
        Row: {
          id: string
          workflow_id: string
          edge_id: string
          source_node_id: string
          target_node_id: string
          created_at: string
        }
        Insert: {
          id?: string
          workflow_id: string
          edge_id: string
          source_node_id: string
          target_node_id: string
          created_at?: string
        }
        Update: {
          id?: string
          workflow_id?: string
          edge_id?: string
          source_node_id?: string
          target_node_id?: string
          created_at?: string
        }
        Relationships: []
      }
      scenarios: {
        Row: {
          id: string
          name: string
          description: string
          workflow_id: string | null
          parameters: Json
          sop_content: string
          flowchart_data: Json
          user_id: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string
          workflow_id?: string | null
          parameters?: Json
          sop_content?: string
          flowchart_data?: Json
          user_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string
          workflow_id?: string | null
          parameters?: Json
          sop_content?: string
          flowchart_data?: Json
          user_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      execution_logs: {
        Row: {
          id: string
          scenario_id: string | null
          workflow_id: string | null
          parameters: Json
          status: string
          started_at: string | null
          completed_at: string | null
          error_message: string | null
          user_id: string | null
          created_at: string
        }
        Insert: {
          id?: string
          scenario_id?: string | null
          workflow_id?: string | null
          parameters?: Json
          status?: string
          started_at?: string | null
          completed_at?: string | null
          error_message?: string | null
          user_id?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          scenario_id?: string | null
          workflow_id?: string | null
          parameters?: Json
          status?: string
          started_at?: string | null
          completed_at?: string | null
          error_message?: string | null
          user_id?: string | null
          created_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

export type Module = Database['public']['Tables']['modules']['Row']
export type Workflow = Database['public']['Tables']['workflows']['Row']
export type WorkflowNode = Database['public']['Tables']['workflow_nodes']['Row']
export type WorkflowEdge = Database['public']['Tables']['workflow_edges']['Row']
export type Scenario = Database['public']['Tables']['scenarios']['Row']
export type ExecutionLog = Database['public']['Tables']['execution_logs']['Row']
