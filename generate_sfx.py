import wave
import struct
import math
import random
import os

OUTPUT_DIR = "assets/audio"
SAMPLE_RATE = 44100

def write_wav(filename, samples):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, filename)
    with wave.open(path, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        for s in samples:
            # Clamp to 16-bit signed int range
            val = max(-32768, min(32767, int(s * 32767)))
            wav_file.writeframes(struct.pack('<h', val))
    print(f"Generated {path}")

def make_tap():
    # Crisp short click: 20ms sine sweep 600Hz -> 100Hz with fast exponential decay
    samples = []
    num_samples = int(SAMPLE_RATE * 0.03)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 600 - (500 * (t / 0.03))
        env = math.exp(-t * 150)
        s = math.sin(2 * math.pi * freq * t) * env * 0.5
        samples.append(s)
    return samples

def make_achievement():
    # Triumphant 4-note chime arpeggio: C5(523), G5(784), C6(1046), E6(1318)
    notes = [523.25, 783.99, 1046.50, 1318.51]
    step_len = int(SAMPLE_RATE * 0.15)
    total_len = step_len * len(notes) + int(SAMPLE_RATE * 0.6)
    samples = [0] * total_len
    for idx, freq in enumerate(notes):
        start = idx * step_len
        for i in range(total_len - start):
            t = i / SAMPLE_RATE
            env = math.exp(-t * 4)
            # Add subtle harmonic
            s = (math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * freq * 2 * t)) * env * 0.4
            samples[start + i] += s
    return samples

def make_displeased():
    # Male groan / "Ugh": Pitch bend down 140Hz -> 90Hz, rich sawtooth-like with lowpass
    samples = []
    num_samples = int(SAMPLE_RATE * 0.5)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 140 - (50 * (t / 0.5))
        env = math.sin(math.pi * (t / 0.5)) * 0.6
        # Sawtooth approximation
        s = sum((math.sin(2 * math.pi * freq * k * t) / k) for k in range(1, 6)) * env * 0.4
        samples.append(s)
    return samples

def make_pleased():
    # Male "Mm-hmm!" or "Aha!": two warm hum notes 130Hz then 180Hz
    samples = []
    num_samples = int(SAMPLE_RATE * 0.6)
    mid = int(num_samples * 0.4)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        if i < mid:
            freq = 130
            env = math.sin(math.pi * (i / mid))
        else:
            freq = 180
            env = math.sin(math.pi * ((i - mid) / (num_samples - mid)))
        s = (math.sin(2 * math.pi * freq * t) + 0.5 * math.sin(2 * math.pi * freq * 2 * t)) * env * 0.4
        samples.append(s)
    return samples

def make_butcher():
    # Looping butcher action: rhythmic heavy meat chops and squelches
    samples = [0] * int(SAMPLE_RATE * 1.2)
    for chop_time in [0.1, 0.7]:
        start = int(SAMPLE_RATE * chop_time)
        chop_len = int(SAMPLE_RATE * 0.25)
        for i in range(chop_len):
            t = i / SAMPLE_RATE
            env = math.exp(-t * 25)
            thump = math.sin(2 * math.pi * (100 - 80 * (t / 0.25)) * t) * env
            squelch = random.uniform(-1, 1) * math.exp(-t * 40) * 0.3
            samples[start + i] += (thump + squelch) * 0.7
    return samples

def make_cooking():
    # Looping cooking action: sizzling oil / frying pan hiss + gentle boiling bubbles
    samples = []
    num_samples = int(SAMPLE_RATE * 1.5)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Sizzle: filtered high frequency noise
        sizzle = random.uniform(-0.2, 0.2)
        # Bubbles: low rhythmic pops
        bubble = 0
        if math.sin(2 * math.pi * 4 * t) > 0.85:
            bubble = math.sin(2 * math.pi * random.uniform(200, 350) * t) * 0.4
        samples.append((sizzle + bubble) * 0.5)
    return samples

def make_writing():
    # Looping writing action: rapid quill scratching on paper
    samples = []
    num_samples = int(SAMPLE_RATE * 1.2)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Modulate amplitude rhythmically to sound like pen strokes
        stroke = math.fabs(math.sin(2 * math.pi * 7 * t))
        scratch = random.uniform(-0.4, 0.4) * stroke
        # Filter out extremely low rumble
        if i % 2 == 0:
            samples.append(scratch * 0.6)
        else:
            samples.append(scratch * 0.4)
    return samples

def make_construction():
    # Looping construction action: rhythmic hammer thuds and metallic saw scrapes
    samples = [0] * int(SAMPLE_RATE * 1.2)
    for hit_time in [0.1, 0.7]:
        start = int(SAMPLE_RATE * hit_time)
        hit_len = int(SAMPLE_RATE * 0.3)
        for i in range(hit_len):
            t = i / SAMPLE_RATE
            env = math.exp(-t * 30)
            thump = math.sin(2 * math.pi * 80 * t) * env
            metal = math.sin(2 * math.pi * 1200 * t) * math.exp(-t * 60) * 0.4
            samples[start + i] += (thump + metal) * 0.6
    return samples

def make_fieldwork():
    # Looping fieldwork action: rhythmic shovel slicing earth and crunching dirt
    samples = [0] * int(SAMPLE_RATE * 1.4)
    for dig_time in [0.2, 0.9]:
        start = int(SAMPLE_RATE * dig_time)
        dig_len = int(SAMPLE_RATE * 0.35)
        for i in range(dig_len):
            t = i / SAMPLE_RATE
            env = math.sin(math.pi * (t / 0.35))
            crunch = random.uniform(-0.5, 0.5) * env * math.exp(-t * 15)
            samples[start + i] += crunch * 0.7
    return samples

