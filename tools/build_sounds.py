"""Synthesize PETOPIA's chiptune music and sound effects (no samples, no
downloads): assets/audio/music/<track>.wav (seamless loops) and
assets/audio/sfx/<name>.wav. Edit the scores or recipes here and rerun.

Style: soft, kid-friendly chiptune to match the pixel art. Pulse leads are
low-passed, nothing is harsh or loud, every sound fades in and out cleanly.
Usage: python3 tools/build_sounds.py [--only name]
"""
import sys, wave
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT/'assets/audio'
SR = 32000
RNG = np.random.default_rng(7)

# ----------------------------------------------------------------- basics
NOTE = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5, 'F#': 6, 'Gb': 6,
        'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11}
def midi(name):
    pitch, octave = name[:-1], int(name[-1])
    return 12*(octave+1)+NOTE[pitch]
def hz(m): return 440.0*2**((m-69)/12)
def t(n): return np.arange(int(n))/SR

def lowpass(x, cutoff):
    """One-pole low-pass (softens square edges)."""
    a = np.exp(-2*np.pi*cutoff/SR)
    y = np.empty_like(x); acc = 0.0
    # vectorised enough for our lengths via scipy-free recursion in chunks
    for i in range(len(x)):
        acc = (1-a)*x[i]+a*acc; y[i] = acc
    return y

def env(n, attack=0.005, decay=0.0, sustain=1.0, release=0.03):
    """ADSR over n samples (release inside n)."""
    n = int(n); e = np.ones(n)*sustain
    a = min(n, int(attack*SR)); r = min(n-a, int(release*SR)); d = min(n-a-r, int(decay*SR))
    if a: e[:a] = np.linspace(0, 1, a)
    if d: e[a:a+d] = np.linspace(1, sustain, d)
    if r: e[n-r:] *= np.linspace(1, 0, r)
    return e

def pulse(f, n, duty=0.25):
    ph = (t(n)*f) % 1.0
    return np.where(ph < duty, 1.0, -1.0)
def tri(f, n):
    ph = (t(n)*f) % 1.0
    return 4*np.abs(ph-0.5)-1
def sine(f, n): return np.sin(2*np.pi*f*t(n))
def bell(f, n):
    x = t(n)
    return (np.sin(2*np.pi*f*x)+0.35*np.sin(2*np.pi*2*f*x)*np.exp(-x*6)+0.12*np.sin(2*np.pi*3.01*f*x)*np.exp(-x*9))*np.exp(-x*2.6)
def noise(n): return RNG.uniform(-1, 1, int(n))

def pluck(f, n, damp=0.996):
    """Karplus-Strong string (cave harp)."""
    period = max(2, int(SR/f)); buf = RNG.uniform(-1, 1, period); out = np.empty(int(n))
    for i in range(int(n)):
        out[i] = buf[i % period]
        buf[i % period] = damp*0.5*(buf[i % period]+buf[(i+1) % period])
    return out

# --------------------------------------------------------------- sequencer
class Song:
    def __init__(self, bpm, bars, beats=4):
        self.beat = 60.0/bpm; self.length = int(round(bars*beats*self.beat*SR))
        self.mix = np.zeros(self.length+SR*3)
    def at(self, beat): return int(round(beat*self.beat*SR))
    def add(self, start_beat, sig, gain):
        s = self.at(start_beat); self.mix[s:s+len(sig)] += sig*gain
    def render(self, delay=None):
        if delay:
            d, fb = int(delay[0]*SR), delay[1]; y = self.mix.copy()
            for k in range(1, 6): y[d*k:] += self.mix[:-d*k]*(fb**k)
            self.mix = y
        # Wrap the tail onto the start so the loop is seamless.
        out = self.mix[:self.length].copy(); tail = self.mix[self.length:]
        out[:len(tail)] += tail
        return out

def score(text):
    """'E5 q G5 e r q ...' -> [(midi or None, beats)]; w h q e s, dotted with '.'."""
    dur = {'w': 4, 'h': 2, 'q': 1, 'e': 0.5, 's': 0.25}
    toks = text.split(); out = []
    for i in range(0, len(toks), 2):
        name, d = toks[i], toks[i+1]
        beats = dur[d.rstrip('.')]*(1.5 if d.endswith('.') else 1)
        out.append((None if name == 'r' else midi(name), beats))
    return out

