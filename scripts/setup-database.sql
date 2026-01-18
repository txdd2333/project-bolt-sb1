/*
  # 运维工作流中心 - 完整数据库初始化脚本

  ## 使用方法
  1. 登录 Supabase 控制台
  2. 进入 SQL Editor
  3. 复制本文件全部内容
  4. 粘贴并点击 Run
  5. 验证：SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

  ## 包含内容
  - 4 个核心表（modules, workflows, scenarios, execution_logs）
  - 完整的 RLS 策略
  - Storage 存储桶和策略
  - 索引优化

  ## 注意事项
  - 使用 IF NOT EXISTS 确保幂等性
  - 可以重复运行不会出错
  - 已有数据不会被删除
*/

-- ============================================
-- 1. 创建 modules 表（模块管理）
-- ============================================
CREATE TABLE IF NOT EXISTS modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  type text NOT NULL,
  config jsonb DEFAULT '{}',
  icon text DEFAULT '📦',
  color text DEFAULT '#3b82f6',
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 启用 RLS
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;

-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "Users can view own modules" ON modules;
DROP POLICY IF EXISTS "Users can create modules" ON modules;
DROP POLICY IF EXISTS "Users can update own modules" ON modules;
DROP POLICY IF EXISTS "Users can delete own modules" ON modules;

-- 创建策略
CREATE POLICY "Users can view own modules"
  ON modules FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create modules"
  ON modules FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own modules"
  ON modules FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own modules"
  ON modules FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_modules_user_id ON modules(user_id);
CREATE INDEX IF NOT EXISTS idx_modules_type ON modules(type);
CREATE INDEX IF NOT EXISTS idx_modules_created_at ON modules(created_at DESC);

COMMENT ON TABLE modules IS '可复用的自动化操作模块';

-- ============================================
-- 2. 创建 workflows 表（工作流管理）
-- ============================================
CREATE TABLE IF NOT EXISTS workflows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  definition jsonb DEFAULT '{"nodes":[],"edges":[]}',
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 启用 RLS
ALTER TABLE workflows ENABLE ROW LEVEL SECURITY;

-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "Users can view own workflows" ON workflows;
DROP POLICY IF EXISTS "Users can create workflows" ON workflows;
DROP POLICY IF EXISTS "Users can update own workflows" ON workflows;
DROP POLICY IF EXISTS "Users can delete own workflows" ON workflows;

-- 创建策略
CREATE POLICY "Users can view own workflows"
  ON workflows FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create workflows"
  ON workflows FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workflows"
  ON workflows FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own workflows"
  ON workflows FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_workflows_user_id ON workflows(user_id);
CREATE INDEX IF NOT EXISTS idx_workflows_created_at ON workflows(created_at DESC);

COMMENT ON TABLE workflows IS '可视化工作流定义';

-- ============================================
-- 3. 创建 scenarios 表（场景管理）
-- ============================================
CREATE TABLE IF NOT EXISTS scenarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  workflow_id uuid REFERENCES workflows(id) ON DELETE SET NULL,
  parameters jsonb DEFAULT '{}',
  sop_content text DEFAULT '',
  flowchart_data jsonb DEFAULT '{}',
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 启用 RLS
ALTER TABLE scenarios ENABLE ROW LEVEL SECURITY;

-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "Users can view own scenarios" ON scenarios;
DROP POLICY IF EXISTS "Users can create scenarios" ON scenarios;
DROP POLICY IF EXISTS "Users can update own scenarios" ON scenarios;
DROP POLICY IF EXISTS "Users can delete own scenarios" ON scenarios;

-- 创建策略
CREATE POLICY "Users can view own scenarios"
  ON scenarios FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create scenarios"
  ON scenarios FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own scenarios"
  ON scenarios FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own scenarios"
  ON scenarios FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_scenarios_user_id ON scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_scenarios_workflow_id ON scenarios(workflow_id);
CREATE INDEX IF NOT EXISTS idx_scenarios_created_at ON scenarios(created_at DESC);

COMMENT ON TABLE scenarios IS '运维场景管理（含SOP和流程图）';

-- ============================================
-- 4. 创建 execution_logs 表（执行日志）
-- ============================================
CREATE TABLE IF NOT EXISTS execution_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id uuid REFERENCES scenarios(id) ON DELETE CASCADE,
  workflow_id uuid REFERENCES workflows(id) ON DELETE CASCADE,
  parameters jsonb DEFAULT '{}',
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- 启用 RLS
ALTER TABLE execution_logs ENABLE ROW LEVEL SECURITY;

