#!/usr/bin/env python3
"""Generate the mandatory store graphics from the checked-in app icon.

The capture workflow runs this script after downloading the device-native
screenshots. It intentionally uses only the Python standard library so the
graphics step does not depend on a system image tool being installed.
"""

from __future__ import annotations

import argparse
import math
import struct
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


class Png:
    def __init__(
        self, width: int, height: int, pixels: bytearray, channels: int = 3
    ) -> None:
        self.width = width
        self.height = height
        self.pixels = pixels
        self.channels = channels


def _chunk(kind: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )


def read_png(path: Path) -> Png:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path} is not a PNG")

    offset = len(PNG_SIGNATURE)
    width = height = bit_depth = color_type = interlace = None
    compressed = bytearray()
    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload = data[offset + 8 : offset + 8 + length]
        offset += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            break

    if width is None or height is None:
        raise ValueError(f"{path} has no IHDR chunk")
    if bit_depth != 8 or color_type not in (2, 6) or interlace != 0:
        raise ValueError(
            f"{path} must be an 8-bit, non-interlaced RGB/RGBA PNG "
            f"(bit depth {bit_depth}, color type {color_type}, interlace {interlace})"
        )

    channels = 3 if color_type == 2 else 4
    stride = width * channels
    decoded = zlib.decompress(compressed)
    expected = height * (stride + 1)
    if len(decoded) != expected:
        raise ValueError(f"{path} has an unexpected decoded size")

    pixels = bytearray()
    previous = bytearray(stride)
    offset = 0
    for _ in range(height):
        filter_type = decoded[offset]
        offset += 1
        row = bytearray(decoded[offset : offset + stride])
        offset += stride
        for index in range(stride):
            left = row[index - channels] if index >= channels else 0
            above = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            if filter_type == 1:
                row[index] = (row[index] + left) & 0xFF
            elif filter_type == 2:
                row[index] = (row[index] + above) & 0xFF
            elif filter_type == 3:
                row[index] = (row[index] + ((left + above) // 2)) & 0xFF
            elif filter_type == 4:
                estimate = left + above - upper_left
                distances = (
                    abs(estimate - left),
                    abs(estimate - above),
                    abs(estimate - upper_left),
                )
                predictor = (left, above, upper_left)[distances.index(min(distances))]
                row[index] = (row[index] + predictor) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"{path} uses unknown PNG filter {filter_type}")

        if channels == 3:
            pixels.extend(row)
        else:
            for index in range(0, stride, channels):
                alpha = row[index + 3]
                # Flatten source alpha over white. The generated store assets
                # are opaque even if a future source icon is not.
                pixels.extend(
                    (
                        (row[index] * alpha + 255 * (255 - alpha)) // 255,
                        (row[index + 1] * alpha + 255 * (255 - alpha)) // 255,
                        (row[index + 2] * alpha + 255 * (255 - alpha)) // 255,
                    )
                )
        previous = row

    return Png(width, height, pixels, channels)


def write_png(path: Path, image: Png) -> None:
    if image.channels != 3 or len(image.pixels) != image.width * image.height * 3:
        raise ValueError("only opaque RGB output is supported")
    rows = bytearray()
    stride = image.width * 3
    for y in range(image.height):
        rows.append(0)
        rows.extend(image.pixels[y * stride : (y + 1) * stride])
    header = struct.pack(">IIBBBBB", image.width, image.height, 8, 2, 0, 0, 0)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(
        PNG_SIGNATURE
        + _chunk(b"IHDR", header)
        + _chunk(b"IDAT", zlib.compress(bytes(rows), level=9))
        + _chunk(b"IEND", b"")
    )


def resize(source: Png, width: int, height: int) -> Png:
    output = bytearray(width * height * 3)
    for y in range(height):
        source_y = (y + 0.5) * source.height / height - 0.5
        y0 = max(0, min(source.height - 1, math.floor(source_y)))
        y1 = max(0, min(source.height - 1, y0 + 1))
        y_weight = source_y - math.floor(source_y)
        for x in range(width):
            source_x = (x + 0.5) * source.width / width - 0.5
            x0 = max(0, min(source.width - 1, math.floor(source_x)))
            x1 = max(0, min(source.width - 1, x0 + 1))
            x_weight = source_x - math.floor(source_x)
            for channel in range(3):
                top_left = source.pixels[(y0 * source.width + x0) * 3 + channel]
                top_right = source.pixels[(y0 * source.width + x1) * 3 + channel]
                bottom_left = source.pixels[(y1 * source.width + x0) * 3 + channel]
                bottom_right = source.pixels[(y1 * source.width + x1) * 3 + channel]
                top = top_left + (top_right - top_left) * x_weight
                bottom = bottom_left + (bottom_right - bottom_left) * x_weight
                value = round(top + (bottom - top) * y_weight)
                output[(y * width + x) * 3 + channel] = max(0, min(255, value))
    return Png(width, height, output)


def crop(source: Png, x: int, y: int, width: int, height: int) -> Png:
    pixels = bytearray()
    for row in range(y, y + height):
        start = (row * source.width + x) * 3
        pixels.extend(source.pixels[start : start + width * 3])
    return Png(width, height, pixels)


def generate(root: Path) -> None:
    icon = read_png(root / "assets/icon/icon.png")
    metadata = root / "fastlane/metadata"
    play_images = metadata / "android/en-US/images"

    # App Store accepts the existing square icon directly. It is already
    # opaque RGB and 1024x1024, so retaining the source bytes avoids a lossy
    # round trip for the marketing icon.
    marketing_icon = metadata / "app_icon.png"
    marketing_icon.parent.mkdir(parents=True, exist_ok=True)
    marketing_icon.write_bytes((root / "assets/icon/icon.png").read_bytes())

    write_png(play_images / "icon.png", resize(icon, 512, 512))

    # Build a simple opaque landscape graphic from the same icon artwork. A
    # center crop keeps the board mark readable without introducing a second
    # background or a transparent border.
    feature = crop(icon, 0, (icon.height - 500) // 2, icon.width, 500)
    write_png(play_images / "featureGraphic.png", feature)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="repository root (defaults to the parent of dev/)",
    )
    args = parser.parse_args()
    generate(args.root.resolve())


if __name__ == "__main__":
    main()
