# Volly Superstars art generator: player faces, mascot layers, court texture. Developer: Sano
import os, math, random, json, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W = 640
OUT = int(os.environ.get("FACE_OUT", "320"))
SKINS = [(245, 208, 176), (224, 172, 126), (198, 134, 66), (141, 85, 36)]
HAIRS = [(27, 27, 27), (74, 44, 23), (160, 82, 45), (232, 197, 71), (255, 122, 26), (217, 74, 74), (59, 111, 217), (154, 154, 154)]
EYES = [(70, 45, 28), (95, 62, 30), (120, 90, 40), (60, 115, 75), (70, 115, 175), (115, 125, 135)]
JERSEYS = [(47, 123, 255), (224, 69, 58), (245, 245, 245), (255, 196, 58), (58, 196, 122), (176, 92, 255), (30, 40, 70)]
YY, XX = np.mgrid[0:W, 0:W].astype(np.float32) / W

def P(x, y): return (x * W, y * W)
def pts(l): return [P(x, y) for x, y in l]
def lighten(c, a): return tuple(int(min(255, v + (255 - v) * a)) for v in c)
def darken(c, a): return tuple(int(v * (1 - a)) for v in c)
def mix(a, b, t): return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))
def layer(): return Image.new("RGBA", (W, W), (0, 0, 0, 0))
def blur(im, r): return im.filter(ImageFilter.GaussianBlur(r))

def clip_to(im, mask):
    im.putalpha(ImageChops.multiply(im.split()[3], mask))
    return im

def shade(img, cx, cy, sx, sy, hi=0.25, lo=0.3, lo_col=(30, 15, 10)):
    d = ((XX - cx) / sx) ** 2 + ((YY - cy) / sy) ** 2
    light = np.exp(-d)
    a = img.split()[3]
    dark = np.zeros((W, W, 4), np.uint8)
    dark[..., 0:3] = lo_col
    dark[..., 3] = ((1 - light) * lo * 255).astype(np.uint8)
    hl = np.full((W, W, 4), 255, np.uint8)
    hl[..., 3] = (light * hi * 255).astype(np.uint8)
    for arr in (dark, hl):
        ov = Image.fromarray(arr, "RGBA")
        ov.putalpha(ImageChops.multiply(ov.split()[3], a))
        img.alpha_composite(ov)
    return img

def face_poly(cx, cy, w, ht, hb, jaw, p=1.25):
    out = []
    n = 90
    for i in range(n + 1):
        t = math.pi * i / n
        out.append((cx + w * math.cos(t), cy - ht * (math.sin(t) ** 0.85)))
    for i in range(1, n):
        t = math.pi + math.pi * i / n
        s = abs(math.sin(t))
        out.append((cx + w * math.cos(t) * (1 - (1 - jaw) * s ** 1.5), cy + hb * (s ** p)))
    return out

def ell(d, cx, cy, rx, ry, fill, outline=None, width=1):
    d.ellipse([P(cx - rx, cy - ry), P(cx + rx, cy + ry)], fill=fill, outline=outline, width=width)

def hair_tex(lay, col, rnd):
    a = lay.split()[3]
    tex = layer()
    d = ImageDraw.Draw(tex)
    for _ in range(70):
        x = rnd.uniform(0.15, 0.85); y = rnd.uniform(0.0, 0.7)
        L = rnd.uniform(0.08, 0.25); ang = rnd.uniform(-0.6, 0.6) + math.pi / 2
        x2 = x + math.cos(ang) * L * 0.4; y2 = y + math.sin(ang) * L
        c = lighten(col, 0.35) if rnd.random() < 0.55 else darken(col, 0.4)
        d.line([P(x, y), P(x2, y2)], fill=c + (70,), width=rnd.randint(2, 5))
    tex = blur(tex, 1.2)
    clip_to(tex, a)
    lay.alpha_composite(tex)
    return lay

