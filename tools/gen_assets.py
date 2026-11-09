# Generates icons + audio for Volly Superstars (run once: python3 tools/gen_assets.py)
import math, os, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = os.path.join(ROOT, "icons")
AUDIO_DIR = os.path.join(ROOT, "audio")
os.makedirs(ICON_DIR, exist_ok=True)
os.makedirs(AUDIO_DIR, exist_ok=True)

# ---------------------------------------------------------------- ICONS
S = 512
def canvas():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

from PIL import ImageChops
def ImageChops_mul(a, b): return ImageChops.multiply(a, b)

BADGE = {
    "transfer": (235, 130, 40), "setting": (90, 110, 170), "team": (50, 110, 245),
    "story": (40, 150, 235), "tournament": (225, 70, 55), "shop": (150, 80, 215),
    "mission": (45, 170, 95), "daily": (215, 70, 110), "back": (90, 100, 150),
}

def badge(glyph, col):
    base = np.zeros((S, S, 4), dtype=np.float32)
    yy, xx = np.mgrid[0:S, 0:S]
    cx = cy = S / 2
    r = S / 2 - 18
    inside = ((xx - cx) ** 2 + (yy - cy) ** 2) <= r * r
    t = np.clip((yy - (cy - r)) / (2 * r), 0, 1)
    light = np.array(col, dtype=np.float32) * 1.25
    dark = np.array(col, dtype=np.float32) * 0.62
    for c in range(3):
        base[..., c] = light[c] * (1 - t) + dark[c] * t
    base[..., 3] = 255
    base = np.clip(base, 0, 255)
    base[~inside] = 0
    img = Image.fromarray(base.astype(np.uint8), "RGBA")
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((cx - r + 6, cy - r + 22, cx + r + 6, cy + r + 22), fill=(0, 0, 0, 90))
    out.alpha_composite(sh)
    out.alpha_composite(img)
    d = ImageDraw.Draw(out)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, 120), width=10)
    gl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(gl).ellipse((cx - r * 0.78, cy - r * 0.92, cx + r * 0.78, cy - r * 0.1), fill=(255, 255, 255, 62))
    out.alpha_composite(gl)
    g = glyph.resize((int(S * 0.6), int(S * 0.6)), Image.LANCZOS)
    ga = g.split()[3]
    olc = tuple(int(v * 0.4) for v in col) + (255,)
    og = Image.new("RGBA", g.size, olc)
    og.putalpha(ga.filter(ImageFilter.MaxFilter(15)))
    grad = np.zeros((g.size[1], g.size[0], 4), np.uint8)
    grad[..., 0:3] = 255
    grad[..., 3] = (np.linspace(110, 0, g.size[1])[:, None] * np.ones((1, g.size[0]))).astype(np.uint8)
    gl2 = Image.fromarray(grad, "RGBA")
    gl2.putalpha(ImageChops_mul(gl2.split()[3], ga))
    g.alpha_composite(gl2)
    gs = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gshadow = Image.new("RGBA", g.size, (0, 0, 0, 110))
    gshadow.putalpha(g.split()[3].point(lambda v: int(v * 0.45)))
    gs.alpha_composite(gshadow, (int(S * 0.2) + 6, int(S * 0.2) + 10))
    out.alpha_composite(gs)
    out.alpha_composite(og, (int(S * 0.2), int(S * 0.2)))
    out.alpha_composite(g, (int(S * 0.2), int(S * 0.2)))
    return out

def save_icon(im, name, size=128):
    if name in BADGE:
        im = badge(im, BADGE[name])
    im.resize((size, size), Image.LANCZOS).save(os.path.join(ICON_DIR, name + ".png"))

def font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except Exception:
        return ImageFont.load_default()

WHITE = (255, 255, 255, 255)
GOLD = (255, 200, 40, 255)
DGOLD = (200, 140, 10, 255)
BLUE = (60, 140, 255, 255)
ORANGE = (255, 140, 40, 255)

