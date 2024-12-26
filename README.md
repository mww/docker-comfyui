# ComfyUI (Stable Diffusion)

## About

A Docker image for running [ComfyUI][ComfyUI] with [ComfyUI Manager][ComfyUIManager] pre-installed. This image has been tested on **Linux with NVIDIA GPUs**. 

The following volume mounts are recommended for data persistence:
- `/comfyui/user`: Contains your workflows and personal workspace settings. Always mount this to preserve your workflows when updating or recreating the container
- `/comfyui/models`: Model files (checkpoints, VAE, Loras, etc.)
- `/comfyui/custom_nodes`: Custom nodes and extensions
- `/comfyui/output`: Generated images and other outputs
- `/comfyui/input`: Input images and other data

The `/comfyui/user` volume is particularly important as it stores your workflow files (`.json`), ensuring you don't lose your work when updating ComfyUI or rebuilding the container. Other volumes like `models`, `input`, and `output` can be shared between different AI tools for a more integrated setup.

## Usage

Build and run the container:

```shell
make
docker run -d --gpus all -p 8188:8188 \
    -v ./user:/comfyui/user \
    -v ./models:/comfyui/models \
    -v ./output:/comfyui/output \
    -v ./input:/comfyui/input \
    --name comfyui jamesbrink/comfyui
```

Optionally run container on host network:  

```shell
docker run -d --gpus all --network=host \
    -v ./user:/comfyui/user \
    -v ./models:/comfyui/models \
    -v ./output:/comfyui/output \
    -v ./input:/comfyui/input \
    --name comfyui jamesbrink/comfyui
```

### Shared Model Setup

If you want to share models between ComfyUI and other tools like Fooocus, you can create a centralized directory structure:

```shell
mkdir -p ~/AI/ComfyUI/user           # Workflows and workspace settings
mkdir -p ~/AI/Models/StableDiffusion # Shared models
mkdir -p ~/AI/Output                 # Generated images
mkdir -p ~/AI/Input                  # Input data
```

Then run the container with these mapped volumes:

```shell
docker run -d --gpus all --network=host \
    -v ~/AI/ComfyUI/user:/comfyui/user \
    -v ~/AI/Models/StableDiffusion/:/comfyui/models \
    -v ~/AI/Output:/comfyui/output \
    -v ~/AI/Input:/comfyui/input \
    --name comfyui jamesbrink/comfyui
```

[ComfyUI]: https://github.com/comfyanonymous/ComfyUI
[ComfyUIManager]: https://github.com/ltdrdata/ComfyUI-Manager