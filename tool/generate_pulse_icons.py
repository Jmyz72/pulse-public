#!/usr/bin/env python3

import math
import os
import struct
import subprocess
import zlib


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

IOS_ICON_DIR = os.path.join(
    ROOT,
    "ios",
    "Runner",
    "Assets.xcassets",
    "AppIcon.appiconset",
)
ANDROID_ICON_DIR = os.path.join(
    ROOT,
    "android",
    "app",
    "src",
    "main",
    "res",
)
MASTER_ICON_PATH = os.path.join(ROOT, "assets", "branding", "pulse_app_icon.png")

IOS_ICONS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

ANDROID_ICONS = {
    os.path.join("mipmap-mdpi", "ic_launcher.png"): 48,
    os.path.join("mipmap-hdpi", "ic_launcher.png"): 72,
    os.path.join("mipmap-xhdpi", "ic_launcher.png"): 96,
    os.path.join("mipmap-xxhdpi", "ic_launcher.png"): 144,
    os.path.join("mipmap-xxxhdpi", "ic_launcher.png"): 192,
}


def clamp(value, minimum=0.0, maximum=1.0):
    return max(minimum, min(maximum, value))


def smoothstep(edge0, edge1, x):
    if edge0 == edge1:
        return 0.0
    t = clamp((x - edge0) / (edge1 - edge0))
    return t * t * (3.0 - 2.0 * t)


def mix(a, b, t):
    return tuple(a[i] * (1.0 - t) + b[i] * t for i in range(len(a)))


def alpha_over(base, overlay):
    br, bg, bb, ba = base
    or_, og, ob, oa = overlay
    out_a = oa + ba * (1.0 - oa)
    if out_a <= 0.0:
        return (0.0, 0.0, 0.0, 0.0)
    out_r = (or_ * oa + br * ba * (1.0 - oa)) / out_a
    out_g = (og * oa + bg * ba * (1.0 - oa)) / out_a
    out_b = (ob * oa + bb * ba * (1.0 - oa)) / out_a
    return (out_r, out_g, out_b, out_a)


def rgba(color, alpha=1.0):
    return (color[0], color[1], color[2], alpha)


def hex_color(value):
    return (
        ((value >> 16) & 0xFF) / 255.0,
        ((value >> 8) & 0xFF) / 255.0,
        (value & 0xFF) / 255.0,
    )


CYAN = hex_color(0x00E5FF)
CYAN_LIGHT = hex_color(0x1AEAFF)
TEAL = hex_color(0x008B9D)
MAGENTA = hex_color(0xE91E63)
BG = hex_color(0x050C10)
BG_LIGHT = hex_color(0x0A1419)
WHITE = (1.0, 1.0, 1.0)


def rounded_rect_sdf(x, y, cx, cy, width, height, radius):
    qx = abs(x - cx) - width / 2.0 + radius
    qy = abs(y - cy) - height / 2.0 + radius
    ax = max(qx, 0.0)
    ay = max(qy, 0.0)
    outside = math.hypot(ax, ay)
    inside = min(max(qx, qy), 0.0)
    return outside + inside - radius


def circle_distance(x, y, cx, cy, radius):
    return math.hypot(x - cx, y - cy) - radius


def segment_distance(px, py, ax, ay, bx, by):
    vx = bx - ax
    vy = by - ay
    wx = px - ax
    wy = py - ay
    length_sq = vx * vx + vy * vy
    if length_sq <= 1e-9:
        return math.hypot(px - ax, py - ay)
    t = clamp((wx * vx + wy * vy) / length_sq)
    qx = ax + t * vx
    qy = ay + t * vy
    return math.hypot(px - qx, py - qy)


def polyline_distance(px, py, points):
    return min(
        segment_distance(
            px,
            py,
            points[i][0],
            points[i][1],
            points[i + 1][0],
            points[i + 1][1],
        )
        for i in range(len(points) - 1)
    )


