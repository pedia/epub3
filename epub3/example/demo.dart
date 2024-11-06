import 'package:epub3/epub3_io.dart' as epub;
// import 'package:image/image.dart';

void dumpChapter(epub.Book b, epub.Chapter c, {int depth = 1}) {
  final char = '#'.codeUnits[0];
  final prefix = String.fromCharCodes(List.generate(depth, (index) => char));

  // final af = b.reader?.readFile(c.href!);
  // final cc = af != null ? af.size : 0;

  var cc = 0;

  print('🚩$prefix ${c.title} ${c.href} $cc');
  for (var cc in c.children) {
    dumpChapter(b, cc, depth: depth + 1);
  }
}

void main(List<String> args) {
  final book =
      epub.readFile(args.isEmpty ? 'test/res/std/epub30-spec.epub' : args[0]);
  for (var c in book!.navigation.chapters) {
    dumpChapter(book, c);
  }

  epub.writeFile(book, 'alice.epub');

  final b2 = epub.readFile('alice.epub');
  for (var c in b2!.navigation.chapters) {
    dumpChapter(b2, c);
  }
}