CHORD = {'maj': [0, 4, 7], 'min': [0, 3, 7]}
def chord(name):
    root = name.rstrip('m') if not name.endswith('m') or name in ('m',) else name[:-1]
    q = 'min' if name.endswith('m') else 'maj'
    r = midi(root+'3')
    return [r+i for i in CHORD[q]]

def melody(song, notes, voice, gain, shift=0, start=0.0):
    b = start
    for m, beats in notes:
        if m is not None:
            n = beats*song.beat*SR
            f = hz(m+shift)
            if voice == 'pulse': sig = lowpass(pulse(f, n, 0.25), 3200)*env(n, 0.006, 0.12, 0.7, min(0.08, beats*song.beat*0.4))
            elif voice == 'pulse50': sig = lowpass(pulse(f, n, 0.5), 2400)*env(n, 0.006, 0.1, 0.6, min(0.08, beats*song.beat*0.4))
            elif voice == 'bell': sig = bell(f, max(n, 1.4*SR))
            elif voice == 'sine': sig = sine(f, n)*env(n, 0.03, 0.2, 0.75, min(0.15, beats*song.beat*0.5))
            elif voice == 'pluck': sig = pluck(f, max(n, 1.2*SR))*np.exp(-t(max(n, 1.2*SR))*2.5)
            # gentle vibrato-free lead: slight fade so repeated notes separate
            song.add(b, sig, gain)
        b += beats
    return b

def accompany(song, chords, style, gain_bass=0.32, gain_arp=0.09, drums=True, beats=4):
    for i, c in enumerate(chords):
        tones = chord(c); bar = i*beats
        root = tones[0]-12
        if style in ('drive', 'bounce'):
            for k in range(beats*2):
                m = root if k % 2 == 0 else root+12
                n = song.beat*0.5*SR
                song.add(bar+k*0.5, tri(hz(m), n)*env(n, 0.004, 0.05, 0.8, 0.03), gain_bass)
            for k in range(beats*2):
                m = tones[k % 3]+12; n = song.beat*0.45*SR
                song.add(bar+k*0.5, lowpass(pulse(hz(m), n, 0.125), 2600)*env(n, 0.003, 0.08, 0.3, 0.03), gain_arp)
        elif style == 'soft':
            n = song.beat*beats*SR
            song.add(bar, sine(hz(root), n)*env(n, 0.05, 0.6, 0.5, 0.3), gain_bass)
            for k in range(beats*2):
                m = tones[[0, 1, 2, 1][k % 4]]+12
                song.add(bar+k*0.5, bell(hz(m), 1.0*SR), gain_arp)
        elif style == 'cave':
            n = song.beat*beats*SR
            song.add(bar, sine(hz(root), n)*env(n, 0.3, 0.5, 0.6, 0.6), gain_bass)
            for k in range(beats):
                m = tones[[0, 2, 1, 2][k % 4]]+12
                song.add(bar+k, pluck(hz(m), 1.3*SR)*np.exp(-t(1.3*SR)*2.2), gain_arp)
        if drums:
            for k in range(beats):
                if k % 2 == 0: song.add(bar+k, kick(), 0.42)
                else: song.add(bar+k, snare(), 0.16)
            for k in range(beats*2):
                song.add(bar+k*0.5, hat(), 0.05 if k % 2 else 0.07)

def kick():
    n = int(0.18*SR); x = t(n); f = 140*np.exp(-x*28)+48
    return np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-x*16)
def snare():
    n = int(0.16*SR); x = t(n)
    return (lowpass(noise(n), 5000)*0.8+0.3*np.sin(2*np.pi*190*x))*np.exp(-x*22)
def hat():
    n = int(0.05*SR); s = noise(n); s = np.diff(s, prepend=0)
    return s*np.exp(-t(n)*70)

