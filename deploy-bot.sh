#!/bin/bash

# ==========================================
# 微信机器人部署脚本
# 用途：将Wechaty机器人部署到云服务器
# ==========================================

# 配置部分 - 请根据实际情况修改
SERVER_HOST="112.126.85.78"           # 云服务器IP地址
SERVER_USER="root"                     # SSH用户名
SERVER_PATH="/opt/wechaty-bot"         # 服务器上的部署路径
SERVER_PORT="22"                       # SSH端口

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 错误处理
set -e
trap 'log_error "脚本执行失败！"; exit 1' ERR

# 检查配置
if [ "$SERVER_HOST" = "your-server-ip" ]; then
    log_error "请先配置SERVER_HOST、SERVER_USER和SERVER_PATH变量！"
    log_info "编辑 $0 文件，修改顶部的配置项"
    exit 1
fi

# 检查.env文件
if [ ! -f ".env" ]; then
    log_error "未找到.env文件！"
    log_info "请先创建.env文件并配置KIMI_API_KEY"
    log_info "可以复制.env.example: cp .env.example .env"
    exit 1
fi

# 检查KIMI_API_KEY是否配置
if ! grep -q "KIMI_API_KEY=sk-" .env; then
    log_error ".env文件中未配置有效的KIMI_API_KEY！"
    log_info "请在.env文件中配置: KIMI_API_KEY=sk-xxxxxxxx"
    exit 1
fi

log_info "========================================"
log_info "开始部署微信机器人到云服务器"
log_info "========================================"

# 1. 清理旧的打包文件
log_info "清理旧的打包文件..."
rm -f wechaty-bot.tar.gz

# 2. 打包项目文件
log_info "打包项目文件..."
tar -czf wechaty-bot.tar.gz \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='.wechaty' \
    --exclude='wechaty-bot.tar.gz' \
    bot.js package.json package-lock.json .env README.md 快速开始.md

log_info "打包完成: wechaty-bot.tar.gz"

# 3. 上传到服务器
log_info "上传到服务器 ${SERVER_HOST}..."
scp -P ${SERVER_PORT} wechaty-bot.tar.gz ${SERVER_USER}@${SERVER_HOST}:/tmp/

# 3.1 上传监控脚本
log_info "上传监控脚本到服务器..."
if [ -f "monitor-bot.sh" ]; then
    scp -P ${SERVER_PORT} monitor-bot.sh ${SERVER_USER}@${SERVER_HOST}:/tmp/
fi

# 4. 在服务器上部署
log_info "在服务器上部署..."
ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    set -e
    
    echo "停止现有服务..."
    # 尝试停止现有的机器人进程
    pkill -f "node.*bot.js" || true
    sleep 2
    
    echo "创建部署目录..."
    mkdir -p /opt/wechaty-bot
    
    echo "备份旧版本..."
    if [ -d "/opt/wechaty-bot/backup" ]; then
        rm -rf /opt/wechaty-bot/backup
    fi
    if [ -d "/opt/wechaty-bot/current" ]; then
        mv /opt/wechaty-bot/current /opt/wechaty-bot/backup
    fi
    
    echo "解压新版本..."
    mkdir -p /opt/wechaty-bot/current
    tar -xzf /tmp/wechaty-bot.tar.gz -C /opt/wechaty-bot/current
    
    echo "清理临时文件..."
    rm /tmp/wechaty-bot.tar.gz
    
    echo "安装监控脚本..."
    if [ -f "/tmp/monitor-bot.sh" ]; then
        cp /tmp/monitor-bot.sh /usr/local/bin/monitor-bot
        chmod +x /usr/local/bin/monitor-bot
        rm /tmp/monitor-bot.sh
        echo "✓ 监控脚本已安装到 /usr/local/bin/monitor-bot"
    fi
    
    echo "检查Node.js..."
    if ! command -v node &> /dev/null; then
        echo "✗ 未检测到Node.js，请先运行setup-server.sh安装依赖"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    echo "✓ Node.js版本: $NODE_VERSION"
    
    echo "安装npm依赖..."
    cd /opt/wechaty-bot/current
    npm install --production
    
    echo "部署完成！"
ENDSSH

# 5. 询问是否立即启动
log_info "是否立即启动机器人？(y/n)"
read -t 10 -n 1 answer || answer="n"
echo

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    log_info "启动机器人..."
    ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
        cd /opt/wechaty-bot/current
        
        # 创建日志目录
        mkdir -p logs
        
        # 使用nohup后台启动
        nohup node bot.js > logs/bot.log 2>&1 &
        
        echo "机器人已在后台启动！"
        echo "进程ID: $(pgrep -f 'node.*bot.js')"
        echo ""
        echo "查看日志: tail -f /opt/wechaty-bot/current/logs/bot.log"
        echo "或使用监控工具: monitor-bot watch"
ENDSSH
else
    log_warn "跳过启动机器人"
fi

# 6. 清理本地临时文件
log_info "清理本地临时文件..."
rm -f wechaty-bot.tar.gz

log_info "========================================"
log_info "部署完成！"
log_info "========================================"
log_info "服务器地址: ${SERVER_HOST}"
log_info "部署路径: ${SERVER_PATH}/current"
log_info ""
log_info "常用命令："
log_info "  SSH登录: ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST}"
log_info "  手动启动: cd ${SERVER_PATH}/current && node bot.js"
log_info "  后台启动: cd ${SERVER_PATH}/current && nohup node bot.js > logs/bot.log 2>&1 &"
log_info "  查看日志: monitor-bot watch"
log_info "  停止机器人: pkill -f 'node.*bot.js'"
log_info "  查看状态: monitor-bot status"
