#!/bin/bash

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

# Install custom nodes
echo "Installing custom nodes..."
comfy node install --mode remote ComfyUI-Crystools,ComfyUI-Custom-Scripts;

if [ $# -eq 0 ]; then
    flags="--listen --port 8188 --preview-method auto"
    echo "Start flags: $flags"
    exec /usr/bin/python main.py $flags
else
    echo "Start flags: $@"
    exec /usr/bin/python main.py "$@"
fi