# ------------------------------------------------------------------ music
def build_music():
    tracks = {}
    # Main menu: bright and welcoming (C major, 112 bpm).
    s = Song(112, 16)
    A = 'E5 q G5 q A5 q G5 q D5 q G5 q B5 h C6 q B5 e A5 e E5 q C5 q F5 q E5 q D5 h '
    B = 'A5 q F5 e A5 e C6 q A5 q B5 q G5 e B5 e D6 h G5 q E5 q B4 q E5 q A5 h E5 q C5 q '
    A2 = 'E5 q G5 q A5 q G5 q D5 q G5 q B5 h C6 q B5 e A5 e E5 q C5 q F5 q A5 q C6 h'
    melody(s, score(A+A+B+A2), 'pulse', 0.16, shift=-12)
    accompany(s, ['C', 'G', 'Am', 'F']*2+['F', 'G', 'Em', 'Am']+['C', 'G', 'Am', 'F'], 'drive')
    tracks['menu'] = s.render()
    # My Pet room: cozy music box (F major, 84 bpm).
    s = Song(84, 12)
    A = 'A5 h C6 q A5 q F5 h D5 h D5 q F5 q Bb5 q A5 q G5 h. C5 q '
    A2 = 'A5 h C6 q F6 q E6 h D6 q C6 q Bb5 q A5 q G5 q F5 q G5 w '
    B = 'Bb5 h D6 q Bb5 q C6 h G5 h A5 q C6 q F6 q C6 q F5 w'
    melody(s, score(A+A2+B), 'bell', 0.20, shift=-12)
    accompany(s, ['F', 'Dm', 'Bb', 'C']*2+['Gm', 'C', 'F', 'F'], 'soft', 0.22, 0.05, drums=False)
    tracks['home'] = s.render(delay=(0.36, 0.25))
    # Green Meadows: adventurous (G major, 120 bpm).
    s = Song(120, 16)
    A1 = 'B4 e D5 e G5 q G5 e A5 e B5 q C6 q B5 e A5 e G5 q E5 q D5 q F#5 e A5 e D6 q C6 q B5 h G5 h '
    A2 = 'G5 q E5 e G5 e B5 q G5 q C6 q E6 q D6 q C6 q B5 q A5 q F#5 q A5 q D6 h A5 q F#5 q '
    B1 = 'E5 q G5 q C6 q E6 q D6 q C6 e B5 e A5 h B5 q D6 q F#6 q D6 q E6 h B5 h '
    B2 = 'C6 q E6 q G6 q E6 q D6 q F#6 q A6 q F#6 q G6 q D6 q B5 q D6 q G5 h D5 h'
    melody(s, score(A1+A2+B1+B2), 'pulse', 0.15, shift=-12)
    accompany(s, ['G', 'C', 'D', 'G', 'Em', 'C', 'D', 'D', 'C', 'D', 'Bm', 'Em', 'C', 'D', 'G', 'G'], 'drive')
    tracks['meadow'] = s.render()
    # Hidden Cave and Old Tower: mysterious, echoing (A minor, 72 bpm).
    s = Song(72, 8)
    M = 'A4 h. C5 q F4 h A4 h E5 h. D5 q D5 h B4 h A4 h C5 q E5 q F5 h E5 q D5 q B4 h. G#4 q E4 w'
    melody(s, score(M), 'sine', 0.17)
    accompany(s, ['Am', 'F', 'C', 'G', 'Am', 'F', 'E', 'E'], 'cave', 0.2, 0.08, drums=False)
    tracks['cave'] = s.render(delay=(0.42, 0.35))
    # Catch the Ball: bouncy (D major, 132 bpm).
    s = Song(132, 8)
    P = ('F#5 e A5 e D6 e A5 e F#5 e A5 e D6 q G5 e B5 e D6 e B5 e G5 q B5 q '
         'A5 e C#6 e E6 e C#6 e A5 q E5 q D6 q A5 q F#5 h '
         'B5 e D6 e F#6 e D6 e B5 q F#5 q G5 e B5 e D6 e G6 e D6 q B5 q '
         'A5 e B5 e C#6 e D6 e E6 q C#6 q A5 h. E5 q')
    melody(s, score(P), 'pulse50', 0.15, shift=-12)
    accompany(s, ['D', 'G', 'A', 'D', 'Bm', 'G', 'A', 'A'], 'bounce')
    tracks['play'] = s.render()
    return tracks

