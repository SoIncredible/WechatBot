#!/bin/bash

# ==========================================
# 微信机器人监控脚本
# 用途：查看机器人运行状态、日志和统计信息
# ==========================================

# 配置
BOT_PATH="/opt/wechaty-bot/current"
LOG_PATH="/opt/wechaty-bot/current/logs"
SERVICE_NAME="wechaty-bot"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 标题函数
print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# 检查机器人进程状态
check_bot_status() {
    print_header "机器人进程状态"
    
    if pgrep -f "node.*bot.js" > /dev/null; then
        PID=$(pgrep -f "node.*bot.js")
        echo -e "${GREEN}✓ 机器人正在运行${NC}"
        echo -e "PID: ${GREEN}$PID${NC}"
        
        # 获取进程运行时间
        if ps -p $PID -o etime= &> /dev/null; then
            UPTIME=$(ps -p $PID -o etime= | tr -d ' ')
            echo -e "运行时间: ${GREEN}$UPTIME${NC}"
        fi
        
        # 获取CPU和内存使用率
        if ps -p $PID -o %cpu,%mem,vsz,rss &> /dev/null; then
            echo ""
            ps -p $PID -o pid,%cpu,%mem,vsz,rss,comm | head -n 1
            ps -p $PID -o pid,%cpu,%mem,vsz,rss,comm | tail -n 1
        fi
        
        return 0
    else
        echo -e "${RED}✗ 机器人未运行${NC}"
        return 1
    fi
}

# 检查systemd服务状态（如果使用）
check_systemd_status() {
    if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
        echo ""
        print_header "Systemd服务状态"
        systemctl status $SERVICE_NAME --no-pager | head -n 15
    fi
}

# 检查PM2状态（如果使用）
check_pm2_status() {
    if command -v pm2 &> /dev/null; then
        if pm2 list 2>/dev/null | grep -q "wechaty-bot"; then
            echo ""
            print_header "PM2进程状态"
            pm2 show wechaty-bot 2>/dev/null || pm2 list | grep wechaty
        fi
    fi
}

# 查看实时日志
view_live_logs() {
    print_header "实时日志（按Ctrl+C退出）"
    
    # 尝试多个可能的日志位置
    POSSIBLE_LOGS=(
        "$LOG_PATH/bot.log"
        "$BOT_PATH/bot.log"
        "$BOT_PATH/logs/bot.log"
    )
    
    LOG_FILE=""
    for log in "${POSSIBLE_LOGS[@]}"; do
        if [ -f "$log" ]; then
            LOG_FILE="$log"
            break
        fi
    done
    
    if [ -n "$LOG_FILE" ]; then
        echo -e "日志文件: ${BLUE}$LOG_FILE${NC}"
        echo ""
        tail -f "$LOG_FILE" | while read line; do
            # 根据日志内容显示不同颜色
            if [[ $line == *"ERROR"* ]] || [[ $line == *"错误"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ $line == *"WARN"* ]] || [[ $line == *"警告"* ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ $line == *"登录成功"* ]] || [[ $line == *"login"* ]]; then
                echo -e "${GREEN}$line${NC}"
            elif [[ $line == *"收到消息"* ]] || [[ $line == *"message"* ]]; then
                echo -e "${CYAN}$line${NC}"
            else
                echo "$line"
            fi
        done
    else
        echo -e "${YELLOW}未找到日志文件${NC}"
        echo "可能的日志位置："
        for log in "${POSSIBLE_LOGS[@]}"; do
            echo "  - $log"
        done
    fi
}

# 查看最近的日志（不跟踪）
view_recent_logs() {
    local lines=${1:-50}
    print_header "最近 $lines 行日志"
    
    POSSIBLE_LOGS=(
        "$LOG_PATH/bot.log"
        "$BOT_PATH/bot.log"
        "$BOT_PATH/logs/bot.log"
    )
    
    LOG_FILE=""
    for log in "${POSSIBLE_LOGS[@]}"; do
        if [ -f "$log" ]; then
            LOG_FILE="$log"
            break
        fi
    done
    
    if [ -n "$LOG_FILE" ]; then
        echo -e "日志文件: ${BLUE}$LOG_FILE${NC}"
        echo ""
        tail -n $lines "$LOG_FILE" | while read line; do
            if [[ $line == *"ERROR"* ]] || [[ $line == *"错误"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ $line == *"WARN"* ]] || [[ $line == *"警告"* ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ $line == *"登录成功"* ]] || [[ $line == *"login"* ]]; then
                echo -e "${GREEN}$line${NC}"
            elif [[ $line == *"收到消息"* ]] || [[ $line == *"message"* ]]; then
                echo -e "${CYAN}$line${NC}"
            else
                echo "$line"
            fi
        done
    else
        echo -e "${YELLOW}未找到日志文件${NC}"
    fi
}