def render(m):
    rnd = random.Random(m["seed"])
    skin = SKINS[m["sk"]]
    hair = HAIRS[m["hc"]]
    fem = m["g"] == 1
    eye_c = EYES[m["eye"]]
    jc = JERSEYS[m["jersey"]]
    cx, cy = 0.5, 0.45
    w = 0.205 + rnd.uniform(-0.012, 0.02) - (0.012 if fem else 0.0)
    ht = 0.2 + rnd.uniform(-0.005, 0.015)
    hb = 0.205 + rnd.uniform(-0.01, 0.025)
    jaw = (0.6 if fem else 0.72) + rnd.uniform(-0.04, 0.06)
    base = layer()
    # ---- shoulders
    sh = layer()
    d = ImageDraw.Draw(sh)
    d.polygon(pts([(0.0, 1.02), (0.06, 0.88), (0.30, 0.775), (0.70, 0.775), (0.94, 0.88), (1.0, 1.02)]), fill=jc + (255,))
    sh = shade(sh, 0.5, 0.88, 0.5, 0.22, 0.18, 0.45, darken(jc, 0.7))
    d = ImageDraw.Draw(sh)
    neck_skin = darken(skin, 0.1)
    d.polygon(pts([(0.40, 0.775), (0.60, 0.775), (0.5, 0.915)]), fill=neck_skin + (255,))
    trim = (255, 255, 255) if sum(jc) < 600 else (30, 40, 70)
    d.line([P(0.385, 0.772), P(0.5, 0.925), P(0.615, 0.772)], fill=trim + (255,), width=int(W * 0.018))
    d.line([P(0.09, 0.86), P(0.20, 0.80)], fill=trim + (200,), width=int(W * 0.014))
    d.line([P(0.91, 0.86), P(0.80, 0.80)], fill=trim + (200,), width=int(W * 0.014))
    # ---- neck
    nk = layer()
    d = ImageDraw.Draw(nk)
    d.polygon(pts([(cx - 0.075, cy + hb * 0.5), (cx + 0.075, cy + hb * 0.5), (cx + 0.092, 0.80), (cx - 0.092, 0.80)]), fill=darken(skin, 0.08) + (255,))
    nk = shade(nk, cx, cy + hb * 0.5, 0.2, 0.2, 0.1, 0.35, darken(skin, 0.6))
    # ---- hair back
    hb_l = layer()
    d = ImageDraw.Draw(hb_l)
    style = m["hs"]
    long_hair = style == 2
    if long_hair:
        d.polygon(pts([(cx - w * 1.15, cy - ht * 0.6), (cx - w * 1.3, 0.96), (cx + w * 1.3, 0.96), (cx + w * 1.15, cy - ht * 0.6)]), fill=hair + (255,))
        ell(d, cx, cy - ht * 0.35, w * 1.22, ht * 1.3, hair + (255,))
    else:
        ell(d, cx, cy - ht * 0.3, w * 1.1, ht * 1.2, hair + (255,))
        if m.get("bun"):
            ell(d, cx, cy - ht * 1.45, w * 0.35, w * 0.35, hair + (255,))
    hb_l = hair_tex(hb_l, hair, rnd)
    # ---- ears
    ea = layer()
    d = ImageDraw.Draw(ea)
    for s in (-1, 1):
        ell(d, cx + s * w * 0.99, cy + 0.03, 0.03, 0.052, darken(skin, 0.05) + (255,))
        ell(d, cx + s * w * 0.99, cy + 0.03, 0.016, 0.032, darken(skin, 0.28) + (255,))
    # ---- face
    fc = layer()
    d = ImageDraw.Draw(fc)
    poly = face_poly(cx, cy, w, ht, hb, jaw)
    d.polygon(pts(poly), fill=skin + (255,))
    fc = shade(fc, cx - 0.02, cy - 0.06, 0.2, 0.26, 0.22, 0.34, darken(skin, 0.62))
    # jaw / chin shadow under
    cs = layer()
    ImageDraw.Draw(cs).polygon(pts([(cx - w * 0.7, cy + hb * 0.78), (cx + w * 0.7, cy + hb * 0.78), (cx + w * 0.4, cy + hb * 1.08), (cx - w * 0.4, cy + hb * 1.08)]), fill=darken(skin, 0.55) + (60,))
    cs = blur(cs, 9)
    fm = Image.new("L", (W, W), 0)
    ImageDraw.Draw(fm).polygon(pts(poly), fill=255)
    clip_to(cs, fm)
    fc.alpha_composite(cs)
    # cheeks blush
    bl = layer()
    d = ImageDraw.Draw(bl)
    blush = (255, 120, 120) if m["sk"] < 3 else (200, 80, 70)
    for s in (-1, 1):
        ell(d, cx + s * w * 0.55, cy + hb * 0.38, 0.05, 0.03, blush + ((70 if fem else 40),))
    bl = blur(bl, 12)
    clip_to(bl, fm)
    fc.alpha_composite(bl)
    if m.get("freckles"):
        fr = layer()
        d = ImageDraw.Draw(fr)
        for _ in range(26):
            s = rnd.choice((-1, 1))
            x = cx + s * rnd.uniform(0.04, 0.17); y = cy + rnd.uniform(0.02, 0.1)
            ell(d, x, y, 0.005, 0.005, darken(skin, 0.4) + (150,))
        clip_to(fr, fm)
        fc.alpha_composite(fr)
    # ---- features
    ft = layer()
    d = ImageDraw.Draw(ft)
    ey = cy + 0.015
    edx = w * 0.47
    ew = 0.06
    eh = 0.034 if fem else 0.03
    if m.get("sleepy"):
        eh *= 0.78
    for s in (-1, 1):
        ex = cx + s * edx
        sock = layer()
        ell(ImageDraw.Draw(sock), ex, ey - 0.004, ew * 1.35, eh * 2.0, darken(skin, 0.4) + (75,))
        sock = blur(sock, 9)
        clip_to(sock, fm)
        ft.alpha_composite(sock)
        eyl = layer()
        de = ImageDraw.Draw(eyl)
        ell(de, ex, ey, ew, eh, (246, 246, 250, 255))
        ir = eh * 1.32
        icx = ex + s * 0.003
        icy = ey - 0.001
        for k in range(12):
            r = ir * (1 - k / 12.0)
            col = mix(darken(eye_c, 0.45), lighten(eye_c, 0.25), k / 12.0)
            ell(de, icx, icy, r, r, col + (255,))
        ell(de, icx, icy, ir * 0.46, ir * 0.46, (8, 8, 12, 255))
        ell(de, icx - ir * 0.34, icy - ir * 0.36, ir * 0.27, ir * 0.27, (255, 255, 255, 245))
        ell(de, icx + ir * 0.3, icy + ir * 0.32, ir * 0.12, ir * 0.12, (255, 255, 255, 170))
        em = Image.new("L", (W, W), 0)
        ImageDraw.Draw(em).ellipse([P(ex - ew, ey - eh), P(ex + ew, ey + eh)], fill=255)
        top = layer()
        ell(ImageDraw.Draw(top), ex, ey - eh * 1.15, ew * 1.2, eh * 0.95, (20, 10, 10, 120))
        top = blur(top, 5)
        eyl.alpha_composite(top)
        clip_to(eyl, em)
        ft.alpha_composite(eyl)
        d = ImageDraw.Draw(ft)
        arc = []
        for i in range(0, 41):
            th = math.pi * i / 40
            arc.append((ex + ew * 1.02 * math.cos(th) * -s * -1, ey - eh * 1.08 * math.sin(th) + (0.002 if True else 0)))
        d.line(pts(arc), fill=(25, 15, 15, 255), width=int(W * (0.0095 if fem else 0.008)), joint="curve")
        if fem:
            ox = ex + s * ew * 1.02
            d.line([P(ox, ey - eh * 0.1), P(ox + s * 0.022, ey - eh * 0.9)], fill=(25, 15, 15, 255), width=int(W * 0.007))
        low = []
        for i in range(8, 33):
            th = math.pi + math.pi * i / 40
            low.append((ex + ew * math.cos(th) * 0.95, ey - eh * 0.85 * math.sin(th)))
        d.line(pts(low), fill=darken(skin, 0.5) + (140,), width=int(W * 0.0045))
        # brows
        bcol = darken(hair, 0.25) if sum(hair) > 300 else hair
        thick = int(W * (0.0085 if fem else 0.0135)) + m.get("brow", 0)
        by = ey - eh * 2.7 - (0.006 if fem else 0.0)
        tilt = m.get("tilt", 0.0)
        bp = [(ex - s * ew * 1.1, by + 0.004 + tilt), (ex - s * ew * 0.2, by - 0.007), (ex + s * ew * 0.9, by - 0.003 - tilt), (ex + s * ew * 1.35, by + 0.012 - tilt)]
        d.line(pts(bp), fill=bcol + (255,), width=thick, joint="curve")
    # nose
    ny = cy + hb * 0.5
    nl = layer()
    dn = ImageDraw.Draw(nl)
    dn.polygon(pts([(cx - 0.012, cy - 0.01), (cx + 0.012, cy - 0.01), (cx + 0.03, ny - 0.01), (cx - 0.03, ny - 0.01)]), fill=darken(skin, 0.5) + (28,))
    nl = blur(nl, 6)
    clip_to(nl, fm)
    ft.alpha_composite(nl)
    d = ImageDraw.Draw(ft)
    for s in (-1, 1):
        ell(d, cx + s * 0.022, ny, 0.011, 0.007, darken(skin, 0.6) + (200,))
        d.arc([P(cx + s * 0.02 - 0.02, ny - 0.02), P(cx + s * 0.02 + 0.02, ny + 0.012)], 200 if s < 0 else -20, 340 if s < 0 else 120, fill=darken(skin, 0.45) + (170,), width=int(W * 0.0045))
    ell(d, cx, ny - 0.016, 0.014, 0.009, lighten(skin, 0.5) + (120,))
    # mouth
    my = cy + hb * 0.78
    lip = mix(skin, (190, 70, 80), 0.45 if fem else 0.3)
    smile = m.get("smile", 1)
    mw = 0.062 + (0.008 if smile == 2 else 0)
    if smile == 2:
        d.polygon(pts([(cx - mw, my - 0.004), (cx + mw, my - 0.004), (cx + mw * 0.7, my + 0.03), (cx, my + 0.04), (cx - mw * 0.7, my + 0.03)]), fill=(60, 15, 20, 255))
        d.polygon(pts([(cx - mw * 0.85, my - 0.002), (cx + mw * 0.85, my - 0.002), (cx + mw * 0.62, my + 0.012), (cx - mw * 0.62, my + 0.012)]), fill=(250, 250, 250, 255))
        ell(d, cx, my + 0.032, 0.026, 0.01, (220, 90, 100, 255))
        d.line(pts([(cx - mw, my - 0.004), (cx - mw * 0.2, my - 0.01), (cx + mw * 0.2, my - 0.01), (cx + mw, my - 0.004)]), fill=darken(lip, 0.45) + (255,), width=int(W * 0.006), joint="curve")
    else:
        curve = 0.016 if smile == 1 else 0.0
        up = []
        for i in range(0, 21):
            t = i / 20.0
            x = cx + mw * (2 * t - 1)
            up.append((x, my - 0.006 * math.sin(math.pi * t) - curve * (2 * t - 1) ** 2))
        lo = []
        for i in range(0, 21):
            t = i / 20.0
            x = cx + mw * (2 * t - 1)
            lo.append((x, my + 0.02 * math.sin(math.pi * t) * (0.9 if smile else 0.7) - curve * (2 * t - 1) ** 2))
        d.polygon(pts(up + lo[::-1]), fill=lip + (255,))
        d.line(pts(up), fill=darken(lip, 0.5) + (255,), width=int(W * 0.0055), joint="curve")
        ell(d, cx, my + 0.015, 0.02, 0.005, lighten(lip, 0.5) + (150,))
    if m.get("beard"):
        bd = layer()
        dd = ImageDraw.Draw(bd)
        bc = darken(hair, 0.15)
        dd.polygon(pts([(cx - w * 0.92, cy + 0.01), (cx - w * 0.8, cy + hb * 0.55), (cx - 0.07, cy + hb * 0.66), (cx, cy + hb * 0.6), (cx + 0.07, cy + hb * 0.66), (cx + w * 0.8, cy + hb * 0.55), (cx + w * 0.92, cy + 0.01), (cx + w * 0.95, cy + hb * 0.9), (cx, cy + hb * 1.04), (cx - w * 0.95, cy + hb * 0.9)]), fill=bc + (235,))
        bd = hair_tex(bd, bc, rnd)
        clip_to(bd, fm)
        ft2 = bd
        # mouth hole
        ell(ImageDraw.Draw(ft2), cx, my + 0.008, mw * 1.05, 0.02, (0, 0, 0, 0))
        fc.alpha_composite(ft2)
        d = ImageDraw.Draw(ft)
        d.line(pts([(cx - mw, my), (cx, my + 0.004), (cx + mw, my)]), fill=darken(lip, 0.5) + (255,), width=int(W * 0.006))
    elif m.get("stubble") and not fem:
        sb = layer()
        dd = ImageDraw.Draw(sb)
        for _ in range(900):
            x = rnd.uniform(cx - w * 0.9, cx + w * 0.9); y = rnd.uniform(cy + hb * 0.45, cy + hb * 1.0)
            dd.point(P(x, y), fill=darken(hair, 0.2) + (110,))
        clip_to(sb, fm)
        fc.alpha_composite(sb)
    if m.get("mole"):
        ell(d, cx + w * 0.4, cy + hb * 0.62, 0.006, 0.006, (60, 30, 20, 230))
    # ---- front hair
    hf = layer()
    d = ImageDraw.Draw(hf)
    fr = m.get("fr", 0.0)
    side = 1 if m["seed"] % 2 == 0 else -1
    top = []
    for i in range(0, 61):
        t = math.pi * i / 60
        r = 1.1
        if style == 1:
            r = 1.08 + (0.42 if i % 6 == 3 else 0.0) + (0.22 if i % 6 in (2, 4) else 0.0)
        top.append((cx + w * r * math.cos(t), cy - ht * 0.15 - (ht * 1.02 + 0.015) * r * math.sin(t) ** 0.8))
    if style == 1:
        low = []
        for i, (xx, yy) in enumerate([(-0.98, -0.05), (-0.85, -0.35), (-0.62, -0.55), (-0.4, -0.38), (-0.2, -0.66), (0.05, -0.45), (0.25, -0.7), (0.45, -0.42), (0.7, -0.55), (0.88, -0.32), (0.98, -0.05)]):
            low.append((cx + xx * w, cy + yy * ht + fr * 0.02))
    else:
        L = [(-0.99, -0.02), (-0.9, -0.38), (-0.55, -0.62 + fr), (-0.12, -0.74 + fr * 0.5), (0.3, -0.5 + fr), (0.62, -0.4 + fr * 0.6), (0.9, -0.38), (0.99, -0.02)]
        if side < 0:
            L = [(-x, y) for x, y in reversed(L)]
        low = [(cx + a * w, cy + b * ht) for a, b in L]
    d.polygon(pts(top + low), fill=hair + (255,))
    for s in (-1, 1):
        d.polygon(pts([(cx + s * w * 1.0, cy - ht * 0.1), (cx + s * w * 1.06, cy + 0.02), (cx + s * w * 0.93, cy + 0.0), (cx + s * w * 0.9, cy - ht * 0.35)]), fill=hair + (255,))
    if long_hair:
        for s in (-1, 1):
            d.polygon(pts([(cx + s * w * 0.99, cy - ht * 0.2), (cx + s * w * 1.12, cy + 0.1), (cx + s * w * 1.2, 0.9), (cx + s * w * 0.98, 0.93), (cx + s * w * 1.0, cy + 0.12)]), fill=hair + (255,))
    hf = hair_tex(hf, hair, rnd)
    hi = layer()
    ImageDraw.Draw(hi).ellipse([P(cx - w * 0.6, cy - ht * 1.12), P(cx + w * 0.2, cy - ht * 0.78)], fill=(255, 255, 255, 38))
    hi = blur(hi, 14)
    clip_to(hi, hf.split()[3])
    hf.alpha_composite(hi)
    if m.get("streak"):
        st = layer()
        ImageDraw.Draw(st).polygon(pts([(cx - 0.05, cy - ht * 1.1), (cx - 0.01, cy - ht * 1.1), (cx + 0.02, cy - ht * 0.5), (cx - 0.03, cy - ht * 0.5)]), fill=(238, 214, 120, 235))
        clip_to(st, hf.split()[3])
        hf.alpha_composite(st)
    if style == 3 or m.get("band"):
        bnd = layer()
        bc = jc if sum(jc) < 650 else (224, 69, 58)
        ImageDraw.Draw(bnd).polygon(pts([(cx - w * 1.05, cy - ht * 0.42), (cx + w * 1.05, cy - ht * 0.42), (cx + w * 1.04, cy - ht * 0.2), (cx - w * 1.04, cy - ht * 0.2)]), fill=bc + (255,))
        bnd = shade(bnd, cx, cy - ht * 0.3, 0.25, 0.04, 0.35, 0.3, darken(bc, 0.6))
        hf.alpha_composite(bnd)
    # accessories
    ac = layer()
    d = ImageDraw.Draw(ac)
    if m.get("glasses"):
        gc = (30, 30, 36, 255)
        for s in (-1, 1):
            ex = cx + s * edx
            d.rounded_rectangle([P(ex - ew * 1.35, ey - eh * 1.9), P(ex + ew * 1.35, ey + eh * 1.9)], radius=int(W * 0.03), outline=gc, width=int(W * 0.008), fill=(200, 230, 255, 38))
        d.line([P(cx - edx + ew * 1.35, ey - eh * 0.4), P(cx + edx - ew * 1.35, ey - eh * 0.4)], fill=gc, width=int(W * 0.007))
    if m.get("mask"):
        mk = layer()
        dm = ImageDraw.Draw(mk)
        dm.polygon(pts([(cx - w * 0.97, cy + 0.0), (cx + w * 0.97, cy + 0.0), (cx + w * 0.75, cy + hb * 0.85), (cx, cy + hb * 1.05), (cx - w * 0.75, cy + hb * 0.85)]), fill=(240, 240, 245, 255))
        mk = shade(mk, cx, cy + hb * 0.5, 0.2, 0.18, 0.1, 0.25, (120, 120, 140))
        for s in (-1, 1):
            ImageDraw.Draw(mk).line([P(cx + s * w * 0.95, cy + 0.0), P(cx + s * w * 0.99, cy + 0.04)], fill=(200, 200, 210, 255), width=int(W * 0.006))
        ac.alpha_composite(mk)
    # ---- compose
    base.alpha_composite(hb_l)
    base.alpha_composite(nk)
    base.alpha_composite(sh)
    if long_hair:
        pass
    base.alpha_composite(ea)
    base.alpha_composite(fc)
    base.alpha_composite(ft)
    base.alpha_composite(hf)
    base.alpha_composite(ac)
    # soft outline
    a = base.split()[3]
    edge = a.filter(ImageFilter.MaxFilter(5))
    ol = Image.new("RGBA", (W, W), (10, 12, 25, 0))
    ol.putalpha(ImageChops.subtract(edge, a).point(lambda v: int(v * 0.7)))
    final = Image.alpha_composite(ol, base)
    return final.resize((OUT, OUT), Image.LANCZOS)