# -------------------------------------------------------------------- sfx
def sweep(f0, f1, dur, shape='sine', curve=1.0):
    n = int(dur*SR); k = np.linspace(0, 1, n)**curve
    f = f0+(f1-f0)*k; ph = 2*np.pi*np.cumsum(f)/SR
    if shape == 'sine': return np.sin(ph)
    if shape == 'tri': return 2/np.pi*np.arcsin(np.sin(ph))
    return np.sign(np.sin(ph))*0.6
def notes(seq, voice='pulse', gap=0.0):
    """seq: [(note, seconds)] played one after another."""
    out = []
    for name, d in seq:
        n = int(d*SR); f = hz(midi(name))
        if voice == 'bell': s = bell(f, n)
        elif voice == 'tri': s = tri(f, n)*env(n, 0.003, 0.05, 0.7, 0.04)
        else: s = lowpass(pulse(f, n, 0.25), 3500)*env(n, 0.003, 0.05, 0.6, 0.04)
        out.append(s); out.append(np.zeros(int(gap*SR)))
    return np.concatenate(out)
def fade(x, a=0.004, r=0.03): return x*env(len(x), a, 0, 1, r)
def formant_voice(f0s, vowels, dur, breath=0.05):
    """Tiny cute 'voice' blips: a buzzy source through vowel formants."""
    F = {'a': (800, 1200), 'e': (500, 1900), 'i': (320, 2400), 'o': (500, 900), 'u': (350, 800)}
    n = int(dur*SR); k = np.linspace(0, 1, n)
    f0 = np.interp(k, np.linspace(0, 1, len(f0s)), f0s)
    ph = 2*np.pi*np.cumsum(f0)/SR
    src = sum(np.sin(h*ph)/h for h in range(1, 16))+breath*noise(n)
    out = np.zeros(n); seg = n//len(vowels)
    for j, v in enumerate(vowels):
        a, b = j*seg, (j+1)*seg if j < len(vowels)-1 else n
        piece = src[a:b]; y = np.zeros_like(piece)
        for fc, g in zip(F[v], (1.0, 0.5)):
            # resonant two-pole band-pass
            r = np.exp(-np.pi*120/SR); c = 2*r*np.cos(2*np.pi*fc/SR)
            y1 = y2 = 0.0; band = np.empty_like(piece)
            for i in range(len(piece)):
                yy = piece[i]*(1-r)+c*y1-r*r*y2; y2, y1 = y1, yy; band[i] = yy
            y += band*g
        out[a:b] = y
    return out/np.max(np.abs(out)+1e-9)

