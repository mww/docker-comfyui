#!/bin/bash

# Function to install requirements from custom nodes
install_custom_node_requirements() {
    local node_dir="$1"
    if [ -f "${node_dir}/requirements.txt" ]; then
        echo "Installing requirements for $(basename ${node_dir})"
        pip install -r "${node_dir}/requirements.txt" || echo "Warning: Some requirements failed to install in ${node_dir}"
    fi
    
    # Handle setup.py if it exists
    if [ -f "${node_dir}/setup.py" ]; then
        echo "Running setup.py for $(basename ${node_dir})"
        cd "${node_dir}"
        pip install -e . || echo "Warning: setup.py installation failed in ${node_dir}"
        cd - > /dev/null
    fi
}

# Main function to process custom nodes
setup_custom_nodes() {
    local custom_nodes_dir="/app/custom_nodes"
    
    # Ensure directory exists
    if [ ! -d "$custom_nodes_dir" ]; then
        echo "Custom nodes directory not found at $custom_nodes_dir"
        return 1
    fi

    # Process each custom node directory
    find "$custom_nodes_dir" -mindepth 1 -maxdepth 1 -type d | while read -r node_dir; do
        if [ -d "$node_dir" ]; then
            echo "Processing custom node: $(basename "$node_dir")"
            install_custom_node_requirements "$node_dir"
        fi
    done
}

# Start Xvfb in background
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99
export MODERNGL_WINDOW=headless
export NVIDIA_DRIVER_CAPABILITIES=all

# Wait for Xvfb to start
sleep 1

# Ensure ComfyUI is synced to the volume.
rsync -avP --update /app/ /comfyui/

# Ensure proper ownership (mostly for volumes)
sudo chown -R comfyui:users /comfyui
git config --global --add safe.directory "*" 

# Simple helpers to make an easy clickable link on console.
export LOCAL_ADDRESS="$(ip route get 1 | awk '{print $(NF-2);exit}')"
export PUBLIC_ADDRESS="$(curl ipinfo.io/ip)"
echo -e "\n\n################################################################################\n"
echo "Server running: http://$(hostname):8188"
echo "Server will be locally available at: http://$LOCAL_ADDRESS:8188"
echo -e "Server will be publicly available at: http://$PUBLIC_ADDRESS:8188\n"
echo -e "################################################################################\n\n"

# Setup the Comfy cli tool.
yes N | comfy tracking disable
comfy --install-completion

# Install custom nodes from CLI
echo "Installing custom nodes..."
comfy node install --mode remote ComfyUI-Crystools ComfyUI-Custom-Scripts;

# Process mounted custom nodes
echo "Processing mounted custom nodes..."
setup_custom_nodes

if [ $# -eq 0 ]; then
    flags="--listen --port 8188 --preview-method auto"
    echo "Start flags: $flags"
    exec /usr/bin/python main.py $flags
else
    echo "Start flags: $@"
    exec /usr/bin/python main.py "$@"
fi