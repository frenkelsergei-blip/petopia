"""Synthesize PETOPIA's chiptune music and sound effects (no samples, no
downloads): assets/audio/music/<track>.wav (seamless loops) and
assets/audio/sfx/<name>.wav. Edit the scores or recipes here and rerun.

Style: gentle sine/triangle melodies, wooden plucks and rounded bloops.
Noise is a quiet, strongly low-passed texture; every note has soft edges.
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
    """One-pole low-pass, also cascaded below for muffled textures."""
    a = np.exp(-2*np.pi*cutoff/SR)
    y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc = (1-a)*x[i]+a*acc; y[i] = acc
    return y

def env(n, attack=0.005, decay=0.0, sustain=1.0, release=0.03):
    """ADSR over n samples (release inside n)."""
    n = int(n); e = np.ones(n)*sustain
    a = min(n, int(attack*SR)); r = min(n-a, int(release*SR)); d = min(n-a-r, int(decay*SR))
    if a: e[:a] = np.sin(np.linspace(0, np.pi/2, a))**2
    if d: e[a:a+d] = sustain+(1-sustain)*np.cos(np.linspace(0, np.pi/2, d))**2
    if r: e[n-r:] *= np.cos(np.linspace(0, np.pi/2, r))**2
    return e

def tri(f, n):
    return 2/np.pi*np.arcsin(sine(f, n))
def sine(f, n): return np.sin(2*np.pi*f*t(n))
def bell(f, n):
    x = t(n)
    tone = np.sin(2*np.pi*f*x)+0.18*np.sin(2*np.pi*2*f*x)*np.exp(-x*6)+0.035*np.sin(2*np.pi*3*f*x)*np.exp(-x*9)
    return tone*np.exp(-x*2.6)*env(n, 0.012, release=min(0.18, len(x)/SR*0.4))
def noise(n): return RNG.uniform(-1, 1, int(n))

def pluck(f, n):
    """Soft wooden/marimba pluck without a noisy string attack."""
    x = t(n)
    tone = sine(f, n)+0.12*sine(2*f, n)*np.exp(-x*22)
    return tone*np.exp(-x*8)*env(n, 0.008, release=min(0.12, len(x)/SR*0.45))

def soft_noise(n, cutoff=650):
    """Two low-pass stages keep any noise well under the tonal body."""
    return lowpass(lowpass(noise(n), cutoff), cutoff)

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
            if voice == 'tri': sig = (0.8*sine(f, n)+0.2*tri(f, n))*env(n, 0.025, 0.12, 0.65, min(0.12, beats*song.beat*0.4))
            elif voice == 'bell': sig = bell(f, max(n, 1.4*SR))
            elif voice == 'sine': sig = sine(f, n)*env(n, 0.03, 0.2, 0.75, min(0.15, beats*song.beat*0.5))
            elif voice == 'pluck': sig = pluck(f, max(n, 1.2*SR))
            # gentle vibrato-free lead: slight fade so repeated notes separate
            song.add(b, sig, gain)
        b += beats
    return b

def accompany(song, chords, style, gain_bass=0.14, gain_arp=0.07, drums=True, beats=4):
    for i, c in enumerate(chords):
        tones = chord(c); bar = i*beats
        root = tones[0]-12
        if style in ('drive', 'bounce'):
            for k in range(beats*2):
                m = root if k % 2 == 0 else root+12
                n = song.beat*0.5*SR
                song.add(bar+k*0.5, sine(hz(m), n)*env(n, 0.035, 0.08, 0.55, 0.08), gain_bass)
            for k in range(beats*2):
                m = tones[k % 3]+12; n = song.beat*0.45*SR
                song.add(bar+k*0.5, pluck(hz(m), n), gain_arp)
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
                song.add(bar+k, pluck(hz(m), 1.3*SR), gain_arp)
        if drums:
            for k in range(beats):
                if k % 2 == 0: song.add(bar+k, kick(), 0.045)
                else: song.add(bar+k, snare(), 0.022)
            for k in range(beats*2):
                song.add(bar+k*0.5, hat(), 0.006)

def kick():
    n = int(0.23*SR); x = t(n); f = 30*np.exp(-x*16)+65
    return np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-x*10)*env(n, 0.025, release=0.1)
def snare():
    n = int(0.16*SR); x = t(n)
    return (sine(165, n)+0.12*soft_noise(n, 650))*np.exp(-x*14)*env(n, 0.018, release=0.08)
def hat():
    # A barely audible wooden tick replaces the metallic noise hat.
    return pluck(420, int(0.075*SR))

# ------------------------------------------------------------------ music
def build_music():
    tracks = {}
    # Main menu: bright and welcoming (C major, 112 bpm).
    s = Song(112, 16)
    A = 'E5 q G5 q A5 q G5 q D5 q G5 q B5 h C6 q B5 e A5 e E5 q C5 q F5 q E5 q D5 h '
    B = 'A5 q F5 e A5 e C6 q A5 q B5 q G5 e B5 e D6 h G5 q E5 q B4 q E5 q A5 h E5 q C5 q '
    A2 = 'E5 q G5 q A5 q G5 q D5 q G5 q B5 h C6 q B5 e A5 e E5 q C5 q F5 q A5 q C6 h'
    melody(s, score(A+A+B+A2), 'tri', 0.16, shift=-12)
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
    melody(s, score(A1+A2+B1+B2), 'tri', 0.15, shift=-12)
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
    melody(s, score(P), 'tri', 0.15, shift=-12)
    accompany(s, ['D', 'G', 'A', 'D', 'Bm', 'G', 'A', 'A'], 'bounce')
    tracks['play'] = s.render()
    return tracks

# -------------------------------------------------------------------- sfx
def sweep(f0, f1, dur, shape='sine', curve=1.0):
    n = int(dur*SR); k = np.linspace(0, 1, n)**curve
    k = k*k*(3-2*k)
    f = f0+(f1-f0)*k; ph = 2*np.pi*np.cumsum(f)/SR
    if shape == 'sine': return np.sin(ph)
    if shape == 'tri': return 2/np.pi*np.arcsin(np.sin(ph))
    raise ValueError('Use a gentle sine or triangle sweep')
def notes(seq, voice='pluck', gap=0.0):
    """seq: [(note, seconds)] played one after another."""
    out = []
    for name, d in seq:
        n = int(d*SR); f = hz(midi(name))
        if voice == 'bell': s = bell(f, n)
        elif voice == 'tri': s = (0.8*sine(f, n)+0.2*tri(f, n))*env(n, 0.012, 0.04, 0.65, min(0.08, d*0.45))
        else: s = pluck(f, n)
        out.append(s); out.append(np.zeros(int(gap*SR)))
    return np.concatenate(out)
def fade(x, a=0.012, r=0.06): return x*env(len(x), a, 0, 1, r)

def bloop(f0, f1, dur, texture=0.0, cutoff=650):
    """Rounded tonal body; filtered noise is only a quiet texture."""
    n = int(dur*SR)
    body = sweep(f0, f1, dur)
    if texture: body += texture*soft_noise(n, cutoff)
    return fade(body*np.exp(-t(n)*2/dur), min(0.025, dur*0.18), dur*0.5)

def phrase(parts, gap=0.045):
    return np.concatenate([piece for i, part in enumerate(parts)
                           for piece in ((np.zeros(int(gap*SR)), part) if i else (part,))])

def chirp(pitches, dur):
    """Sweet, simple voice with a small smooth pitch bend, no formants."""
    n = int(dur*SR); k = np.linspace(0, 1, n)
    positions = k*(len(pitches)-1)
    segment = np.minimum(positions.astype(int), len(pitches)-2)
    bend = positions-segment
    bend = bend*bend*(3-2*bend)
    pitches = np.asarray(pitches)
    f0 = pitches[segment]+(pitches[segment+1]-pitches[segment])*bend
    ph = 2*np.pi*np.cumsum(f0)/SR
    tone = 0.9*np.sin(ph)+0.1*(2/np.pi)*np.arcsin(np.sin(ph))
    return fade(tone, min(0.035, dur*0.2), dur*0.45)

def build_sfx():
    S = {}
    # UI: short wooden notes, with a fade on every individual note.
    S['ui_tap'] = pluck(hz(midi('C5')), 0.065*SR)
    S['ui_open'] = notes([('C5', 0.06), ('G5', 0.09)])
    S['ui_close'] = notes([('G5', 0.06), ('C5', 0.09)])
    S['ui_toggle'] = pluck(hz(midi('E5')), 0.07*SR)
    S['ui_error'] = notes([('E4', 0.1), ('C4', 0.16)])
    S['coin'] = notes([('B5', 0.08), ('E6', 0.2)], 'bell')
    S['buy'] = notes([('C5', 0.08), ('E5', 0.08), ('G5', 0.08), ('C6', 0.24)], 'bell')
    S['banner'] = notes([('G5', 0.22), ('C6', 0.22), ('E6', 0.22), ('G6', 0.8)], 'bell')
    # Child
    S['jump'] = bloop(330, 580, 0.16)
    S['double_jump'] = bloop(440, 760, 0.2)
    S['land'] = bloop(150, 120, 0.14, 0.08, 450)
    S['step'] = bloop(135, 115, 0.075, 0.04, 400)
    S['child_hup'] = chirp([390, 455], 0.14)
    S['child_yay'] = chirp([420, 540, 510], 0.32)
    S['child_ouch'] = chirp([450, 340], 0.24)
    S['hurt'] = bloop(390, 230, 0.28)
    S['throw'] = bloop(340, 490, 0.22, 0.08, 700)
    # Foxy: little melodic chirps and muffled pats, never formant buzz.
    S['fox_yip'] = chirp([620, 740, 670], 0.16)
    S['fox_happy'] = phrase([chirp([620, 710], 0.13), chirp([700, 790, 740], 0.16)])
    S['fox_sniff'] = phrase([bloop(290, 330, 0.11, 0.12, 700) for _ in range(3)])
    # Three low sine puffs, with just a trace of twice-filtered earth texture.
    S['fox_dig'] = phrase([bloop(f, f-25, 0.15, 0.12, 500) for f in (165, 180, 155)], 0.06)
    S['fox_eat'] = phrase([bloop(f, f-30, 0.15) for f in (280, 315, 290)], 0.055)
    S['fox_drink'] = phrase([bloop(420, 530, 0.1, 0.04, 650) for _ in range(4)], 0.08)
    S['fox_bath'] = phrase([bloop(f, f+90, 0.18, 0.15, 850) for f in (380, 460, 420, 520)], 0.015)
    n = int(0.5*SR)
    S['fox_shake'] = fade((sweep(250, 290, 0.5)+0.16*soft_noise(n, 800))*(0.7+0.3*np.cos(2*np.pi*9*t(n))), 0.05, 0.14)
    n = int(1.2*SR)
    S['fox_snore'] = fade((sine(145, n)+0.14*soft_noise(n, 350))*np.sin(np.linspace(0, np.pi, n))**2, 0.2, 0.3)
    S['fox_yawn'] = chirp([430, 495, 350], 0.55)
    n = int(0.9*SR)
    S['fox_purr'] = fade((sine(155, n)+0.1*soft_noise(n, 250))*(0.85+0.15*np.sin(2*np.pi*18*t(n))), 0.1, 0.2)
    S['fox_whine'] = chirp([650, 540], 0.28)
    # World
    S['chest'] = phrase([bloop(190, 155, 0.16, 0.08, 450), notes([('C5', 0.09), ('E5', 0.09), ('G5', 0.09), ('C6', 0.4)], 'bell')], 0.02)
    S['door'] = bloop(180, 140, 0.4, 0.1, 450)
    S['lever'] = phrase([bloop(240, 205, 0.14), bloop(190, 165, 0.16)], 0.03)
    n = int(1.1*SR)
    S['rumble'] = fade((sweep(110, 90, 1.1)+0.18*soft_noise(n, 180))*(0.9+0.1*np.sin(2*np.pi*3*t(n))), 0.18, 0.35)
    # A continuous gentle turn replaces the repeated ratchet knocks.
    n = int(1.0*SR)
    S['crank'] = fade((sweep(175, 205, 1.0)+0.08*soft_noise(n, 500))*(0.85+0.15*np.cos(2*np.pi*4*t(n))), 0.1, 0.2)
    S['bridge'] = bloop(155, 125, 1.05, 0.15, 400)
    S['crate_place'] = bloop(175, 140, 0.18, 0.08, 450)
    S['crate_pick'] = bloop(280, 390, 0.15)
    S['pickup'] = notes([('E5', 0.07), ('A5', 0.16)], 'bell')
    S['key'] = notes([('A5', 0.1), ('C#6', 0.1), ('E6', 0.1), ('A6', 0.4)], 'bell')
    S['carrot'] = notes([('G4', 0.12), ('C5', 0.18)])
    S['super_jump'] = bloop(340, 850, 0.3)
    S['heart'] = notes([('E5', 0.09), ('G#5', 0.09), ('B5', 0.26)], 'bell')
    S['lantern'] = notes([('G5', 0.12), ('D6', 0.12), ('G6', 0.5)], 'bell')
    S['boing'] = bloop(260, 540, 0.22)
    S['bonk'] = bloop(280, 180, 0.2)
    S['splash'] = bloop(330, 220, 0.42, 0.22, 900)
    S['ability'] = notes([('C5', 0.1), ('E5', 0.1), ('G5', 0.1), ('C6', 0.1), ('E6', 0.1), ('G6', 0.45)], 'bell')
    S['fanfare'] = notes([('G5', 0.12), ('G5', 0.12), ('G5', 0.12), ('E6', 0.5), ('D6', 0.15), ('E6', 0.15), ('G6', 0.7)], 'bell', 0.02)
    S['bounce'] = bloop(330, 260, 0.12)
    S['catch'] = notes([('A4', 0.07), ('E5', 0.16)])
    S['miss'] = notes([('E4', 0.12), ('C4', 0.22)], 'tri')
    S['coins_many'] = np.concatenate([S['coin'], np.zeros(int(0.03*SR)), S['coin']])
    return S

# Loudness targets (RMS); frequent actions stay especially quiet. Default: 0.085.
# Set loudness here, since normalization would undo recipe-only gain reductions.
LOUD = {'step': 0.018, 'land': 0.04, 'ui_tap': 0.045, 'ui_toggle': 0.045, 'ui_open': 0.055, 'ui_close': 0.055,
        'ui_error': 0.06, 'fox_dig': 0.055, 'fox_eat': 0.06, 'fox_sniff': 0.04, 'fox_shake': 0.05,
        'fox_drink': 0.05, 'fox_bath': 0.06, 'fox_snore': 0.035, 'fox_purr': 0.04,
        'child_hup': 0.065, 'child_yay': 0.075, 'child_ouch': 0.06, 'fox_yip': 0.065,
        'fox_happy': 0.07, 'fox_whine': 0.055, 'fox_yawn': 0.05,
        'rumble': 0.045, 'crank': 0.04, 'bridge': 0.045, 'lever': 0.05, 'door': 0.05,
        'crate_place': 0.05, 'carrot': 0.065, 'bonk': 0.055, 'hurt': 0.06, 'miss': 0.06, 'splash': 0.06,
        'fanfare': 0.1, 'ability': 0.095, 'music': 0.075}
def level(name, x):
    rms = np.sqrt(np.mean(x**2))+1e-9
    x = x*(LOUD.get(name, 0.085)/rms)
    peak = np.max(np.abs(x))
    return x*(0.88/peak) if peak > 0.88 else x

def write(path, x):
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = np.max(np.abs(x))
    if peak > 0.88: x = x*(0.88/peak)
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
