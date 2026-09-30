// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() async {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  print('Generating SFX into assets/audio/...');

  _writeWav(
    File('assets/audio/button_tap.wav'),
    _generateTone(
      durationSec: 0.05,
      sampleRate: 44100,
      startFreq: 800,
      endFreq: 400,
      decayPower: 4.0,
    ),
  );

  _writeWav(
    File('assets/audio/pickup.wav'),
    _generateTone(
      durationSec: 0.12,
      sampleRate: 44100,
      startFreq: 440,
      endFreq: 880,
      decayPower: 2.0,
    ),
  );

  _writeWav(
    File('assets/audio/place.wav'),
    _generateTone(
      durationSec: 0.15,
      sampleRate: 44100,
      startFreq: 520,
      endFreq: 260,
      decayPower: 2.5,
    ),
  );

  _writeWav(
    File('assets/audio/invalid.wav'),
    _generateTone(
      durationSec: 0.2,
      sampleRate: 44100,
      startFreq: 180,
      endFreq: 120,
      decayPower: 1.5,
    ),
  );

  _writeWav(
    File('assets/audio/clear.wav'),
    _generateChord(
      durationSec: 0.35,
      sampleRate: 44100,
      frequencies: [523.25, 659.25, 783.99, 1046.50], // C Major
    ),
  );

  _writeWav(
    File('assets/audio/combo.wav'),
    _generateArpeggio(
      durationSec: 0.45,
      sampleRate: 44100,
      frequencies: [523.25, 659.25, 783.99, 1046.50, 1318.51],
    ),
  );

  _writeWav(
    File('assets/audio/perfect_clear.wav'),
    _generateArpeggio(
      durationSec: 0.8,
      sampleRate: 44100,
      frequencies: [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.0],
    ),
  );

  _writeWav(
    File('assets/audio/game_over.wav'),
    _generateChord(
      durationSec: 0.6,
      sampleRate: 44100,
      frequencies: [392.00, 311.13, 261.63], // Minor descent
    ),
  );

  _writeWav(
    File('assets/audio/reward_claim.wav'),
    _generateArpeggio(
      durationSec: 0.5,
      sampleRate: 44100,
      frequencies: [440.0, 554.37, 659.25, 880.0],
    ),
  );

  _writeWav(
    File('assets/audio/bg_music.wav'),
    _generateAmbientPad(durationSec: 4.0, sampleRate: 44100),
  );

  print('All sound assets generated successfully!');
}

Uint8List _generateTone({
  required double durationSec,
  required int sampleRate,
  required double startFreq,
  required double endFreq,
  required double decayPower,
}) {
  final numSamples = (durationSec * sampleRate).toInt();
  final samples = Int16List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / numSamples;
    final freq = startFreq + (endFreq - startFreq) * t;
    final env = math.pow(1.0 - t, decayPower);
    final value = math.sin(2 * math.pi * freq * (i / sampleRate)) * env;
    samples[i] = (value * 28000).toInt().clamp(-32768, 32767);
  }
  return samples.buffer.asUint8List();
}

Uint8List _generateChord({
  required double durationSec,
  required int sampleRate,
  required List<double> frequencies,
}) {
  final numSamples = (durationSec * sampleRate).toInt();
  final samples = Int16List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / numSamples;
    final env = math.pow(1.0 - t, 1.8);
    double value = 0;
    for (final freq in frequencies) {
      value += math.sin(2 * math.pi * freq * (i / sampleRate));
    }
    value = (value / frequencies.length) * env;
    samples[i] = (value * 28000).toInt().clamp(-32768, 32767);
  }
  return samples.buffer.asUint8List();
}

Uint8List _generateArpeggio({
  required double durationSec,
  required int sampleRate,
  required List<double> frequencies,
}) {
  final numSamples = (durationSec * sampleRate).toInt();
  final samples = Int16List(numSamples);
  final noteDuration = numSamples / frequencies.length;

  for (int i = 0; i < numSamples; i++) {
    final noteIndex = (i / noteDuration).floor().clamp(
      0,
      frequencies.length - 1,
    );
    final noteT = (i % noteDuration) / noteDuration;
    final freq = frequencies[noteIndex];
    final env = math.pow(1.0 - noteT, 1.5);
    final value = math.sin(2 * math.pi * freq * (i / sampleRate)) * env;
    samples[i] = (value * 26000).toInt().clamp(-32768, 32767);
  }
  return samples.buffer.asUint8List();
}

Uint8List _generateAmbientPad({
  required double durationSec,
  required int sampleRate,
}) {
  final numSamples = (durationSec * sampleRate).toInt();
  final samples = Int16List(numSamples);
  final freqs = [220.0, 277.18, 329.63, 440.0]; // A major 7th chord pad

  for (int i = 0; i < numSamples; i++) {
    final t = i / numSamples;
    final loopEnv = math.sin(
      t * math.pi,
    ); // smooth zero at edges for seamless loop
    double value = 0;
    for (int fi = 0; fi < freqs.length; fi++) {
      final f = freqs[fi];
      value += math.sin(2 * math.pi * f * (i / sampleRate) + fi * 0.5);
    }
    value = (value / freqs.length) * loopEnv * 0.6;
    samples[i] = (value * 24000).toInt().clamp(-32768, 32767);
  }
  return samples.buffer.asUint8List();
}

void _writeWav(File file, Uint8List pcmData) {
  final numSamples = pcmData.lengthInBytes ~/ 2;
  final sampleRate = 44100;
  final numChannels = 1;
  final bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final subChunk2Size = numSamples * numChannels * (bitsPerSample ~/ 8);
  final chunkSize = 36 + subChunk2Size;

  final header = ByteData(44);
  // "RIFF"
  header.setUint8(0, 0x52);
  header.setUint8(1, 0x49);
  header.setUint8(2, 0x46);
  header.setUint8(3, 0x46);
  header.setUint32(4, chunkSize, Endian.little);
  // "WAVE"
  header.setUint8(8, 0x57);
  header.setUint8(9, 0x41);
  header.setUint8(10, 0x56);
  header.setUint8(11, 0x45);
  // "fmt "
  header.setUint8(12, 0x66);
  header.setUint8(13, 0x6D);
  header.setUint8(14, 0x74);
  header.setUint8(15, 0x20);
  header.setUint32(16, 16, Endian.little); // SubChunk1Size (16 for PCM)
  header.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  // "data"
  header.setUint8(36, 0x64);
  header.setUint8(37, 0x61);
  header.setUint8(38, 0x74);
  header.setUint8(39, 0x61);
  header.setUint32(40, subChunk2Size, Endian.little);

  final bytes = BytesBuilder();
  bytes.add(header.buffer.asUint8List());
  bytes.add(pcmData);

  file.writeAsBytesSync(bytes.toBytes());
}
