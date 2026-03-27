# embeddings-server-base

Pre-built Docker base image with cached embedding models for the [aithena](https://github.com/jmservera/aithena) embeddings-server.

## Purpose

The aithena embeddings-server needs to download a ~1GB model on every Docker build. This base image caches the model so that code-only rebuilds skip the download entirely.

Two variants are built — one with the default PyTorch/safetensors model files, and one with OpenVINO IR model files for Intel GPU acceleration. Each variant caches the correct model format so the consuming Dockerfile can run fully offline.

## Available Tags

| Tag | Backend | Model format |
|-----|---------|-------------|
| `3.12-slim-multilingual-e5-base` | torch (default) | PyTorch safetensors |
| `3.12-slim-multilingual-e5-base-openvino` | openvino | OpenVINO IR (xml + bin) |
| `latest` | torch | Alias for the default tag |

## Usage

In your Dockerfile:
```dockerfile
# Standard (CPU / NVIDIA)
FROM ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base

# OpenVINO (Intel GPU)
FROM ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base-openvino
```

Model files are pre-cached in `/models/sentence_transformers/` and `/models/huggingface/`.

## Building

```bash
# Standard (torch) variant
docker build --secret id=HF_TOKEN,env=HF_TOKEN \
  -t ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base .

# OpenVINO variant
docker build --build-arg BACKEND=openvino --secret id=HF_TOKEN,env=HF_TOKEN \
  -t ghcr.io/jmservera/embeddings-server-base:3.12-slim-multilingual-e5-base-openvino .
```

## Related

- [aithena](https://github.com/jmservera/aithena) — Main project
- [Issue #1231](https://github.com/jmservera/aithena/issues/1231) — Tracking issue
