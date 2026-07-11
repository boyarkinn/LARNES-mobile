const supportedZaitsevLetters = [
  'А', 'О', 'У', 'Ы', 'Э', 'Я', 'Ё', 'Ю', 'И', 'Е', 'Б', 'П', 'В', 'Ф', 'Г', 'К',
  'Д', 'Т', 'Ж', 'Ш', 'З', 'С', 'Л', 'М', 'Н', 'Р', 'Й', 'Х', 'Ц', 'Ч', 'Щ', 'Ъ', 'Ь',
];

final _supportedZaitsevLetterSet = Set<String>.from(supportedZaitsevLetters);

bool isSupportedDrawShowLetter(String letter) {
  return _supportedZaitsevLetterSet.contains(letter);
}

bool isSupportedBuildLetter(String letter) {
  return isSupportedDrawShowLetter(letter);
}
