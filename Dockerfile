FROM python:3.12-slim

ARG MODEL_NAME=intfloat/multilingual-e5-base
ARG BACKEND=torch

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/models/huggingface \
    SENTENCE_TRANSFORMERS_HOME=/models/sentence_transformers

RUN mkdir -p /models

# Install the Python packages required to download the model.
# OpenVINO backend requires optimum-intel + openvino to load/download IR files.
RUN pip install --no-cache-dir sentence-transformers huggingface_hub && \
    if [ "$BACKEND" = "openvino" ]; then \
      pip install --no-cache-dir optimum-intel openvino; \
    fi

# Pre-download the model so it is baked into the image.
# The BACKEND arg controls the model format:
#   torch    → downloads PyTorch/safetensors files (default)
#   openvino → downloads OpenVINO IR files (openvino_model.xml + .bin)
# HF_TOKEN is mounted as a build secret — never stored in image layers.
RUN --mount=type=secret,id=HF_TOKEN \
    export HF_TOKEN="$(cat /run/secrets/HF_TOKEN 2>/dev/null || true)" && \
    if [ "$BACKEND" = "openvino" ]; then \
      python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('${MODEL_NAME}', backend='openvino')"; \
    else \
      python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('${MODEL_NAME}')"; \
    fi
