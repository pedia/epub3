import 'package:epub3/epub3_io.dart' as epub;

void dumpChapter(epub.Chapter c, {int depth = 1}) {
  final char = '#'.codeUnits[0];
  final prefix = String.fromCharCodes(List.generate(depth, (index) => char));

  print('$prefix ${c.title}');
  for (var cc in c.children) {
    dumpChapter(cc, depth: depth + 1);
  }
}

void main(List<String> args) {
  final book = epub.Book.create(
    title: 'dream world',
    author: 'joe doe',
  );

  book.add(
    epub.Chapter(title: 'Part 1', children: [
      epub.Chapter.textContent('Chapter 1', 'Chapter 1 content'),
      epub.Chapter.textContent('Chapter 2', 'Chapter 2 content'),
    ]),
  );

  for (var c in book.navigation.chapters) {
    dumpChapter(c);
  }

  epub.writeFile(book, 'new.epub');

  // [epubcheck](https://www.w3.org/publishing/epubcheck/) result:
  // $ java -jar epubcheck-5.1.0/epubcheck.jar new.epub
  //
  // Validating using EPUB version 3.3 rules.
  // No errors or warnings detected.
  // Messages: 0 fatals / 0 errors / 0 warnings / 0 infos
}