LEG_HC = [4, 0, 3, 0, 1, 0, 0, 7, 1, 1, 0, 1, 0, 3, 7, 0, 3, 7, 0, 3, 7, 3, 0, 0, 5, 1, 7, 3, 1, 1, 1, 0]
# per legend: (hair style, extras)
LEG_X = [
    (1, {}), (0, {"fr": 0.04, "eye": 5}), (0, {"glasses": 1, "eye": 2}), (0, {"freckles": 1}),
    (0, {"streak": 1, "brow": 2}), (0, {"fr": -0.1, "brow": 4}), (0, {"smile": 1}), (0, {"mole": 1}),
    (2, {"beard": 1, "bun": 1}), (0, {"fr": 0.05}), (1, {"brow": 3}), (0, {"eye": 3, "brow": 5, "tilt": 0.004}),
    (1, {"smile": 2, "tilt": -0.004}), (2, {"sleepy": 1, "eye": 2}), (1, {"smile": 2, "brow": 3}), (0, {"eye": 5, "fr": 0.06}),
    (0, {"smile": 2}), (0, {"smile": 0}), (0, {"mask": 1, "eye": 5}), (0, {"band": 1, "smile": 2}),
    (0, {"eye": 3, "smile": 2}), (0, {"smile": 2, "fr": 0.02}), (0, {"brow": 3, "smile": 0}), (1, {"band": 1, "smile": 2}),
    (1, {"smile": 2, "tilt": -0.004}), (0, {"fr": 0.08, "eye": 5}), (0, {"fr": 0.05, "mole": 1}), (0, {"smile": 1}),
    (0, {"sleepy": 1, "eye": 5}), (0, {"smile": 1}), (0, {"smile": 1}), (0, {"smile": 0}),
]

