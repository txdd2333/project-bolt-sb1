# 使用 Node.js 18 官方镜像
FROM node:18-bullseye

# 设置工作目录
WORKDIR /app

# 安装 Playwright 浏览器依赖（Chromium）
RUN apt-get update && apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 复制 package 文件
COPY package*.json ./

# 安装依赖
RUN npm ci --production=false

# 安装 Playwright 浏览器
RUN npx playwright install chromium

# 复制项目文件
COPY . .

# 构建前端
RUN npm run build

# 构建后端
RUN npm run server:build

# 暴露端口
EXPOSE 5173 3000

# 启动命令（使用 PM2）
RUN npm install -g pm2

CMD ["pm2-runtime", "start", "ecosystem.config.cjs"]
