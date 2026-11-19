"""Makes every Chai Chaos sound effect, ambience and music loop from scratch.

    python tools/make_sounds.py          (needs numpy and ffmpeg)

Everything is synthesised here (no samples, so there is nothing to license):
coins, chimes, egg pops and cracks, a chappal slap, the chowkidar's whistle,
four vehicle horns and engines, waves, wind, a fountain, birds, the sea, and
three dhol and tumbi loops for the bazaar, the zones and events.

It writes:
  assets/sounds/ChaiChaosSounds.ogg   every sound in one file (a "sound sheet"):
                                      upload this ONE file to Roblox
  assets/sounds/sfx/<Name>.ogg        each sound on its own, if you prefer
  src/shared/SoundSheet.luau          where each sound starts in the sheet and
                                      how long it is (the game plays just that part)
"""

import math
import os
import subprocess
import tempfile
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sounds")
SR = 44100
GAP = 0.3  # seconds of silence between sounds in the sheet
rng = np.random.default_rng(2024)


# --------------------------------------------------------------- building blocks
def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def env(dur, attack=0.005, decay=None, hold=0.0):
    """Attack, hold, then an exponential decay to silence by the end."""
    t = t_axis(dur)
    e = np.ones_like(t)
    a = max(1, int(attack * SR))
    e[:a] = np.linspace(0, 1, a)
    start = int((attack + hold) * SR)
    if start < len(t):
        k = decay if decay else (dur - attack - hold) / 5
        e[start:] = np.exp(-(t[start:] - t[start]) / max(k, 1e-4))
    fade = min(len(t), int(0.01 * SR))
    e[-fade:] *= np.linspace(1, 0, fade)
    return e


def tone(freq, dur, kind="sine", phase=0.0):
    """A tone; `freq` may be a number or an array (a sweep)."""
    t = t_axis(dur)
    f = np.broadcast_to(np.asarray(freq, dtype=float), t.shape)
    ph = 2 * np.pi * np.cumsum(f) / SR + phase
    if kind == "sine":
        return np.sin(ph)
    if kind == "square":
        return np.sign(np.sin(ph)) * 0.7
    if kind == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1) - 1
    if kind == "tri":
        return 2 * np.abs(2 * ((ph / (2 * np.pi)) % 1) - 1) - 1
    raise ValueError(kind)


def noise(dur):
    return rng.uniform(-1, 1, int(dur * SR))


def lowpass(x, cutoff):
    """A simple one-pole low-pass filter; `cutoff` may vary over time."""
    c = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1 - np.exp(-2 * np.pi * c / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def bandpass(x, lo, hi):
    return lowpass(highpass(x, lo), hi)


def resonator(x, freq, q=20.0):
    """A two-pole resonant filter (rings at `freq`)."""
    w = 2 * np.pi * np.broadcast_to(np.asarray(freq, dtype=float), x.shape) / SR
    r = np.exp(-w / (2 * q))
    a1, a2 = -2 * r * np.cos(w), r * r
    y = np.zeros_like(x)
    y1 = y2 = 0.0
    for i in range(len(x)):
        y0 = x[i] - a1[i] * y1 - a2[i] * y2
        y[i] = y0
        y2, y1 = y1, y0
    return y * (1 - r)


def pluck(freq, dur, bright=0.5):
    """A plucked string (Karplus-Strong): the tumbi."""
    n = int(dur * SR)
    period = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, period)
    out = np.empty(n)
    blend = 0.5 + bright * 0.49
    idx = 0
    prev = 0.0
    for i in range(n):
        v = buf[idx]
        nv = blend * v + (1 - blend) * prev
        prev = v
        buf[idx] = nv * 0.996
        out[i] = v
        idx = (idx + 1) % period
    return out * env(dur, 0.002, dur / 4)


def place(dst, src, at, gain=1.0):
    """Mixes `src` into `dst` starting at `at` seconds (wrapping round for loops)."""
    i = int(at * SR) % len(dst)
    n = len(src)
    end = i + n
    if end <= len(dst):
        dst[i:end] += src * gain
    else:
        k = len(dst) - i
        dst[i:] += src[:k] * gain
        rest = src[k:]
        while len(rest):
            m = min(len(rest), len(dst))
            dst[:m] += rest[:m] * gain
            rest = rest[m:]


