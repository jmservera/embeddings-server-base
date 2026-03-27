# embeddings-server-base

Pre-built Docker base image with cached embedding models for the [aithena](https://github.com/jmservera/aithena) embeddings-server.

## Purpose

The aithena embeddings-server needs to download a ~1GB model on every Docker build. This base image caches the model so that code-only rebuilds skip the download entirely.

## Available Tags

| Tag | Variant | Model | Use Case |
|-----|---------|-------|----------|
| `3.12-slim-multilingual-e5-base` | CPU/NVIDIA | intfloat/multilingual-e5-base | CPU or NVIDIA GPU acceleration |
| `3.12-slim-multilingual-e5-base-openvino` | OpenVINO | intfloat/multilingual-e5-base | Intel GPU acceleration |
| `latest` | CPU/NVIDIA | intfloat/multilingual-e5-base | Alias for CPU variant |

### When to Use Each Variant

- **CPU/NVIDIA variant** (`3.12-slim-multilingual-e5-base`): Use for CPU inference or NVIDIA GPU acceleration with CUDA. This is the default and most widely compatible option.
- **OpenVINO variant** (`3.12-slim-multilingual-e5-base-openvino`): Use when deploying on Intel hardware with GPU acceleration support. Includes optimum-intel and openvino packages for Intel GPU inference.

## Usage

In your Dockerfile:
```dockerfile
# For CPU or NVIDIA GPU:
FROM ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base AS model-cache

# For Intel GPU:
FROM ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base-openvino AS model-cache

# Model is pre-cached in /models/sentence_transformers/ and /models/huggingface/
```

## Building

```bash
# CPU variant:
docker build -t ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base .

# OpenVINO variant:
docker build --build-arg INSTALL_OPENVINO=true -t ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base-openvino .
```

With HF token for faster downloads:
```bash
docker build --secret id=HF_TOKEN,env=HF_TOKEN -t ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base .
```

## Related

- [aithena](https://github.com/jmservera/aithena) — Main project
- [Issue #1231](https://github.com/jmservera/aithena/issues/1231) — Tracking issue