def ic_coin():
    im, d = canvas()
    d.ellipse((30, 30, 482, 482), fill=DGOLD)
    d.ellipse((60, 60, 452, 452), fill=GOLD)
    d.ellipse((110, 110, 402, 402), outline=DGOLD, width=22)
    f = font(230)
    d.text((256, 262), "V", fill=DGOLD, font=f, anchor="mm")
    save_icon(im, "coin")

def ic_transfer():
    im, d = canvas()
    d.polygon([(60, 170), (300, 170), (300, 90), (452, 210), (300, 330), (300, 250), (60, 250)], fill=WHITE)
    d.polygon([(452, 340), (212, 340), (212, 260), (60, 380), (212, 500), (212, 420), (452, 420)], fill=ORANGE)
    save_icon(im, "transfer")

def ic_setting():
    im, d = canvas()
    cx = cy = 256
    for k in range(8):
        a = k * math.pi / 4
        pts = []
        for da, r in ((-0.22, 150), (-0.16, 225), (0.16, 225), (0.22, 150)):
            pts.append((cx + r * math.cos(a + da), cy + r * math.sin(a + da)))
        d.polygon(pts, fill=WHITE)
    d.ellipse((cx - 170, cy - 170, cx + 170, cy + 170), fill=WHITE)
    d.ellipse((cx - 80, cy - 80, cx + 80, cy + 80), fill=(0, 0, 0, 0))
    save_icon(im, "setting")

def ic_team():
    im, d = canvas()
    def person(cx, top, sc, col):
        r = 55 * sc
        d.ellipse((cx - r, top, cx + r, top + 2 * r), fill=col)
        d.rounded_rectangle((cx - 95 * sc, top + 2 * r + 12, cx + 95 * sc, top + 2 * r + 190 * sc), radius=int(60 * sc), fill=col)
    person(120, 130, 0.8, (170, 200, 255, 255))
    person(392, 130, 0.8, (170, 200, 255, 255))
    person(256, 90, 1.0, WHITE)
    save_icon(im, "team")

def ic_story():
    im, d = canvas()
    d.polygon([(40, 120), (256, 160), (256, 440), (40, 400)], fill=(80, 150, 255, 255))
    d.polygon([(472, 120), (256, 160), (256, 440), (472, 400)], fill=(120, 190, 255, 255))
    cx, cy = 256, 230
    pts = []
    for k in range(10):
        r = 120 if k % 2 == 0 else 50
        a = -math.pi / 2 + k * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.polygon(pts, fill=GOLD)
    save_icon(im, "story")

def ic_tournament():
    im, d = canvas()
    d.polygon([(130, 60), (382, 60), (360, 240), (290, 310), (222, 310), (152, 240)], fill=GOLD)
    d.arc((40, 70, 170, 220), 90, 270, fill=GOLD, width=26)
    d.arc((342, 70, 472, 220), -90, 90, fill=GOLD, width=26)
    d.rectangle((236, 300, 276, 400), fill=DGOLD)
    d.rounded_rectangle((150, 395, 362, 450), radius=18, fill=DGOLD)
    save_icon(im, "tournament")

def ic_shop():
    im, d = canvas()
    d.rounded_rectangle((90, 110, 330, 420), radius=26, fill=(160, 90, 255, 255))
    d.rounded_rectangle((160, 80, 400, 390), radius=26, fill=(255, 200, 60, 255))
    d.rounded_rectangle((230, 50, 470, 360), radius=26, fill=(255, 255, 255, 255))
    d.ellipse((290, 130, 410, 250), fill=(255, 140, 40, 255))
    save_icon(im, "shop")

def ic_mission():
    im, d = canvas()
    d.rounded_rectangle((90, 60, 422, 460), radius=36, fill=WHITE)
    d.rounded_rectangle((190, 30, 322, 110), radius=20, fill=BLUE)
    for i, y in enumerate((170, 260, 350)):
        d.line([(130, y + 10), (160, y + 40), (215, y - 15)], fill=(40, 190, 90, 255), width=18)
        d.rounded_rectangle((250, y - 10, 380, y + 20), radius=10, fill=(150, 160, 180, 255))
    save_icon(im, "mission")

