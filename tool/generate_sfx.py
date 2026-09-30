import os
import math
import struct
import wave

def generate_tone(filepath, duration_sec, sample_rate, start_freq, end_freq, decay_power):
    num_samples = int(duration_sec * sample_rate)
    samples = []
    for i in range(num_samples):
        t = i / num_samples
        freq = start_freq + (end_freq - start_freq) * t
        env = math.pow(1.0 - t, decay_power)
        val = math.sin(2 * math.pi * freq * (i / sample_rate)) * env
        samples.append(int(val * 28000))
    write_wav(filepath, samples, sample_rate)

def generate_chord(filepath, duration_sec, sample_rate, frequencies):
    num_samples = int(duration_sec * sample_rate)
    samples = []
    for i in range(num_samples):
        t = i / num_samples
        env = math.pow(1.0 - t, 1.8)
        val = sum(math.sin(2 * math.pi * f * (i / sample_rate)) for f in frequencies)
        val = (val / len(frequencies)) * env
        samples.append(int(val * 28000))
    write_wav(filepath, samples, sample_rate)

def generate_arpeggio(filepath, duration_sec, sample_rate, frequencies):
    num_samples = int(duration_sec * sample_rate)
    samples = []
    note_duration = num_samples / len(frequencies)
    for i in range(num_samples):
        idx = min(int(i / note_duration), len(frequencies) - 1)
        note_t = (i % note_duration) / note_duration
        freq = frequencies[idx]
        env = math.pow(1.0 - note_t, 1.5)
        val = math.sin(2 * math.pi * freq * (i / sample_rate)) * env
        samples.append(int(val * 26000))
    write_wav(filepath, samples, sample_rate)

def generate_ambient(filepath, duration_sec, sample_rate):
    num_samples = int(duration_sec * sample_rate)
    samples = []
    freqs = [220.0, 277.18, 329.63, 440.0]
    for i in range(num_samples):
        t = i / num_samples
        loop_env = math.sin(t * math.pi)
        val = sum(math.sin(2 * math.pi * f * (i / sample_rate) + idx * 0.5) for idx, f in enumerate(freqs))
        val = (val / len(freqs)) * loop_env * 0.6
        samples.append(int(val * 24000))
    write_wav(filepath, samples, sample_rate)

def write_wav(filepath, samples, sample_rate):
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        packed_data = bytearray()
        for sample in samples:
            clamped = max(-32768, min(32767, sample))
            packed_data.extend(struct.pack('<h', clamped))
        wav_file.writeframes(packed_data)

def main():
    out_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
    os.makedirs(out_dir, exist_ok=True)
    sample_rate = 44100

    generate_tone(os.path.join(out_dir, 'button_tap.wav'), 0.05, sample_rate, 800, 400, 4.0)
    generate_tone(os.path.join(out_dir, 'pickup.wav'), 0.12, sample_rate, 440, 880, 2.0)
    generate_tone(os.path.join(out_dir, 'place.wav'), 0.15, sample_rate, 520, 260, 2.5)
    generate_tone(os.path.join(out_dir, 'invalid.wav'), 0.2, sample_rate, 180, 120, 1.5)
    generate_chord(os.path.join(out_dir, 'clear.wav'), 0.35, sample_rate, [523.25, 659.25, 783.99, 1046.50])
    generate_arpeggio(os.path.join(out_dir, 'combo.wav'), 0.45, sample_rate, [523.25, 659.25, 783.99, 1046.50, 1318.51])
    generate_arpeggio(os.path.join(out_dir, 'perfect_clear.wav'), 0.8, sample_rate, [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.0])
    generate_chord(os.path.join(out_dir, 'game_over.wav'), 0.6, sample_rate, [392.00, 311.13, 261.63])
    generate_arpeggio(os.path.join(out_dir, 'reward_claim.wav'), 0.5, sample_rate, [440.0, 554.37, 659.25, 880.0])
    generate_ambient(os.path.join(out_dir, 'bg_music.wav'), 4.0, sample_rate)
    print("Python SFX generation complete!")

if __name__ == '__main__':
    main()
