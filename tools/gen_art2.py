# Mascot layers + court texture. Developer: Sano
import os, math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.makedirs(os.path.join(ROOT, "mascot"), exist_ok=True)
os.makedirs(os.path.join(ROOT, "tex"), exist_ok=True)

def blur(im, r): return im.filter(ImageFilter.GaussianBlur(r))

def radial(size, cx, cy, r, c_light, c_dark, lx=-0.35, ly=-0.4):
    yy, xx = np.mgrid[0:size[1], 0:size[0]].astype(np.float32)
    nx = (xx - cx) / r
    ny = (yy - cy) / r
    d = np.sqrt((nx - lx) ** 2 + (ny - ly) ** 2) / 1.7
    t = np.clip(d, 0, 1)[..., None]
    a = np.array(c_light, np.float32)
    b = np.array(c_dark, np.float32)
    rgb = a * (1 - t) + b * t
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").convert("RGBA")

def mascot():
    S = 640
    cx, cy, r = 320, 340, 270
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    ball = radial((S, S), cx, cy, r, (255, 255, 255), (160, 178, 224))
    pan = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(pan)
    blue = (47, 123, 255, 255)
    yel = (255, 196, 58, 255)
    d.arc([cx - 420, cy - 200, cx + 130, cy + 380], 285, 25, fill=blue, width=64)
    d.arc([cx - 130, cy - 420, cx + 420, cy + 130], 105, 205, fill=yel, width=64)
    d.arc([cx - 300, cy + 40, cx + 300, cy + 560], 200, 340, fill=blue, width=64)
    d.arc([cx - 520, cy - 300, cx + 20, cy + 250], 330, 60, fill=yel, width=56)
    d.arc([cx + 20, cy - 80, cx + 520, cy + 420], 140, 250, fill=yel, width=56)
    seam = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ds = ImageDraw.Draw(seam)
    for bb, a0, a1 in (([cx - 420, cy - 200, cx + 130, cy + 380], 285, 25), ([cx - 130, cy - 420, cx + 420, cy + 130], 105, 205), ([cx - 300, cy + 40, cx + 300, cy + 560], 200, 340)):
        ds.arc(bb, a0, a1, fill=(20, 40, 110, 140), width=70)
        ds.arc(bb, a0, a1, fill=(0, 0, 0, 0), width=60)
    pan.alpha_composite(seam)
    pan.putalpha(ImageChops.multiply(pan.split()[3].point(lambda v: int(v * 0.55)), mask))
    ball.alpha_composite(pan)
    # shading overlay
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    nx = (xx - cx) / r; ny = (yy - cy) / r
    rr = np.sqrt(nx ** 2 + ny ** 2)
    sh = np.zeros((S, S, 4), np.uint8)
    sh[..., 0:3] = (20, 30, 90)
    sh[..., 3] = (np.clip(rr - 0.5, 0, 1) ** 1.6 * 80 + np.clip((nx + ny) * 0.5, 0, 1) * 40).astype(np.uint8)
    shi = Image.fromarray(sh, "RGBA")
    shi.putalpha(ImageChops.multiply(shi.split()[3], mask))
    ball.alpha_composite(shi)
    hl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(hl).ellipse([cx - 190, cy - 230, cx - 40, cy - 130], fill=(255, 255, 255, 150))
    hl = blur(hl, 18)
    hl.putalpha(ImageChops.multiply(hl.split()[3], mask))
    ball.alpha_composite(hl)
    ball.putalpha(mask)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ol = Image.new("RGBA", (S, S), (15, 25, 70, 255))
    ol.putalpha(mask.filter(ImageFilter.MaxFilter(15)))
    out.alpha_composite(ol)
    out.alpha_composite(ball)
    # headband
    band = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    db = ImageDraw.Draw(band)
    db.polygon([(0, cy - 150), (S, cy - 165), (S, cy - 100), (0, cy - 88)], fill=(232, 69, 47, 255))
    db.polygon([(0, cy - 150), (S, cy - 165), (S, cy - 150), (0, cy - 138)], fill=(255, 120, 90, 255))
    band.putalpha(ImageChops.multiply(band.split()[3], mask))
    out.alpha_composite(band)
    knot = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dk = ImageDraw.Draw(knot)
    kx, ky = cx + 262, cy - 118
    dk.ellipse([kx - 26, ky - 26, kx + 26, ky + 26], fill=(232, 69, 47, 255), outline=(15, 25, 70, 255), width=6)
    dk.polygon([(kx, ky), (kx + 60, ky - 40), (kx + 52, ky + 6)], fill=(232, 69, 47, 255), outline=(15, 25, 70, 255))
    dk.polygon([(kx, ky), (kx + 62, ky + 32), (kx + 40, ky + 48)], fill=(210, 55, 38, 255), outline=(15, 25, 70, 255))
    out.alpha_composite(knot)
    # face
    fc = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    df = ImageDraw.Draw(fc)
    for sx in (-1, 1):
        ex, ey = cx + sx * 88, cy - 15
        df.ellipse([ex - 56, ey - 70, ex + 56, ey + 70], fill=(15, 25, 70, 255))
        df.ellipse([ex - 50, ey - 64, ex + 50, ey + 64], fill=(255, 255, 255, 255))
        for k in range(10):
            rr_ = 44 * (1 - k / 11.0)
            col = (int(25 + 70 * k / 10), int(55 + 90 * k / 10), int(130 + 100 * k / 10), 255)
            df.ellipse([ex + sx * 2 - rr_, ey + 10 - rr_ * 1.12, ex + sx * 2 + rr_, ey + 10 + rr_ * 1.12], fill=col)
        df.ellipse([ex + sx * 2 - 22, ey + 10 - 26, ex + sx * 2 + 22, ey + 10 + 26], fill=(8, 10, 24, 255))
        df.ellipse([ex - 26, ey - 22, ex - 4, ey], fill=(255, 255, 255, 255))
        df.ellipse([ex + 12, ey + 24, ex + 26, ey + 38], fill=(255, 255, 255, 190))
        df.arc([ex - 52, ey - 122, ex + 52, ey - 52], 205, 335, fill=(15, 25, 70, 255), width=12)
    df.polygon([(cx - 78, cy + 78), (cx + 78, cy + 78), (cx + 62, cy + 130), (cx + 30, cy + 158), (cx - 30, cy + 158), (cx - 62, cy + 130)], fill=(95, 18, 34, 255), outline=(15, 25, 70, 255))
    df.polygon([(cx - 70, cy + 80), (cx + 70, cy + 80), (cx + 62, cy + 100), (cx - 62, cy + 100)], fill=(255, 255, 255, 255))
    df.ellipse([cx - 38, cy + 118, cx + 38, cy + 164], fill=(240, 100, 120, 255))
    bl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    for sx in (-1, 1):
        ImageDraw.Draw(bl).ellipse([cx + sx * 158 - 40, cy + 62 - 24, cx + sx * 158 + 40, cy + 62 + 24], fill=(255, 110, 130, 150))
    bl = blur(bl, 9)
    out.alpha_composite(bl)
    out.alpha_composite(fc)
    out.save(os.path.join(ROOT, "mascot", "body.png"))
    # blink overlay
    bk = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dk2 = ImageDraw.Draw(bk)
    for sx in (-1, 1):
        ex, ey = cx + sx * 88, cy - 15
        dk2.ellipse([ex - 62, ey - 76, ex + 62, ey + 76], fill=(238, 244, 255, 255))
        dk2.arc([ex - 50, ey - 28, ex + 50, ey + 30], 20, 160, fill=(15, 25, 70, 255), width=12)
    bk.save(os.path.join(ROOT, "mascot", "blink.png"))
    # arm
    A = Image.new("RGBA", (220, 420), (0, 0, 0, 0))
    da = ImageDraw.Draw(A)
    skin = (250, 206, 170, 255)
    da.polygon([(78, 40), (142, 40), (128, 280), (92, 280)], fill=(15, 25, 70, 255))
    da.polygon([(84, 44), (136, 44), (124, 276), (96, 276)], fill=skin)
    da.polygon([(110, 44), (136, 44), (124, 276), (110, 276)], fill=(232, 180, 140, 255))
    da.ellipse([66, 20, 154, 100], fill=(15, 25, 70, 255))
    da.ellipse([72, 26, 148, 94], fill=(255, 255, 255, 255))
    da.rectangle([90, 270, 130, 310], fill=(232, 69, 47, 255), outline=(15, 25, 70, 255), width=5)
    da.ellipse([52, 296, 168, 410], fill=(15, 25, 70, 255))
    da.ellipse([60, 304, 160, 402], fill=(255, 255, 255, 255))
    da.ellipse([70, 312, 130, 366], fill=(240, 244, 255, 255))
    da.arc([84, 330, 140, 392], 200, 330, fill=(150, 165, 210, 255), width=4)
    A.save(os.path.join(ROOT, "mascot", "arm.png"))
    # leg
    L = Image.new("RGBA", (150, 330), (0, 0, 0, 0))
    dl = ImageDraw.Draw(L)
    dl.rectangle([52, 10, 98, 150], fill=(15, 25, 70, 255))
    dl.rectangle([57, 10, 93, 150], fill=skin)
    dl.rectangle([52, 140, 98, 230], fill=(15, 25, 70, 255))
    dl.rectangle([57, 140, 93, 230], fill=(255, 255, 255, 255))
    dl.rectangle([57, 160, 93, 172], fill=(47, 123, 255, 255))
    dl.rectangle([57, 182, 93, 194], fill=(232, 69, 47, 255))
    dl.rounded_rectangle([30, 222, 146, 300], radius=34, fill=(15, 25, 70, 255))
    dl.rounded_rectangle([36, 228, 140, 294], radius=30, fill=(232, 69, 47, 255))
    dl.rounded_rectangle([36, 266, 140, 296], radius=14, fill=(255, 255, 255, 255))
    dl.rounded_rectangle([88, 236, 134, 262], radius=12, fill=(255, 140, 110, 255))
    for k in range(3):
        dl.line([(58 + k * 10, 236 + k * 3), (70 + k * 10, 252 + k * 3)], fill=(255, 255, 255, 255), width=4)
    L.save(os.path.join(ROOT, "mascot", "leg.png"))

