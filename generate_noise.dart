import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final sampleRate = 44100;
  final duration = 10; // 10 seconds of noise
  final numSamples = sampleRate * duration;
  final numChannels = 1;
  final bitsPerSample = 16;
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final byteRate = sampleRate * blockAlign;
  final dataSize = numSamples * blockAlign;
  final fileSize = 36 + dataSize;
  
  final file = File('assets/audio/white_noise.wav');
  file.createSync(recursive: true);
  final sink = file.openSync(mode: FileMode.write);
  
  // RIFF header
  sink.writeStringSync('RIFF');
  final sizeBytes = ByteData(4)..setUint32(0, fileSize, Endian.little);
  sink.writeFromSync(sizeBytes.buffer.asUint8List());
  sink.writeStringSync('WAVE');
  
  // fmt chunk
  sink.writeStringSync('fmt ');
  final fmtChunkSize = ByteData(4)..setUint32(0, 16, Endian.little);
  sink.writeFromSync(fmtChunkSize.buffer.asUint8List());
  final audioFormat = ByteData(2)..setUint16(0, 1, Endian.little);
  sink.writeFromSync(audioFormat.buffer.asUint8List());
  final channels = ByteData(2)..setUint16(0, numChannels, Endian.little);
  sink.writeFromSync(channels.buffer.asUint8List());
  final sRate = ByteData(4)..setUint32(0, sampleRate, Endian.little);
  sink.writeFromSync(sRate.buffer.asUint8List());
  final bRate = ByteData(4)..setUint32(0, byteRate, Endian.little);
  sink.writeFromSync(bRate.buffer.asUint8List());
  final bAlign = ByteData(2)..setUint16(0, blockAlign, Endian.little);
  sink.writeFromSync(bAlign.buffer.asUint8List());
  final bps = ByteData(2)..setUint16(0, bitsPerSample, Endian.little);
  sink.writeFromSync(bps.buffer.asUint8List());
  
  // data chunk
  sink.writeStringSync('data');
  final dSize = ByteData(4)..setUint32(0, dataSize, Endian.little);
  sink.writeFromSync(dSize.buffer.asUint8List());
  
  final rand = Random();
  final dataBuffer = ByteData(dataSize);
  for (int i = 0; i < numSamples; i++) {
    // 16-bit PCM values: -32768 to 32767
    final val = rand.nextInt(8000) - 4000;
    dataBuffer.setInt16(i * 2, val, Endian.little);
  }
  
  sink.writeFromSync(dataBuffer.buffer.asUint8List());
  sink.closeSync();
  print('white_noise.wav created successfully.');
}
