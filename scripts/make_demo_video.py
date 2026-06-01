from __future__ import annotations

import argparse
import os
import struct
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def write_chunk(handle, tag: bytes, payload: bytes) -> None:
    handle.write(tag)
    handle.write(struct.pack("<I", len(payload)))
    handle.write(payload)
    if len(payload) % 2 == 1:
        handle.write(b"\0")


def make_list(tag: bytes, payload: bytes) -> bytes:
    out = BytesIO()
    out.write(b"LIST")
    out.write(struct.pack("<I", len(payload) + 4))
    out.write(tag)
    out.write(payload)
    if len(payload) % 2 == 1:
      out.write(b"\0")
    return out.getvalue()


def jpeg_bytes(path: Path, size: tuple[int, int], caption: str) -> bytes:
    image = Image.open(path).convert("RGB")
    image.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", size, (246, 248, 252))
    x = (size[0] - image.width) // 2
    y = max(12, (size[1] - image.height) // 2 - 18)
    canvas.paste(image, (x, y))

    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 28)
    except OSError:
        font = ImageFont.load_default()
    text_box = draw.textbbox((0, 0), caption, font=font)
    text_w = text_box[2] - text_box[0]
    draw.rounded_rectangle(
        (24, size[1] - 64, size[0] - 24, size[1] - 18),
        radius=14,
        fill=(255, 255, 255),
        outline=(215, 222, 234),
        width=2,
    )
    draw.text(((size[0] - text_w) // 2, size[1] - 56), caption, fill=(14, 22, 38), font=font)

    output = BytesIO()
    canvas.save(output, format="JPEG", quality=88, optimize=True)
    return output.getvalue()


def write_mjpeg_avi(frames: list[bytes], output: Path, width: int, height: int, fps: int) -> None:
    frame_count = len(frames)
    if frame_count == 0:
        raise ValueError("no frames to encode")
    max_frame = max(len(frame) + (len(frame) % 2) for frame in frames)
    usec_per_frame = int(1_000_000 / fps)

    avih = struct.pack(
        "<IIIIIIIIIIIIIIII",
        usec_per_frame,
        max_frame * fps,
        0,
        0x10,
        frame_count,
        0,
        1,
        max_frame,
        width,
        height,
        0,
        0,
        0,
        0,
        0,
        0,
    )

    strh = struct.pack(
        "<4s4sIHHIIIIIIIIhhhh",
        b"vids",
        b"MJPG",
        0,
        0,
        0,
        0,
        1,
        fps,
        0,
        frame_count,
        max_frame,
        0xFFFFFFFF,
        0,
        0,
        0,
        width,
        height,
    )

    strf = struct.pack(
        "<IiiHH4sIiiII",
        40,
        width,
        height,
        1,
        24,
        b"MJPG",
        max_frame,
        0,
        0,
        0,
        0,
    )

    hdrl_payload = b""
    hdrl_payload += b"avih" + struct.pack("<I", len(avih)) + avih
    strl_payload = b""
    strl_payload += b"strh" + struct.pack("<I", len(strh)) + strh
    strl_payload += b"strf" + struct.pack("<I", len(strf)) + strf
    hdrl_payload += make_list(b"strl", strl_payload)
    hdrl = make_list(b"hdrl", hdrl_payload)

    movi_data = BytesIO()
    offsets: list[tuple[int, int]] = []
    for frame in frames:
        offsets.append((movi_data.tell() + 4, len(frame)))
        write_chunk(movi_data, b"00dc", frame)
    movi = make_list(b"movi", movi_data.getvalue())

    idx = BytesIO()
    for offset, size in offsets:
        idx.write(struct.pack("<4sIII", b"00dc", 0x10, offset, size))
    idx1 = b"idx1" + struct.pack("<I", idx.tell()) + idx.getvalue()

    riff_size = 4 + len(hdrl) + len(movi) + len(idx1)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("wb") as handle:
        handle.write(b"RIFF")
        handle.write(struct.pack("<I", riff_size))
        handle.write(b"AVI ")
        handle.write(hdrl)
        handle.write(movi)
        handle.write(idx1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--frames-dir", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--fps", type=int, default=2)
    parser.add_argument("--width", type=int, default=720)
    parser.add_argument("--height", type=int, default=1280)
    parser.add_argument("--hold", type=int, default=1)
    parser.add_argument("--caption", action="append", default=[])
    args = parser.parse_args()

    frames_dir = Path(args.frames_dir)
    files = sorted(frames_dir.glob("*.jpeg")) + sorted(frames_dir.glob("*.jpg")) + sorted(frames_dir.glob("*.png"))
    if not files:
        raise SystemExit(f"no image frames found in {frames_dir}")

    captions = args.caption or ["知序运行演示"]
    encoded: list[bytes] = []
    for index, path in enumerate(files):
        caption = captions[min(index, len(captions) - 1)]
        frame = jpeg_bytes(path, (args.width, args.height), caption)
        encoded.extend([frame] * max(1, args.hold))

    write_mjpeg_avi(encoded, Path(args.output), args.width, args.height, args.fps)
    print(f"wrote {args.output} ({len(encoded)} frames, {args.fps} fps)")


if __name__ == "__main__":
    main()
