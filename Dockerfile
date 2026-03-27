FROM python:3.12-slim

ARG MODEL_NAME=intfloat/multilingual-e5-base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/models/huggingface \
    SENTENCE_TRANSFORMERS_HOME=/models/sentence_transformers

RUN mkdir -p /models

# Install the Python packages required to download the model
RUN pip install --no-cache-dir sentence-transformers huggingface_hub

# Pre-download the model so it is baked into the image.
# HF_TOKEN is mounted as a build secret — never stored in image layers.
RUN --mount=type=secret,id=HF_TOKEN \
    export HF_TOKEN="$(cat /run/secrets/HF_TOKEN 2>/dev/null || true)" && \
    python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('${MODEL_NAME}')"
