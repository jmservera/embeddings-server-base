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

# Copy pyproject.toml and model verification script
COPY pyproject.toml /app/
COPY scripts/verify_model.py /app/scripts/

# Create .venv and install heavy deps using uv (mounted transiently, not in image).
# These are the large packages (torch ~1.7GB, sentence-transformers, etc.) that
# the app image inherits. The app adds only its light deps on top via --inexact.
RUN --mount=from=ghcr.io/astral-sh/uv:latest,source=/uv,target=/usr/local/bin/uv \
    uv venv /app/.venv && \
    if [ "$BACKEND" = "openvino" ]; then \
      VIRTUAL_ENV=/app/.venv uv sync --no-dev --extra openvino; \
    else \
      VIRTUAL_ENV=/app/.venv uv sync --no-dev; \
    fi

ENV PATH="/app/.venv/bin:${PATH}"

# Download model and save to a known local path for offline loading.
# Loading from a local directory bypasses all HF Hub API calls, which is the
# only reliable way to support offline mode with the openvino backend.
# HF_TOKEN is mounted as a build secret — never stored in image layers.
RUN --mount=type=secret,id=HF_TOKEN \
    export HF_TOKEN="$(cat /run/secrets/HF_TOKEN 2>/dev/null || true)" && \
    python scripts/verify_model.py --model-name "${MODEL_NAME}" --backend "${BACKEND}" --save-dir /models/sentence_transformers

# Verify offline loading from local path — fails the build if cache is incomplete.
RUN python scripts/verify_model.py --model-name "${MODEL_NAME}" --backend "${BACKEND}" --save-dir /models/sentence_transformers --verify-offline

# Own /app to app user; /models stays root-owned, world-readable
RUN chown -R app:app /app && chmod -R a+rX /models
