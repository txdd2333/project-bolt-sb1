/*
  运维工作流中心 - MySQL 兼容 Schema

  本文件包含完全兼容 MySQL 8.0+ 的数据库架构定义
  可用于迁移到 OceanBase 或其他 MySQL 兼容数据库

  核心改动：
  1. uuid → CHAR(36)
  2. jsonb → JSON
  3. timestamptz → DATETIME
  4. gen_random_uuid() → 应用层生成 UUID
  5. now() → CURRENT_TIMESTAMP
  6. RLS → 应用层权限控制
*/

-- 1. modules 表 (模块表)
CREATE TABLE IF NOT EXISTS modules (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT DEFAULT '',
  type VARCHAR(100) NOT NULL,
  config JSON DEFAULT NULL,
  icon VARCHAR(50) DEFAULT 'Box',
  color VARCHAR(20) DEFAULT '#3b82f6',
  user_id CHAR(36) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_modules_user_id (user_id),
  INDEX idx_modules_type (type),
  INDEX idx_modules_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. workflows 表 (工作流表)
CREATE TABLE IF NOT EXISTS workflows (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT DEFAULT '',
  trigger_type VARCHAR(50) DEFAULT 'manual',
  definition TEXT DEFAULT NULL,
  user_id CHAR(36) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_workflows_user_id (user_id),
  INDEX idx_workflows_trigger_type (trigger_type),
  INDEX idx_workflows_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. workflow_nodes 表 (工作流节点表)
CREATE TABLE IF NOT EXISTS workflow_nodes (
  id CHAR(36) PRIMARY KEY,
  workflow_id CHAR(36) NOT NULL,
  module_id CHAR(36) NOT NULL,
  node_id VARCHAR(100) NOT NULL,
  position JSON DEFAULT NULL,
  data JSON DEFAULT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE,
  FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE,

  INDEX idx_workflow_nodes_workflow_id (workflow_id),
  INDEX idx_workflow_nodes_module_id (module_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. workflow_edges 表 (工作流连接表)
CREATE TABLE IF NOT EXISTS workflow_edges (
  id CHAR(36) PRIMARY KEY,
  workflow_id CHAR(36) NOT NULL,
  edge_id VARCHAR(100) NOT NULL,
  source_node_id VARCHAR(100) NOT NULL,
  target_node_id VARCHAR(100) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE,

  INDEX idx_workflow_edges_workflow_id (workflow_id),
  INDEX idx_workflow_edges_source (source_node_id),
  INDEX idx_workflow_edges_target (target_node_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. scenarios 表 (应急场景表)
CREATE TABLE IF NOT EXISTS scenarios (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT DEFAULT '',
  category VARCHAR(100) DEFAULT '',
  sop_content TEXT DEFAULT NULL,
  flowchart_definition TEXT DEFAULT NULL,
  flowchart_data TEXT DEFAULT NULL,
  workflow_id CHAR(36) DEFAULT NULL,
  workflow_ids JSON DEFAULT NULL,
  parameters JSON DEFAULT NULL,
  user_id CHAR(36) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE SET NULL,

  INDEX idx_scenarios_user_id (user_id),
  INDEX idx_scenarios_workflow_id (workflow_id),
  INDEX idx_scenarios_category (category),
  INDEX idx_scenarios_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. execution_logs 表 (执行日志表)
CREATE TABLE IF NOT EXISTS execution_logs (
  id CHAR(36) PRIMARY KEY,
  scenario_id CHAR(36) DEFAULT NULL,
  workflow_id CHAR(36) DEFAULT NULL,
  parameters JSON DEFAULT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  started_at DATETIME DEFAULT NULL,
  completed_at DATETIME DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  logs TEXT DEFAULT NULL,
  user_id CHAR(36) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (scenario_id) REFERENCES scenarios(id) ON DELETE SET NULL,
  FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE SET NULL,

  INDEX idx_execution_logs_scenario_id (scenario_id),
  INDEX idx_execution_logs_workflow_id (workflow_id),
  INDEX idx_execution_logs_user_id (user_id),
  INDEX idx_execution_logs_status (status),
  INDEX idx_execution_logs_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. users 表 (用户表 - 替代 Supabase Auth)
CREATE TABLE IF NOT EXISTS users (
  id CHAR(36) PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_login DATETIME DEFAULT NULL,

  INDEX idx_users_email (email),
  INDEX idx_users_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. sessions 表 (会话表 - 替代 Supabase Auth)
CREATE TABLE IF NOT EXISTS sessions (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  access_token VARCHAR(500) NOT NULL,
  refresh_token VARCHAR(500) DEFAULT NULL,
  expires_at DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

  INDEX idx_sessions_user_id (user_id),
  INDEX idx_sessions_access_token (access_token(255)),
  INDEX idx_sessions_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入示例数据（可选）
INSERT INTO modules (id, name, description, type, config, icon, color, user_id) VALUES
  (UUID(), '打开URL', '在新标签页中打开指定URL', 'open_url', '{"url": ""}', 'ExternalLink', '#3b82f6', 'system'),
  (UUID(), '等待页面加载', '等待页面完全加载', 'wait', '{"seconds": 2}', 'Clock', '#10b981', 'system'),
  (UUID(), '点击元素', '点击页面上的指定元素', 'click_element', '{"selector": ""}', 'MousePointer', '#f59e0b', 'system'),
  (UUID(), '填写表单', '填写表单字段', 'fill_form', '{"selector": "", "value": ""}', 'Edit', '#8b5cf6', 'system'),
  (UUID(), '执行命令', '在终端执行命令', 'execute_command', '{"command": ""}', 'Terminal', '#ef4444', 'system')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 注意事项：
-- 1. UUID 生成需要在应用层实现（JavaScript: crypto.randomUUID()）
-- 2. 用户权限控制需要在应用层实现
-- 3. 密码哈希使用 bcrypt 或 argon2
-- 4. JWT 令牌生成和验证在后端服务实现
-- 5. 所有查询都应该添加 WHERE user_id = ? 条件
