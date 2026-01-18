/*
  # 为 execution_logs 表添加 scenario_id 字段

  1. 修改内容
    - 添加 scenario_id 字段（可选，因为有些执行可能直接来自工作流）
    - 添加外键约束到 scenarios 表
    - 添加索引提升查询性能

  2. 数据完整性
    - scenario_id 可以为 NULL（直接执行工作流的情况）
    - 级联删除设置为 SET NULL（删除场景时保留执行记录）
*/

-- 添加 scenario_id 字段
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'execution_logs' AND column_name = 'scenario_id'
  ) THEN
    ALTER TABLE execution_logs 
      ADD COLUMN scenario_id uuid REFERENCES scenarios(id) ON DELETE SET NULL;
  END IF;
END $$;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_execution_logs_scenario_id ON execution_logs(scenario_id);