def make_meta():
    rng = random.Random(777)
    metas = []
    for i in range(1132):
        legend = i >= 1100
        star = 1000 <= i < 1100
        if legend:
            g = 0
        elif star:
            g = 0 if (i - 1000) < 50 else 1
        else:
            g = rng.randint(0, 1)
        sk = rng.choices([0, 1, 2, 3], weights=[34, 34, 22, 10])[0]
        if i % 3 == 0:  # Indonesian style names
            sk = rng.choices([1, 2, 3], weights=[40, 40, 20])[0]
        elif i % 3 in (1, 2) and not (legend or star):
            sk = rng.choices([0, 1], weights=[70, 30])[0]
        if legend:
            sk = 0 if rng.random() < 0.8 else 1
        hc = rng.choices([0, 1, 2, 3, 4, 5, 6, 7], weights=[48, 28, 6, 6, 3, 3, 3, 3])[0]
        if legend:
            hc = LEG_HC[i - 1100]
        hs = rng.choices([0, 1, 2, 3], weights=([45, 18, 5, 12] if g == 0 else [30, 6, 50, 14]))[0]
        extras = {}
        if legend:
            hs, extras = LEG_X[i - 1100]
        else:
            extras["eye"] = rng.choices(range(6), weights=[40, 28, 10, 6, 8, 8])[0]
            extras["smile"] = rng.choices([0, 1, 2], weights=[25, 55, 20])[0]
            extras["fr"] = rng.uniform(-0.05, 0.1)
            extras["brow"] = rng.randint(0, 3)
            extras["tilt"] = rng.uniform(-0.004, 0.005)
            if g == 0:
                if rng.random() < 0.16: extras["stubble"] = 1
                if rng.random() < 0.05: extras["beard"] = 1
            if rng.random() < 0.08: extras["glasses"] = 1
            if rng.random() < 0.07: extras["freckles"] = 1
            if rng.random() < 0.05: extras["mole"] = 1
            if g == 1 and hs == 2 and rng.random() < 0.2: extras["bun"] = 1
            if rng.random() < 0.06: extras["sleepy"] = 1
        m = {"g": g, "sk": sk, "hc": hc, "hs": hs, "eye": extras.pop("eye", 0), "jersey": rng.randint(0, 6), "seed": 1000 + i * 7}
        m.update(extras)
        metas.append(m)
    return metas