def make_cleaning():
    # Looping cleaning action: gentle sweeping broom whooshes
    samples = [0] * int(SAMPLE_RATE * 1.4)
    for sweep_time in [0.15, 0.85]:
        start = int(SAMPLE_RATE * sweep_time)
        sweep_len = int(SAMPLE_RATE * 0.4)
        for i in range(sweep_len):
            t = i / SAMPLE_RATE
            env = math.sin(math.pi * (t / 0.4))
            whoosh = random.uniform(-0.3, 0.3) * env
            samples[start + i] += whoosh * 0.6
    return samples

def make_washing():
    # Looping washing action: rhythmic water splashing and swirling
    samples = []
    num_samples = int(SAMPLE_RATE * 1.2)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        swirl = math.sin(2 * math.pi * 3 * t)
        splash = random.uniform(-0.3, 0.3) if swirl > 0.3 else random.uniform(-0.1, 0.1)
        samples.append(splash * 0.5)
    return samples

def make_giles_shuffle():
    # Giles dragging feet: slow, distinct heavy footfall followed by a long raspy slide
    samples = [0] * int(SAMPLE_RATE * 1.5)
    start = int(SAMPLE_RATE * 0.1)
    length = int(SAMPLE_RATE * 1.2)
    for i in range(length):
        t = i / SAMPLE_RATE
        # Step thump at the beginning
        thump = math.sin(2 * math.pi * 70 * t) * math.exp(-t * 20) * 0.5
        # Shuffling drag scrape across stone
        scrape = random.uniform(-0.3, 0.3) * math.sin(math.pi * (t / 1.2)) * 0.5
        samples[start + i] += (thump + scrape) * 0.7
    return samples

def make_footsteps():
    # Normal footsteps: brisk, crisp alternating walking steps on stone/wood
    samples = [0] * int(SAMPLE_RATE * 1.0)
    for step_time in [0.1, 0.55]:
        start = int(SAMPLE_RATE * step_time)
        step_len = int(SAMPLE_RATE * 0.15)
        for i in range(step_len):
            t = i / SAMPLE_RATE
            env = math.exp(-t * 35)
            click = random.uniform(-0.4, 0.4) * env
            thump = math.sin(2 * math.pi * 110 * t) * env * 0.6
            samples[start + i] += (click + thump) * 0.6
    return samples

def make_eggs():
    # Eggs being produced: cheerful upbeat cluck and pop
    samples = []
    num_samples = int(SAMPLE_RATE * 0.35)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 350 + (400 * (t / 0.35))
        env = math.sin(math.pi * (t / 0.35))
        s = math.sin(2 * math.pi * freq * t) * env * 0.5
        samples.append(s)
    return samples

def make_meal():
    # Meal completed: satisfying silverware/plate clatter and celebratory chime
    samples = [0] * int(SAMPLE_RATE * 0.8)
    # Chime
    chime_freq = 1174.66 # D6
    for i in range(len(samples)):
        t = i / SAMPLE_RATE
        s = math.sin(2 * math.pi * chime_freq * t) * math.exp(-t * 6) * 0.3
        samples[i] += s
    # Clatter
    for clatter_time in [0.05, 0.15, 0.28]:
        start = int(SAMPLE_RATE * clatter_time)
        for i in range(int(SAMPLE_RATE * 0.05)):
            t = i / SAMPLE_RATE
            metal = math.sin(2 * math.pi * random.uniform(1800, 2400) * t) * math.exp(-t * 40) * 0.2
            samples[start + i] += metal
    return samples

def make_experiment():
    # Experiment completed: dramatic electric spark BZZZT + triumphant organ/orchestral swell
    samples = [0] * int(SAMPLE_RATE * 2.0)
    # Spark Bzzzt at the beginning
    for i in range(int(SAMPLE_RATE * 0.5)):
        t = i / SAMPLE_RATE
        buzz = (random.uniform(-1, 1) if i % 3 == 0 else 0) * math.exp(-t * 5) * 0.5
        samples[i] += buzz
    # Triumphant chord (C minor -> C major resolution or lightning chord: C3, G3, C4, E4)
    chords = [130.81, 196.00, 261.63, 329.63]
    for idx, freq in enumerate(chords):
        for i in range(len(samples)):
            t = i / SAMPLE_RATE
            env = math.sin(math.pi * (i / len(samples)))
            s = math.sin(2 * math.pi * freq * t) * env * 0.3
            samples[i] += s
    return samples

def main():
    write_wav("sfx_tap.wav", make_tap())
    write_wav("sfx_achievement.wav", make_achievement())
    write_wav("sfx_displeased.wav", make_displeased())
    write_wav("sfx_pleased.wav", make_pleased())
    write_wav("sfx_butcher.wav", make_butcher())
    write_wav("sfx_cooking.wav", make_cooking())
    write_wav("sfx_writing.wav", make_writing())
    write_wav("sfx_construction.wav", make_construction())
    write_wav("sfx_fieldwork.wav", make_fieldwork())
    write_wav("sfx_cleaning.wav", make_cleaning())
    write_wav("sfx_washing.wav", make_washing())
    write_wav("sfx_giles_shuffle.wav", make_giles_shuffle())
    write_wav("sfx_footsteps.wav", make_footsteps())
    write_wav("sfx_eggs.wav", make_eggs())
    write_wav("sfx_meal.wav", make_meal())
    write_wav("sfx_experiment.wav", make_experiment())
    print("All 16 SFX successfully generated!")

if __name__ == "__main__":
    main()
