"""Find the probe widget's magenta container background in a screenshot.

Reports the bounding box of each connected magenta region in pixels and points.
No third-party imaging libraries: the PNG is decoded with zlib and the standard filters.
"""
import sys, zlib, struct

def decode_png(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', "not a PNG"
    pos, idat, w = 8, b'', None
    while pos < len(data):
        ln = struct.unpack('>I', data[pos:pos+4])[0]
        typ = data[pos+4:pos+8]
        body = data[pos+8:pos+8+ln]
        if typ == b'IHDR':
            w, h, depth, color = struct.unpack('>IIBB', body[:10])
            assert depth == 8, f"bit depth {depth} unsupported"
            assert color in (2, 6), f"colour type {color} unsupported"
            channels = 3 if color == 2 else 4
        elif typ == b'IDAT':
            idat += body
        elif typ == b'IEND':
            break
        pos += 12 + ln
    raw = zlib.decompress(idat)
    stride = w * channels
    out, prev = [], bytearray(stride)
    p = 0
    for _ in range(h):
        f = raw[p]; p += 1
        line = bytearray(raw[p:p+stride]); p += stride
        if f == 1:
            for i in range(channels, stride): line[i] = (line[i] + line[i-channels]) & 255
        elif f == 2:
            for i in range(stride): line[i] = (line[i] + prev[i]) & 255
        elif f == 3:
            for i in range(stride):
                a = line[i-channels] if i >= channels else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 255
        elif f == 4:
            for i in range(stride):
                a = line[i-channels] if i >= channels else 0
                b = prev[i]; c = prev[i-channels] if i >= channels else 0
                pa, pb, pc = abs(b-c), abs(a-c), abs(a+b-2*c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        out.append(bytes(line)); prev = line
    return w, h, channels, out

MODE = "magenta"

def is_fill(px):
    r, g, b = px[0], px[1], px[2]
    if MODE == 'magenta':
        return r > 180 and g < 90 and b > 180
    # 'bright': the Lock Screen removes the container background and renders vibrant,
    # so the widget shows as a bright, near-neutral patch against the wallpaper.
    lo = min(r, g, b)
    return lo > 150 and (max(r, g, b) - lo) < 60

def regions(w, h, channels, rows, min_side=40):
    seen = [[False]*w for _ in range(h)]
    found = []
    for y in range(h):
        row = rows[y]
        for x in range(w):
            if seen[y][x] or not is_fill(row[x*channels:x*channels+3]):
                continue
            stack, x0, x1, y0, y1, n = [(x, y)], x, x, y, y, 0
            seen[y][x] = True
            while stack:
                cx, cy = stack.pop(); n += 1
                x0, x1 = min(x0, cx), max(x1, cx)
                y0, y1 = min(y0, cy), max(y1, cy)
                for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx, ny = cx+dx, cy+dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] \
                       and is_fill(rows[ny][nx*channels:nx*channels+3]):
                        seen[ny][nx] = True; stack.append((nx, ny))
            bw, bh = x1-x0+1, y1-y0+1
            if bw >= min_side and bh >= min_side:
                found.append((x0, y0, bw, bh, n))
    return found

if __name__ == '__main__':
    path = sys.argv[1]
    scale = float(sys.argv[2]) if len(sys.argv) > 2 else 2.0
    if len(sys.argv) > 3:
        globals()['MODE'] = sys.argv[3]
    crop = [int(v) for v in sys.argv[4].split(',')] if len(sys.argv) > 4 else None
    w, h, ch, rows = decode_png(path)
    if crop:
        cx, cy, cw, chh = crop
        rows = [r[cx*ch:(cx+cw)*ch] for r in rows[cy:cy+chh]]
        w, h = cw, chh
        print(f"cropped to ({cx},{cy}) {cw}x{chh}")
    print(f"image {w}x{h}, {ch} channels, scale {scale:g}, mode {MODE}")
    found = regions(w, h, ch, rows, min_side=20)
    if not found:
        print("no widget-coloured region found")
    for x, y, bw, bh, n in sorted(found, key=lambda r: -r[4]):
        fill = n / (bw*bh)
        print(f"  at ({x},{y})  {bw}x{bh} px  =  {bw/scale:g}x{bh/scale:g} pt   (region {fill:.0%} solid)")
