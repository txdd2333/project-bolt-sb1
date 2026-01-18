# Docker 快速部署（5分钟上线）

## 🚀 一键部署命令

```bash
# 1. 上传项目到服务器并解压到 /opt/ops-workflow-center
# 2. 执行以下命令：

cd /opt/ops-workflow-center
sudo bash docker-deploy.sh
```

就这么简单！脚本会自动完成所有配置。

---

## 📋 部署前检查清单

在运行部署脚本前，确保：

- [ ] 项目文件已上传到服务器
- [ ] `.env` 文件包含 Supabase 配置
- [ ] CentOS 7 系统（其他 Linux 发行版也支持）
- [ ] 有 sudo 权限

---

## 🔧 手动安装（如果一键脚本失败）

### 安装 Docker

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
```

### 安装 Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
```

### 启动项目

```bash
cd /opt/ops-workflow-center
sudo docker-compose build
sudo docker-compose up -d
```

---

## 🎯 访问地址

部署成功后：

- **前端**: `http://服务器IP:5173`
- **后端 API**: `http://服务器IP:3000`

---

## 📊 常用命令速查表

| 功能 | 命令 |
|------|------|
| 查看日志 | `sudo docker-compose logs -f` |
| 停止服务 | `sudo docker-compose down` |
| 启动服务 | `sudo docker-compose up -d` |
| 重启服务 | `sudo docker-compose restart` |
| 查看状态 | `sudo docker-compose ps` |
| 进入容器 | `sudo docker exec -it ops-workflow-center bash` |
| 查看应用日志 | `tail -f logs/api-out.log` |

---

## 🔥 防火墙配置

```bash
# 开放端口
sudo firewall-cmd --permanent --add-port=5173/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

云服务器还需在控制台安全组中开放这些端口。

---

## ⚠️ 故障排查

### 容器无法启动

```bash
# 查看详细错误
sudo docker-compose logs

# 检查端口占用
sudo netstat -tulpn | grep 5173
sudo netstat -tulpn | grep 3000
```

### 无法访问服务

```bash
# 检查容器是否运行
sudo docker ps

# 检查防火墙
sudo firewall-cmd --list-all

# 在容器内测试
sudo docker exec -it ops-workflow-center curl http://localhost:5173
```

### 重新构建

```bash
# 完全清理并重建
sudo docker-compose down
sudo docker-compose build --no-cache
sudo docker-compose up -d
```

---

## 🔄 更新部署

```bash
# 1. 上传新代码
# 2. 执行更新

cd /opt/ops-workflow-center
sudo docker-compose down
sudo docker-compose build
sudo docker-compose up -d
```

---

## 📦 备份数据

```bash
# 备份数据目录和配置
tar -czf backup-$(date +%Y%m%d).tar.gz logs uploads .env

# 备份 Docker 镜像
sudo docker save ops-workflow-center_app > ops-image.tar
```

---

## 💡 优势说明

使用 Docker 部署的好处：

✅ **环境隔离** - 不影响系统其他服务
✅ **一键启停** - 简单的命令管理服务
✅ **易于迁移** - 可快速迁移到任何服务器
✅ **版本管理** - 可同时运行多个版本
✅ **资源控制** - 可限制 CPU 和内存使用
✅ **快速回滚** - 出问题立即回到上个版本

---

## 📞 需要帮助？

详细文档请查看: `DOCKER_DEPLOYMENT.md`

常见问题：

1. **端口冲突**: 修改 `docker-compose.yml` 中的端口映射
2. **内存不足**: 至少需要 2GB 可用内存
3. **磁盘空间**: 镜像大约需要 1-2GB 空间
4. **网络问题**: 确保服务器可访问 Docker Hub

---

**部署时间**: 首次构建 5-10 分钟，后续启动 10 秒内

**系统要求**: CentOS 7+, 2GB+ RAM, 5GB+ 磁盘空间
