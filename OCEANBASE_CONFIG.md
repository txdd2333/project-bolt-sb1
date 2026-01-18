# OceanBase MySQL 模式配置指南

## 🎯 快速配置

### OceanBase 连接特点

OceanBase MySQL 模式的连接方式与标准 MySQL 不同，用户名格式为：

```
用户名@租户名#集群名
```

### 连接命令示例

```bash
mysql -h数据库地址 -P端口 -u用户名@租户名#集群名 -p密码

# 实际例子：
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__
```

**参数说明**：
- `-h` 数据库地址（OBProxy 地址）
- `-P` 端口（OceanBase 默认 2883）
- `-u` 用户名格式：`用户名@租户名#集群名`
- `-p` 密码

---

## 📝 .env 配置

### 完整配置示例

```bash
# 服务提供商（必须设置为 custom）
VITE_SERVICE_PROVIDER=custom

# API 服务器地址
VITE_API_URL=http://localhost:3000

# ========== OceanBase MySQL 模式配置 ==========
DB_HOST=192.168.1.70                    # OBProxy 地址
DB_PORT=2883                             # OBProxy 端口（默认 2883）
DB_USER=root@Tianji4_MySQL#Tianji4      # 用户名@租户名#集群名
DB_PASSWORD=aaAA11__                    # 密码
DB_DATABASE=ops_workflow_center         # 数据库名称

# JWT 密钥（请修改为随机字符串）
JWT_SECRET=change-this-to-a-random-secret-key-in-production

# 文件上传目录
UPLOAD_DIR=./uploads
```

### 关键配置解析

| 配置项 | 值 | 说明 |
|--------|------|------|
| `DB_HOST` | `192.168.1.70` | OBProxy 服务器地址 |
| `DB_PORT` | `2883` | OceanBase 默认端口 |
| `DB_USER` | `root@Tianji4_MySQL#Tianji4` | **完整格式**：用户名@租户名#集群名 |
| `DB_PASSWORD` | `aaAA11__` | 数据库密码 |
| `DB_DATABASE` | `ops_workflow_center` | 数据库名称 |

---

## ✅ 测试连接

### 方法 1: 使用 MySQL 客户端

```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__
```

成功连接后应该看到：
```
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 1574038
Server version: 5.6.25 OceanBase 4.2.1.10
```

### 方法 2: 验证数据库

```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "USE ops_workflow_center; SHOW TABLES;"
```

应该返回：
```
+-------------------------------+
| Tables_in_ops_workflow_center |
+-------------------------------+
| execution_logs                |
| modules                       |
| scenarios                     |
| users                         |
| workflows                     |
+-------------------------------+
```

### 方法 3: 测试查询

```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "USE ops_workflow_center; SELECT COUNT(*) FROM users;"
```

---

## 🔍 常见问题

### Q1: 用户名中的 @ 和 # 符号会不会有问题？

**A**: 不会。MySQL2 驱动完全支持这种格式，只需将完整的用户名作为 `DB_USER` 的值即可。

```bash
# 正确
DB_USER=root@Tianji4_MySQL#Tianji4

# 错误（不要拆分）
DB_USER=root
DB_TENANT=Tianji4_MySQL
DB_CLUSTER=Tianji4
```

### Q2: 标准 MySQL 和 OceanBase 的区别？

| 项目 | 标准 MySQL | OceanBase MySQL 模式 |
|------|------------|---------------------|
| 默认端口 | 3306 | 2883 |
| 用户名格式 | `root` | `root@租户名#集群名` |
| 连接方式 | 直连数据库 | 通过 OBProxy |
| 字符集 | utf8mb4 | utf8mb4（兼容） |

### Q3: 如何获取租户名和集群名？

**方法 1**: 询问 DBA

**方法 2**: 从已有连接命令中提取
```bash
# 如果你的连接命令是：
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -p

# 那么：
# 租户名：Tianji4_MySQL
# 集群名：Tianji4
```

**方法 3**: 登录后查询
```sql
-- 查看当前租户
SHOW VARIABLES LIKE 'ob_tenant_name';

-- 查看集群名
SHOW PARAMETERS LIKE 'cluster';
```

### Q4: 连接失败怎么办？

**错误 1: Access denied**
```
ERROR 1045 (28000): Access denied for user 'root@Tianji4_MySQL#Tianji4'
```
**原因**: 用户名或密码错误
**解决**: 检查 DB_USER 和 DB_PASSWORD 配置