def render_sample(u, v):
    diag_t = clamp((u * 0.52) + (v * 0.48))
    color = rgba(mix(CYAN, TEAL, diag_t), 1.0)

    glow_dist = math.hypot(u - 0.24, v - 0.18)
    glow_alpha = clamp(1.0 - glow_dist / 0.65) ** 2 * 0.28
    color = alpha_over(color, rgba(WHITE, glow_alpha))

    magenta_dist = math.hypot(u - 0.08, v - 0.82)
    magenta_alpha = clamp(1.0 - magenta_dist / 0.48) ** 2 * 0.08
    color = alpha_over(color, rgba(MAGENTA, magenta_alpha))

    beam_alpha = clamp((0.72 - abs(u - 0.64)) / 0.18) * 0.08
    color = alpha_over(color, rgba(WHITE, beam_alpha * (1.0 - v * 0.8)))

    outer_border = min(u, 1.0 - u, v, 1.0 - v)
    if outer_border < 0.022:
        alpha = (1.0 - outer_border / 0.022) * 0.12
        color = alpha_over(color, rgba(WHITE, alpha))

    inner_sdf = abs(rounded_rect_sdf(u, v, 0.5, 0.5, 0.72, 0.72, 0.17))
    if inner_sdf < 0.012:
        alpha = (1.0 - inner_sdf / 0.012) * 0.18
        color = alpha_over(color, rgba(WHITE, alpha))

    core_dist = circle_distance(u, v, 0.5, 0.54, 0.22)
    if core_dist <= 0.0:
        center_t = clamp(math.hypot(u - 0.5, v - 0.54) / 0.22)
        core_color = mix(BG_LIGHT, BG, center_t)
        color = alpha_over(color, rgba(core_color, 0.96))
    elif core_dist < 0.015:
        alpha = (1.0 - core_dist / 0.015) * 0.26
        color = alpha_over(color, rgba(CYAN, alpha))

    pulse_points = [
        (0.32, 0.56),
        (0.42, 0.56),
        (0.485, 0.44),
        (0.545, 0.65),
        (0.62, 0.52),
        (0.69, 0.52),
    ]
    pulse_dist = polyline_distance(u, v, pulse_points)
    if pulse_dist < 0.045:
        alpha = (1.0 - pulse_dist / 0.045) * 0.16
        color = alpha_over(color, rgba(CYAN, alpha))
    if pulse_dist < 0.026:
        x_blend = clamp((u - 0.30) / 0.45)
        stroke_color = mix(WHITE, CYAN_LIGHT, x_blend)
        alpha = 1.0 - smoothstep(0.0, 0.026, pulse_dist)
        color = alpha_over(color, rgba(stroke_color, alpha))

    dot_dist = circle_distance(u, v, 0.72, 0.52, 0.043)
    if dot_dist < 0.05:
        alpha = (1.0 - clamp(dot_dist / 0.05)) * 0.28
        color = alpha_over(color, rgba(CYAN, alpha))
    if dot_dist <= 0.0:
        dot_t = clamp(math.hypot(u - 0.72, v - 0.52) / 0.043)
        dot_color = mix(WHITE, CYAN_LIGHT, dot_t)
        color = alpha_over(color, rgba(dot_color, 1.0))

    ping_ring = abs(circle_distance(u, v, 0.72, 0.25, 0.055))
    if ping_ring < 0.012:
        alpha = (1.0 - ping_ring / 0.012) * 0.20
        color = alpha_over(color, rgba(WHITE, alpha))

    ping_dot = circle_distance(u, v, 0.72, 0.25, 0.022)
    if ping_dot <= 0.0:
        color = alpha_over(color, rgba(WHITE, 0.72))

    return color


def render_icon(size, samples=2):
    rows = []

    for y in range(size):
        row = bytearray()
        for x in range(size):
            accum = [0.0, 0.0, 0.0, 0.0]
            for sy in range(samples):
                for sx in range(samples):
                    u = (x + (sx + 0.5) / samples) / size
                    v = (y + (sy + 0.5) / samples) / size
                    sample = render_sample(u, v)
                    for i in range(4):
                        accum[i] += sample[i]
            scale = 1.0 / (samples * samples)
            pixel = [
                int(round(clamp(channel * scale) * 255.0))
                for channel in accum
            ]
            row.extend(pixel)
        rows.append(bytes([0]) + bytes(row))

    raw = b"".join(rows)
    return png_bytes(size, size, raw)


def png_chunk(tag, data):
    return (
        struct.pack("!I", len(data))
        + tag
        + data
        + struct.pack("!I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def png_bytes(width, height, raw_data):
    return b"".join(
        [
            b"\x89PNG\r\n\x1a\n",
            png_chunk(
                b"IHDR",
                struct.pack("!2I5B", width, height, 8, 6, 0, 0, 0),
            ),
            png_chunk(b"IDAT", zlib.compress(raw_data, 9)),
            png_chunk(b"IEND", b""),
        ]
    )


def write_icon(path, size):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as file:
        file.write(render_icon(size))
    print(f"Wrote {path} ({size}x{size})")


def resize_icon(source_path, destination_path, size):
    os.makedirs(os.path.dirname(destination_path), exist_ok=True)
    subprocess.run(
        [
            "sips",
            "-z",
            str(size),
            str(size),
            source_path,
            "--out",
            destination_path,
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    print(f"Resized {destination_path} ({size}x{size})")


def main():
    write_icon(MASTER_ICON_PATH, 1024)

    for filename, size in IOS_ICONS.items():
        destination = os.path.join(IOS_ICON_DIR, filename)
        if size == 1024:
            if destination != MASTER_ICON_PATH:
                resize_icon(MASTER_ICON_PATH, destination, size)
        else:
            resize_icon(MASTER_ICON_PATH, destination, size)

    for relative_path, size in ANDROID_ICONS.items():
        resize_icon(
            MASTER_ICON_PATH,
            os.path.join(ANDROID_ICON_DIR, relative_path),
            size,
        )


if __name__ == "__main__":
    main()