def circular(filt, x, cutoff, *more):
    """Runs a filter as if the sound loops: the end feeds into the start, so a
    looping sound has no click where it wraps round."""
    def twice(v):
        return np.concatenate([v, v]) if np.ndim(v) else v
    return filt(twice(x), twice(cutoff), *[twice(m) for m in more])[len(x):]


def loop_freq(freq, dur):
    """The nearest frequency that fits a whole number of cycles in `dur` (no click at the loop)."""
    return max(1, round(freq * dur)) / dur


def normalise(x, peak=0.9):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def seamless(dur, render):
    """A loop: render() fills a buffer that wraps round, so the end flows into the start."""
    buf = np.zeros(int(dur * SR))
    render(buf)
    return buf


# ------------------------------------------------------------------ drums
def dhol_bass(dur=0.45, pitch=70):
    """The dhol's deep side (dagga): a thumping pitch-dropping boom."""
    t = t_axis(dur)
    f = pitch * (1 + 1.5 * np.exp(-t * 30))
    body = tone(f, dur) * env(dur, 0.002, 0.12)
    thump = lowpass(noise(dur), 400) * env(dur, 0.001, 0.02) * 1.5
    return body + thump


def dhol_treble(dur=0.18):
    """The dhol's thin side (tilli): a sharp crack."""
    crack = bandpass(noise(dur), 1800, 6000) * env(dur, 0.001, 0.025)
    ring = tone(620, dur) * env(dur, 0.001, 0.04) * 0.4
    return crack * 1.2 + ring


def tabla(dur=0.35, freq=330, damp=0.09):
    """A tabla stroke: a pitched ring with a little slap."""
    t = t_axis(dur)
    f = freq * (1 + 0.15 * np.exp(-t * 40))
    ring = (tone(f, dur) + 0.4 * tone(f * 2.02, dur) + 0.2 * tone(f * 3.01, dur)) * env(dur, 0.001, damp)
    slap = bandpass(noise(dur), 900, 4000) * env(dur, 0.001, 0.01) * 0.6
    return ring + slap


def bell(freq, dur=1.0, decay=0.3):
    """A small bell: inharmonic partials that ring and fade."""
    partials = ((1, 1.0), (2.76, 0.5), (5.4, 0.25), (8.93, 0.12))
    out = sum(a * tone(freq * m, dur) * env(dur, 0.001, decay / m ** 0.5) for m, a in partials)
    return out


def chime(notes, step=0.09, dur=0.6, kind="sine", decay=0.18):
    total = step * (len(notes) - 1) + dur
    out = np.zeros(int(total * SR))
    for i, f in enumerate(notes):
        place(out, (tone(f, dur, kind) * 0.7 + tone(f * 2, dur) * 0.2) * env(dur, 0.003, decay), i * step)
    return out


NOTE = {n: 440 * 2 ** ((i - 9) / 12) for i, n in enumerate(("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A",
                                                            "A#", "B"))}


def note(name, octave=4):
    return NOTE[name] * 2 ** (octave - 4)


# ------------------------------------------------------------------ effects
def s_click():
    return tone(2400, 0.05) * env(0.05, 0.001, 0.008) + bandpass(noise(0.05), 2000, 8000) * env(0.05, 0.0005, 0.004)


def s_coin():
    out = np.zeros(int(0.5 * SR))
    place(out, bell(note("B", 5), 0.45, 0.12), 0)
    place(out, bell(note("E", 6), 0.4, 0.14), 0.07)
    return out


def s_sell():
    # cha-ching: the drawer rattles, then a bright till bell
    out = np.zeros(int(0.9 * SR))
    place(out, bandpass(noise(0.12), 1500, 7000) * env(0.12, 0.002, 0.03), 0)
    place(out, bandpass(noise(0.1), 2500, 9000) * env(0.1, 0.002, 0.02), 0.07)
    place(out, bell(note("E", 6), 0.75, 0.25) + bell(note("G#", 6), 0.75, 0.25) * 0.7, 0.14)
    return out