def ic_daily():
    im, d = canvas()
    d.rounded_rectangle((70, 200, 442, 460), radius=24, fill=(230, 60, 90, 255))
    d.rounded_rectangle((50, 140, 462, 230), radius=20, fill=(255, 100, 120, 255))
    d.rectangle((226, 140, 286, 460), fill=GOLD)
    d.ellipse((130, 40, 260, 150), outline=GOLD, width=26)
    d.ellipse((252, 40, 382, 150), outline=GOLD, width=26)
    save_icon(im, "daily")

def ic_back():
    im, d = canvas()
    d.polygon([(60, 256), (240, 90), (240, 190), (450, 190), (450, 322), (240, 322), (240, 422)], fill=WHITE)
    save_icon(im, "back")

def draw_ball(d, cx, cy, r, base=(255, 255, 255, 255)):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=base)
    col1 = (40, 110, 230, 255)
    col2 = (250, 200, 40, 255)
    w = max(4, int(r * 0.09))
    d.arc((cx - r * 1.5, cy - r * 0.9, cx + r * 0.5, cy + r * 1.1), 300, 60, fill=col1, width=w)
    d.arc((cx - r * 0.5, cy - r * 1.1, cx + r * 1.5, cy + r * 0.9), 120, 240, fill=col2, width=w)
    d.arc((cx - r * 1.0, cy - r * 1.6, cx + r * 1.0, cy + r * 0.4), 20, 160, fill=col1, width=w)
    d.arc((cx - r * 1.0, cy - r * 0.4, cx + r * 1.0, cy + r * 1.6), 200, 340, fill=col2, width=w)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(30, 40, 70, 255), width=max(3, int(r * 0.04)))

def ic_ball():
    im, d = canvas()
    draw_ball(d, 256, 256, 220)
    save_icon(im, "ball")

def ic_logo():
    im, d = canvas()
    draw_ball(d, 256, 256, 230)
    save_icon(im, "logo", 256)

def ic_app():
    # launcher icon 432 (adaptive style) + 192 legacy
    im = Image.new("RGBA", (S, S), (0, 0, 0, 255))
    px = im.load()
    for y in range(S):
        for x in range(S):
            t = y / S
            px[x, y] = (int(20 + 30 * t), int(40 + 60 * (1 - t)), int(110 + 90 * (1 - t)), 255)
    d = ImageDraw.Draw(im)
    draw_ball(d, 256, 215, 150)
    f = font(120)
    d.text((256, 410), "VS", fill=(255, 210, 60, 255), font=f, anchor="mm")
    im.resize((192, 192), Image.LANCZOS).save(os.path.join(ROOT, "icon.png"))
    im.resize((432, 432), Image.LANCZOS).save(os.path.join(ICON_DIR, "app_432.png"))
    # adaptive foreground (transparent bg) and solid background
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(fg)
    draw_ball(d2, 256, 230, 120)
    d2.text((256, 385), "VS", fill=(255, 210, 60, 255), font=font(95), anchor="mm")
    fg.resize((432, 432), Image.LANCZOS).save(os.path.join(ICON_DIR, "app_fg_432.png"))
    bg = Image.new("RGBA", (432, 432), (22, 60, 150, 255))
    bg.save(os.path.join(ICON_DIR, "app_bg_432.png"))

for fn in (ic_coin, ic_transfer, ic_setting, ic_team, ic_story, ic_tournament, ic_shop,
           ic_mission, ic_daily, ic_back, ic_ball, ic_logo, ic_app):
    fn()

# ---------------------------------------------------------------- AUDIO
SR = 22050
def mtof(m): return 440.0 * 2 ** ((m - 69) / 12.0)
def tarr(d): return np.arange(int(SR * d)) / SR

