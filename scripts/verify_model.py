#!/usr/bin/env python3
"""Download and verify sentence transformer model with optional OpenVINO backend."""

import argparse
import os
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="Download and verify sentence transformer model"
    )
    parser.add_argument(
        "--model-name",
        required=True,
        help="HuggingFace model name (e.g., intfloat/multilingual-e5-base)",
    )
    parser.add_argument(
        "--backend",
        default="torch",
        choices=["torch", "openvino"],
        help="Backend to use (torch or openvino)",
    )
    parser.add_argument(
        "--save-dir",
        required=True,
        help="Directory to save the model",
    )
    parser.add_argument(
        "--verify-offline",
        action="store_true",
        help="Verify model can be loaded offline",
    )

    args = parser.parse_args()

    from sentence_transformers import SentenceTransformer

    # Normalize model name to safe directory name
    model_dir = args.model_name.replace("/", "_")
    save_path = Path(args.save_dir) / model_dir

    if args.verify_offline:
        # Verify mode: load from local path in offline mode
        os.environ["HF_HUB_OFFLINE"] = "1"
        os.environ["TRANSFORMERS_OFFLINE"] = "1"
        
        if args.backend == "openvino":
            model = SentenceTransformer(str(save_path), backend="openvino")
        else:
            model = SentenceTransformer(str(save_path))
        
        dim = model.get_sentence_embedding_dimension()
        print(f"OK dim={dim}")
    else:
        # Download/convert mode
        if args.backend == "openvino":
            model = SentenceTransformer(args.model_name, backend="openvino")
        else:
            model = SentenceTransformer(args.model_name)
        
        model.save(str(save_path))
        print(f"Model saved to {save_path}")


if __name__ == "__main__":
    main()
