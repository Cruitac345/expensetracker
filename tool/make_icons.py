#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Генератор иконок приложения для ОС Аврора.

Иконка строится по гайдлайну «Иконки приложений»: основная форма —
суперэллипс, содержимое не выходит за безопасную зону. Размеры 86×86,
108×108, 128×128 и 172×172 соответствуют сеткам домашнего экрана.

Скрипт не требует сторонних библиотек: PNG собирается вручную из zlib.
"""

import math
import struct
import zlib
from pathlib import Path

SIZES = (86, 108, 128, 172)
SUPERSAMPLE = 4

# Палитра совпадает с темой приложения (lib/core/theme/aurora_colors.dart).
GRADIENT_TOP = (0x2B, 0x6C, 0xD8)
GRADIENT_BOTTOM = (0x4B, 0x9F, 0xFF)
GLYPH = (0xFF, 0xFF, 0xFF)

# Показатель степени суперэллипса.
SUPERELLIPSE_N = 4.0

# Доля стороны, отведённая под безопасную зону контента.
SAFE_ZONE = 0.62


def superellipse_mask(x, y, size):
    """Принадлежит ли точка фигуре суперэллипса."""
    half = size / 2.0
    nx = (x - half) / (half * 0.96)
    ny = (y - half) / (half * 0.96)
    return abs(nx) ** SUPERELLIPSE_N + abs(ny) ** SUPERELLIPSE_N <= 1.0


def bars(size):
    """Прямоугольники столбчатой диаграммы внутри безопасной зоны."""
    zone = size * SAFE_ZONE
    left = (size - zone) / 2.0
    bottom = size - left
    width = zone / 5.0
    gap = width / 2.0
    heights = (0.45, 0.72, 1.0)
    result = []
    for index, factor in enumerate(heights):
        x0 = left + index * (width + gap)
        result.append((x0, bottom - zone * factor, x0 + width, bottom))
    return result


def render(size):
    """Возвращает пиксели RGBA для иконки заданного размера."""
    scale = size * SUPERSAMPLE
    rects = bars(scale)
    radius = (rects[0][2] - rects[0][0]) / 2.0

    rows = []
    for y in range(scale):
        row = bytearray()
        for x in range(scale):
            if not superellipse_mask(x + 0.5, y + 0.5, scale):
                row += bytes((0, 0, 0, 0))
                continue

            ratio = y / max(scale - 1, 1)
            color = tuple(
                round(GRADIENT_TOP[i] + (GRADIENT_BOTTOM[i] - GRADIENT_TOP[i]) * ratio)
                for i in range(3)
            )

            for x0, y0, x1, y1 in rects:
                if x0 <= x + 0.5 <= x1 and y0 <= y + 0.5 <= y1:
                    if _in_rounded_top(x + 0.5, y + 0.5, x0, y0, x1, radius):
                        color = GLYPH
                    break

            row += bytes((color[0], color[1], color[2], 255))
        rows.append(bytes(row))

    return downsample(rows, scale, size)


def _in_rounded_top(x, y, x0, y0, x1, radius):
    """Скругление верхних углов столбца."""
    if y > y0 + radius:
        return True
    cx_left = x0 + radius
    cx_right = x1 - radius
    cy = y0 + radius
    if cx_left <= x <= cx_right:
        return True
    cx = cx_left if x < cx_left else cx_right
    return math.hypot(x - cx, y - cy) <= radius


def downsample(rows, scale, size):
    """Усреднение блоков SUPERSAMPLE×SUPERSAMPLE — сглаживание краёв."""
    result = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            totals = [0, 0, 0, 0]
            for dy in range(SUPERSAMPLE):
                source = rows[y * SUPERSAMPLE + dy]
                for dx in range(SUPERSAMPLE):
                    offset = (x * SUPERSAMPLE + dx) * 4
                    alpha = source[offset + 3]
                    totals[0] += source[offset] * alpha
                    totals[1] += source[offset + 1] * alpha
                    totals[2] += source[offset + 2] * alpha
                    totals[3] += alpha
            count = SUPERSAMPLE * SUPERSAMPLE
            alpha = totals[3] / count
            if totals[3] == 0:
                row += bytes((0, 0, 0, 0))
            else:
                row += bytes(
                    (
                        round(totals[0] / totals[3]),
                        round(totals[1] / totals[3]),
                        round(totals[2] / totals[3]),
                        round(alpha),
                    )
                )
        result.append(bytes(row))
    return result


def write_png(path, rows, size):
    raw = b"".join(b"\x00" + row for row in rows)

    def chunk(tag, data):
        body = tag + data
        return (
            struct.pack(">I", len(data))
            + body
            + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)
        )

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


def main():
    target = Path(__file__).resolve().parent.parent / "aurora" / "icons"
    target.mkdir(parents=True, exist_ok=True)
    for size in SIZES:
        write_png(target / f"{size}x{size}.png", render(size), size)
        print(f"icons/{size}x{size}.png")


if __name__ == "__main__":
    main()
