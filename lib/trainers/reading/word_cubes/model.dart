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

List<CubeRound> cubeRoundsFromPayload(Map<String, dynamic>? payload) {
  final rounds = payload?['rounds'];
  if (rounds is! List || rounds.isEmpty) return const [];
  return rounds.map((raw) {
    final word = raw['word'] as Map;
    final parts = (word['parts'] as List)
        .map(
          (part) => CubeWordPart(
            part['cubeId'].toString(),
            part['target'].toString(),
          ),
        )
        .toList();
    final cubes = (raw['cubes'] as List).map((item) {
      final cube = item['cube'] as Map;
      final faces = (cube['faces'] as List)
          .map((face) => face.toString())
          .toList();
      final initial = (item['initialFace'] as num).toInt();
      if (initial < 0 ||
          initial >= faces.length ||
          !faces.contains(item['target']))
        throw const FormatException('Invalid frozen cube');
      return WordCube(
        WarehouseCube(
          cube['id'].toString(),
          cube['kind'].toString(),
          cube['small'] == true,
          faces,
        ),
        item['target'].toString(),
        initial,
      );
    }).toList();
    return CubeRound(
      CubeWord(word['slug'].toString(), word['word'].toString(), parts),
      cubes,
    );
  }).toList();
}

int nextCubeFace(WarehouseCube cube, int face) =>
    (face + 1) % cube.faces.length;
bool isCubeRoundComplete(CubeRound round, List<int> faces) =>
    faces.length == round.cubes.length &&
    List.generate(round.cubes.length, (index) => index).every(
      (index) =>
          faces[index] >= 0 &&
          faces[index] < round.cubes[index].cube.faces.length &&
          round.cubes[index].cube.faces[faces[index]] ==
              round.cubes[index].target,
    );