def s_purchase():
    return chime([note("C", 5), note("E", 5), note("G", 5)], 0.07, 0.4)


def s_error():
    out = np.zeros(int(0.36 * SR))
    for k in range(2):
        b = (tone(150, 0.13, "square") * 0.5 + tone(156, 0.13, "saw") * 0.3) * env(0.13, 0.004, 0.06)
        place(out, lowpass(b, 1200), k * 0.17)
    return out


def s_egg_pickup():
    t = t_axis(0.16)
    return tone(300 + 900 * t / 0.16, 0.16) * env(0.16, 0.002, 0.05) + tone(1800, 0.16) * env(0.16, 0.001, 0.01) * 0.3


def s_egg_home():
    out = np.zeros(int(0.7 * SR))
    place(out, lowpass(noise(0.1), 300) * env(0.1, 0.002, 0.03), 0)
    place(out, chime([note("G", 5), note("C", 6)], 0.11, 0.55), 0.04)
    return out


def s_egg_crack():
    out = np.zeros(int(0.45 * SR))
    for k, at in enumerate((0.0, 0.05, 0.11, 0.2)):
        c = bandpass(noise(0.06), 1200 + k * 400, 7000) * env(0.06, 0.0005, 0.008 + k * 0.003)
        place(out, c, at, 1.0 - k * 0.15)
    place(out, lowpass(noise(0.2), 600) * env(0.2, 0.01, 0.06), 0.18, 0.4)
    return out


def s_egg_hatch():
    notes = [note(n, o) for n, o in (("C", 5), ("E", 5), ("G", 5), ("C", 6), ("E", 6), ("G", 6))]
    out = chime(notes, 0.06, 0.7, "tri")
    sparkle = np.zeros(len(out))
    for k in range(10):
        place(sparkle, bell(rng.uniform(2500, 4500), 0.3, 0.06), 0.25 + k * 0.05, 0.25)
    return out + sparkle


def s_treasure():
    # the lid creaks open, then sparkles
    t = t_axis(0.4)
    creak = resonator(noise(0.4) * (0.5 + 0.5 * np.sin(2 * np.pi * 35 * t)), 380 + 200 * t, 12)
    out = np.zeros(int(1.3 * SR))
    place(out, creak * env(0.4, 0.05, 0.15) * 3, 0)
    place(out, chime([note("G", 5), note("B", 5), note("D", 6), note("G", 6)], 0.07, 0.8, "tri"), 0.35)
    for k in range(8):
        place(out, bell(rng.uniform(3000, 5000), 0.3, 0.05), 0.6 + k * 0.06, 0.2)
    return out


def s_bonk():
    # a chappal slap: a sharp flat smack with a little body
    slap = bandpass(noise(0.2), 600, 5000) * env(0.2, 0.0005, 0.018) * 1.5
    body = tone(180 * (1 + np.exp(-t_axis(0.2) * 50)), 0.2) * env(0.2, 0.001, 0.04) * 0.6
    return slap + body


def s_chor_alert():
    # the chowkidar's whistle: two trilling blasts
    out = np.zeros(int(1.05 * SR))
    for k, (at, d) in enumerate(((0.0, 0.32), (0.42, 0.55))):
        t = t_axis(d)
        f = 2900 + 120 * np.sign(np.sin(2 * np.pi * 28 * t))
        w = tone(f, d) + 0.25 * bandpass(noise(d), 2500, 4000)
        place(out, w * env(d, 0.01, None, hold=d - 0.06), at)
    return out


def s_splash():
    d = 0.9
    t = t_axis(d)
    x = lowpass(noise(d), 2500 * np.exp(-t * 3) + 300) * env(d, 0.01, 0.25)
    drops = np.zeros(len(t))
    for k in range(6):
        place(drops, tone(rng.uniform(900, 1600) * (1 + np.exp(-t_axis(0.06) * 60)), 0.06) * env(0.06, 0.001, 0.015),
              0.15 + k * 0.08, 0.3)
    return x + drops


def s_hit():
    d = 0.3
    return tone(90 * (1 + 2 * np.exp(-t_axis(d) * 40)), d) * env(d, 0.001, 0.07) + lowpass(noise(d), 900) * env(
        d, 0.001, 0.03)