# 搜索日志
search_logs() {
    local keyword=$1
    print_header "搜索日志: $keyword"
    
    POSSIBLE_LOGS=(
        "$LOG_PATH/bot.log"
        "$BOT_PATH/bot.log"
        "$BOT_PATH/logs/bot.log"
    )
    
    for log in "${POSSIBLE_LOGS[@]}"; do
        if [ -f "$log" ]; then
            echo -e "${BLUE}文件: $log${NC}"
            grep -i --color=always "$keyword" "$log" | tail -n 50
            echo ""
        fi
    done
}

# 查看错误日志
view_errors() {
    local lines=${1:-20}
    print_header "最近 $lines 条错误日志"
    
    POSSIBLE_LOGS=(
        "$LOG_PATH/bot.log"
        "$LOG_PATH/error.log"
        "$BOT_PATH/bot.log"
        "$BOT_PATH/logs/bot.log"
        "$BOT_PATH/logs/error.log"
    )
    
    for log in "${POSSIBLE_LOGS[@]}"; do
        if [ -f "$log" ]; then
            echo -e "日志文件: ${BLUE}$log${NC}"
            echo ""
            grep -E "(ERROR|错误|Error)" "$log" | tail -n $lines | while read line; do
                echo -e "${RED}$line${NC}"
            done
            echo ""
        fi
    done
}

# 持续监控新日志（增量输出，不刷屏）
watch_logs_continuously() {
    print_header "持续监控模式 - 实时输出新日志"
    echo -e "${YELLOW}提示: 终端将持续运行，新日志产生时立即显示${NC}"
    echo -e "${YELLOW}按 Ctrl+C 退出监控${NC}"
    echo ""
    
    trap 'echo -e "\n${GREEN}监控已退出${NC}"; exit 0' INT
    
    POSSIBLE_LOGS=(
        "$LOG_PATH/bot.log"
        "$BOT_PATH/bot.log"
        "$BOT_PATH/logs/bot.log"
    )
    
    LOG_FILE=""
    for log in "${POSSIBLE_LOGS[@]}"; do
        if [ -f "$log" ]; then
            LOG_FILE="$log"
            break
        fi
    done
    
    if [ -n "$LOG_FILE" ]; then
        echo -e "${CYAN}正在监控: $LOG_FILE${NC}"
        echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
        
        # 先显示最近10行作为上下文
        echo -e "${YELLOW}[最近10行上下文]${NC}"
        tail -n 10 "$LOG_FILE" 2>/dev/null | while read line; do
            if [[ $line == *"ERROR"* ]] || [[ $line == *"错误"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ $line == *"WARN"* ]] || [[ $line == *"警告"* ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ $line == *"登录成功"* ]] || [[ $line == *"login"* ]]; then
                echo -e "${GREEN}$line${NC}"
            elif [[ $line == *"收到消息"* ]] || [[ $line == *"message"* ]]; then
                echo -e "${CYAN}$line${NC}"
            else
                echo "$line"
            fi
        done
        
        echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
        echo -e "${YELLOW}[持续监控中...新日志将实时显示]${NC}"
        echo ""
        
        # 实时跟踪新日志（增量输出）
        tail -f "$LOG_FILE" | while read line; do
            if [[ $line == *"ERROR"* ]] || [[ $line == *"错误"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ $line == *"WARN"* ]] || [[ $line == *"警告"* ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ $line == *"登录成功"* ]] || [[ $line == *"login"* ]]; then
                echo -e "${GREEN}$line${NC}"
            elif [[ $line == *"收到消息"* ]] || [[ $line == *"message"* ]]; then
                echo -e "${CYAN}$line${NC}"
            else
                echo "$line"
            fi
        done
    else
        echo -e "${YELLOW}未找到日志文件，等待日志生成...${NC}"
        sleep 2
        watch_logs_continuously
    fi
}

