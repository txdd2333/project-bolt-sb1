/*
  # 测试数据生成脚本

  ## 用途
  为新部署的系统创建示例数据，方便测试和演示。

  ## 使用方法
  1. 先注册一个用户并登录
  2. 在 Supabase SQL Editor 中运行本脚本
  3. 刷新前端页面查看测试数据

  ## 包含内容
  - 5 个示例模块
  - 3 个示例工作流
  - 2 个示例场景

  ## 注意
  - 需要先有至少一个已注册用户
  - 脚本会自动获取第一个用户的 ID
  - 可重复运行（每次都会创建新数据）
*/

-- ============================================
-- 1. 创建测试模块
-- ============================================

DO $$
DECLARE
  test_user_id uuid;
BEGIN
  -- 获取第一个用户的 ID
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  IF test_user_id IS NULL THEN
    RAISE EXCEPTION '错误：没有找到用户。请先注册一个用户！';
  END IF;

  RAISE NOTICE '使用用户 ID: %', test_user_id;

  -- 模块1: 打开百度
  INSERT INTO modules (name, description, type, config, icon, color, user_id)
  VALUES (
    '打开百度首页',
    '自动打开百度首页并等待加载完成',
    'playwright',
    jsonb_build_object(
      'action', 'navigate',
      'url', 'https://www.baidu.com',
      'browserType', 'chromium'
    ),
    '🌐',
    '#3b82f6',
    test_user_id
  );

  -- 模块2: 打开GitHub
  INSERT INTO modules (name, description, type, config, icon, color, user_id)
  VALUES (
    '打开GitHub',
    '访问GitHub主页',
    'playwright',
    jsonb_build_object(
      'action', 'navigate',
      'url', 'https://github.com',
      'browserType', 'chromium'
    ),
    '🐙',
    '#6366f1',
    test_user_id
  );

  -- 模块3: 页面截图
  INSERT INTO modules (name, description, type, config, icon, color, user_id)
  VALUES (
    '页面截图',
    '对当前页面进行全屏截图',
    'playwright',
    jsonb_build_object(
      'action', 'screenshot',
      'browserType', 'chromium'
    ),
    '📸',
    '#8b5cf6',
    test_user_id
  );

  -- 模块4: 等待3秒
  INSERT INTO modules (name, description, type, config, icon, color, user_id)
  VALUES (
    '等待3秒',
    '暂停执行3秒钟',
    'playwright',
    jsonb_build_object(
      'action', 'wait',
      'milliseconds', 3000,
      'browserType', 'chromium'
    ),
    '⏱️',
    '#f59e0b',
    test_user_id
  );

  -- 模块5: 点击百度搜索按钮
  INSERT INTO modules (name, description, type, config, icon, color, user_id)
  VALUES (
    '点击百度搜索',
    '点击百度搜索按钮',
    'playwright',
    jsonb_build_object(
      'action', 'click',
      'selector', '#su',
      'browserType', 'chromium'
    ),
    '🖱️',
    '#10b981',
    test_user_id
  );

  RAISE NOTICE '✓ 已创建 5 个测试模块';
END $$;

-- ============================================
-- 2. 创建测试工作流
-- ============================================

DO $$
DECLARE
  test_user_id uuid;
BEGIN
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  -- 工作流1: 简单访问百度
  INSERT INTO workflows (name, description, definition, user_id)
  VALUES (
    '访问百度首页',
    '打开百度并截图',
    jsonb_build_object(
      'nodes', jsonb_build_array(
        jsonb_build_object(
          'id', 'start-1',
          'type', 'start',
          'properties', '{}'::jsonb
        ),
        jsonb_build_object(
          'id', 'nav-1',
          'type', 'playwright',
          'properties', jsonb_build_object(
            'action', 'navigate',
            'url', 'https://www.baidu.com',
            'browserType', 'chromium'
          )
        ),
        jsonb_build_object(
          'id', 'screenshot-1',
          'type', 'playwright',
          'properties', jsonb_build_object(
            'action', 'screenshot',
            'browserType', 'chromium'
          )
        ),
        jsonb_build_object(
          'id', 'end-1',
          'type', 'end',
          'properties', '{}'::jsonb
        )
      ),
      'edges', jsonb_build_array(
        jsonb_build_object('id', 'e1', 'sourceNodeId', 'start-1', 'targetNodeId', 'nav-1'),
        jsonb_build_object('id', 'e2', 'sourceNodeId', 'nav-1', 'targetNodeId', 'screenshot-1'),
        jsonb_build_object('id', 'e3', 'sourceNodeId', 'screenshot-1', 'targetNodeId', 'end-1')
      )
    ),
    test_user_id
  );

  -- 工作流2: 访问GitHub
  INSERT INTO workflows (name, description, definition, user_id)
  VALUES (
    '访问GitHub',
    '打开GitHub主页',
    jsonb_build_object(
      'nodes', jsonb_build_array(
        jsonb_build_object(
          'id', 'start-1',
          'type', 'start',
          'properties', '{}'::jsonb
        ),
        jsonb_build_object(
          'id', 'nav-1',
          'type', 'playwright',
          'properties', jsonb_build_object(
            'action', 'navigate',
            'url', 'https://github.com',
            'browserType', 'chromium'
          )
        ),
        jsonb_build_object(
          'id', 'wait-1',
          'type', 'playwright',
          'properties', jsonb_build_object(
            'action', 'wait',
            'milliseconds', 2000,
            'browserType', 'chromium'
          )
        ),
        jsonb_build_object(
          'id', 'end-1',
          'type', 'end',
          'properties', '{}'::jsonb
        )
      ),
      'edges', jsonb_build_array(
        jsonb_build_object('id', 'e1', 'sourceNodeId', 'start-1', 'targetNodeId', 'nav-1'),
        jsonb_build_object('id', 'e2', 'sourceNodeId', 'nav-1', 'targetNodeId', 'wait-1'),
        jsonb_build_object('id', 'e3', 'sourceNodeId', 'wait-1', 'targetNodeId', 'end-1')
      )
    ),
    test_user_id
  );

  -- 工作流3: 多标签页演示
  INSERT INTO workflows (name, description, definition, user_id)
  VALUES (
    '打开多个标签页',
    '演示多标签页操作',
    jsonb_build_object(
      'nodes', jsonb_build_array(
        jsonb_build_object(
          'id', 'start-1',
          'type', 'start',
          'properties', '{}'::jsonb
        ),
        jsonb_build_object(
          'id', 'open-tabs-1',
          'type', 'playwright',
          'properties', jsonb_build_object(
            'action', 'open_tabs',
            'count', 3,
            'urls', 'https://www.baidu.com,https://www.github.com,https://www.google.com',
            'browserType', 'chromium'
          )
        ),
        jsonb_build_object(
          'id', 'end-1',
          'type', 'end',
          'properties', '{}'::jsonb
        )
      ),
      'edges', jsonb_build_array(
        jsonb_build_object('id', 'e1', 'sourceNodeId', 'start-1', 'targetNodeId', 'open-tabs-1'),
        jsonb_build_object('id', 'e2', 'sourceNodeId', 'open-tabs-1', 'targetNodeId', 'end-1')
      )
    ),
    test_user_id
  );

  RAISE NOTICE '✓ 已创建 3 个测试工作流';