def s_crash():
    d = 1.0
    out = lowpass(noise(d), 3000) * env(d, 0.001, 0.12)
    for f in (420, 655, 980, 1310):
        out += 0.35 * tone(f, d) * env(d, 0.001, 0.25)
    for k in range(5):
        place(out, bandpass(noise(0.08), 2000, 8000) * env(0.08, 0.001, 0.02), 0.12 + k * 0.09, 0.5)
    return out


def horn(freqs, dur, kind="saw", cutoff=2500, buzz=0.0):
    t = t_axis(dur)
    out = sum(tone(f * (1 + buzz * np.sin(2 * np.pi * 30 * t)), dur, kind) for f in freqs) / len(freqs)
    return lowpass(out, cutoff) * env(dur, 0.01, None, hold=dur - 0.05)


def s_horn_bike():
    return horn([660, 990], 0.16, "square", 4000)


def s_horn_rickshaw():
    # pon: a nasal, wobbly two-tone squeeze-horn
    d = 0.24
    t = t_axis(d)
    f = 420 * (1 + 0.06 * np.exp(-t * 20))
    x = tone(f, d, "saw") + 0.6 * tone(f * 1.26, d, "saw")
    return resonator(x, 900, 3) * 4 * env(d, 0.008, None, hold=d - 0.05)


def s_horn_taxi():
    return horn([370, 466], 0.42, "saw", 2200)


def s_horn_truck():
    return horn([196, 247, 294], 0.7, "saw", 1500, buzz=0.004) * 1.2


def engine(dur, pulse_hz, tone_hz, rough, cutoff):
    """An engine loop: firing pulses on a low tone, roughened with noise."""
    t = t_axis(dur)
    pulses = np.maximum(0, np.sin(2 * np.pi * pulse_hz * t)) ** 6
    body = tone(loop_freq(tone_hz, dur), dur, "saw") * (0.4 + pulses)
    grit = circular(lowpass, noise(dur), cutoff) * pulses * rough
    return circular(lowpass, body, cutoff) + grit


def s_engine_bike():
    return engine(1.0, 45, 90, 0.8, 2200)


def s_engine_rickshaw():
    return engine(1.0, 14, 56, 1.4, 1500)  # the two-stroke putt-putt


def s_engine_taxi():
    return engine(1.0, 30, 60, 0.5, 1100)


def s_engine_truck():
    return engine(1.0, 10, 40, 1.2, 700)


def s_fuel():
    # glug glug: falling bubbles
    out = np.zeros(int(0.9 * SR))
    for k in range(5):
        d = 0.14
        f = (520 - k * 40) * (1 + 0.6 * t_axis(d) / d)
        place(out, tone(f, d) * env(d, 0.004, 0.04), k * 0.15, 0.8)
    return out


def s_gate_open():
    out = np.zeros(int(1.1 * SR))
    place(out, lowpass(noise(0.12), 1500) * env(0.12, 0.001, 0.03) + tone(140, 0.12) * env(0.12, 0.001, 0.05), 0)
    place(out, bell(note("C", 6), 0.3, 0.06) * 0.4, 0.05)
    place(out, chime([note("C", 5), note("G", 5), note("C", 6), note("E", 6)], 0.08, 0.7, "tri"), 0.18)
    return out


def s_catch():
    d = 0.45
    t = t_axis(d)
    boing = tone(220 * (1 + 0.8 * np.sin(2 * np.pi * 9 * t) * np.exp(-t * 6)) * (1 + t), d) * env(d, 0.003, 0.15)
    out = np.zeros(int(0.8 * SR))
    place(out, boing, 0)
    place(out, chime([note("E", 6), note("A", 6)], 0.06, 0.4), 0.28, 0.6)
    return out


def s_wave():
    d = 1.4
    t = t_axis(d)
    swell = np.sin(np.pi * t / d) ** 2
    return lowpass(noise(d), 400 + 2600 * swell) * swell


def s_rumble():
    d = 1.1
    return lowpass(noise(d), 180) * env(d, 0.05, 0.3) * 3 + lowpass(noise(d), 900) * env(d, 0.001, 0.05)