-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "Users can view own execution logs" ON execution_logs;
DROP POLICY IF EXISTS "Users can create execution logs" ON execution_logs;

-- 创建策略
CREATE POLICY "Users can view own execution logs"
  ON execution_logs FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create execution logs"
  ON execution_logs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_execution_logs_user_id ON execution_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_scenario_id ON execution_logs(scenario_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_workflow_id ON execution_logs(workflow_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_status ON execution_logs(status);
CREATE INDEX IF NOT EXISTS idx_execution_logs_created_at ON execution_logs(created_at DESC);

COMMENT ON TABLE execution_logs IS '工作流执行日志记录';

-- ============================================
-- 5. 创建 Storage 存储桶
-- ============================================

-- 创建 sop-images 存储桶（如果不存在）
INSERT INTO storage.buckets (id, name, public)
VALUES ('sop-images', 'sop-images', true)
ON CONFLICT (id) DO NOTHING;

-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "Anyone can view SOP images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload SOP images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own SOP images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own SOP images" ON storage.objects;

-- 创建存储策略
CREATE POLICY "Anyone can view SOP images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'sop-images');

CREATE POLICY "Authenticated users can upload SOP images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'sop-images');

CREATE POLICY "Users can update own SOP images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'sop-images' AND auth.uid()::text = owner);

CREATE POLICY "Users can delete own SOP images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'sop-images' AND auth.uid()::text = owner);

-- ============================================
-- 6. 创建视图（可选 - 便于查询）
-- ============================================

-- 场景详情视图（包含关联的工作流信息）
CREATE OR REPLACE VIEW scenario_details AS
SELECT
  s.id,
  s.name,
  s.description,
  s.sop_content,
  s.flowchart_data,
  s.parameters,
  s.user_id,
  s.created_at,
  s.updated_at,
  w.id as workflow_id,
  w.name as workflow_name,
  w.definition as workflow_definition
FROM scenarios s
LEFT JOIN workflows w ON s.workflow_id = w.id;

COMMENT ON VIEW scenario_details IS '场景详情视图（含工作流信息）';

-- 执行统计视图
CREATE OR REPLACE VIEW execution_stats AS
SELECT
  user_id,
  COUNT(*) as total_executions,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
  COUNT(*) FILTER (WHERE status = 'failed') as failed_count,
  COUNT(*) FILTER (WHERE status = 'running') as running_count,
  COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
  AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_duration_seconds
FROM execution_logs
GROUP BY user_id;

COMMENT ON VIEW execution_stats IS '用户执行统计视图';

-- ============================================
-- 7. 创建函数（可选 - 便捷操作）
-- ============================================

-- 更新 updated_at 时间戳的函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为需要的表添加触发器
DROP TRIGGER IF EXISTS update_modules_updated_at ON modules;
CREATE TRIGGER update_modules_updated_at
BEFORE UPDATE ON modules
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_workflows_updated_at ON workflows;
CREATE TRIGGER update_workflows_updated_at
BEFORE UPDATE ON workflows
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_scenarios_updated_at ON scenarios;
CREATE TRIGGER update_scenarios_updated_at
BEFORE UPDATE ON scenarios
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. 验证脚本（打印结果）
-- ============================================

DO $$
DECLARE
  table_count integer;
  policy_count integer;
  bucket_count integer;
BEGIN
  -- 统计表数量
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('modules', 'workflows', 'scenarios', 'execution_logs');

  -- 统计策略数量
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public';

  -- 统计存储桶
  SELECT COUNT(*) INTO bucket_count
  FROM storage.buckets
  WHERE name = 'sop-images';

  -- 输出结果
  RAISE NOTICE '====================================';
  RAISE NOTICE '数据库初始化完成！';
  RAISE NOTICE '====================================';
  RAISE NOTICE '创建的表: % 个', table_count;
  RAISE NOTICE '创建的策略: % 个', policy_count;
  RAISE NOTICE '创建的存储桶: % 个', bucket_count;
  RAISE NOTICE '====================================';

  IF table_count < 4 THEN
    RAISE WARNING '警告：表数量不足，请检查脚本执行结果';
  END IF;
END $$;

-- ============================================
-- 9. 显示表结构（用于验证）
-- ============================================

SELECT
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count,
  (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.table_name) as policy_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
  AND table_name IN ('modules', 'workflows', 'scenarios', 'execution_logs')
ORDER BY table_name;
