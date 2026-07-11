// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final src = File(
    r'd:\projects\LARNES-2.0\platform\src\trainers\reading\letter-draw-show\zaitsev-catalog\catalog.ts',
  ).readAsStringSync();

  final letterBlocks = RegExp(
    r'"([^"]+)":\s*\{\s*viewBox:\s*"([^"]+)",\s*strokeWidth:\s*(\d+),\s*strokes:\s*\[(.*?)\]\s*,\s*\}',
    dotAll: true,
  ).allMatches(src);

  final buffer = StringBuffer('''
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_types.dart';

/// Web: `platform/src/trainers/reading/letter-draw-show/zaitsev-catalog/catalog.ts`

const zaitsevLetterDrawings = <String, ZaitsevLetterDrawing>{
''');

  for (final block in letterBlocks) {
    final letter = block.group(1)!;
    final viewBox = block.group(2)!;
    final strokeWidth = block.group(3)!;
    final strokesBlock = block.group(4)!;
    final strokeMatches = RegExp(
      r'path:\s*"([^"]+)"\s*,\s*durationMs:\s*(\d+)',
    ).allMatches(strokesBlock);

    buffer.writeln("  '$letter': ZaitsevLetterDrawing(");
    buffer.writeln("    viewBox: '$viewBox',");
    buffer.writeln('    strokeWidth: $strokeWidth,');
    buffer.writeln('    strokes: [');
    for (final stroke in strokeMatches) {
      final path = stroke.group(1)!;
      final durationMs = stroke.group(2)!;
      buffer.writeln("      ZaitsevLetterStroke(path: r'$path', durationMs: $durationMs),");
    }
    buffer.writeln('    ],');
    buffer.writeln('  ),');
  }

  buffer.writeln('};');
  buffer.writeln('''
List<String> get supportedDrawShowLetters {
  final letters = zaitsevLetterDrawings.keys.toList()
    ..sort((a, b) => a.compareTo(b));
  return letters;
}

bool isSupportedDrawShowLetter(String letter) {
  return zaitsevLetterDrawings.containsKey(letter);
}

ZaitsevLetterDrawing? getZaitsevLetterDrawing(String letter) {
  return zaitsevLetterDrawings[letter];
}
''');

  final out = File(r'd:\projects\LARNES-2.0\larnes-mobile\lib\trainers\reading\zaitsev\zaitsev_catalog.dart');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(buffer.toString());
  print('Wrote ${letterBlocks.length} letters to ${out.path}');
}