def s_snowball():
    d = 0.32
    return lowpass(noise(d), 1500) * env(d, 0.001, 0.04) + bandpass(noise(d), 3000, 8000) * env(d, 0.01, 0.06) * 0.4


def s_train_horn():
    return horn([175, 220], 1.3, "saw", 1100, buzz=0.003) * 1.3


def s_crossing_bell():
    out = np.zeros(int(1.4 * SR))
    for k in range(6):
        place(out, bell(1250, 0.4, 0.1), k * 0.22, 0.7)
    return out


def s_upgrade():
    return chime([note("C", 5), note("E", 5), note("G", 5), note("C", 6)], 0.08, 0.6, "tri")


def s_rebirth():
    out = np.zeros(int(2.0 * SR))
    for k, at in enumerate((0.0, 0.18, 0.36)):
        place(out, dhol_bass(), at, 0.9)
    chord = [note("C", 4), note("E", 4), note("G", 4), note("C", 5)]
    pad = sum(tone(f, 1.4, "saw") for f in chord) / 4
    place(out, lowpass(pad, 2500) * env(1.4, 0.05, 0.5), 0.5, 0.7)
    place(out, chime([note("C", 6), note("E", 6), note("G", 6), note("C", 7)], 0.06, 0.8), 0.55, 0.6)
    return out


def s_event_start():
    out = np.zeros(int(1.6 * SR))
    for k in range(8):  # a dhol roll
        place(out, dhol_treble(), k * 0.06, 0.6 + k * 0.05)
    place(out, dhol_bass(), 0.5)
    shehnai = horn([note("D", 5), note("D", 5) * 1.005], 0.9, "saw", 3000, buzz=0.01)
    place(out, shehnai, 0.55, 0.7)
    return out


def s_roll_spin():
    return tone(1800, 0.04) * env(0.04, 0.001, 0.006)


def s_roll_reveal():
    out = np.zeros(int(1.0 * SR))
    chord = [note("G", 4), note("B", 4), note("D", 5), note("G", 5)]
    place(out, sum(tone(f, 0.9, "tri") for f in chord) / 3 * env(0.9, 0.01, 0.3), 0)
    place(out, dhol_bass(), 0)
    return out


def s_wind():
    def render(buf):
        n = len(buf)
        t = np.arange(n) / SR
        dur = n / SR
        gust = 0.6 + 0.4 * np.sin(2 * np.pi * t / dur) * np.sin(2 * np.pi * 2 * t / dur)
        x = noise(dur)
        buf += circular(lowpass, x, 300 + 700 * gust) * gust
    return seamless(6.0, render)


def s_fountain():
    def render(buf):
        dur = len(buf) / SR
        buf += circular(lowpass, circular(highpass, noise(dur), 300), 3500) * 0.35
        for k in range(160):
            d = 0.05
            f = rng.uniform(600, 2200)
            blip = tone(f * (1 + 0.5 * t_axis(d) / d), d) * env(d, 0.002, 0.012)
            place(buf, blip, rng.uniform(0, dur), rng.uniform(0.1, 0.3))
    return seamless(6.0, render)


def s_birds():
    def render(buf):
        dur = len(buf) / SR
        buf += circular(lowpass, noise(dur), 500) * 0.04
        for k in range(14):
            at = rng.uniform(0, dur)
            base = rng.uniform(2200, 4200)
            for j in range(rng.integers(2, 5)):
                d = rng.uniform(0.05, 0.11)
                t = t_axis(d)
                f = base * (1 + 0.25 * np.sin(np.pi * t / d)) * (1 - 0.1 * j)
                place(buf, tone(f, d) * env(d, 0.004, d / 3), at + j * 0.13, 0.35)
    return seamless(6.0, render)


def s_sea():
    def render(buf):
        dur = len(buf) / SR
        t = np.arange(len(buf)) / SR
        swell = 0.35 + 0.65 * np.sin(np.pi * ((t / dur * 2) % 1)) ** 2
        buf += circular(lowpass, noise(dur), 300 + 1400 * swell) * swell
    return seamless(6.0, render)


