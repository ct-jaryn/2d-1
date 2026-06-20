import wave
import math
import struct
from pathlib import Path

OUTPUT_DIR = Path("assets/sounds")
OUTPUT_DIR.mkdir(exist_ok=True)

SAMPLE_RATE = 44100


def save_wav(filename: str, samples: list):
    path = OUTPUT_DIR / filename
    with wave.open(str(path), "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        f.writeframes(b"".join([struct.pack("<h", int(s * 32767)) for s in samples]))
    print(f"Saved {path}")


def generate_square_wave(frequency: float, duration: float, volume: float = 0.3) -> list:
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        value = 1.0 if math.sin(2 * math.pi * frequency * t) >= 0 else -1.0
        samples.append(value * volume)
    return samples


def generate_sine_wave(frequency: float, duration: float, volume: float = 0.3) -> list:
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        value = math.sin(2 * math.pi * frequency * t)
        samples.append(value * volume)
    return samples


def apply_fade(samples: list, fade_duration: float = 0.05) -> list:
    fade_samples = int(SAMPLE_RATE * fade_duration)
    for i in range(min(fade_samples, len(samples))):
        samples[i] *= i / fade_samples
    for i in range(min(fade_samples, len(samples))):
        samples[-(i + 1)] *= i / fade_samples
    return samples


def generate_attack() -> list:
    samples = []
    duration = 0.15
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 800 - t * 4000
        if freq < 100:
            freq = 100
        value = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        samples.append(value * 0.2)
    return apply_fade(samples, 0.02)


def generate_hit() -> list:
    samples = []
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        value = math.sin(2 * math.pi * 200 * t) * (1 - t / duration)
        samples.append(value * 0.4)
    return samples


def generate_level_up() -> list:
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.50]
    duration_per_note = 0.12
    for freq in notes:
        samples.extend(generate_sine_wave(freq, duration_per_note, 0.25))
    return apply_fade(samples, 0.05)


def generate_coin() -> list:
    samples = []
    duration = 0.1
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 1200 + t * 2000
        value = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        samples.append(value * 0.15)
    return apply_fade(samples, 0.02)


def generate_bgm() -> list:
    """生成一段简单的 8-bit 循环背景音乐（约 8 秒）"""
    samples = []
    melody = [
        (261.63, 0.5), (329.63, 0.5), (392.00, 0.5), (523.25, 0.5),
        (392.00, 0.5), (329.63, 0.5), (261.63, 1.0),
        (196.00, 0.5), (246.94, 0.5), (293.66, 0.5), (392.00, 0.5),
        (293.66, 0.5), (246.94, 0.5), (196.00, 1.0),
    ]
    for freq, duration in melody:
        samples.extend(generate_square_wave(freq, duration, 0.08))
    return apply_fade(samples, 0.1)


def main():
    save_wav("attack.wav", generate_attack())
    save_wav("hit.wav", generate_hit())
    save_wav("level_up.wav", generate_level_up())
    save_wav("coin.wav", generate_coin())
    save_wav("bgm.wav", generate_bgm())
    print("Done")


if __name__ == "__main__":
    main()
