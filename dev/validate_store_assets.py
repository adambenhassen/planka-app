#!/usr/bin/env python3
"""Fail the store-assets workflow if a device or graphic is not uploadable."""

from __future__ import annotations

import argparse
from pathlib import Path

from generate_store_graphics import read_png


def check_png(root: Path, relative: str, dimensions: tuple[int, int]) -> None:
    path = root / relative
    image = read_png(path)
    actual = (image.width, image.height)
    if actual != dimensions:
        raise SystemExit(f"{relative}: expected {dimensions}, got {actual}")
    if image.channels != 3:
        raise SystemExit(f"{relative}: PNG has an alpha channel")
    print(f"ok {relative}: {image.width}x{image.height}, opaque RGB")


def check_capture_set(
    root: Path, directory: str, prefix: str, dimensions: tuple[int, int], count: int
) -> None:
    paths = sorted((root / directory).glob(f"{prefix}_*.png"))
    if len(paths) != count:
        raise SystemExit(f"{directory}: expected {count} {prefix} captures, got {len(paths)}")
    for path in paths:
        check_png(root, str(path.relative_to(root)), dimensions)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="repository root (defaults to the parent of dev/)",
    )
    root = parser.parse_args().root.resolve()

    check_png(root, "fastlane/metadata/android/en-US/images/icon.png", (512, 512))
    check_png(
        root,
        "fastlane/metadata/android/en-US/images/featureGraphic.png",
        (1024, 500),
    )
    check_png(root, "fastlane/metadata/app_icon.png", (1024, 1024))
    check_capture_set(
        root,
        "fastlane/metadata/android/en-US/images/phoneScreenshots",
        "android",
        (1080, 1920),
        4,
    )
    check_capture_set(root, "fastlane/screenshots/en-US", "iphone", (1320, 2868), 4)
    check_capture_set(root, "fastlane/screenshots/en-US", "ipad", (2064, 2752), 4)


if __name__ == "__main__":
    main()
