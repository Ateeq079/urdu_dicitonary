/// Converts the MoizRauf Urdu-Roman-English TSV files into a clean JSON
/// dictionary asset for the Lughat app.
///
/// Run with: dart run scripts/build_dictionary_json.dart

import 'dart:convert';
import 'dart:io';

void main() {
  final entries = <String, Map<String, String>>{};

  // Process all TSV files — high quality first, then mid, then low.
  // Earlier entries take priority (higher quality).
  final files = [
    'scripts/en_ur_rom.high.tsv',
    'scripts/en_ur_rom.mid.tsv',
    'scripts/en_ur_rom.low.tsv',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('⚠ Skipping $path (not found)');
      continue;
    }
    final lines = file.readAsLinesSync(encoding: utf8);
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split('\t');
      if (parts.length < 4) continue;

      final urdu = parts[0].trim();
      final roman = parts[1].trim().toLowerCase();
      final urRomScore = double.tryParse(parts[2].trim()) ?? 0;
      final english = parts[3].trim().toLowerCase();
      final urEnScore =
          parts.length >= 5 ? (double.tryParse(parts[4].trim()) ?? 0) : 0.0;

      // Skip empty or junk entries
      if (urdu.isEmpty || english.isEmpty || roman.isEmpty) continue;
      if (urdu.length < 2 && !_isSingleCharWord(urdu)) continue;

      // Skip entries where the English translation has very low confidence
      // AND isn't the same as the Roman Urdu (which implies transliteration).
      if (urEnScore < 0.4 && english != roman) continue;

      // Skip entries where Roman-Urdu confidence is too low
      if (urRomScore < 0.5) continue;

      // Use the Urdu word as the dedup key — first seen wins (higher quality).
      if (!entries.containsKey(urdu)) {
        entries[urdu] = {
          'urdu': urdu,
          'roman': roman,
          'english': english,
        };
      }
    }
  }

  // Also process Gold Annotations (human-verified, highest quality).
  // These OVERRIDE any existing entries since they're gold-standard.
  final goldFile = File('scripts/Gold_Annotations.tsv');
  if (goldFile.existsSync()) {
    final lines = goldFile.readAsLinesSync(encoding: utf8);
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split('\t');
      if (parts.length < 5) continue;

      final urdu = parts[0].trim();
      final roman = parts[1].trim().toLowerCase();
      final english = parts[2].trim().toLowerCase();
      final urRomScore = int.tryParse(parts[3].trim()) ?? 0;
      final urEnScore = int.tryParse(parts[4].trim()) ?? 0;

      if (urdu.isEmpty || english.isEmpty || roman.isEmpty) continue;

      // Only use gold entries where both scores are at least 3/5.
      if (urRomScore >= 3 && urEnScore >= 3) {
        entries[urdu] = {
          'urdu': urdu,
          'roman': roman,
          'english': english,
        };
      }
    }
  }

  // Write the output as a JSON array.
  final output = entries.values.toList();
  output.sort((a, b) => a['urdu']!.compareTo(b['urdu']!));

  final outFile = File('assets/dictionary.json');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent(null).convert(output),
    encoding: utf8,
  );

  print('✅ Built assets/dictionary.json');
  print('   ${output.length} entries');
  print('   ${outFile.lengthSync()} bytes');
}

bool _isSingleCharWord(String s) {
  // Some single-character Urdu words are valid (e.g., و = "and")
  const valid = {'و', 'ہ', 'ا', 'ے'};
  return valid.contains(s);
}