def faces(limit=None, sheet=False, start=0):
    metas = make_meta()
    os.makedirs(os.path.join(ROOT, "faces"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "data"), exist_ok=True)
    n = limit or len(metas)
    if sheet:
        ids = [0, 1, 2, 3, 4, 5, 1000, 1001, 1060, 1061, 1100, 1101, 1102, 1103, 1108, 1112, 1118, 1105]
        cols = 6
        sh = Image.new("RGBA", (cols * OUT, ((len(ids) + cols - 1) // cols) * OUT), (50, 60, 90, 255))
        for k, i in enumerate(ids):
            f = render(metas[i])
            sh.alpha_composite(f, ((k % cols) * OUT, (k // cols) * OUT))
        sh.convert("RGB").save("/home/claude/faces_sheet.png")
        return
    for i in range(start, n):
        render(metas[i]).save(os.path.join(ROOT, "faces", "f_%d.png" % i), optimize=True)
        if i % 100 == 0:
            print("face", i, flush=True)
    json.dump([{"sk": m["sk"], "hc": m["hc"], "hs": m["hs"]} for m in metas], open(os.path.join(ROOT, "data", "faces.json"), "w"))

if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "faces"
    if what == "sheet":
        faces(sheet=True)
    elif what == "faces":
        a = int(sys.argv[2]) if len(sys.argv) > 2 else 0
        b = int(sys.argv[3]) if len(sys.argv) > 3 else None
        faces(limit=b, start=a)
