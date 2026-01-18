/*
  # 修复 scenarios 表结构
  
  ## 修改内容
  
  ### 1. 添加必需的字段
  - `workflow_id` (uuid) - 关联的工作流ID，可为空
  - `parameters` (jsonb) - 场景参数定义
*/

-- 添加 workflow_id 字段
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'scenarios' AND column_name = 'workflow_id'
  ) THEN
    ALTER TABLE scenarios ADD COLUMN workflow_id uuid REFERENCES workflows(id) ON DELETE SET NULL;
  END IF;
END $$;

-- 添加 parameters 字段
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'scenarios' AND column_name = 'parameters'
  ) THEN
    ALTER TABLE scenarios ADD COLUMN parameters jsonb DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_scenarios_workflow_id ON scenarios(workflow_id);