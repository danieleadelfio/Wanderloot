"""Generatore degli effetti sonori e delle musiche di Wanderloot (sintesi chiptune, numpy + wave).
Uso: python3 tools/audio.py (dalla root del progetto). Scrive WAV mono 16-bit in assets/audio/."""
import os, wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
RNG = np.random.default_rng(3)


def t(dur):
    return np.arange(int(SR * dur)) / SR


def sweep(f0, f1, dur):
    # fase integrata: frequenza che scorre da f0 a f1 (esponenziale)
    f = f0 * (f1 / f0) ** (t(dur) / dur)
    return np.cumsum(f) / SR


def square(phase, duty=0.5):
    return np.where((phase % 1.0) < duty, 1.0, -1.0)


def triangle(phase):
    return 4.0 * np.abs((phase % 1.0) - 0.5) - 1.0


def noise(dur):
    return RNG.uniform(-1, 1, int(SR * dur))


def env(n, attack=0.005, release=None, curve=3.0):
    x = np.linspace(0, 1, n)
    e = (1 - x) ** curve if release is None else np.ones(n)
    a = int(SR * attack)
    if a > 0:
        e[:a] *= np.linspace(0, 1, a)
    return e


def lowpass(x, k=0.2):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def save(name, x, gain=0.8):
    x = np.clip(x / max(1e-6, np.max(np.abs(x))) * gain, -1, 1)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def note(n):  # MIDI -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)


# --- SFX ---
d = 0.09; save("shoot", square(sweep(1100, 420, d), 0.25) * env(int(SR * d), curve=2.5), 0.45)
d = 0.06; save("enemy_hit", mix(lowpass(noise(d), 0.35) * env(int(SR * d), curve=2), 0.5 * square(sweep(260, 160, d)) * env(int(SR * d))), 0.5)
d = 0.22; save("enemy_die", mix(square(sweep(520, 90, d), 0.5) * env(int(SR * d), curve=1.5), 0.6 * lowpass(noise(d), 0.25) * env(int(SR * d), curve=4)), 0.55)
d = 0.25; ph = sweep(200, 80, d) + 0.02 * np.sin(2 * np.pi * 30 * t(d)); save("player_hurt", square(ph, 0.4) * env(int(SR * d), curve=1.2), 0.7)
seq = [72, 76, 79, 84]; save("level_up", np.concatenate([triangle(np.cumsum(np.full(int(SR * 0.07), note(n))) / SR) * env(int(SR * 0.07), curve=0.8) for n in seq] + [triangle(np.cumsum(np.full(int(SR * 0.25), note(84))) / SR) * env(int(SR * 0.25))]), 0.7)
parts = []
for i, n in enumerate([60, 64, 67, 72, 76, 79]):
    seg = int(SR * 0.08)
    parts.append(np.pad(0.6 * square(np.cumsum(np.full(seg * (8 - i), note(n))) / SR, 0.5) * env(seg * (8 - i), curve=1.5), (seg * i, 0)))
save("extract", mix(*parts), 0.7)
d = 0.9; save("player_death", triangle(sweep(note(60), note(36), d)) * env(int(SR * d), curve=1.0) + 0.3 * lowpass(noise(d), 0.1) * env(int(SR * d), curve=3), 0.75)
clink = lambda: mix(np.sin(2 * np.pi * 1750 * t(0.18)) * env(int(SR * 0.18), curve=5), 0.5 * np.sin(2 * np.pi * 2630 * t(0.12)) * env(int(SR * 0.12), curve=6), 0.4 * noise(0.02) * env(int(SR * 0.02)))
c = clink(); save("craft", mix(c, np.pad(c * 0.8, (int(SR * 0.16), 0))), 0.6)
d = 0.05; save("ui_select", square(np.cumsum(np.full(int(SR * d), 1320.0)) / SR, 0.5) * env(int(SR * d), curve=2), 0.35)