def court():
    PX = 100
    Wd, Hd = int(14.5 * PX), int(23 * PX)
    rng = np.random.RandomState(4)
    img = np.zeros((Hd, Wd, 3), np.float32)
    free = np.array((38, 108, 150), np.float32)
    wood = np.array((222, 132, 62), np.float32)
    img[:] = free
    x0, x1 = int((7.25 - 4.5) * PX), int((7.25 + 4.5) * PX)
    z0, z1 = int((11.5 - 9) * PX), int((11.5 + 9) * PX)
    cols = np.arange(Wd)
    plank = (cols // 11)
    tone = (rng.rand(plank.max() + 2) - 0.5) * 22
    tone_col = tone[plank][None, :]
    img[z0:z1, x0:x1] = wood
    img[z0:z1, x0:x1] += tone_col[:, x0:x1][..., None]
    grain = rng.randn(Hd, Wd).astype(np.float32)
    grain = (grain[:, :] * 0.5 + np.roll(grain, 1, 0) * 0.3 + np.roll(grain, 2, 0) * 0.2)
    img[z0:z1, x0:x1] += grain[z0:z1, x0:x1][..., None] * 5
    img[:z0] += grain[:z0][..., None] * 3
    img[z1:] += grain[z1:][..., None] * 3
    img[:, :x0] += grain[:, :x0][..., None] * 3
    img[:, x1:] += grain[:, x1:][..., None] * 3
    # seams
    img[:, ::11] *= 0.93
    # gloss gradient
    yy, xx = np.mgrid[0:Hd, 0:Wd].astype(np.float32)
    g = 1.0 + 0.1 * np.exp(-(((xx - Wd / 2) / (Wd * 0.45)) ** 2 + ((yy - Hd / 2) / (Hd * 0.4)) ** 2))
    img *= g[..., None]
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(im)
    wl = (250, 250, 250)
    lw = 6
    d.rectangle([x0, z0, x1, z1], outline=wl, width=lw)
    for zz in (-3, 0, 3):
        zp = int((11.5 + zz) * PX)
        d.line([(x0, zp), (x1, zp)], fill=wl, width=lw)
    # center circle emblem
    cxp, czp = Wd // 2, int(11.5 * PX)
    d.ellipse([cxp - 110, czp - 110, cxp + 110, czp + 110], outline=(255, 255, 255), width=5)
    im.save(os.path.join(ROOT, "tex", "court.png"), optimize=True)

mascot()
court()
print("art2 ok")
