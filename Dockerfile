ARG BASE_IMAGE=nvidia/cuda:12.6.3-runtime-ubuntu22.04
FROM ${BASE_IMAGE} AS base

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install deps
RUN set -xe; \
    apt update && apt install -y \
        bash-completion \
        build-essential \
        cmake \
        curl \
        ffmpeg \
        git \
        iproute2 \
        libbz2-dev \
        libgl1-mesa-dev \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libglu1-mesa-dev \
        libglvnd-dev \
        libopencv-dev \
        libx11-dev \
        libxcursor-dev \
        libxi-dev \
        libxinerama-dev \
        libxrandr-dev \
        mesa-common-dev \
        ninja-build \
        pkg-config \
        python-is-python3 \
        python3 \
        python3-opencv \
        python3-pip \
        python3-psutil \
        rsync \
        sudo \
        unzip \
        vim \
        wget; \
    apt clean; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /var/cache/apt;

# Create our group & user.
RUN set -xe; \
    useradd -u 1000 -g 100 -G sudo -r -d /comfyui -s /bin/sh comfyui; \
    echo "comfyui ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    mkdir -p /comfyui; \
    mkdir -p /app;

# Setup ComfyUI
ARG VERSION=v0.3.9
RUN set -xe; \
    git clone https://github.com/comfyanonymous/ComfyUI.git /app; \
    cd /app; \
    git fetch --all --tags; \
    git checkout ${VERSION}; \
    pip install --no-cache-dir -r requirements.txt; \
    pip install --no-cache-dir comfy-cli;

# Setup ComfyUI Manager
ARG UI_MANAGER_VERSION=main
RUN set -xe; \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /app/custom_nodes/ComfyUI-Manager; \
    cd /app/custom_nodes/ComfyUI-Manager; \
    git fetch --all --tags; \
    git checkout ${UI_MANAGER_VERSION}; \
    pip install --no-cache-dir -r requirements.txt;

# Copy our entrypoint into the container.
COPY ./runtime-assets /

# Ensure entrypoint is executable
RUN set -xe; \
    chmod 0755 /usr/local/bin/entrypoint.sh; \
    chown -R comfyui:users /app; \
    chown -R comfyui:users /comfyui;

# Labels / Metadata.
LABEL \
    org.opencontainers.image.authors="James Brink <brink.james@gmail.com>" \
    org.opencontainers.image.description="ComfyUI Interface for Stable Diffusion" \
    org.opencontainers.image.revision="1" \
    org.opencontainers.image.source="https://github.com/jamesbrink/comfyui" \
    org.opencontainers.image.title="comfyui" \
    org.opencontainers.image.vendor="jamesbrink" \
    org.opencontainers.image.version="${VERSION}"

# Setup our environment variables.
ENV \
    HOME="/comfyui" \
    PATH="/usr/local/bin:/comfyui/.local/bin:$PATH" \
    VERSION="${VERSION}"

# Drop down to our unprivileged user.
USER comfyui
WORKDIR /comfyui

# Setup git
RUN set -xe; \
    git config --global user.name "ComfyUI"; \
    git config --global user.email "ComfyUI@urandom.io"; \
    git config --global init.defaultBranch main; \
    git config --global core.editor "vim"; \
    git config --global --add safe.directory /comfyui; \
    git config --global --add safe.directory /comfyui/custom_nodes/ComfyUI-Manager;

# Expose our http port.
EXPOSE 8188

# Volumes
VOLUME [ "/comfyui", "/comfyui/models", "/comfyui/output", "/comfyui/input", "/comfyui/user" ]

# Set the entrypoint.
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# Set the default command
CMD [ "--listen", "--port","8188", "--preview-method", "auto", "--multi-user" ]

# Stage for sd-turbo
FROM base AS sd-turbo
COPY ./build-assets/app/models/checkpoints/sd_turbo.safetensors /app/models/checkpoints/sd_turbo.safetensors

# Stage for sd-1.5
FROM base AS sd-1.5
COPY ./build-assets/app/models/checkpoints/v1-5-pruned-emaonly.ckpt /app/models/checkpoints/v1-5-pruned-emaonly.ckpt

# Stage for SVD 14 Frame
FROM base AS svd-14-frame
COPY ./build-assets/app/models/checkpoints/svd.safetensors /app/models/checkpoints/svd.safetensors

# Stage for SVD 25 Frame
FROM base AS svd-25-frame
COPY ./build-assets/app/models/checkpoints/svd_xt_image_decoder.safetensors /app/models/checkpoints/svd_xt_image_decoder.safetensors

# Stage for both SVD models
FROM base AS svd
COPY --from=3 /app/models/checkpoints/svd.safetensors /app/models/checkpoints/svd.safetensors
COPY --from=4 /app/models/checkpoints/svd_xt_image_decoder.safetensors /app/models/checkpoints/svd_xt_image_decoder.safetensors

# Stage for models
FROM svd AS all-models
COPY --from=1 /app/models/checkpoints/sd_turbo.safetensors /app/models/checkpoints/sd_turbo.safetensors
COPY --from=2 /app/models/checkpoints/v1-5-pruned-emaonly.ckpt /app/models/checkpoints/v1-5-pruned-emaonly.ckpt
COPY --from=3 /app/models/checkpoints/svd.safetensors /app/models/checkpoints/svd.safetensors
COPY --from=4 /app/models/checkpoints/svd_xt_image_decoder.safetensors /app/models/checkpoints/svd_xt_image_decoder.safetensors