END $$;

-- ============================================
-- 3. 创建测试场景
-- ============================================

DO $$
DECLARE
  test_user_id uuid;
  workflow_id_1 uuid;
  workflow_id_2 uuid;
BEGIN
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  -- 获取刚创建的工作流ID
  SELECT id INTO workflow_id_1 FROM workflows WHERE name = '访问百度首页' AND user_id = test_user_id ORDER BY created_at DESC LIMIT 1;
  SELECT id INTO workflow_id_2 FROM workflows WHERE name = '访问GitHub' AND user_id = test_user_id ORDER BY created_at DESC LIMIT 1;

  -- 场景1: 日常巡检
  INSERT INTO scenarios (name, description, workflow_id, sop_content, flowchart_data, user_id)
  VALUES (
    '网站可用性巡检',
    '定期检查关键网站是否可访问',
    workflow_id_1,
    E'# 网站可用性巡检 SOP\n\n## 目的\n定期检查关键业务网站的可用性，及时发现并处理故障。\n\n## 巡检频率\n每小时一次\n\n## 检查项目\n1. 百度首页是否可访问\n2. 页面加载时间是否正常\n3. 关键元素是否正常显示\n\n## 处理流程\n- 如果网站无法访问，立即通知运维团队\n- 记录故障时间和现象\n- 进行故障分析和排查\n\n## 注意事项\n- 确保网络连接正常\n- 记录每次巡检结果\n- 异常情况及时上报',
    jsonb_build_object(
      'nodes', jsonb_build_array(),
      'edges', jsonb_build_array()
    ),
    test_user_id
  );

  -- 场景2: 自动化部署
  INSERT INTO scenarios (name, description, workflow_id, sop_content, flowchart_data, user_id)
  VALUES (
    'GitHub代码检查',
    '自动访问GitHub检查代码更新',
    workflow_id_2,
    E'# GitHub代码检查 SOP\n\n## 目的\n自动化检查GitHub仓库的代码更新情况。\n\n## 执行时机\n- 每天上午9点\n- 收到代码提交通知时\n\n## 检查内容\n1. 访问项目主页\n2. 查看最新提交记录\n3. 检查CI/CD状态\n\n## 后续操作\n- 如有新提交，触发测试流程\n- 通知相关开发人员\n- 更新项目看板',
    jsonb_build_object(
      'nodes', jsonb_build_array(),
      'edges', jsonb_build_array()
    ),
    test_user_id
  );

  RAISE NOTICE '✓ 已创建 2 个测试场景';
END $$;

-- ============================================
-- 4. 验证创建结果
-- ============================================

DO $$
DECLARE
  module_count integer;
  workflow_count integer;
  scenario_count integer;
  test_user_id uuid;
BEGIN
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  SELECT COUNT(*) INTO module_count FROM modules WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO workflow_count FROM workflows WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO scenario_count FROM scenarios WHERE user_id = test_user_id;

  RAISE NOTICE '====================================';
  RAISE NOTICE '测试数据创建完成！';
  RAISE NOTICE '====================================';
  RAISE NOTICE '模块数量: %', module_count;
  RAISE NOTICE '工作流数量: %', workflow_count;
  RAISE NOTICE '场景数量: %', scenario_count;
  RAISE NOTICE '====================================';
  RAISE NOTICE '提示：刷新前端页面查看测试数据';
END $$;

-- ============================================
-- 5. 显示创建的数据摘要
-- ============================================

-- 查看模块列表
SELECT
  name,
  type,
  icon,
  config->>'action' as action,
  created_at
FROM modules
ORDER BY created_at DESC
LIMIT 10;

-- 查看工作流列表
SELECT
  name,
  description,
  jsonb_array_length(definition->'nodes') as node_count,
  created_at
FROM workflows
ORDER BY created_at DESC
LIMIT 10;

-- 查看场景列表
SELECT
  name,
  description,
  (SELECT w.name FROM workflows w WHERE w.id = scenarios.workflow_id) as workflow_name,
  created_at
FROM scenarios
ORDER BY created_at DESC
LIMIT 10;
