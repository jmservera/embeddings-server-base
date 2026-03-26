# embeddings-server-base

Pre-built Docker base image with cached embedding models for the [aithena](https://github.com/jmservera/aithena) embeddings-server.

## Purpose

The aithena embeddings-server needs to download a ~1GB model on every Docker build. This base image caches the model so that code-only rebuilds skip the download entirely.

## Available Tags

| Tag | Model | Size |
|-----|-------|------|
| `multilingual-e5-base` | intfloat/multilingual-e5-base | ~1.1GB |

## Usage

In your Dockerfile:
```dockerfile
FROM ghcr.io/jmservera/embeddings-server-base:multilingual-e5-base AS model-cache
# Model is pre-cached in /models/sentence_transformers/ and /models/huggingface/
```

## Building

```bash
docker build -t ghcr.io/jmservera/embeddings-server-base:multilingual-e5-base .
```

With HF token for faster downloads:
```bash
docker build --secret id=HF_TOKEN,env=HF_TOKEN -t ghcr.io/jmservera/embeddings-server-base:multilingual-e5-base .
```

## Related

- [aithena](https://github.com/jmservera/aithena) — Main project
- [Issue #1231](https://github.com/jmservera/aithena/issues/1231) — Tracking issue