def build_sfx():
    S = {}
    # UI
    S['ui_tap'] = fade(sweep(900, 1300, 0.05, 'tri'))*0.5
    S['ui_open'] = fade(notes([('C6', 0.05), ('G6', 0.08)], 'tri'))*0.45
    S['ui_close'] = fade(notes([('G6', 0.05), ('C6', 0.08)], 'tri'))*0.45
    S['ui_toggle'] = fade(sweep(600, 900, 0.06, 'tri'))*0.45
    S['ui_error'] = fade(notes([('E4', 0.08), ('C4', 0.14)], 'tri'))*0.45
    S['coin'] = fade(notes([('B5', 0.06), ('E6', 0.16)], 'pulse'))*0.38
    S['buy'] = fade(notes([('C6', 0.06), ('E6', 0.06), ('G6', 0.06), ('C7', 0.18)], 'pulse'))*0.32
    S['banner'] = fade(np.concatenate([bell(hz(midi(n)), 0.22*SR)[:int(0.22*SR)] for n in ('G5', 'C6', 'E6')]+[bell(hz(midi('G6')), 0.8*SR)]))*0.35
    # Child
    S['jump'] = fade(sweep(320, 720, 0.12, 'square', 0.6))*0.22
    S['double_jump'] = fade(sweep(520, 1150, 0.16, 'square', 0.5))*0.2+fade(lowpass(noise(0.16*SR), 2500)*np.exp(-t(0.16*SR)*18))*0.15
    S['land'] = fade(lowpass(noise(0.07*SR), 900)*np.exp(-t(0.07*SR)*45))*0.5
    S['step'] = fade(lowpass(noise(0.035*SR), 1400)*np.exp(-t(0.035*SR)*80))*0.25
    S['child_hup'] = fade(formant_voice([380, 460], 'u', 0.13))*0.35
    S['child_yay'] = fade(formant_voice([360, 520, 470], 'eai', 0.36))*0.35
    S['child_ouch'] = fade(formant_voice([520, 360], 'au', 0.26))*0.35
    S['hurt'] = fade(sweep(700, 220, 0.25, 'square', 0.7))*0.18
    S['throw'] = fade(lowpass(noise(0.22*SR), 1800)*np.sin(np.linspace(0, np.pi, int(0.22*SR))))*0.4
    # Foxy (high little yips, sniffs, crunches)
    S['fox_yip'] = fade(formant_voice([900, 1300, 1000], 'ii', 0.14, 0.15))*0.3
    S['fox_happy'] = np.concatenate([fade(formant_voice([950, 1350], 'i', 0.1, 0.15)), np.zeros(int(0.05*SR)), fade(formant_voice([1100, 1500, 1200], 'ie', 0.14, 0.15))])*0.3
    sniff = lambda: fade(lowpass(noise(0.07*SR), 3000)*np.sin(np.linspace(0, np.pi, int(0.07*SR))))
    S['fox_sniff'] = np.concatenate([sniff(), np.zeros(int(0.05*SR)), sniff(), np.zeros(int(0.05*SR)), sniff()])*0.35
    dig = lambda: fade(lowpass(noise(0.09*SR), 1200)*np.exp(-t(0.09*SR)*30))
    S['fox_dig'] = np.concatenate([dig(), np.zeros(int(0.07*SR)), dig(), np.zeros(int(0.07*SR)), dig()])*0.5
    crunch = lambda: fade(lowpass(noise(0.06*SR), 4000)*np.exp(-t(0.06*SR)*40))
    S['fox_eat'] = np.concatenate([x for _ in range(4) for x in (crunch(), np.zeros(int(0.09*SR)))])*0.4
    lap = lambda: fade(sweep(500, 1100, 0.06, 'sine'))*0.5+fade(lowpass(noise(0.06*SR), 2500))*0.15
    S['fox_drink'] = np.concatenate([x for _ in range(4) for x in (lap(), np.zeros(int(0.1*SR)))])*0.45
    S['fox_bath'] = fade(np.concatenate([lowpass(noise(0.4*SR), 2000)*0.3]+[sweep(800+i*90, 1600+i*90, 0.05) for i in range(8)]))*0.35
    S['fox_shake'] = fade(lowpass(noise(0.45*SR), 3500)*(0.5+0.5*np.sin(2*np.pi*14*t(0.45*SR))))*0.4
    S['fox_snore'] = fade(lowpass(noise(1.2*SR), 500)*np.sin(np.linspace(0, np.pi, int(1.2*SR)))**2, 0.2, 0.3)*0.35
    S['fox_yawn'] = fade(formant_voice([700, 900, 500], 'aou', 0.55, 0.2), 0.05, 0.12)*0.28
    S['fox_purr'] = fade(lowpass(noise(0.9*SR), 300)*(0.6+0.4*np.sin(2*np.pi*24*t(0.9*SR))), 0.1, 0.2)*0.5
    S['fox_whine'] = fade(formant_voice([1000, 800], 'iu', 0.3, 0.1))*0.22
    # World
    S['chest'] = fade(np.concatenate([lowpass(noise(0.12*SR), 900)*0.6*np.exp(-t(0.12*SR)*20), notes([('C6', 0.07), ('E6', 0.07), ('G6', 0.07), ('C7', 0.3)], 'bell')]))*0.4
    S['door'] = fade(sweep(180, 120, 0.4, 'tri')*np.exp(-t(0.4*SR)*3)+lowpass(noise(0.4*SR), 600)*0.2)*0.45
    S['lever'] = fade(np.concatenate([lowpass(noise(0.05*SR), 3000), np.zeros(int(0.03*SR)), sweep(300, 140, 0.12, 'square')*0.4]))*0.4
    S['rumble'] = fade(lowpass(noise(1.1*SR), 160)*np.sin(np.linspace(0, np.pi, int(1.1*SR))), 0.1, 0.3)*0.9
    S['crank'] = fade(np.concatenate([x for i in range(8) for x in (lowpass(noise(0.03*SR), 2500)*np.exp(-t(0.03*SR)*90), np.zeros(int(0.1*SR)))]))*0.4
    S['bridge'] = fade(np.concatenate([lowpass(noise(0.9*SR), 400)*np.linspace(0.3, 1, int(0.9*SR)), (lowpass(noise(0.15*SR), 700)*np.exp(-t(0.15*SR)*20))]))*0.5
    S['crate_place'] = fade(lowpass(noise(0.12*SR), 700)*np.exp(-t(0.12*SR)*25)+sweep(160, 90, 0.12, 'sine')*0.5)*0.5
    S['crate_pick'] = fade(sweep(300, 600, 0.1, 'tri'))*0.35
    S['pickup'] = fade(notes([('E6', 0.05), ('A6', 0.12)], 'pulse'))*0.32
    S['key'] = fade(notes([('A5', 0.08), ('C#6', 0.08), ('E6', 0.08), ('A6', 0.35)], 'bell'))*0.4
    S['carrot'] = np.concatenate([crunch(), np.zeros(int(0.05*SR)), crunch()])*0.5+0.0
    S['super_jump'] = fade(sweep(300, 1400, 0.3, 'square', 0.4))*0.18
    S['heart'] = fade(notes([('E6', 0.07), ('G#6', 0.07), ('B6', 0.2)], 'bell'))*0.38
    S['lantern'] = fade(notes([('G5', 0.1), ('D6', 0.1), ('G6', 0.5)], 'bell'))*0.38
    S['boing'] = fade(sweep(250, 650, 0.18, 'sine', 0.5)*(0.6+0.4*np.sin(2*np.pi*30*t(0.18*SR))))*0.45
    S['bonk'] = fade(sweep(420, 180, 0.15, 'tri'))*0.45
    S['splash'] = fade(lowpass(noise(0.4*SR), 2500)*np.exp(-t(0.4*SR)*7))*0.4
    S['ability'] = fade(notes([('C5', 0.1), ('E5', 0.1), ('G5', 0.1), ('C6', 0.1), ('E6', 0.1), ('G6', 0.45)], 'pulse'))*0.3
    S['fanfare'] = fade(notes([('G5', 0.12), ('G5', 0.12), ('G5', 0.12), ('E6', 0.5), ('D6', 0.15), ('E6', 0.15), ('G6', 0.7)], 'pulse', 0.02))*0.3
    S['bounce'] = fade(sweep(380, 260, 0.08, 'sine'))*0.5
    S['catch'] = fade(notes([('A5', 0.05), ('E6', 0.12)], 'tri'))*0.4
    S['miss'] = fade(notes([('E5', 0.1), ('C5', 0.2)], 'tri'))*0.35
    S['coins_many'] = np.concatenate([S['coin'], np.zeros(int(0.03*SR)), S['coin']])
    return S

