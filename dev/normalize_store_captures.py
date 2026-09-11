#!/usr/bin/env python3
"""Convert raw device captures to opaque RGB PNGs without resizing them."""

from __future__ import annotations

import argparse
from pathlib import Path

from generate_store_graphics import read_png, write_png


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(".store-captures"))
    root = parser.parse_args().root.resolve()

    for path in sorted(root.rglob("*.png")):
        write_png(path, read_png(path))
        print(f"normalized {path}")


if __name__ == "__main__":
    main()