# --- Musica (loop esatti: lunghezza = battute intere) ---
def render(bpm, bars, voices):
    beat = 60.0 / bpm
    total = int(SR * beat * 4 * bars)
    out = np.zeros(total)
    for events, wave_fn, vol in voices:
        for start, length, n in events:
            a = int(SR * start * beat); b = min(total, a + int(SR * length * beat))
            if n is None or a >= total:
                continue
            seg = b - a
            ph = np.cumsum(np.full(seg, note(n))) / SR
            e = np.minimum(1, np.linspace(0, 12, seg)) * np.linspace(1, 0.35, seg)
            e[-int(min(seg, SR * 0.01)):] *= np.linspace(1, 0, int(min(seg, SR * 0.01)))
            out[a:b] += vol * wave_fn(ph) * e
    return out

# Hub: 90 BPM, Am F C G, calmo
prog = [(57, [57, 60, 64]), (53, [53, 57, 60]), (48, [55, 60, 64]), (55, [55, 59, 62])]
bass, arp, lead = [], [], []
melody = [76, None, 74, 72, 71, None, 72, 74, 72, None, 71, 69, 67, None, 69, 71]
for bar in range(8):
    root, chord = prog[bar % 4]
    bass += [(bar * 4, 2, root - 12), (bar * 4 + 2, 2, root - 12)]
    for i in range(8):
        arp.append((bar * 4 + i * 0.5, 0.5, chord[i % 3] + 12))
    if bar >= 4:
        for i in range(4):
            lead.append((bar * 4 + i, 1, melody[((bar - 4) * 4 + i) % 16]))
save("music_hub", render(90, 8, [(bass, triangle, 0.5), (arp, lambda p: square(p, 0.125), 0.12), (lead, triangle, 0.3)]), 0.6)

# Arena: 140 BPM, Dm Bb C A, ritmo incalzante
prog = [50, 46, 48, 45]
bass, lead, hat = [], [], []
riff = [74, 77, 76, 74, 72, 74, None, 69]
for bar in range(8):
    root = prog[bar % 4]
    for i in range(8):
        bass.append((bar * 4 + i * 0.5, 0.45, root - 12 + (12 if i % 4 == 3 else 0)))
    if bar % 2 == 1 or bar >= 4:
        for i, n in enumerate(riff):
            lead.append((bar * 4 + i * 0.5, 0.45, None if n is None else n + (prog[bar % 4] - 50)))
drums = np.zeros(int(SR * 60 / 140 * 32))
step = int(SR * 60 / 140 / 2)
for i in range(64):
    hit = lowpass(noise(0.03), 0.9 if i % 2 else 0.5) * env(int(SR * 0.03), curve=3) * (0.25 if i % 2 else 0.4)
    drums[i * step:i * step + len(hit)] += hit[:len(drums) - i * step]
    if i % 4 == 0:
        kick = np.sin(2 * np.pi * sweep(150, 45, 0.12)) * env(int(SR * 0.12), curve=2) * 0.8
        drums[i * step:i * step + len(kick)] += kick[:len(drums) - i * step]
music = render(140, 8, [(bass, lambda p: square(p, 0.5), 0.28), (lead, lambda p: square(p, 0.25), 0.16)])
save("music_arena", mix(music, drums), 0.6)
# --- raccolta (M5): exp = blip breve che sale, materiali = due note a campanella ---
d = 0.06; save("pickup_exp", triangle(sweep(1300, 2100, d)) * env(int(SR * d), curve=1.8), 0.35)
chime = lambda n, dur: triangle(np.cumsum(np.full(int(SR * dur), note(n))) / SR) * env(int(SR * dur), curve=2.2)
save("pickup_item", mix(chime(88, 0.16), np.pad(chime(95, 0.2), (int(SR * 0.06), 0))), 0.5)
# --- nemici a distanza (M7): schiocco d'arco + sibilo ---
d = 0.16; save("enemy_shoot", mix(triangle(sweep(620, 240, d)) * env(int(SR * d), curve=2.5), 0.35 * lowpass(noise(d), 0.3) * env(int(SR * d), curve=1.5)), 0.45)
# --- Ossario (M7): bordone cupo con dissonanza, campana lontana, battito (loop esatto di 24s) ---
D = 24.0
tt = t(D)
lfo = 0.6 + 0.4 * np.sin(2 * np.pi * tt / 8.0)
drone = lfo * (0.5 * np.sin(2 * np.pi * 55.0 * tt) + 0.28 * np.sin(2 * np.pi * 82.5 * tt) + 0.18 * np.sin(2 * np.pi * 58.25 * tt))
bells = np.zeros(len(tt))
for start in (0.0, 6.0, 12.0, 18.0):
    a = int(SR * start); n = int(SR * 5.5)
    b = t(5.5)
    tone = sum(w * np.sin(2 * np.pi * f * b) for f, w in ((196.0, 0.5), (466.0, 0.25), (741.0, 0.12)))
    bells[a:a + n] += tone * np.exp(-b * 0.9) * 0.35
