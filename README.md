# wave_generator

A dart package to generate audio wave data on the fly.

** Fork of [pathandthat's wave-generator project](https://github.com/patchandthat/wave-generator).

## Usage

tbd

### Example

``` dart
import 'package:wave_generator/wave_generator.dart';

() async {

    var generator = WaveGenerator(
        /* sample rate */ 44100,
        BitDepth.Depth8bit);

    var note = Note(
        /* frequency */ 220,
        /* msDuration */ 3000,
        /* waveform */ Waveform.Triangle,
        /* volume */ 0.5);

    var file = new File('output.wav');

    List<int> bytes = List<int>();
    await for (int byte in generator.generate(note)) {
      bytes.add(byte);
    }

    file.writeAsBytes(bytes, mode: FileMode.append);
  });
```

Or string together a sequence of Notes

``` dart

 await for (int byte in generator.generateSequence([note1, note2, note3 /* etc */])) {
   // ...
 }

```

### Features

* Sine wave generation
* 8, 16, 32bitdepth single tone frequency .wav generation