# Loudness targets (RMS) so sounds sit together; anything not listed: 0.12.
LOUD = {'step': 0.05, 'land': 0.08, 'ui_tap': 0.09, 'ui_toggle': 0.09, 'ui_open': 0.1, 'ui_close': 0.1,
        'fox_snore': 0.06, 'fox_purr': 0.07, 'rumble': 0.1, 'crank': 0.08, 'bridge': 0.1,
        'fanfare': 0.13, 'ability': 0.13, 'music': 0.11}
def level(name, x):
    rms = np.sqrt(np.mean(x**2))+1e-9
    x = x*(LOUD.get(name, 0.12)/rms)
    peak = np.max(np.abs(x))
    return x*(0.9/peak) if peak > 0.9 else x

def write(path, x):
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = np.max(np.abs(x))
    if peak > 0.98: x = x*(0.98/peak)
    data = (np.clip(x, -1, 1)*32767).astype('<i2').tobytes()
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data)

if __name__ == '__main__':
    only = sys.argv[sys.argv.index('--only')+1] if '--only' in sys.argv else None
    for name, x in build_sfx().items():
        if only and only != name: continue
        write(OUT/'sfx'/f'{name}.wav', level(name, x))
    if not only or only in ('menu', 'home', 'meadow', 'cave', 'play', 'music'):
        for name, x in build_music().items():
            if only and only not in (name, 'music'): continue
            # Music sits under the effects.
            write(OUT/'music'/f'{name}.wav', level('music', x))
    print('sounds written to', OUT)