# 实时监控面板
show_dashboard() {
    local refresh_interval=${1:-3}
    
    echo -e "${GREEN}启动实时监控面板...${NC}"
    echo -e "${YELLOW}刷新间隔: ${refresh_interval}秒 | 按 Ctrl+C 退出${NC}"
    sleep 1
    
    # 捕获 Ctrl+C 信号
    trap 'echo -e "\n${GREEN}监控面板已退出${NC}"; exit 0' INT
    
    while true; do
        clear
        
        # 显示标题和时间
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║          微信机器人实时监控面板                                  ║${NC}"
        echo -e "${CYAN}║          $(date '+%Y-%m-%d %H:%M:%S')                                  ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # 1. 机器人进程状态（简化版）
        echo -e "${MAGENTA}【机器人状态】${NC}"
        if pgrep -f "node.*bot.js" > /dev/null; then
            PID=$(pgrep -f "node.*bot.js")
            UPTIME=$(ps -p $PID -o etime= 2>/dev/null | tr -d ' ' || echo "N/A")
            CPU=$(ps -p $PID -o %cpu= 2>/dev/null | tr -d ' ' || echo "0")
            MEM=$(ps -p $PID -o %mem= 2>/dev/null | tr -d ' ' || echo "0")
            echo -e "  状态: ${GREEN}运行中${NC} | PID: ${GREEN}$PID${NC} | 运行时间: ${GREEN}$UPTIME${NC}"
            echo -e "  CPU: ${GREEN}${CPU}%${NC} | 内存: ${GREEN}${MEM}%${NC}"
        else
            echo -e "  状态: ${RED}未运行${NC}"
        fi
        echo ""
        
        # 2. 系统资源
        echo -e "${MAGENTA}【系统资源】${NC}"
        if command -v free &> /dev/null; then
            free -h | awk 'NR==2{printf "  内存: 已用 %s / 总计 %s (可用: %s)\n", $3, $2, $7}'
        fi
        if command -v df &> /dev/null; then
            df -h / | awk 'NR==2{printf "  磁盘: 已用 %s / 总计 %s (可用: %s, 使用率: %s)\n", $3, $2, $4, $5}'
        fi
        echo ""
        
        # 3. 最新日志（15行）
        echo -e "${MAGENTA}【最新日志】${NC}"
        
        POSSIBLE_LOGS=(
            "$LOG_PATH/bot.log"
            "$BOT_PATH/bot.log"
            "$BOT_PATH/logs/bot.log"
        )
        
        LOG_FILE=""
        for log in "${POSSIBLE_LOGS[@]}"; do
            if [ -f "$log" ]; then
                LOG_FILE="$log"
                break
            fi
        done
        
        if [ -n "$LOG_FILE" ]; then
            tail -n 15 "$LOG_FILE" 2>/dev/null | while read line; do
                if [[ $line == *"ERROR"* ]] || [[ $line == *"错误"* ]]; then
                    echo -e "  ${RED}$line${NC}"
                elif [[ $line == *"WARN"* ]] || [[ $line == *"警告"* ]]; then
                    echo -e "  ${YELLOW}$line${NC}"
                elif [[ $line == *"登录成功"* ]] || [[ $line == *"login"* ]]; then
                    echo -e "  ${GREEN}$line${NC}"
                elif [[ $line == *"收到消息"* ]] || [[ $line == *"message"* ]]; then
                    echo -e "  ${CYAN}$line${NC}"
                else
                    echo "  $line"
                fi
            done
        else
            echo -e "  ${YELLOW}暂无日志${NC}"
        fi
        
        # 底部提示
        echo ""
        echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
        echo -e "  ${YELLOW}刷新间隔: ${refresh_interval}秒 | 按 Ctrl+C 退出监控面板${NC}"
        
        # 等待刷新
        sleep $refresh_interval
    done
}

# 系统资源信息
show_system_resources() {
    print_header "系统资源使用情况"
    
    echo "CPU使用率:"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  使用: " 100 - $1 "%"}' || echo "  无法获取"
    
    echo ""
    echo "内存使用:"
    free -h | awk 'NR==2{printf "  总计: %s, 已用: %s, 可用: %s, 使用率: %.2f%%\n", $2, $3, $7, $3/$2*100}' || echo "  无法获取"
    
    echo ""
    echo "磁盘使用:"
    df -h / | awk 'NR==2{printf "  总计: %s, 已用: %s, 可用: %s, 使用率: %s\n", $2, $3, $4, $5}' || echo "  无法获取"
}

# 启动机器人
start_bot() {
    print_header "启动机器人"
    
    if pgrep -f "node.*bot.js" > /dev/null; then
        echo -e "${YELLOW}机器人已在运行中${NC}"
        return 0
    fi
    
    # 检查PM2
    if command -v pm2 &> /dev/null; then
        echo "使用PM2启动..."
        cd $BOT_PATH
        pm2 start bot.js --name wechaty-bot
        sleep 2
        pm2 status wechaty-bot
        return 0
    fi
    
    # 检查systemd
    if systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
        echo "使用systemd启动..."
        sudo systemctl start $SERVICE_NAME
        sleep 2
        systemctl status $SERVICE_NAME --no-pager | head -n 10
        return 0
    fi
    
    # 手动启动
    echo "手动启动机器人..."
    cd $BOT_PATH
    nohup node bot.js > logs/bot.log 2>&1 &
    sleep 2
    echo -e "${GREEN}✓ 机器人已启动${NC}"
    echo "PID: $(pgrep -f 'node.*bot.js')"
}

