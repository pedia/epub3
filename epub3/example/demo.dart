import 'package:epub3/epub3_io.dart' as epub;
// import 'package:image/image.dart';

void dumpChapter(epub.Chapter c, {int depth = 1}) {
  final char = '#'.codeUnits[0];
  final prefix = String.fromCharCodes(List.generate(depth, (index) => char));

  print('$prefix ${c.title}');
  for (var cc in c.children) {
    dumpChapter(cc, depth: depth + 1);
  }
}

void main(List<String> args) {
  final book =
      epub.readFile(args.isEmpty ? 'test/res/std/epub30-spec.epub' : args[0]);
  for (var c in book!.navigation.chapters) {
    dumpChapter(c);
  }

  epub.writeFile(book, 'alice.epub');

  final b2 = epub.readFile('alice.epub');
  for (var c in b2!.navigation.chapters) {
    dumpChapter(c);
  }
}
