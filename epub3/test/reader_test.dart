import 'package:epub3/epub3_io.dart';
import 'package:archive/archive_io.dart';
import 'package:test/test.dart';

void main() {
  test('epub2', () {
    final r = Reader(
        ZipDecoder().decodeBuffer(InputFileStream('test/res/epub2.epub')));
    final book = r.parse();
    expect(book!.version, Version.epub2);
    expect(
        book.metadata.gets('title'), equals(['Test title 1', 'Test title 2']));

    expect(book.metadata.gets('creator'), equals(['John Doe', 'Jane Doe']));
    expect(book.metadata.gets('contributor'),
        equals(['John Editor', 'Jane Editor']));
    expect(book.metadata.gets('identifier'),
        equals(['https://example.com/books/123', '9781234567890']));
    expect(book.metadata.gets('subject'),
        equals(['Test subject 1', 'Test subject 2']));
    expect(book.metadata.gets('publisher'),
        equals(['Test publisher 1', 'Test publisher 2']));
    expect(book.metadata.gets('description'), equals(['Test description']));
    expect(book.metadata.gets('type'), equals(['dictionary', 'preview']));
    expect(book.metadata.gets('format'), equals(['format-1', 'format-2']));
    expect(
        book.metadata.gets('source'),
        equals([
          'https://example.com/books/123/content-1.html',
          'https://example.com/books/123/content-2.html',
        ]));

    expect(book.manifest.length, 14);
    expect(
      book.manifest[0],
      equals(ManifestItem(
        id: 'item-front',
        mediaType: 'application/xhtml+xml',
        href: 'front.html',
      )),
    );

    expect(book.chapters.length, 3);
    expect(
        book.chapters[0],
        equals(Chapter(title: 'Chapter 1', href: 'chapter1.html', children: [
          Chapter(
              title: 'Chapter 1.1',
              href: 'chapter1.html#section-1',
              children: []),
          Chapter(
              title: 'Chapter 1.2',
              href: 'chapter1.html#section-2',
              children: []),
        ])));

    final cover = r.extractFile(book.cover!);
    expect(cover?.length, 116);
    final coverImage = r.extractFile(book.coverImage!);
    expect(coverImage?.length, 610);
  });

  test('epub3', () {
    final book = readFile('test/res/epub3.epub');
    expect(book!.version, Version.epub3);
    expect(
        book.metadata.gets('title'), equals(['Test title 1', 'Test title 2']));
    expect('John Doe', 'John Doe');
    expect(book.metadata.gets('creator'), equals(['John Doe', 'Jane Doe']));
    expect(book.metadata.gets('contributor'),
        equals(['John Editor', 'Jane Editor']));
    expect(book.metadata.gets('identifier'),
        equals(['https://example.com/books/123', '9781234567890']));
    expect(book.metadata.gets('subject'),
        equals(['Test subject 1', 'Test subject 2']));
    expect(book.metadata.gets('publisher'),
        equals(['Test publisher 1', 'Test publisher 2']));
    expect(book.metadata.gets('description'), equals(['Test description']));
    expect(book.metadata.gets('type'), equals(['dictionary', 'preview']));
    expect(book.metadata.gets('format'), equals(['format-1', 'format-2']));
    expect(
        book.metadata.gets('source'),
        equals([
          'https://example.com/books/123/content-1.html',
          'https://example.com/books/123/content-2.html',
        ]));

    expect(book.manifest.length, 17);
    expect(
      book.manifest[0],
      equals(ManifestItem(
        id: 'item-front',
        mediaType: 'application/xhtml+xml',
        href: 'front.html',
      )),
    );

    expect(book.chapters.length, 3);
    expect(
        book.chapters[0],
        equals(
            Chapter(title: 'Chapter 1', href: 'chapter1.html', children: [])));
    expect(
        book.chapters[1],
        equals(
            Chapter(title: 'Chapter 2', href: 'chapter2.html', children: [])));

    expect(book.hrefToPath('ncx'), 'toc.ncx');
  });

  const fs = [
    // 'test/res/alicesAdventuresUnderGround.epub',
    // 'test/res/epub2.epub',
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

  void dumpChapter(Book book, Chapter c, {int depth = 1}) {
    final char = '#'.codeUnits[0];
    final prefix = String.fromCharCodes(List.generate(depth, (index) => char));
    expect(c.title.contains('\n'), isFalse);
    expect(c.title.startsWith(' '), isFalse);

    final contentLength = c.href != null ? book.readBytes(c.href!)?.length : 0;

    print('$prefix "${c.title}" ${c.href} $contentLength');
    for (var cc in c.children) {
      dumpChapter(book, cc, depth: depth + 1);
    }
  }

  test('std-read', () {
    for (var f in fs) {
      print('epub: $f');
      final book = readFile(f)!;
      expect(book.manifest, isNotNull);

      print(' title: ${book.title} ${book.version}');
      print(' author: ${book.author}');

      for (var c in book.chapters) {
        dumpChapter(book, c);
      }

      void readit(Chapter c) {
        if (c.href != null) {
          final af = book.readBytes(c.href!);
          expect(af, isNotNull, reason: '${c.href} "${c.title}"');
        }
        for (var cc in c.children) {
          readit(cc);
        }
      }

      for (var c in book.chapters) {
        readit(c);
      }
    }
  });

  const csharput = [
    'test/res/53.epub',
    'test/res/55.epub',
    'test/res/57.epub',
    'test/res/invalid-manifest-epub2.epub',
    'test/res/invalid-manifest-epub3.epub',
    'test/res/missing-navigation-point.epub',
    'test/res/missing-toc.epub',
    'test/res/remote-content.epub',
    'test/res/xml11.epub',
  ];

  test('malformed', () {
    csharput.forEach((f) {
      print('epub: $f');
      final book = readFile(f)!;
      expect(book.manifest, isNotNull);
      // expect(book.catalog.title, isNotEmpty);
      print(' ver: ${book.version}');
      print(' title: ${book.title}');
      // print('author: ${book.author}');
      print(' cc: ${book.chapters.length}');
    });
  });
}