beat = np.zeros(len(tt))
for i in range(int(D / 1.2)):
    for off, vol in ((0.0, 1.0), (0.22, 0.6)):
        a = int(SR * (i * 1.2 + off)); n = int(SR * 0.16)
        thump = np.sin(2 * np.pi * sweep(70, 38, 0.16)) * env(n, curve=3) * vol * 0.55
        beat[a:a + n] += thump[:max(0, len(beat) - a)]
save("music_ossuary", mix(drone, bells, beat), 0.6)
# --- Boss (M8): comparsa (ruggito gorgogliante), preavviso del salto, impatto ---
d = 1.1
roar = square(sweep(70, 45, d), 0.4) * env(int(SR * d), attack=0.08, curve=1.2) * 0.6
roar = roar + 0.5 * lowpass(noise(d), 0.08) * env(int(SR * d), attack=0.05, curve=1.5)
save("boss_appear", mix(roar, triangle(sweep(140, 60, d)) * env(int(SR * d), curve=2) * 0.4), 0.7)
d = 0.5
save("boss_warn", mix(square(sweep(300, 900, d), 0.25) * env(int(SR * d), attack=0.02, curve=0.8) * 0.35), 0.5)
d = 0.45
thud = np.sin(2 * np.pi * sweep(90, 30, d)) * env(int(SR * d), curve=2.5)
save("boss_slam", mix(thud, 0.7 * lowpass(noise(d), 0.12) * env(int(SR * d), curve=3)), 0.8)
# --- Eventi (M10): inizio evento (tuono lontano), fulmine (schiocco) ---
d = 1.4
rumble = lowpass(noise(d), 0.04) * env(int(SR * d), attack=0.25, curve=1.2)
save("event_start", mix(rumble, 0.4 * triangle(sweep(90, 60, d)) * env(int(SR * d), attack=0.2, curve=1.5)), 0.8)
d = 0.35
crack = lowpass(noise(d), 0.6) * env(int(SR * d), curve=5)
save("lightning", mix(crack, 0.5 * lowpass(noise(d), 0.08) * env(int(SR * d), curve=2)), 0.6)
# --- Consumabili (M10.1): arpeggio breve ascendente ---
parts = []
for i, n in enumerate((72, 76, 79, 84)):
    d = 0.09
    parts.append(np.pad(square(note(n) * t(d), 0.25) * env(int(SR * d), curve=2) * 0.5, (int(SR * 0.055 * i), 0)))
save("power_up", mix(*parts), 0.5)
# --- Pentagramma (M10.2): candela che si spegne (soffio breve) ---
d = 0.25
save("candle_out", mix(lowpass(noise(d), 0.35) * env(int(SR * d), attack=0.02, curve=2.5), 0.3 * np.sin(2 * np.pi * sweep(900, 400, d)) * env(int(SR * d), curve=4)), 0.35)
print("audio:", sorted(os.listdir(OUT)))
# --- Drop di equipaggiamento per rarita' (M11.1): dal rintocco singolo del Comune alla fanfara del Mitico ---
def tone(n, dur, wave=triangle, curve=2.2, vib=0.0):
    ph = np.cumsum(note(n) * (1 + vib * np.sin(2 * np.pi * 5.5 * t(dur)))) / SR
    return wave(ph) * env(int(SR * dur), curve=curve)
