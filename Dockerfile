# syntax=docker/dockerfile:1
FROM python:3.12-slim

ARG MODEL_NAME=intfloat/multilingual-e5-base
ARG BACKEND=torch

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/models/huggingface \
    SENTENCE_TRANSFORMERS_HOME=/models/sentence_transformers

# Create app user (uid 1000) — consistent with the app image
RUN groupadd --system --gid 1000 app && \
    useradd --system --uid 1000 --gid app --create-home app

RUN mkdir -p /models /app

WORKDIR /app

# Create .venv and install heavy deps using uv (mounted transiently, not in image).
# These are the large packages (torch ~1.7GB, sentence-transformers, etc.) that
# the app image inherits. The app adds only its light deps on top via --inexact.
RUN --mount=from=ghcr.io/astral-sh/uv:latest,source=/uv,target=/usr/local/bin/uv \
    uv venv /app/.venv && \
    VIRTUAL_ENV=/app/.venv uv pip install --no-cache sentence-transformers huggingface_hub && \
    if [ "$BACKEND" = "openvino" ]; then \
      VIRTUAL_ENV=/app/.venv uv pip install --no-cache optimum-intel openvino; \
    fi

ENV PATH="/app/.venv/bin:${PATH}"

# Download model and save to a known local path for offline loading.
# Loading from a local directory bypasses all HF Hub API calls, which is the
# only reliable way to support offline mode with the openvino backend.
# HF_TOKEN is mounted as a build secret — never stored in image layers.
RUN --mount=type=secret,id=HF_TOKEN \
    export HF_TOKEN="$(cat /run/secrets/HF_TOKEN 2>/dev/null || true)" && \
    if [ "$BACKEND" = "openvino" ]; then \
      python -c "from sentence_transformers import SentenceTransformer; m = SentenceTransformer('${MODEL_NAME}', backend='openvino'); m.save('/models/sentence_transformers/$(echo ${MODEL_NAME} | tr / _)')"; \
    else \
      python -c "from sentence_transformers import SentenceTransformer; m = SentenceTransformer('${MODEL_NAME}'); m.save('/models/sentence_transformers/$(echo ${MODEL_NAME} | tr / _)')"; \
    fi

# Verify offline loading from local path — fails the build if cache is incomplete.
RUN if [ "$BACKEND" = "openvino" ]; then \
      HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 python -c \
        "from sentence_transformers import SentenceTransformer; m = SentenceTransformer('/models/sentence_transformers/$(echo ${MODEL_NAME} | tr / _)', backend='openvino'); print(f'OK dim={m.get_sentence_embedding_dimension()}')"; \
    else \
      HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 python -c \
        "from sentence_transformers import SentenceTransformer; m = SentenceTransformer('/models/sentence_transformers/$(echo ${MODEL_NAME} | tr / _)'); print(f'OK dim={m.get_sentence_embedding_dimension()}')"; \
    fi

# Own /app to app user; /models stays root-owned, world-readable
RUN chown -R app:app /app && chmod -R a+rX /models
