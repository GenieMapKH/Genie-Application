"""Writes the call tones in assets/sounds/call/ (synthesised, no third-party audio).

    python tool/generate_call_tones.py

ringback.wav  "toot-toot ... toot-toot": the other phone is ringing (looped).
answered.wav  two rising notes: the other person picked up.
rejected.wav  three busy beeps: the call was declined or the person is busy.
"""

import math
import struct
import wave
from pathlib import Path

RATE = 16000
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds" / "call"

# 8 ms ramps at each edge, so no tone starts or stops with a click.
RAMP = int(RATE * 0.008)


def tone(seconds, frequencies, level=0.3, decay=False):
    count = int(RATE * seconds)
    samples = []
    for i in range(count):
        t = i / RATE
        value = sum(math.sin(2 * math.pi * f * t) for f in frequencies) / len(frequencies)
        edge = min(1.0, i / RAMP, (count - 1 - i) / RAMP)
        fade = 1.0 - 0.6 * (i / count) if decay else 1.0
        samples.append(value * level * edge * fade)
    return samples


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in samples))


ring = [400, 450]
write("ringback.wav", tone(0.4, ring) + silence(0.2) + tone(0.4, ring) + silence(2.0))

write("answered.wav", tone(0.09, [587.33], level=0.35) + tone(0.18, [880.0], level=0.35, decay=True))

busy = [480, 620]
write("rejected.wav", (tone(0.25, busy) + silence(0.25)) * 3)
