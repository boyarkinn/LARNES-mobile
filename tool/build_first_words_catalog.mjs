import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const catalogTs = join(
  here,
  "../../platform/src/trainers/shared/first-words/catalog.ts",
);
const outPath = join(here, "../lib/trainers/shared/first_words/catalog.dart");

const source = readFileSync(catalogTs, "utf8");
const rowRe =
  /\{\s*slug:\s*"([^"]+)",\s*label:\s*"([^"]+)",\s*firstLetter:\s*"([^"]+)",\s*folder:\s*"([^"]+)"\s*\}/g;
const rows = [...source.matchAll(rowRe)].map((match) => ({
  slug: match[1],
  label: match[2],
  firstLetter: match[3],
  folder: match[4],
}));

if (rows.length !== 256) {
  throw new Error(`expected 256 words, got ${rows.length}`);
}

mkdirSync(dirname(outPath), { recursive: true });

const lines = [
  "/// Web: `platform/src/trainers/shared/first-words/catalog.ts`",
  "",
  "class FirstWord {",
  "  const FirstWord({",
  "    required this.slug,",
  "    required this.label,",
  "    required this.firstLetter,",
  "    required this.folder,",
  "  });",
  "",
  "  final String slug;",
  "  final String label;",
  "  final String firstLetter;",
  "  final String folder;",
  "}",
  "",
  "const firstWords = <FirstWord>[",
  ...rows.map(
    (word) =>
      `  FirstWord(slug: '${word.slug}', label: '${word.label}', firstLetter: '${word.firstLetter}', folder: '${word.folder}'),`,
  ),
  "];",
  "",
];

writeFileSync(outPath, lines.join("\n"), "utf8");
console.log(`wrote ${rows.length} words -> ${outPath}`);