# -------------------------------------------------------------------- music
def tumbi_riff(buf, bpm, notes, start_beat=0, step=0.5, gain=0.35):
    beat = 60 / bpm
    for i, n in enumerate(notes):
        if n:
            place(buf, pluck(n, 0.45, 0.6), (start_beat + i * step) * beat, gain)


def m_bazaar():
    """A relaxed bhangra chaal on the dhol, with a tumbi riff and a drone."""
    bpm = 100
    bars = 4
    dur = bars * 4 * 60 / bpm

    def render(buf):
        beat = 60 / bpm
        for bar in range(bars):
            b0 = bar * 4
            for at in (0, 1.5, 2, 3.5):  # dha .. dha dha .. : the chaal
                place(buf, dhol_bass(), (b0 + at) * beat, 0.9)
            for at in (0.5, 1, 2.5, 3, 3.75):
                place(buf, dhol_treble(), (b0 + at) * beat, 0.5)
        sa = note("D", 4)
        scale = [sa, sa * 9 / 8, sa * 5 / 4, sa * 3 / 2, sa * 5 / 3, sa * 2]
        riff = [scale[0], 0, scale[2], scale[3], scale[4], 0, scale[3], scale[2],
                scale[0], 0, scale[2], scale[3], scale[5], scale[4], scale[3], 0]
        tumbi_riff(buf, bpm, riff * 2, 0, 0.5)
        drone = (tone(loop_freq(sa / 2, dur), dur, "saw") + tone(loop_freq(sa * 3 / 4, dur), dur, "saw") * 0.6) / 2
        buf += circular(lowpass, drone, 700) * 0.12
    return seamless(dur, render)


def m_zones():
    """Calmer: tabla with a soft tumbi melody and a drone."""
    bpm = 88
    bars = 4
    dur = bars * 4 * 60 / bpm

    def render(buf):
        beat = 60 / bpm
        for bar in range(bars):
            b0 = bar * 4
            for at, f, damp, g in ((0, 110, 0.18, 0.8), (1, 330, 0.08, 0.5), (1.5, 330, 0.06, 0.35),
                                   (2, 110, 0.18, 0.7), (2.5, 330, 0.08, 0.4), (3, 440, 0.05, 0.45),
                                   (3.5, 330, 0.06, 0.35)):
                place(buf, tabla(0.4, f, damp), (b0 + at) * beat, g)
        sa = note("C", 4)
        scale = [sa, sa * 9 / 8, sa * 6 / 5, sa * 3 / 2, sa * 8 / 5, sa * 2]
        melody = [scale[3], 0, scale[2], 0, scale[1], scale[0], 0, 0, scale[2], 0, scale[3], scale[4], scale[3], 0,
                  0, 0]
        tumbi_riff(buf, bpm, melody * 2, 0, 0.5, 0.28)
        drone = tone(loop_freq(sa / 2, dur), dur, "saw") + tone(loop_freq(sa * 3 / 4, dur), dur, "saw") * 0.5
        buf += circular(lowpass, drone, 500) * 0.08
    return seamless(dur, render)


def m_event():
    """Fast and loud: a full bhangra dhol beat and a busy tumbi."""
    bpm = 132
    bars = 4
    dur = bars * 4 * 60 / bpm

    def render(buf):
        beat = 60 / bpm
        for bar in range(bars):
            b0 = bar * 4
            for at in (0, 0.75, 1.5, 2, 2.75, 3.5):
                place(buf, dhol_bass(0.35), (b0 + at) * beat, 0.9)
            for k in range(8):
                place(buf, dhol_treble(), (b0 + k * 0.5 + 0.25) * beat, 0.45)
        sa = note("E", 4)
        scale = [sa, sa * 9 / 8, sa * 5 / 4, sa * 3 / 2, sa * 5 / 3, sa * 2]
        riff = [scale[0], scale[2], scale[3], scale[2], scale[4], scale[3], scale[2], scale[0]] * 4
        tumbi_riff(buf, bpm, riff, 0, 0.5, 0.3)
        drone = tone(loop_freq(sa / 2, dur), dur, "saw")
        buf += circular(lowpass, drone, 600) * 0.1
    return seamless(dur, render)


