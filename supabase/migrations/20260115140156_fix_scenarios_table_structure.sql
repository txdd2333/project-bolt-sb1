/*
  # 修复 scenarios 表结构
  
  ## 问题描述
  现有的 scenarios 表结构与应用需求不匹配，缺少关键字段
  
  ## 修改内容
  
  ### 1. 删除不需要的字段
  - `category_id` - 不需要的分类字段
  - `code` - 不需要的编码字段
  - `severity_level` - 不需要的严重程度字段
  - `tags` - 不需要的标签字段
  - `created_by` - 使用 user_id 替代
  - `updated_by` - 不需要的字段
  
  ### 2. 添加必需的字段
  - `workflow_id` (uuid) - 关联的工作流ID，可为空
  - `parameters` (jsonb) - 场景参数定义
  
  ### 3. 保留的字段
  - `id`, `name`, `description`, `user_id`, `created_at`, `updated_at`
  
  注意：由于需要大幅调整表结构，采用重建表的方式以确保数据完整性
*/

-- 备份现有数据（如果有）
DO $$
DECLARE
  table_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'scenarios'
  ) INTO table_exists;
  
  IF table_exists THEN
    -- 创建临时备份表
    CREATE TABLE IF NOT EXISTS scenarios_backup AS 
    SELECT id, name, description, user_id, created_at, updated_at 
    FROM scenarios;
    
    -- 删除旧表（级联删除相关数据）
    DROP TABLE IF EXISTS scenarios CASCADE;
  END IF;
END $$;

-- 创建新的 scenarios 表
CREATE TABLE scenarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  workflow_id uuid REFERENCES workflows(id) ON DELETE SET NULL,
  parameters jsonb DEFAULT '[]'::jsonb,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 恢复数据（如果有备份）
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'scenarios_backup'
  ) THEN
    INSERT INTO scenarios (id, name, description, user_id, created_at, updated_at)
    SELECT id, name, description, user_id, created_at, updated_at
    FROM scenarios_backup
    ON CONFLICT (id) DO NOTHING;
    
    -- 删除备份表
    DROP TABLE scenarios_backup;
  END IF;
END $$;

-- 启用 RLS
ALTER TABLE scenarios ENABLE ROW LEVEL SECURITY;

-- 创建 RLS 策略
CREATE POLICY "Users can view own scenarios"
  ON scenarios FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can create own scenarios"
  ON scenarios FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own scenarios"
  ON scenarios FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own scenarios"
  ON scenarios FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_scenarios_workflow_id ON scenarios(workflow_id);
CREATE INDEX IF NOT EXISTS idx_scenarios_user_id ON scenarios(user_id);
