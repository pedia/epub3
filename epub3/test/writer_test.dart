import 'package:epub3/epub3_io.dart';
import 'package:test/test.dart';
import 'package:archive/archive.dart';

void main() {
  const fs = [
    // 'test/res/alicesAdventuresUnderGround.epub',
    'test/res/epub2.epub',
    'test/res/epub3.epub',
    'test/res/hittelOnGoldMines.epub',
    'test/res/std/WCAG.epub',
    'test/res/std/accessible_epub_3.epub',
    'test/res/std/cc-shared-culture.epub',
    'test/res/std/childrens-literature.epub',
    'test/res/std/childrens-media-query.epub',
    'test/res/std/cole-voyage-of-life-tol.epub',
    'test/res/std/cole-voyage-of-life.epub',
    'test/res/std/epub30-spec.epub',
    'test/res/std/figure-gallery-bindings.epub',
    'test/res/std/georgia-cfi.epub',
    'test/res/std/georgia-pls-ssml.epub',
    'test/res/std/hefty-water.epub',
    'test/res/std/igp-year5-school-maths.epub',
    'test/res/std/indexing-for-eds-and-auths-3f.epub',
    'test/res/std/indexing-for-eds-and-auths-3md.epub',
    'test/res/std/internallinks.epub',
    'test/res/std/israelsailing.epub',
    'test/res/std/jlreq-in-english.epub',
    'test/res/std/jlreq-in-japanese.epub',
    'test/res/std/linear-algebra.epub',
  ];

  test('epub3', () {
    for (var f in fs) {
      final book = readFile(f);
      expect(book, isNotNull);

      final w = Writer(book!);
      final a = Archive();
      w.write(a);

      // read again
      final book2 = Reader.open(a).read()!;
      // expect(book2!.author, book.author);
      expect(book2.title, book.title);
      expect(book2.chapters.length, equals(book.chapters.length));
      for (var i = 0; i < book2.chapters.length; i++) {
        expect(book2.chapters[i].title, equals(book.chapters[i].title));
        // expect(book2.chapters[i].href, equals(book.chapters[i].href));
        // expect(book2.chapters[i].children, equals(book.chapters[i].children));
      }
    }
  });
}