# 停止机器人
stop_bot() {
    print_header "停止机器人"
    
    if ! pgrep -f "node.*bot.js" > /dev/null; then
        echo -e "${YELLOW}机器人未运行${NC}"
        return 0
    fi
    
    # 检查PM2
    if command -v pm2 &> /dev/null && pm2 list 2>/dev/null | grep -q "wechaty-bot"; then
        echo "使用PM2停止..."
        pm2 stop wechaty-bot
        echo -e "${GREEN}✓ 机器人已停止${NC}"
        return 0
    fi
    
    # 检查systemd
    if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
        echo "使用systemd停止..."
        sudo systemctl stop $SERVICE_NAME
        echo -e "${GREEN}✓ 机器人已停止${NC}"
        return 0
    fi
    
    # 手动停止
    echo "发送终止信号..."
    pkill -f "node.*bot.js"
    sleep 2
    
    if pgrep -f "node.*bot.js" > /dev/null; then
        echo -e "${YELLOW}强制终止进程...${NC}"
        pkill -9 -f "node.*bot.js"
    fi
    
    echo -e "${GREEN}✓ 机器人已停止${NC}"
}

# 重启机器人
restart_bot() {
    stop_bot
    sleep 2
    start_bot
}

# 显示完整状态
show_full_status() {
    check_bot_status
    echo ""
    show_system_resources
    echo ""
    check_systemd_status
    check_pm2_status
    echo ""
    
    # 显示最近的几条日志
    POSSIBLE_LOGS=(
        "$LOG_PATH/bot.log"
        "$BOT_PATH/bot.log"
        "$BOT_PATH/logs/bot.log"
    )
    
    for log in "${POSSIBLE_LOGS[@]}"; do
        if [ -f "$log" ]; then
            echo ""
            print_header "最近日志（10行）"
            tail -n 10 "$log" | while read line; do
                if [[ $line == *"ERROR"* ]] || [[ $line == *"错误"* ]]; then
                    echo -e "${RED}$line${NC}"
                elif [[ $line == *"WARN"* ]] || [[ $line == *"警告"* ]]; then
                    echo -e "${YELLOW}$line${NC}"
                elif [[ $line == *"登录成功"* ]] || [[ $line == *"login"* ]]; then
                    echo -e "${GREEN}$line${NC}"
                elif [[ $line == *"收到消息"* ]] || [[ $line == *"message"* ]]; then
                    echo -e "${CYAN}$line${NC}"
                else
                    echo "$line"
                fi
            done
            break
        fi
    done
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}微信机器人监控工具${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  status          - 显示机器人完整状态（默认）"
    echo "  watch           - 持续监控新日志（增量输出，不刷屏）⭐⭐ 推荐"
    echo "  dashboard [秒]  - 实时监控面板（全屏刷新）"
    echo "  live            - 实时查看日志（tail -f）"
    echo "  recent [N]      - 查看最近N行日志（默认50行）"
    echo "  errors [N]      - 查看最近N条错误日志（默认20条）"
    echo "  search <关键词> - 搜索日志中的关键词"
    echo "  start           - 启动机器人"
    echo "  stop            - 停止机器人"
    echo "  restart         - 重启机器人"
    echo "  help            - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                      # 显示机器人状态"
    echo "  $0 watch                # 持续监控，新日志立即输出 ⭐"
    echo "  $0 dashboard            # 启动实时监控面板（3秒刷新）"
    echo "  $0 dashboard 5          # 启动实时监控面板（5秒刷新）"
    echo "  $0 live                 # 实时查看日志"
    echo "  $0 recent 100           # 查看最近100行日志"
    echo "  $0 search \"登录\"       # 搜索包含登录的日志"
    echo "  $0 errors               # 查看错误日志"
}

# 主函数
main() {
    local command=${1:-status}
    
    case $command in
        status)
            show_full_status
            ;;
        watch)
            watch_logs_continuously
            ;;
        dashboard)
            local interval=${2:-3}
            show_dashboard $interval
            ;;
        live)
            view_live_logs
            ;;
        recent)
            local lines=${2:-50}
            view_recent_logs $lines
            ;;
        errors)
            local lines=${2:-20}
            view_errors $lines
            ;;
        search)
            if [ -z "$2" ]; then
                echo -e "${RED}错误: 请提供搜索关键词${NC}"
                echo "用法: $0 search <关键词>"
                exit 1
            fi
            search_logs "$2"
            ;;
        start)
            start_bot
            ;;
        stop)
            stop_bot
            ;;
        restart)
            restart_bot
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}未知命令: $command${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
