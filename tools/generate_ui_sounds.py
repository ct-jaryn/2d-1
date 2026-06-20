import wave
import math
import struct
import os

def write_tone(path, freq, duration, volume=0.5, sample_rate=44100):
    n_samples = int(sample_rate * duration)
    data = bytearray()
    attack = int(sample_rate * 0.005)
    release = int(sample_rate * 0.02)
    for i in range(n_samples):
        env = 1.0
        if i < attack:
            env = i / attack
        elif i > n_samples - release:
            env = (n_samples - i) / release
        t = i / sample_rate
        val = volume * env * math.sin(2 * math.pi * freq * t)
        sample = int(max(-32768, min(32767, val * 32767)))
        data += struct.pack('<h', sample)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        w.writeframes(data)

base = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
write_tone(os.path.join(base, 'ui_click.wav'), 1200, 0.06, 0.35)
write_tone(os.path.join(base, 'ui_hover.wav'), 800, 0.04, 0.12)
print('UI sounds generated.')
