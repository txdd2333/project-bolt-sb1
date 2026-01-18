/*
  # 添加用户关联和数据隔离

  ## 修改内容

  ### 1. 添加用户字段
  为所有主要表添加 `user_id` 字段，关联到 auth.users 表：
  - modules.user_id
  - workflows.user_id
  - scenarios.user_id
  - execution_logs.user_id

  注意：workflow_nodes 和 workflow_edges 通过 workflow_id 间接关联用户

  ### 2. 更新 RLS 策略
  将原有的 `USING (true)` 策略改为基于用户所有权的策略：
  - 用户只能查看、创建、更新和删除自己的数据
  - SELECT 策略：检查 user_id = auth.uid()
  - INSERT 策略：强制 user_id = auth.uid()
  - UPDATE 策略：检查 user_id = auth.uid()
  - DELETE 策略：检查 user_id = auth.uid()

  ### 3. 数据完整性
  - 所有 user_id 字段设置为 NOT NULL
  - 添加外键约束引用 auth.users(id)
  - 当用户删除时，级联删除相关数据

  ### 4. 索引优化
  为 user_id 字段添加索引以提升查询性能
*/

-- 添加 user_id 字段到 modules 表
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'modules' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE modules ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 添加 user_id 字段到 workflows 表
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'workflows' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE workflows ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 添加 user_id 字段到 scenarios 表
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'scenarios' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE scenarios ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 添加 user_id 字段到 execution_logs 表
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'execution_logs' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE execution_logs ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 删除旧的 RLS 策略
DROP POLICY IF EXISTS "Allow authenticated users to view modules" ON modules;
DROP POLICY IF EXISTS "Allow authenticated users to create modules" ON modules;
DROP POLICY IF EXISTS "Allow authenticated users to update modules" ON modules;
DROP POLICY IF EXISTS "Allow authenticated users to delete modules" ON modules;

DROP POLICY IF EXISTS "Allow authenticated users to view workflows" ON workflows;
DROP POLICY IF EXISTS "Allow authenticated users to create workflows" ON workflows;
DROP POLICY IF EXISTS "Allow authenticated users to update workflows" ON workflows;
DROP POLICY IF EXISTS "Allow authenticated users to delete workflows" ON workflows;

DROP POLICY IF EXISTS "Allow authenticated users to view workflow_nodes" ON workflow_nodes;
DROP POLICY IF EXISTS "Allow authenticated users to create workflow_nodes" ON workflow_nodes;
DROP POLICY IF EXISTS "Allow authenticated users to update workflow_nodes" ON workflow_nodes;
DROP POLICY IF EXISTS "Allow authenticated users to delete workflow_nodes" ON workflow_nodes;

DROP POLICY IF EXISTS "Allow authenticated users to view workflow_edges" ON workflow_edges;
DROP POLICY IF EXISTS "Allow authenticated users to create workflow_edges" ON workflow_edges;
DROP POLICY IF EXISTS "Allow authenticated users to update workflow_edges" ON workflow_edges;
DROP POLICY IF EXISTS "Allow authenticated users to delete workflow_edges" ON workflow_edges;

DROP POLICY IF EXISTS "Allow authenticated users to view scenarios" ON scenarios;
DROP POLICY IF EXISTS "Allow authenticated users to create scenarios" ON scenarios;
DROP POLICY IF EXISTS "Allow authenticated users to update scenarios" ON scenarios;
DROP POLICY IF EXISTS "Allow authenticated users to delete scenarios" ON scenarios;

DROP POLICY IF EXISTS "Allow authenticated users to view execution_logs" ON execution_logs;
DROP POLICY IF EXISTS "Allow authenticated users to create execution_logs" ON execution_logs;
DROP POLICY IF EXISTS "Allow authenticated users to update execution_logs" ON execution_logs;

-- 创建新的 RLS 策略 - modules 表
CREATE POLICY "Users can view own modules"
  ON modules FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can create own modules"
  ON modules FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own modules"
  ON modules FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own modules"
  ON modules FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- 创建新的 RLS 策略 - workflows 表
CREATE POLICY "Users can view own workflows"
  ON workflows FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can create own workflows"
  ON workflows FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own workflows"
  ON workflows FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own workflows"
  ON workflows FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- 创建新的 RLS 策略 - workflow_nodes 表（基于关联的 workflow）
CREATE POLICY "Users can view nodes of own workflows"
  ON workflow_nodes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_nodes.workflow_id
      AND workflows.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create nodes in own workflows"
  ON workflow_nodes FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_nodes.workflow_id
      AND workflows.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update nodes in own workflows"
  ON workflow_nodes FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_nodes.workflow_id
      AND workflows.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_nodes.workflow_id
      AND workflows.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete nodes in own workflows"
  ON workflow_nodes FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_nodes.workflow_id
      AND workflows.user_id = auth.uid()
    )
  );

-- 创建新的 RLS 策略 - workflow_edges 表（基于关联的 workflow）
CREATE POLICY "Users can view edges of own workflows"
  ON workflow_edges FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_edges.workflow_id
      AND workflows.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create edges in own workflows"
  ON workflow_edges FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_edges.workflow_id
      AND workflows.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update edges in own workflows"
  ON workflow_edges FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_edges.workflow_id
      AND workflows.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_edges.workflow_id
      AND workflows.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete edges in own workflows"
  ON workflow_edges FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workflows
      WHERE workflows.id = workflow_edges.workflow_id
      AND workflows.user_id = auth.uid()
    )
  );

-- 创建新的 RLS 策略 - scenarios 表
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

-- 创建新的 RLS 策略 - execution_logs 表
CREATE POLICY "Users can view own execution logs"
  ON execution_logs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can create own execution logs"
  ON execution_logs FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own execution logs"
  ON execution_logs FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 创建索引以提升基于用户的查询性能
CREATE INDEX IF NOT EXISTS idx_modules_user_id ON modules(user_id);
CREATE INDEX IF NOT EXISTS idx_workflows_user_id ON workflows(user_id);
CREATE INDEX IF NOT EXISTS idx_scenarios_user_id ON scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_user_id ON execution_logs(user_id);
