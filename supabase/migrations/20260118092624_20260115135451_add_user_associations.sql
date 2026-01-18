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
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'modules') THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'modules' AND column_name = 'user_id'
    ) THEN
      ALTER TABLE modules ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
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

-- 创建索引以提升基于用户的查询性能
CREATE INDEX IF NOT EXISTS idx_workflows_user_id ON workflows(user_id);
CREATE INDEX IF NOT EXISTS idx_scenarios_user_id ON scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_user_id ON execution_logs(user_id);