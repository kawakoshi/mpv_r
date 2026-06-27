#!/usr/bin/env python3
import struct
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: pngs-to-ico.py OUTPUT.ico INPUT.png...", file=sys.stderr)
        return 2

    output = Path(sys.argv[1])
    inputs = [Path(path) for path in sys.argv[2:]]
    images = []

    for path in inputs:
        data = path.read_bytes()
        if data[:8] != b"\x89PNG\r\n\x1a\n":
            print(f"not a PNG file: {path}", file=sys.stderr)
            return 1
        width = struct.unpack(">I", data[16:20])[0]
        height = struct.unpack(">I", data[20:24])[0]
        images.append((width, height, data))

    header = struct.pack("<HHH", 0, 1, len(images))
    entries = []
    offset = 6 + (16 * len(images))

    for width, height, data in images:
        entry = struct.pack(
            "<BBBBHHII",
            0 if width >= 256 else width,
            0 if height >= 256 else height,
            0,
            0,
            1,
            32,
            len(data),
            offset,
        )
        entries.append(entry)
        offset += len(data)

    output.write_bytes(header + b"".join(entries) + b"".join(data for _, _, data in images))
    print(f"Created: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