**错误 2: Unknown database**
```
ERROR 1049 (42000): Unknown database 'ops_workflow_center'
```
**原因**: 数据库不存在
**解决**: 执行初始化脚本 `source scripts/init-mysql-database.sql`

**错误 3: Connection refused**
```
ERROR 2003 (HY000): Can't connect to MySQL server on '192.168.1.70'
```
**原因**: 网络不通或 OBProxy 未运行
**解决**:
```bash
ping 192.168.1.70
telnet 192.168.1.70 2883
```

---

## 🚀 完整部署流程

### 1. 初始化数据库

```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ < scripts/init-mysql-database.sql
```

### 2. 配置 .env

```bash
cp .env.example .env
vi .env
```

填入您的 OceanBase 配置：
```bash
DB_HOST=192.168.1.70
DB_PORT=2883
DB_USER=root@Tianji4_MySQL#Tianji4
DB_PASSWORD=aaAA11__
DB_DATABASE=ops_workflow_center
```

### 3. 测试连接

```bash
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e "USE ops_workflow_center; SELECT COUNT(*) FROM users;"
```

### 4. 部署应用

```bash
sudo bash docker-deploy.sh
```

### 5. 验证部署

```bash
# 检查容器
sudo docker-compose ps

# 查看日志
sudo docker-compose logs | grep -i "DB_HOST"

# 应该看到：
# - DB_HOST: 192.168.1.70
# - DB_PORT: 2883
# - DB_DATABASE: ops_workflow_center
```

### 6. 访问应用

- 前端: `http://服务器IP:5173`
- 后端: `http://服务器IP:3000`

---

## 📊 技术细节

### MySQL2 驱动支持

Node.js 的 `mysql2` 驱动完全支持 OceanBase 的用户名格式：

```javascript
const pool = mysql.createPool({
  host: '192.168.1.70',
  port: 2883,
  user: 'root@Tianji4_MySQL#Tianji4',  // 完整的用户名字符串
  password: 'aaAA11__',
  database: 'ops_workflow_center',
});
```

### 字符串转义

不需要转义 `@` 和 `#` 符号，直接使用即可：

```bash
# .env 文件中不需要引号
DB_USER=root@Tianji4_MySQL#Tianji4

# 也可以加引号（可选）
DB_USER="root@Tianji4_MySQL#Tianji4"
```

### 环境变量传递

Docker Compose 会正确传递包含特殊字符的环境变量：

```yaml
environment:
  - DB_USER=${DB_USER}  # 自动读取 .env 中的值
```

---

## 🔐 安全建议

### 1. 创建专用用户（推荐）

不要使用 root 用户，创建专用应用用户：

```sql
-- 在 OceanBase 中创建用户
CREATE USER 'ops_app'@'%' IDENTIFIED BY '强密码';

-- 授予权限
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_workflow_center.* TO 'ops_app'@'%';
FLUSH PRIVILEGES;
```

然后更新 .env：
```bash
DB_USER=ops_app@Tianji4_MySQL#Tianji4
DB_PASSWORD=强密码
```

### 2. 限制访问IP

在 OBProxy 或防火墙层面限制只允许应用服务器访问。

### 3. 使用强密码

修改默认密码为强密码，包含大小写字母、数字和特殊字符。

---

## 📚 相关文档

- [MySQL 部署操作手册](MySQL部署操作手册.md) - 完整部署指南
- [MYSQL_DEPLOYMENT.md](MYSQL_DEPLOYMENT.md) - 技术文档
- [START_HERE_MYSQL.md](START_HERE_MYSQL.md) - 快速开始

---

## 📞 获取帮助

### 检查日志

```bash
# 应用日志
sudo docker-compose logs -f

# 数据库连接日志
sudo docker-compose logs | grep -i "database\|mysql\|connection"
```

### 验证配置

```bash
# 查看环境变量
cat .env

# 在容器内查看
sudo docker exec -it ops-workflow-center env | grep DB_
```

### 测试连接

```bash
# 从宿主机测试
mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -p

# 从容器内测试
sudo docker exec -it ops-workflow-center sh -c "mysql -h192.168.1.70 -P2883 -uroot@Tianji4_MySQL#Tianji4 -paaAA11__ -e 'SELECT 1'"
```

---

**更新时间**: 2024-01-18

**适用版本**: OceanBase 4.x MySQL 模式
