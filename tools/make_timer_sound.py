"""Generuje assets/sounds/timer_done.wav: lekki dźwięk końca minutnika.

Placeholder: dwa miękkie tony (jak „ding-dong") z wygasaniem. Żeby zmienić
dźwięk, podmień plik WAV albo zmień tu nuty i uruchom:

  python3 tools/make_timer_sound.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets/sounds/timer_done.wav"

# (częstotliwość Hz, start s, długość s)
NOTES = [(1046.5, 0.0, 0.7), (784.0, 0.28, 0.9)]  # C6, potem G5
VOLUME = 0.28


def sample(t):
    v = 0.0
    for f, start, dur in NOTES:
        x = t - start
        if 0 <= x < dur:
            attack = min(1.0, x / 0.008)          # bez trzasku na początku
            decay = math.exp(-x * 5.0)            # miękkie wygasanie
            tone = math.sin(2 * math.pi * f * x) + 0.25 * math.sin(4 * math.pi * f * x)
            v += attack * decay * tone
    return v


def main():
    length = max(s + d for _, s, d in NOTES)
    n = int(RATE * length)
    frames = b"".join(
        struct.pack("<h", int(max(-1, min(1, VOLUME * sample(i / RATE))) * 32767))
        for i in range(n)
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f"zapisano {OUT.relative_to(OUT.parent.parent.parent)} ({length:.2f} s)")


if __name__ == "__main__":
    main()
