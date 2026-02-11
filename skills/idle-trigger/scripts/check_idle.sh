#!/bin/bash
# 检测系统空闲时间（秒）
# 返回用户键盘/鼠标无操作的时间
# 服务器环境：结合多种方式检测

# 1. 检查是否有 xprintidle（X11 桌面环境）
if command -v xprintidle &> /dev/null && [ -n "$DISPLAY" ]; then
    IDLE_MS=$(xprintidle)
    echo $((IDLE_MS / 1000))
    exit 0
fi

# 2. 服务器环境：检查终端会话空闲时间
# 使用 `w` 命令获取用户会话的 IDLE 时间
# IDLE 格式可能是: X.XXs, X:XXm, X:XX, 或 idle
get_max_idle_from_w() {
    local max_idle=0
    # 获取所有用户会话的 IDLE 时间（跳过标题行）
    w -h 2>/dev/null | while read user tty from login idle jcpu pcpu what; do
        # 跳过 '-' 或无效值
        [[ -z "$idle" || "$idle" == "-" || "$idle" == "idle" ]] && continue
        
        local idle_secs=0
        if [[ "$idle" =~ ^([0-9]+):([0-9]+)$ ]]; then
            # 格式 HH:MM
            idle_secs=$(( ${BASH_REMATCH[1]} * 3600 + ${BASH_REMATCH[2]} * 60 ))
        elif [[ "$idle" =~ ^([0-9]+)\.([0-9]+)s$ ]]; then
            # 格式 X.XXs
            idle_secs=${BASH_REMATCH[1]}
        elif [[ "$idle" =~ ^([0-9]+)s$ ]]; then
            # 格式 Xs
            idle_secs=${BASH_REMATCH[1]}
        elif [[ "$idle" =~ ^([0-9]+)$ ]]; then
            # 可能是分钟数
            idle_secs=$(( ${BASH_REMATCH[1]} * 60 ))
        fi
        
        echo $idle_secs
    done | sort -rn | head -1
}

IDLE_FROM_W=$(get_max_idle_from_w)
if [[ -n "$IDLE_FROM_W" && "$IDLE_FROM_W" -gt 0 ]]; then
    echo "$IDLE_FROM_W"
    exit 0
fi

# 3. 检查最近终端活动（通过 utmp/last）
# 获取最近 10 分钟内的登录活动
RECENT_LOGINS=$(last -n 5 -w 2>/dev/null | grep -c "still logged in" || echo "0")

# 4. 检查系统负载
LOAD=$(cat /proc/loadavg | awk '{print $1}')

# 5. 检查正在运行的交互式进程（shell, vim, etc）
INTERACTIVE_PROCS=$(ps aux | grep -E "(vim|nano|less|man|top|htop)" | grep -v grep | wc -l)

# 6. 综合判断
# 低负载 + 无交互式进程 = 系统空闲
if (( $(echo "$LOAD < 0.5" | bc -l) )) && [ "$INTERACTIVE_PROCS" -eq 0 ]; then
    # 系统空闲，返回一个大值（表示长时间空闲）
    echo "3600"
else
    # 有活动，返回较小值
    # 根据负载返回部分空闲时间
    if (( $(echo "$LOAD < 0.3" | bc -l) )); then
        echo "600"  # 10分钟空闲
    else
        echo "0"
    fi
fi
