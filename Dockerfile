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
# 1. snapshot_download() caches the full HF Hub repo (metadata + tree listings)
#    so that offline loading doesn't need to reach huggingface.co.
# 2. SentenceTransformer() warms the sentence-transformers cache for the backend.
# HF_TOKEN is mounted as a build secret — never stored in image layers.
RUN --mount=type=secret,id=HF_TOKEN \
    export HF_TOKEN="$(cat /run/secrets/HF_TOKEN 2>/dev/null || true)" && \
    python -c "from huggingface_hub import snapshot_download; snapshot_download('${MODEL_NAME}')" && \
    if [ "$BACKEND" = "openvino" ]; then \
      python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('${MODEL_NAME}', backend='openvino')"; \
    else \
      python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('${MODEL_NAME}')"; \
    fi

# Verify the cache works fully offline — fail the build if it doesn't.
RUN if [ "$BACKEND" = "openvino" ]; then \
      HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 python -c \
        "from sentence_transformers import SentenceTransformer; SentenceTransformer('${MODEL_NAME}', backend='openvino')"; \
    else \
      HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 python -c \
        "from sentence_transformers import SentenceTransformer; SentenceTransformer('${MODEL_NAME}')"; \
    fi