# Every sound, in the order it goes into the sheet: name -> (maker, peak level)
SOUNDS = {
    "Click": (s_click, 0.6), "Coin": (s_coin, 0.8), "Sell": (s_sell, 0.85), "Purchase": (s_purchase, 0.8),
    "Error": (s_error, 0.7), "EggPickup": (s_egg_pickup, 0.8), "EggHome": (s_egg_home, 0.8),
    "EggCrack": (s_egg_crack, 0.85), "EggHatch": (s_egg_hatch, 0.85), "Treasure": (s_treasure, 0.85),
    "Bonk": (s_bonk, 0.9), "ChorAlert": (s_chor_alert, 0.75), "Splash": (s_splash, 0.85), "Hit": (s_hit, 0.9),
    "Crash": (s_crash, 0.9), "HornBike": (s_horn_bike, 0.8), "HornRickshaw": (s_horn_rickshaw, 0.85),
    "HornTaxi": (s_horn_taxi, 0.85), "HornTruck": (s_horn_truck, 0.9), "EngineBike": (s_engine_bike, 0.6),
    "EngineRickshaw": (s_engine_rickshaw, 0.6), "EngineTaxi": (s_engine_taxi, 0.6),
    "EngineTruck": (s_engine_truck, 0.65), "Fuel": (s_fuel, 0.8), "GateOpen": (s_gate_open, 0.85),
    "Catch": (s_catch, 0.85), "Wave": (s_wave, 0.85), "Rumble": (s_rumble, 0.9), "Snowball": (s_snowball, 0.85),
    "TrainHorn": (s_train_horn, 0.9), "CrossingBell": (s_crossing_bell, 0.7), "Upgrade": (s_upgrade, 0.8),
    "Rebirth": (s_rebirth, 0.9), "EventStart": (s_event_start, 0.9), "RollSpin": (s_roll_spin, 0.5),
    "RollReveal": (s_roll_reveal, 0.85), "Wind": (s_wind, 0.6), "Fountain": (s_fountain, 0.55),
    "Birds": (s_birds, 0.5), "Sea": (s_sea, 0.6), "MusicBazaar": (m_bazaar, 0.8), "MusicBiome": (m_zones, 0.8),
    "MusicEvent": (m_event, 0.85),
}
LOOPED = {"EngineBike", "EngineRickshaw", "EngineTaxi", "EngineTruck", "Wind", "Fountain", "Birds", "Sea",
          "MusicBazaar", "MusicBiome", "MusicEvent"}


def write_wav(path, data):
    pcm = (np.clip(data, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def to_ogg(data, path):
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "x.wav")
        write_wav(wav, data)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "6", path],
                       check=True)


def main():
    os.makedirs(os.path.join(OUT, "sfx"), exist_ok=True)
    sheet, regions, at = [], [], 0.0
    gap = np.zeros(int(GAP * SR))
    for name, (make, peak) in SOUNDS.items():
        data = normalise(make(), peak)
        to_ogg(data, os.path.join(OUT, "sfx", f"{name}.ogg"))
        length = len(data) / SR
        regions.append((name, at, length))
        sheet += [data, gap]
        at += length + GAP
        print(f"{name:16s} {length:5.2f}s")
    to_ogg(np.concatenate(sheet), os.path.join(OUT, "ChaiChaosSounds.ogg"))

    lines = [
        "-- Where each sound is in the sound sheet (assets/sounds/ChaiChaosSounds.ogg):",
        "-- its start and length in seconds.",
        "--",
        "-- GENERATED by tools/make_sounds.py: do not edit by hand.",
        "-- stylua: ignore start",
        "return {",
    ]
    for name, start, length in regions:
        loop = ", looped = true" if name in LOOPED else ""
        lines.append(f"\t{name} = {{ start = {start:.3f}, length = {length:.3f}{loop} }},")
    lines += ["}", "-- stylua: ignore end", ""]
    with open(os.path.join(ROOT, "src", "shared", "SoundSheet.luau"), "w") as f:
        f.write("\n".join(lines))
    print(f"sheet: {at:.1f}s, {len(regions)} sounds")


if __name__ == "__main__":
    main()
