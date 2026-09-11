import sys
import struct
import tempfile
import unittest
import zlib
from pathlib import Path


DEV = Path(__file__).resolve().parent
sys.path.insert(0, str(DEV))

from generate_store_graphics import (  # noqa: E402
    PNG_SIGNATURE,
    Png,
    _chunk,
    generate,
    read_png,
    write_png,
)
from validate_store_assets import check_png  # noqa: E402


def write_rgba_png(path: Path, width: int, height: int, pixels: bytes) -> None:
    if len(pixels) != width * height * 4:
        raise ValueError("invalid RGBA pixel buffer")
    rows = bytearray()
    stride = width * 4
    for y in range(height):
        rows.append(0)
        rows.extend(pixels[y * stride : (y + 1) * stride])
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    path.write_bytes(
        PNG_SIGNATURE
        + _chunk(b"IHDR", header)
        + _chunk(b"IDAT", zlib.compress(bytes(rows)))
        + _chunk(b"IEND", b"")
    )


class StoreAssetPngTests(unittest.TestCase):
    def test_rgba_read_flattens_over_white_and_remembers_source_type(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "source.png"
            write_rgba_png(
                path,
                3,
                1,
                bytes((255, 0, 0, 128, 10, 20, 30, 0, 1, 2, 3, 255)),
            )

            image = read_png(path)

        self.assertEqual(image.color_type, 6)
        self.assertEqual(image.channels, 3)
        self.assertEqual(
            image.pixels,
            bytearray((255, 127, 127, 255, 255, 255, 1, 2, 3)),
        )

    def test_rgb_write_round_trip_preserves_pixels_and_stored_type(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "rgb.png"
            source = Png(2, 1, bytearray((1, 2, 3, 250, 240, 230)))
            write_png(path, source)

            image = read_png(path)

        self.assertEqual(image.color_type, 2)
        self.assertEqual(image.channels, 3)
        self.assertEqual(image.pixels, source.pixels)

    def test_generation_flattens_rgba_source_to_opaque_graphics(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "assets/icon/icon.png"
            source.parent.mkdir(parents=True)
            write_rgba_png(source, 2, 500, bytes((0, 0, 0, 0)) * 1000)

            generate(root)

            for relative, dimensions in (
                ("fastlane/metadata/app_icon.png", (2, 500)),
                ("fastlane/metadata/android/en-US/images/icon.png", (512, 512)),
                (
                    "fastlane/metadata/android/en-US/images/featureGraphic.png",
                    (2, 500),
                ),
            ):
                image = read_png(root / relative)
                self.assertEqual((image.width, image.height), dimensions)
                self.assertEqual(image.color_type, 2)
                self.assertEqual(set(image.pixels), {255})

    def test_validator_rejects_stored_rgba_and_accepts_rgb(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            relative = "capture.png"
            rgba = root / relative
            write_rgba_png(rgba, 1, 1, bytes((0, 0, 0, 0)))
            with self.assertRaisesRegex(SystemExit, "alpha channel"):
                check_png(root, relative, (1, 1))

            write_png(rgba, Png(1, 1, bytearray((255, 255, 255))))
            check_png(root, relative, (1, 1))


if __name__ == "__main__":
    unittest.main()
