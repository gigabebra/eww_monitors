#!/bin/bash
# scripts/bars_control.sh

EWW=`which eww`
CFG="$HOME/.config/eww/eww_monitors/"

## Run eww daemon if not running already
if [[ ! `pidof eww` ]]; then
	${EWW} daemon
	sleep 1
fi

case "$1" in
    "start")
        # check the number of monitors
        monitor_count=$(hyprctl monitors -j | jq length)
        
        ${EWW} --config "$CFG" open bar0
        
        if [ $monitor_count -gt 1 ]; then
            ${EWW} --config "$CFG" open bar1
        fi
        ;;
    "stop")
        ${EWW} --config "$CFG" close bar0 2>/dev/null || true
        ${EWW} --config "$CFG" close bar1 2>/dev/null || true
        # kill processes
        pkill -f "listen_workspaces.sh" 2>/dev/null || true
        ;;
    "restart")
        $0 stop
        sleep 1
        $0 start
        ;;
    "status")
        ${EWW} --config "$CFG" active-windows | grep -q "bar0" && echo "  bar0: up" || echo "  bar0: down"
        ${EWW} --config "$CFG" active-windows | grep -q "bar1" && echo "  bar1: up" || echo "  bar1: down"
        ;;
    *)
        echo "use: $0 {start|stop|restart|status}"
        echo ""
        echo "  start   - start bars for all monitors"
        echo "  stop    - stop bars for all monitors"
        echo "  restart - restart all bars"
        echo "  status  - show status"
        exit 1
        ;;
esac