def arp(notes, step, dur, wave=triangle, gain=1.0):
    return mix(*[np.pad(tone(n, dur, wave) * gain, (int(SR * step * i), 0)) for i, n in enumerate(notes)])
def shimmer(dur, base=96):
    return mix(*[np.pad(np.sin(2 * np.pi * note(base + k) * t(dur - 0.05 * j)) * env(int(SR * (dur - 0.05 * j)), attack=0.1, curve=1.6) * 0.25, (int(SR * 0.05 * j), 0)) for j, k in enumerate((0, 4, 7, 12))])
def boom(dur, f0=110, f1=40):
    return np.sin(2 * np.pi * sweep(f0, f1, dur)) * env(int(SR * dur), curve=2.0)
save("drop_common", tone(84, 0.18), 0.35)
save("drop_uncommon", arp((79, 86), 0.07, 0.22), 0.42)
save("drop_rare", mix(arp((76, 79, 83, 88), 0.06, 0.25), np.pad(tone(88, 0.5, curve=1.6) * 0.6, (int(SR * 0.18), 0))), 0.5)
save("drop_super_rare", mix(arp((72, 76, 79, 84, 88), 0.06, 0.3), np.pad(shimmer(0.9), (int(SR * 0.2), 0)), np.pad(tone(91, 0.7, curve=1.4) * 0.5, (int(SR * 0.3), 0))), 0.58)
brass = lambda n, d: tone(n, d, lambda p: square(p, 0.3), curve=1.1, vib=0.004) * 0.35
save("drop_legendary", mix(boom(0.8) * 0.8, brass(55, 1.2), brass(62, 1.2), brass(67, 1.2), np.pad(arp((79, 83, 86, 91, 95), 0.07, 0.35), (int(SR * 0.15), 0)), np.pad(shimmer(1.3, 98), (int(SR * 0.4), 0))), 0.7)
pad = lambda n, d: lowpass(sum(square(np.cumsum(np.full(int(SR * d), note(n) * (1 + dt))) / SR, 0.5) for dt in (-0.006, 0.0, 0.006)), 0.08) * env(int(SR * d), attack=0.25, curve=1.0)
save("drop_mythic", mix(boom(1.2, 90, 30), np.pad(boom(0.9, 70, 30) * 0.6, (int(SR * 0.45), 0)), pad(50, 2.2) * 0.5, pad(57, 2.2) * 0.4, pad(62, 2.2) * 0.4, brass(62, 1.6), brass(69, 1.6), np.pad(arp((74, 78, 81, 86, 90, 93, 98), 0.08, 0.4), (int(SR * 0.2), 0)), np.pad(shimmer(1.8, 100), (int(SR * 0.6), 0))), 0.8)
print("drop sounds ok")
# --- Overtime (M11.1): allarme a due toni, gong grave all'ingresso ---
d = 0.9
alarm = mix(*[np.pad(square(np.cumsum(np.full(int(SR * 0.14), note(n))) / SR, 0.4) * env(int(SR * 0.14), curve=0.8) * 0.5, (int(SR * 0.16 * i), 0)) for i, n in enumerate((81, 76, 81, 76))])
save("overtime_warn", alarm, 0.5)
d = 2.0
gong = mix(np.sin(2 * np.pi * sweep(80, 55, d)) * env(int(SR * d), curve=1.3), 0.5 * np.sin(2 * np.pi * 131 * t(d)) * env(int(SR * d), curve=2.2), 0.35 * np.sin(2 * np.pi * 197 * t(d)) * env(int(SR * d), curve=3), 0.4 * lowpass(noise(d), 0.03) * env(int(SR * d), attack=0.05, curve=1.5))
save("overtime_start", gong, 0.8)
print("overtime sounds ok")
