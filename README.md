# embeddings-server-base

Pre-built Docker base image with cached embedding models for the [aithena](https://github.com/jmservera/aithena) embeddings-server.

## Purpose

The aithena embeddings-server needs to download a ~1GB model on every Docker build. This base image caches the model so that code-only rebuilds skip the download entirely.

Two variants are built — one with the default PyTorch/safetensors model files, and one with OpenVINO IR model files for Intel GPU acceleration. Each variant caches the correct model format so the consuming Dockerfile can run fully offline.

## .venv Pattern

Heavy Python packages (torch ~1.7GB, sentence-transformers, etc.) are pre-installed into `/app/.venv` rather than system site-packages. This enables the app image to use `uv sync --inexact` to add only its light dependencies (~200MB delta layer) on top, instead of duplicating the entire ~4GB .venv in a COPY layer.

Key details:
- **uv is NOT in the image** — it is BuildKit-mounted transiently via `--mount=from=ghcr.io/astral-sh/uv:latest` during `RUN` commands only
- **`/app/.venv`** is owned by the `app` user (uid 1000), consistent with the app image
- **`/models/`** stays root-owned and world-readable (`chmod a+rX`) to avoid duplicating the ~5GB model layer via chown
- The app image inherits this .venv and runs `uv sync --inexact` to install its own light deps (fastapi, uvicorn, etc.) without touching the heavy packages

See [jmservera/aithena#1325](https://github.com/jmservera/aithena/issues/1325) for the full optimization rationale.

## Available Tags

| Tag | Backend | Model format |
|-----|---------|-------------|
| `3.12-slim-multilingual-e5-base` | torch (default) | PyTorch safetensors |
| `3.12-slim-multilingual-e5-base-openvino` | openvino | OpenVINO IR (xml + bin) |
| `latest` | torch | Alias for the default tag |

## Usage

In your Dockerfile:
```dockerfile
# syntax=docker/dockerfile:1
FROM ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base

# Install only your app's light deps on top of the pre-installed heavy packages
RUN --mount=from=ghcr.io/astral-sh/uv:latest,source=/uv,target=/usr/local/bin/uv \
    uv sync --frozen --no-dev --inexact
```

For the OpenVINO variant:
```dockerfile
# syntax=docker/dockerfile:1
FROM ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base-openvino

RUN --mount=from=ghcr.io/astral-sh/uv:latest,source=/uv,target=/usr/local/bin/uv \
    uv sync --frozen --no-dev --inexact
```

Model files are pre-cached in `/models/sentence_transformers/`.

## Building

Both Dockerfiles require BuildKit (Docker 18.09+, enabled by default in Docker Desktop and CI).

```bash
# Standard (torch) variant
docker build --secret id=HF_TOKEN,env=HF_TOKEN \
  -t ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base .

# OpenVINO variant (uses Dockerfile.openvino)
docker build -f Dockerfile.openvino --secret id=HF_TOKEN,env=HF_TOKEN \
  -t ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base-openvino .
```

## Related

- [aithena](https://github.com/jmservera/aithena) — Main project
- [Issue #1231](https://github.com/jmservera/aithena/issues/1231) — Base image tracking issue
- [Issue #1325](https://github.com/jmservera/aithena/issues/1325) — Layer optimization tracking issue
