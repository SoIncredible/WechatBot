#!/bin/bash

# ==========================================
# 服务器依赖检查和安装脚本
# 用途：检查并安装运行Wechaty机器人所需的依赖
# 支持：Ubuntu/Debian、CentOS/RHEL、Fedora
# ==========================================

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        log_info "检测到操作系统: $OS $VERSION"
    else
        log_error "无法检测操作系统！"
        exit 1
    fi
}

# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_warn "建议使用sudo运行此脚本以便安装依赖"
        log_warn "某些安装步骤可能需要输入密码"
    fi
}

# 检查Node.js
check_nodejs() {
    log_step "检查Node.js..."
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | tr -d 'v')
        
        log_info "已安装Node.js版本: $NODE_VERSION"
        
        # 检查是否为16+版本
        if [ $NODE_MAJOR -ge 16 ]; then
            log_info "✓ Node.js版本符合要求（需要16+）"
            return 0
        else
            log_warn "Node.js版本过低，需要16或更高版本"
            return 1
        fi
    else
        log_warn "✗ Node.js未安装"
        return 1
    fi
}

# 安装Node.js
install_nodejs() {
    log_step "安装Node.js..."
    
    case $OS in
        ubuntu|debian)
            log_info "使用NodeSource仓库安装Node.js 20.x..."
            # 下载并安装NodeSource仓库脚本
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            
            # 安装Node.js
            sudo apt-get install -y nodejs
            ;;
            
        centos|rhel|fedora)
            log_info "使用NodeSource仓库安装Node.js 20.x..."
            # 下载并安装NodeSource仓库脚本
            curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
            
            # 安装Node.js
            if command -v dnf &> /dev/null; then
                sudo dnf install -y nodejs
            else
                sudo yum install -y nodejs
            fi
            ;;
            
        *)
            log_error "不支持的操作系统: $OS"
            log_info "请手动安装Node.js 16+: https://nodejs.org/"
            exit 1
            ;;
    esac
    
    # 验证安装
    if command -v node &> /dev/null; then
        log_info "✓ Node.js安装成功！版本: $(node --version)"
        log_info "✓ npm版本: $(npm --version)"
    else
        log_error "✗ Node.js安装失败！"
        exit 1
    fi
}

# 检查npm
check_npm() {
    log_step "检查npm..."
    
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        log_info "✓ npm版本: $NPM_VERSION"
        return 0
    else
        log_warn "✗ npm未安装"
        return 1
    fi
}

# 检查Git（可选）
check_git() {
    log_step "检查Git..."
    
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version)
        log_info "✓ $GIT_VERSION"
        return 0
    else
        log_warn "✗ Git未安装（可选）"
        return 1
    fi
}

# 安装Git
install_git() {
    log_step "安装Git..."
    
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y git
            ;;
            
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y git
            else
                sudo yum install -y git
            fi
            ;;
    esac
    
    if command -v git &> /dev/null; then
        log_info "✓ Git安装成功"
    fi
}

# 检查其他工具
check_tools() {
    log_step "检查其他必需工具..."
    
    MISSING_TOOLS=()
    
    # 检查tar
    if ! command -v tar &> /dev/null; then
        MISSING_TOOLS+=("tar")
    fi
    
    # 检查curl
    if ! command -v curl &> /dev/null; then
        MISSING_TOOLS+=("curl")
    fi
    
    # 检查wget
    if ! command -v wget &> /dev/null; then
        MISSING_TOOLS+=("wget")
    fi
    
    if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
        log_info "✓ 所有必需工具已安装"
        return 0
    else
        log_warn "✗ 缺少工具: ${MISSING_TOOLS[*]}"
        return 1
    fi
}

# 安装基础工具
install_tools() {
    log_step "安装基础工具..."
    
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y tar curl wget
            ;;
            
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y tar curl wget
            else
                sudo yum install -y tar curl wget
            fi
            ;;
    esac
    
    log_info "✓ 基础工具安装完成"
}

# 创建部署目录
create_directories() {
    log_step "创建部署目录..."
    
    sudo mkdir -p /opt/wechaty-bot/current
    sudo mkdir -p /opt/wechaty-bot/logs
    sudo chown -R $(whoami):$(whoami) /opt/wechaty-bot
    
    log_info "✓ 部署目录创建完成: /opt/wechaty-bot"
}

# 配置防火墙（如果需要Web服务）
configure_firewall() {
    log_step "检查防火墙配置..."
    
    log_info "Wechaty机器人通常不需要开放端口"
    log_info "如果需要Web管理界面，可以手动配置防火墙"
}

