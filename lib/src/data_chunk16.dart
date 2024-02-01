import 'dart:typed_data';
import 'dart:math';

import 'byte_helpers.dart';
import 'chunk.dart';
import 'format_chunk.dart';
import 'generator_function.dart';

import '../wave_generator.dart';

class DataChunk16 implements DataChunk {
  final FormatChunk format;
  final List<Note> notes;

  final String _sGroupId = 'data';

  // stored as signed bytes
  static const int min = -32768;
  static const int max = 32767;

  // any values passed in that are
  // out of bounds for 16 bit will be clamped
  int clamp(int byte) {
    return byte.clamp(min, max);
  }

  const DataChunk16(this.format, this.notes);

  @override
  Stream<int> bytes() async* {
    var groupIdBytes = ByteHelpers.toBytes(_sGroupId);
    var bytes = groupIdBytes.buffer.asByteData();

    // Subchunk2ID  >> contains the letters "data"
    for (int i = 0; i < 4; i++) {
      yield bytes.getUint8(i);
    }

    // SubChunk2Size == NumSamples * NumChannels * BitsPerSample/8
    //  This is the number of bytes in the data.
    // length = length of the data chunk
    var byteData = ByteData(4);
    byteData.setUint32(0, length, Endian.little);
    for (int i = 0; i < 4; i++) {
      yield byteData.getUint8(i);
    }

    // Determine when one note ends and the next begins
    // Number of samples per note given by sampleRate * note duration
    // compare against step count to select the correct note
    int noteNumber = 0;
    int incrementNoteOnSample =
        (notes[noteNumber].msDuration * format.sampleRate) ~/ 1000;

    int sampleMax = totalSamples;
    var amplify = (max + 1) / 2;
    for (int step = 0; step < sampleMax; step++) {
      if (incrementNoteOnSample == step) {
        noteNumber += 1;
        incrementNoteOnSample +=
            (notes[noteNumber].msDuration * format.sampleRate) ~/ 1000;
      }

      double theta = notes[noteNumber].frequency * (2 * pi) / format.sampleRate;
      GeneratorFunction generator =
          GeneratorFunction.create(notes[noteNumber].waveform);

      var y = generator.generate(theta * step);
      double volume = (amplify * notes[noteNumber].volume);
      double sample = (volume * y) + volume;
      int intSampleVal = sample.toInt();
      int sampleByte = clamp(intSampleVal);
      // yield sampleByte;

      var byteData = ByteData(2);
      byteData.setInt16(0, sampleByte, Endian.little);
      for (int i = 0; i < 2; i++) {
        yield byteData.getInt8(i);
      }
    }

    // If the number of bytes is not word-aligned, ie. number of bytes is odd, we need to pad with additional zero bytes.
    // These zero bytes should not appear in the data chunk length header
    // but probably do get included for the length bytes in the file header
    if (length % 2 != 0) yield 0x00;
  }

  @override
  int get length => totalSamples * format.blockAlign;

  int get totalSamples {
    double secondsDuration =
        (notes.map((note) => note.msDuration).reduce((a, b) => a + b) / 1000);
    return (format.sampleRate * secondsDuration).toInt();
  }

  @override
  String get sGroupId => _sGroupId;

  @override
  int get bytesPadding => length % 2 == 0 ? 0 : 1;
}