def env(n, a=0.005, d=0.1, s=0.6, r=0.1):
    e = np.ones(n)
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    a_n = max(1, min(a_n, n)); 
    e[:a_n] = np.linspace(0, 1, a_n)
    if d_n > 0 and a_n + d_n < n:
        e[a_n:a_n + d_n] = np.linspace(1, s, d_n)
        e[a_n + d_n:] = s
    r_n = min(r_n, n)
    if r_n > 0:
        e[-r_n:] *= np.linspace(1, 0, r_n)
    return e

def lowpass(x, k):
    # simple one-pole lowpass, k in (0,1]
    y = np.zeros_like(x); acc = 0.0
    for i in range(len(x)):
        acc += k * (x[i] - acc); y[i] = acc
    return y

def marimba(m, dur=0.6, vol=0.5):
    f = mtof(m); t = tarr(dur)
    x = np.sin(2 * np.pi * f * t) * np.exp(-t * 7) + 0.4 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 18) + 0.2 * np.sin(2 * np.pi * f * 9.2 * t) * np.exp(-t * 30)
    return x * vol

def bell(m, dur=1.2, vol=0.4):
    f = mtof(m); t = tarr(dur)
    x = np.sin(2 * np.pi * f * t) * np.exp(-t * 3) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 5) + 0.3 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 8)
    return x * vol

def pluck(m, dur=0.5, vol=0.4):
    f = mtof(m); t = tarr(dur)
    x = np.zeros_like(t)
    for h in range(1, 7):
        x += np.sin(2 * np.pi * f * h * t) / h * np.exp(-t * (4 + h * 3))
    return x * vol

def pad(ms, dur, vol=0.12):
    t = tarr(dur); x = np.zeros_like(t)
    for m in ms:
        for det in (-0.004, 0.0, 0.004):
            f = mtof(m) * (1 + det)
            x += np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2 * t)
    x *= env(len(t), a=0.6, d=0.0, s=1.0, r=0.5)
    return x * vol / max(1, len(ms))

def bass(m, dur=0.5, vol=0.5):
    f = mtof(m); t = tarr(dur)
    x = (np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 2 * t)) * env(len(t), a=0.01, d=0.2, s=0.5, r=0.08)
    return x * vol

def synth(m, dur=0.25, vol=0.25):
    f = mtof(m); t = tarr(dur)
    x = np.sign(np.sin(2 * np.pi * f * t)) * 0.4 + np.sin(2 * np.pi * f * t) * 0.6
    x = lowpass(x, 0.25)
    return x * env(len(t), a=0.005, d=0.1, s=0.4, r=0.06) * vol

def noise(d): return np.random.RandomState(7).uniform(-1, 1, int(SR * d))

def kick(vol=0.9):
    t = tarr(0.28); f = 120 * np.exp(-t * 18) + 42
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 11) * vol

def snare(vol=0.5):
    t = tarr(0.2)
    return (noise(0.2) * np.exp(-t * 22) * 0.8 + np.sin(2 * np.pi * 190 * t) * np.exp(-t * 28) * 0.5) * vol

def hat(vol=0.18, open_=False):
    d = 0.18 if open_ else 0.05
    t = tarr(d); n = noise(d)
    n = n - np.concatenate([[0], n[:-1]])  # highpass-ish
    return n * np.exp(-t * (14 if open_ else 70)) * vol

def shaker(vol=0.12):
    t = tarr(0.09); n = noise(0.09)
    return n * np.exp(-t * 35) * vol * (1 - np.exp(-t * 200))

class Track:
    def __init__(self, seconds):
        self.n = int(SR * seconds)
        self.buf = np.zeros(self.n + SR * 4)
    def add(self, x, at):
        i = int(at * SR)
        if i < 0: return
        j = min(len(self.buf), i + len(x))
        self.buf[i:j] += x[:j - i]
    def finish(self, reverb=0.25):
        b = self.buf
        out = b.copy()
        for dly, g in ((0.11, 0.28), (0.19, 0.2), (0.31, 0.14), (0.47, 0.09)):
            k = int(dly * SR)
            out[k:] += b[:-k] * g * reverb * 3
        # wrap tail for seamless loop
        tail = out[self.n:]
        out = out[:self.n].copy()
        out[:len(tail)] += tail[:len(out)]
        return out

