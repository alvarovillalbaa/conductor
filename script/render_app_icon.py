#!/usr/bin/env python3
"""Export the repo's rectangle-only SVG icon without third-party dependencies."""

import argparse
import math
from pathlib import Path
import re
import struct
import xml.etree.ElementTree as ET
import zlib


ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "artwork/app-icon.svg"
OUTPUT = ROOT / "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
SIZE = 1024
SAMPLES = 4
SAMPLE_COUNT = SAMPLES * SAMPLES
SVG = "{http://www.w3.org/2000/svg}"


def png_chunk(kind, data):
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )


def render():
    root = ET.parse(MASTER).getroot()
    if root.tag != SVG + "svg" or root.attrib != {
        "width": "1024", "height": "1024", "viewBox": "0 0 1024 1024"
    }:
        raise ValueError("The master must have a 1024-square SVG viewBox.")
    pixels = bytearray(SIZE * SIZE * 3)
    shapes = 0
    for element in root:
        if element.tag in (SVG + "title", SVG + "desc"):
            continue
        allowed = {"x", "y", "width", "height", "rx", "fill"}
        if element.tag != SVG + "rect" or set(element.attrib) - allowed or len(element):
            raise ValueError("Only solid, axis-aligned rounded rectangles are supported.")
        shapes += 1
        if shapes > 32:
            raise ValueError("The icon must remain a small set of simple shapes.")
        x, y, width, height, radius = (
            float(element.get(key, "0")) for key in ("x", "y", "width", "height", "rx")
        )
        if not all(math.isfinite(value) for value in (x, y, width, height, radius)):
            raise ValueError("Rectangle coordinates must be finite.")
        if not (0 <= x < x + width <= SIZE and 0 <= y < y + height <= SIZE):
            raise ValueError("Rectangles must fit completely within the icon.")
        if not 0 <= radius <= min(width, height) / 2:
            raise ValueError("Invalid corner radius.")
        fill = element.get("fill", "")
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", fill):
            raise ValueError("Rectangle fills must be opaque RGB hex colors.")
        color = tuple(int(fill[index:index + 2], 16) for index in (1, 3, 5))
        if shapes == 1:
            if (x, y, width, height, radius) != (0, 0, SIZE, SIZE, 0):
                raise ValueError("The first rectangle must be a full-square opaque background.")
            pixels[:] = bytes(color) * (SIZE * SIZE)
            continue
        for row in range(math.floor(y), math.ceil(y + height)):
            for column in range(math.floor(x), math.ceil(x + width)):
                coverage = 0
                for sample_y in range(SAMPLES):
                    py = row + (sample_y + 0.5) / SAMPLES
                    dy = max(y + radius - py, 0, py - (y + height - radius))
                    for sample_x in range(SAMPLES):
                        px = column + (sample_x + 0.5) / SAMPLES
                        dx = max(x + radius - px, 0, px - (x + width - radius))
                        if x <= px < x + width and y <= py < y + height and dx * dx + dy * dy <= radius * radius:
                            coverage += 1
                offset = (row * SIZE + column) * 3
                for channel in range(3):
                    pixels[offset + channel] = (
                        color[channel] * coverage
                        + pixels[offset + channel] * (SAMPLE_COUNT - coverage)
                        + SAMPLE_COUNT // 2
                    ) // SAMPLE_COUNT
    if shapes < 2:
        raise ValueError("The icon needs foreground artwork.")
    scanlines = b"".join(
        b"\0" + pixels[row * SIZE * 3:(row + 1) * SIZE * 3] for row in range(SIZE)
    )
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
        + png_chunk(b"sRGB", b"\0")
        + png_chunk(b"IDAT", zlib.compress(scanlines, 9))
        + png_chunk(b"IEND", b"")
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="compare the committed PNG without writing")
    args = parser.parse_args()
    image = render()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_bytes() != image:
            raise SystemExit("AppIcon.png differs from the SVG export; run script/render_app_icon.py.")
        print("AppIcon.png matches the SVG export.")
    else:
        OUTPUT.write_bytes(image)
        print("Exported Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