# 安装PM2（推荐的进程管理器）
install_pm2() {
    log_step "检查PM2进程管理器..."
    
    if command -v pm2 &> /dev/null; then
        PM2_VERSION=$(pm2 --version)
        log_info "✓ PM2已安装，版本: $PM2_VERSION"
        return 0
    fi
    
    echo -n "是否安装PM2进程管理器？（推荐，用于管理机器人进程）(y/n): "
    read -r install_pm2_choice
    
    if [ "$install_pm2_choice" != "y" ] && [ "$install_pm2_choice" != "Y" ]; then
        log_info "跳过PM2安装"
        return 0
    fi
    
    log_info "全局安装PM2..."
    sudo npm install -g pm2
    
    if command -v pm2 &> /dev/null; then
        log_info "✓ PM2安装成功！版本: $(pm2 --version)"
        log_info ""
        log_info "PM2常用命令："
        log_info "  启动: pm2 start bot.js --name wechaty-bot"
        log_info "  停止: pm2 stop wechaty-bot"
        log_info "  重启: pm2 restart wechaty-bot"
        log_info "  查看日志: pm2 logs wechaty-bot"
        log_info "  查看状态: pm2 status"
        log_info "  开机自启: pm2 startup && pm2 save"
    else
        log_error "✗ PM2安装失败"
    fi
}

# 创建systemd服务（可选）
create_service() {
    log_step "创建systemd服务..."
    
    echo -n "是否创建systemd服务以便开机自启？(y/n): "
    read -r create_service_choice
    
    if [ "$create_service_choice" != "y" ] && [ "$create_service_choice" != "Y" ]; then
        log_info "跳过systemd服务创建"
        return 0
    fi
    
    sudo bash -c 'cat > /etc/systemd/system/wechaty-bot.service << EOF
[Unit]
Description=Wechaty Bot Service
After=network.target

[Service]
Type=simple
User='$(whoami)'
WorkingDirectory=/opt/wechaty-bot/current
ExecStart=/usr/bin/node /opt/wechaty-bot/current/bot.js
Restart=always
RestartSec=10
StandardOutput=append:/opt/wechaty-bot/logs/bot.log
StandardError=append:/opt/wechaty-bot/logs/error.log

[Install]
WantedBy=multi-user.target
EOF'
    
    sudo systemctl daemon-reload
    sudo systemctl enable wechaty-bot.service
    
    log_info "✓ systemd服务创建完成"
    log_info "启动服务: sudo systemctl start wechaty-bot"
    log_info "查看状态: sudo systemctl status wechaty-bot"
    log_info "查看日志: sudo journalctl -u wechaty-bot -f"
}

# 显示系统信息
show_system_info() {
    log_step "系统信息摘要"
    echo "========================================"
    echo "操作系统: $OS $VERSION"
    echo "内核: $(uname -r)"
    echo "内存: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "磁盘空间: $(df -h / | awk 'NR==2 {print $4}') 可用"
    echo "========================================"
}

# 显示安装后的信息
show_next_steps() {
    log_info "========================================"
    log_info "✓ 所有依赖检查和安装完成！"
    log_info "========================================"
    log_info ""
    log_info "下一步："
    log_info "1. 在本地配置 .env 文件，设置 KIMI_API_KEY"
    log_info "2. 运行部署脚本: ./deploy-bot.sh"
    log_info "3. 在服务器上启动机器人:"
    log_info "   cd /opt/wechaty-bot/current"
    log_info "   node bot.js"
    log_info ""
    log_info "或者使用PM2管理（如已安装）："
    log_info "   pm2 start bot.js --name wechaty-bot"
    log_info "   pm2 save"
    log_info "   pm2 startup"
    log_info ""
    log_info "或者使用systemd管理（如已创建服务）："
    log_info "   sudo systemctl start wechaty-bot"
}

# 主函数
main() {
    log_info "========================================"
    log_info "Wechaty机器人服务器依赖检查和安装"
    log_info "========================================"
    
    check_root
    detect_os
    show_system_info
    
    # 检查并安装基础工具
    if ! check_tools; then
        install_tools
    fi
    
    # 检查并安装Node.js
    if ! check_nodejs; then
        echo -n "是否安装Node.js 20.x？(y/n): "
        read -r install_choice
        if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
            install_nodejs
        else
            log_error "缺少Node.js 16+，无法继续"
            exit 1
        fi
    fi
    
    # 检查npm
    check_npm
    
    # 检查Git
    if ! check_git; then
        echo -n "是否安装Git？(可选，用于版本控制) (y/n): "
        read -r install_git_choice
        if [ "$install_git_choice" = "y" ] || [ "$install_git_choice" = "Y" ]; then
            install_git
        fi
    fi
    
    # 创建部署目录
    create_directories
    
    # 配置防火墙
    configure_firewall
    
    # 安装PM2
    install_pm2
    
    # 创建systemd服务
    create_service
    
    show_next_steps
}

# 执行主函数
main
