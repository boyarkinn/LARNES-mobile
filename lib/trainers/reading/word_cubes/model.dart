part 'catalog.dart';

class WarehouseCube {
  const WarehouseCube(this.id, this.kind, this.small, this.faces);
  final String id, kind;
  final bool small;
  final List<String> faces;
}

class CubeWordPart {
  const CubeWordPart(this.cubeId, this.target);
  final String cubeId, target;
}

class CubeWord {
  const CubeWord(this.slug, this.word, this.parts);
  final String slug, word;
  final List<CubeWordPart> parts;
}

class WordCube {
  const WordCube(this.cube, this.target, this.initialFace);
  final WarehouseCube cube;
  final String target;
  final int initialFace;
}

class CubeRound {
  const CubeRound(this.word, this.cubes);
  final CubeWord word;
  final List<WordCube> cubes;
}

List<CubeRound> buildCubeRounds(String slug, double Function() rng) {
  final words = cubeWords.where((word) => slug == 'all' || word.slug == slug).toList();
  if (words.isEmpty) throw ArgumentError('INVALID_CUBE_WORD_SELECTION');
  return words.map((word) {
    if (!RegExp(r'^[А-ЯЁ]{1,4}$').hasMatch(word.word) || word.parts.map((part) => part.target).join() != word.word) {
      throw ArgumentError('INVALID_CUBE_WORD');
    }
    return CubeRound(word, word.parts.map((part) {
      final cube = warehouseCubes.firstWhere((cube) => cube.id == part.cubeId);
      if (!cube.faces.contains(part.target)) throw ArgumentError('INVALID_CUBE_WORD');
      final incorrect = [for (var i = 0; i < cube.faces.length; i++) if (cube.faces[i] != part.target) i];
      return WordCube(cube, part.target, incorrect[(rng() * incorrect.length).floor()]);
    }).toList());
  }).toList();
}

int nextCubeFace(WarehouseCube cube, int face) => (face + 1) % cube.faces.length;
bool isCubeRoundComplete(CubeRound round, List<int> faces) => faces.length == round.cubes.length &&
    List.generate(round.cubes.length, (index) => index).every((index) => faces[index] >= 0 && faces[index] < round.cubes[index].cube.faces.length && round.cubes[index].cube.faces[faces[index]] == round.cubes[index].target);
