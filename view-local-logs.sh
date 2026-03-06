#!/bin/bash

# ==========================================
# 本地日志查看脚本
# 用途：在开发环境快速查看日志
# ==========================================

LOG_PATH="logs"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 自动检测日志目录
if [ ! -d "$LOG_PATH" ]; then
    echo -e "${RED}未找到日志目录: $LOG_PATH${NC}"
    echo "请先运行机器人以生成日志"
    exit 1
fi

# 获取最新日志文件
get_latest_log() {
    if [ -f "$LOG_PATH/bot.log" ]; then
        echo "$LOG_PATH/bot.log"
    else
        ls -t $LOG_PATH/*.log 2>/dev/null | head -n 1
    fi
}

LATEST_LOG=$(get_latest_log)

if [ -z "$LATEST_LOG" ]; then
    echo -e "${RED}未找到日志文件${NC}"
    exit 1
fi

# 持续监控新日志（增量输出，不刷屏）
watch_logs_continuously() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}持续监控模式 - 实时输出新日志${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}提示: 终端将持续运行，新日志产生时立即显示${NC}"
    echo -e "${YELLOW}按 Ctrl+C 退出监控${NC}"
    echo ""
    
    trap 'echo -e "\n${GREEN}监控已退出${NC}"; exit 0' INT
    
    CURRENT_LOG=$(get_latest_log)
    
    if [ -n "$CURRENT_LOG" ]; then
        echo -e "${CYAN}正在监控: $(basename $CURRENT_LOG)${NC}"
        echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
        
        # 显示最近10行作为上下文
        echo -e "${YELLOW}[最近10行上下文]${NC}"
        tail -n 10 "$CURRENT_LOG" 2>/dev/null | while read line; do
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
        tail -f "$CURRENT_LOG" | while read line; do
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

# 实时监控面板（本地开发版）
show_dashboard() {
    refresh_interval=${1:-3}
    
    echo -e "${GREEN}启动本地实时监控面板...${NC}"
    echo -e "${YELLOW}刷新间隔: ${refresh_interval}秒 | 按 Ctrl+C 退出${NC}"
    sleep 1
    
    trap 'echo -e "\n${GREEN}监控面板已退出${NC}"; exit 0' INT
    
    while true; do
        clear
        
        # 标题
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║          微信机器人本地开发监控面板                              ║${NC}"
        echo -e "${CYAN}║          $(date '+%Y-%m-%d %H:%M:%S')                                  ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # 1. 机器人进程状态
        echo -e "${CYAN}【机器人状态】${NC}"
        if pgrep -f "node.*bot.js" > /dev/null; then
            PID=$(pgrep -f "node.*bot.js")
            echo -e "  状态: ${GREEN}运行中${NC} | PID: ${GREEN}$PID${NC}"
            
            if ps -p $PID -o %cpu,%mem &> /dev/null; then
                CPU=$(ps -p $PID -o %cpu= | tr -d ' ')
                MEM=$(ps -p $PID -o %mem= | tr -d ' ')
                echo -e "  CPU: ${GREEN}${CPU}%${NC} | 内存: ${GREEN}${MEM}%${NC}"
            fi
        else
            echo -e "  状态: ${RED}未运行${NC}"
            echo -e "  ${YELLOW}提示: 使用 'npm start' 或 'node bot.js' 启动${NC}"
        fi
        echo ""
        
        # 2. 日志文件信息
        CURRENT_LOG=$(get_latest_log)
        if [ -n "$CURRENT_LOG" ]; then
            echo -e "${CYAN}【日志信息】${NC}"
            LOG_SIZE=$(ls -lh "$CURRENT_LOG" | awk '{print $5}')
            LOG_LINES=$(wc -l < "$CURRENT_LOG" | tr -d ' ')
            ERROR_COUNT=$(grep -c "ERROR\|错误" "$CURRENT_LOG" 2>/dev/null || echo 0)
            WARNING_COUNT=$(grep -c "WARN\|警告" "$CURRENT_LOG" 2>/dev/null || echo 0)
            
            echo -e "  文件: $(basename $CURRENT_LOG)"
            echo -e "  大小: ${CYAN}$LOG_SIZE${NC} | 行数: ${CYAN}$LOG_LINES${NC}"
            echo -e "  ${RED}错误: $ERROR_COUNT${NC} | ${YELLOW}警告: $WARNING_COUNT${NC}"
            echo ""
            
            # 3. 最新日志（15行）
            echo -e "${CYAN}【最新日志】${NC}"
            tail -n 15 "$CURRENT_LOG" 2>/dev/null | while read line; do
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
            echo -e "${CYAN}【日志信息】${NC}"
            echo -e "  ${YELLOW}暂无日志文件${NC}"
        fi
        
        # 底部提示
        echo ""
        echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
        echo -e "  ${YELLOW}自动刷新: ${refresh_interval}秒 | 按 Ctrl+C 退出${NC}"
        
        sleep $refresh_interval
    done
}

# 根据参数决定操作
case "${1:-recent}" in
    watch)
        watch_logs_continuously
        ;;
    dashboard)
        interval=${2:-3}
        show_dashboard $interval
        ;;
    live)
        echo -e "${CYAN}实时日志：$LATEST_LOG${NC}"
        echo ""
        tail -f "$LATEST_LOG" | while read line; do
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
        ;;
    recent)
        lines=${2:-50}
        echo -e "${CYAN}最近 $lines 行日志：$LATEST_LOG${NC}"
        echo ""
        tail -n $lines "$LATEST_LOG" | while read line; do
            if [[ $line == *"ERROR"* ]] || [[ $line == *"错误"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ $line == *"WARN"* ]] || [[ $line == *"警告"* ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ $line == *"收到消息"* ]] || [[ $line == *"message"* ]]; then
                echo -e "${CYAN}$line${NC}"
            else
                echo "$line"
            fi
        done
        ;;
    errors)
        echo -e "${CYAN}错误日志：$LATEST_LOG${NC}"
        echo ""
        grep -E "ERROR|错误" "$LATEST_LOG" | tail -n 20 | while read line; do
            echo -e "${RED}$line${NC}"
        done
        ;;
    search)
        keyword="$2"
        if [ -z "$keyword" ]; then
            echo -e "${RED}请提供搜索关键词${NC}"
            exit 1
        fi
        echo -e "${CYAN}搜索 '$keyword'：$LATEST_LOG${NC}"
        echo ""
        grep -i --color=always "$keyword" "$LATEST_LOG"
        ;;
    all)
        echo -e "${CYAN}完整日志：$LATEST_LOG${NC}"
        echo ""
        cat "$LATEST_LOG" | while read line; do
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
        ;;
    *)
        echo -e "${CYAN}本地日志查看工具${NC}"
        echo ""
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  watch           - 持续监控新日志（增量输出，不刷屏）⭐⭐ 推荐"
        echo "  dashboard [秒]  - 实时监控面板（全屏刷新）"
        echo "  live            - 实时查看日志（tail -f）"
        echo "  recent [N]      - 查看最近N行（默认50）"
        echo "  errors          - 查看错误日志"
        echo "  search <关键词> - 搜索日志"
        echo "  all             - 查看完整日志"
        echo ""
        echo "示例:"
        echo "  $0 watch             # 持续监控，新日志立即输出 ⭐"
        echo "  $0 dashboard         # 启动监控面板（3秒刷新）"
        echo "  $0 dashboard 5       # 启动监控面板（5秒刷新）"
        echo "  $0 live              # 实时查看日志"
        echo "  $0 recent 100        # 查看最近100行"
        echo "  $0 search \"登录\"    # 搜索关键词"
        ;;
esac