def write_wav(name, x, peak=0.85):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    data = (x * 32767).astype("<i2")
    with wave.open(os.path.join(AUDIO_DIR, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())

CH = [  # (root bass midi, chord tones)
    (45, [57, 60, 64]),   # Am
    (41, [57, 60, 65]),   # F
    (48, [55, 60, 64]),   # C
    (43, [55, 59, 62]),   # G
]
MEL = [
    [(0, 76, 1.5), (1.5, 74, .5), (2, 72, 1), (3, 69, 1)],
    [(0, 72, 1.5), (1.5, 69, .5), (2, 72, 1), (3, 74, 1)],
    [(0, 76, 1), (1, 79, 1), (2, 76, 1.5), (3.5, 74, .5)],
    [(0, 74, 1.5), (1.5, 71, .5), (2, 74, 1), (3, 76, 1)],
]

def music_menu():
    bpm = 96; beat = 60 / bpm; bars = 8
    tr = Track(bars * 4 * beat)
    for bar in range(bars):
        root, tones = CH[(bar // 2) % 4]
        t0 = bar * 4 * beat
        tr.add(pad(tones + [tones[0] + 12], 4 * beat + 0.4), t0)
        for b in (0, 2):
            tr.add(bass(root, 1.6 * beat), t0 + b * beat)
        arp = [tones[0], tones[1], tones[2], tones[1]] * 2
        for k in range(8):
            tr.add(pluck(arp[k] + 12, 0.5, 0.22), t0 + k * 0.5 * beat)
        for n in MEL[(bar // 2) % 4 if bar % 2 == 0 else (bar // 2) % 4]:
            m = n[1] + (12 if bar >= 4 and n[0] == 0 else 0)
            tr.add(marimba(m, 0.9, 0.38) if bar < 4 else bell(m, 1.3, 0.3), t0 + n[0] * beat)
        for k in range(8):
            tr.add(shaker(0.1 if k % 2 == 0 else 0.07), t0 + k * 0.5 * beat)
        if bar % 2 == 0:
            tr.add(kick(0.35), t0); tr.add(kick(0.3), t0 + 2 * beat)
    write_wav("bgm_menu", tr.finish(0.35))

def music_match():
    bpm = 124; beat = 60 / bpm; bars = 8
    tr = Track(bars * 4 * beat)
    for bar in range(bars):
        root, tones = CH[(bar // 2) % 4]
        t0 = bar * 4 * beat
        tr.add(pad(tones, 4 * beat + 0.2, 0.09), t0)
        for k in range(4):
            tr.add(kick(0.8), t0 + k * beat)
            if k in (1, 3): tr.add(snare(0.45), t0 + k * beat)
        for k in range(8):
            tr.add(hat(0.16, open_=(k % 2 == 1)), t0 + k * 0.5 * beat)
            tr.add(bass(root if k % 4 != 3 else root + 12, 0.45 * beat, 0.4), t0 + k * 0.5 * beat)
        arp = [tones[0], tones[1], tones[2], tones[1] + 12]
        for k in range(16):
            tr.add(synth(arp[k % 4] + 12, 0.2, 0.17), t0 + k * 0.25 * beat)
        for n in MEL[(bar // 2) % 4]:
            tr.add(marimba(n[1] + (12 if bar >= 4 else 0), 0.7, 0.45), t0 + n[0] * beat)
    write_wav("bgm_match", tr.finish(0.18))

def sfx_hit():
    t = tarr(0.22)
    x = noise(0.22) * np.exp(-t * 40) * 0.6 + np.sin(2 * np.pi * (180 * np.exp(-t * 14) + 70) * t) * np.exp(-t * 18)
    write_wav("hit", x)

def sfx_pass():
    t = tarr(0.2)
    x = np.sin(2 * np.pi * (130 * np.exp(-t * 10) + 80) * t) * np.exp(-t * 16) + noise(0.2) * np.exp(-t * 60) * 0.25
    write_wav("pass", x)

def sfx_set():
    t = tarr(0.16)
    x = np.sin(2 * np.pi * (320 * np.exp(-t * 12) + 220) * t) * np.exp(-t * 20) * 0.8 + noise(0.16) * np.exp(-t * 70) * 0.15
    write_wav("set", x)

def sfx_spike():
    t = tarr(0.35)
    sweep = np.sin(2 * np.pi * np.cumsum(900 * np.exp(-t * 9) + 100) / SR) * np.exp(-t * 9) * 0.5
    x = noise(0.35) * np.exp(-t * 22) * 0.9 + sweep + np.sin(2 * np.pi * 70 * t) * np.exp(-t * 12)
    write_wav("spike", x)

def sfx_whistle():
    t = tarr(0.7)
    f = 2900 + 120 * np.sin(2 * np.pi * 28 * t)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * (0.8 + 0.2 * np.sin(2 * np.pi * 38 * t)) * env(len(t), a=0.01, d=0, s=1, r=0.1)
    write_wav("whistle", x, 0.6)

def sfx_point():
    tr = Track(1.3)
    for i, m in enumerate((72, 76, 79, 84)):
        tr.add(bell(m, 0.8, 0.5), i * 0.11)
    write_wav("point", tr.finish(0.2)[:int(SR * 1.3)])

def sfx_lose():
    tr = Track(1.4)
    for i, m in enumerate((67, 64, 60)):
        tr.add(marimba(m, 0.8, 0.6), i * 0.2)
    write_wav("lose", tr.finish(0.2)[:int(SR * 1.4)])

def sfx_click():
    t = tarr(0.07)
    write_wav("click", np.sin(2 * np.pi * 900 * t) * np.exp(-t * 60) + np.sin(2 * np.pi * 1800 * t) * np.exp(-t * 80) * 0.4)

def sfx_coin():
    tr = Track(0.9)
    tr.add(bell(88, 0.5, 0.6), 0.0); tr.add(bell(95, 0.7, 0.6), 0.08)
    write_wav("coin", tr.finish(0.1)[:int(SR * 0.9)])

def sfx_card():
    t = tarr(0.4)
    n = noise(0.4); sw = np.sin(2 * np.pi * np.cumsum(300 + 1800 * t) / SR) * 0.3
    write_wav("card", (n * 0.35 + sw) * np.exp(-t * 6) * (1 - np.exp(-t * 60)))

def sfx_win():
    tr = Track(3.0)
    seq = [(0, 72), (0.18, 76), (0.36, 79), (0.54, 84), (0.9, 79), (1.08, 84), (1.3, 88)]
    for at, m in seq:
        tr.add(bell(m, 1.2, 0.5), at); tr.add(pad([m - 12, m - 8, m - 5], 1.0, 0.1), at)
    write_wav("win", tr.finish(0.3)[:int(SR * 3.0)])

def sfx_cheer():
    t = tarr(1.6)
    n = noise(1.6)
    n = lowpass(n, 0.35)
    x = n * np.sin(np.pi * t / 1.6) ** 1.5 * (0.7 + 0.3 * np.sin(2 * np.pi * 7 * t))
    write_wav("cheer", x, 0.5)

def sfx_crowd():
    n = 6.0
    t = tarr(n)
    x = lowpass(noise(n), 0.22) * (0.5 + 0.25 * np.sin(2 * np.pi * t / n * 2) + 0.15 * np.sin(2 * np.pi * t / n * 5))
    x += 0.12 * np.sin(2 * np.pi * (230 + 8 * np.sin(2 * np.pi * t / n * 3)) * t) * (0.5 + 0.5 * np.sin(2 * np.pi * t / n * 3) ** 2)
    write_wav("crowd", x, 0.5)

for fn in (sfx_crowd, sfx_hit, sfx_pass, sfx_set, sfx_spike, sfx_whistle, sfx_point,
           sfx_lose, sfx_click, sfx_coin, sfx_card, sfx_win, sfx_cheer):
    fn()
print("assets ok")
