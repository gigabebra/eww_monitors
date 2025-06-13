#!/bin/bash
# scripts/listen_workspaces.sh

monitor_id=${1:-0}

get_workspaces() {
    local monitor_id=$1
    
    # get information about monitors and workspaces
    local monitors_data=$(hyprctl monitors -j)
    local workspaces_data=$(hyprctl workspaces -j)
    
    # get monitor_id
    local monitor_name=$(echo "$monitors_data" | jq -r ".[$monitor_id].name // empty")
    
    if [ -z "$monitor_name" ]; then
        echo "[]"
        return
    fi
    
    # get active workspace for monitor
    local active_workspace_for_monitor=$(echo "$monitors_data" | jq -r ".[$monitor_id].activeWorkspace.id // empty")
    
    # check focus on this monitor
    local is_focused=$(echo "$monitors_data" | jq -r ".[$monitor_id].focused // false")
    
    # get all workspaces for this monitor
    local workspaces_for_monitor=$(echo "$workspaces_data" | jq -r --arg monitor "$monitor_name" '.[] | select(.monitor == $monitor) | .id' | sort -n)
    
    # create JSON for eww
    local json_output="["
    local first=true
    
    for ws in $workspaces_for_monitor; do
        if [ "$first" = false ]; then
            json_output="$json_output,"
        fi
        first=false
        
        if [ "$ws" = "$active_workspace_for_monitor" ]; then
            json_output="$json_output{\"id\":$ws,\"active\":true,\"focused\":$is_focused}"
        else
            json_output="$json_output{\"id\":$ws,\"active\":false,\"focused\":false}"
        fi
    done
    
    json_output="$json_output]"
    echo "$json_output"
}

# return start state
get_workspaces $monitor_id

# listen Hyprland socket
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    # update when something about monitors or workspaces
    case "$line" in
        workspace*|createworkspace*|destroyworkspace*|moveworkspace*|focusedmon*)
            get_workspaces $monitor_id
            ;;
    esac
done
