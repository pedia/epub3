import 'package:epubrs/epubrs_io.dart';
import 'package:archive/archive_io.dart';
import 'package:test/test.dart';

void main() {
  const fs = [
    'test/res/alicesAdventuresUnderGround.epub',
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

  test('epub2', () {
    final r = Reader.open(
        ZipDecoder().decodeBuffer(InputFileStream('test/res/epub2.epub')));
    final book = r.read();
    expect(book!.version, Version.epub2);
    expect(
        book.scheme.metadata.title, equals(['Test title 1', 'Test title 2']));
    expect(
      MetaCreator('John Doe', fileAs: 'Doe, John', role: 'author') ==
          MetaCreator('John Doe', fileAs: 'Doe, John', role: 'author'),
      isTrue,
    );
    expect(
        book.scheme.metadata.creator,
        equals([
          MetaCreator('John Doe', fileAs: 'Doe, John', role: 'author'),
          MetaCreator('Jane Doe', fileAs: 'Doe, Jane', role: 'author'),
        ]));
    expect(
        book.scheme.metadata.contributor,
        equals([
          MetaCreator('John Editor', fileAs: 'Editor, John', role: 'editor'),
          MetaCreator('Jane Editor', fileAs: 'Editor, Jane', role: 'editor'),
        ]));
    expect(
        book.scheme.metadata.identifier,
        equals([
          MetaIdentifier('https://example.com/books/123',
              id: 'identifier-1', scheme: 'URI'),
          MetaIdentifier('9781234567890', id: 'identifier-2', scheme: 'ISBN'),
        ]));
    expect(book.scheme.metadata.subject,
        equals(['Test subject 1', 'Test subject 2']));
    expect(book.scheme.metadata.publisher,
        equals(['Test publisher 1', 'Test publisher 2']));
    expect(book.scheme.metadata.description, equals(['Test description']));
    expect(book.scheme.metadata.type, equals(['dictionary', 'preview']));
    expect(book.scheme.metadata.format, equals(['format-1', 'format-2']));
    expect(
        book.scheme.metadata.source,
        equals([
          'https://example.com/books/123/content-1.html',
          'https://example.com/books/123/content-2.html',
        ]));

    expect(book.scheme.manifest.length, 14);
    expect(
      book.scheme.manifest[0],
      equals(ManifestItem(
        id: 'item-front',
        type: 'application/xhtml+xml',
        href: 'front.html',
      )),
    );

    expect(book.navigation.chapterCount, 5);
    expect(
        book.navigation.chapters[0],
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

    final cover = r.readFile(book.cover!);
    expect(cover!.content.length, 116);
    final coverImage = r.readFile(book.coverImage!);
    expect(coverImage!.content.length, 610);
  });

  test('epub3', () {
    final book = readFile('test/res/epub3.epub');
    expect(book!.version, Version.epub3);
    expect(
        book.scheme.metadata.title, equals(['Test title 1', 'Test title 2']));
    expect(
      MetaCreator('John Doe', fileAs: 'Doe, John', role: 'author'),
      MetaCreator('John Doe', fileAs: 'Doe, John', role: 'author'),
    );
    expect(
        book.scheme.metadata.creator,
        equals([
          MetaCreator('John Doe', fileAs: 'Doe, John', role: 'author'),
          MetaCreator('Jane Doe', fileAs: 'Doe, Jane', role: 'author'),
        ]));
    expect(
        book.scheme.metadata.contributor,
        equals([
          MetaCreator('John Editor', fileAs: 'Editor, John', role: 'editor'),
          MetaCreator('Jane Editor', fileAs: 'Editor, Jane', role: 'editor'),
        ]));
    expect(
        book.scheme.metadata.identifier,
        equals([
          MetaIdentifier('https://example.com/books/123',
              id: 'identifier-1', scheme: 'URI'),
          MetaIdentifier('9781234567890', id: 'identifier-2', scheme: 'ISBN'),
        ]));
    expect(book.scheme.metadata.subject,
        equals(['Test subject 1', 'Test subject 2']));
    expect(book.scheme.metadata.publisher,
        equals(['Test publisher 1', 'Test publisher 2']));
    expect(book.scheme.metadata.description, equals(['Test description']));
    expect(book.scheme.metadata.type, equals(['dictionary', 'preview']));
    expect(book.scheme.metadata.format, equals(['format-1', 'format-2']));
    expect(
        book.scheme.metadata.source,
        equals([
          'https://example.com/books/123/content-1.html',
          'https://example.com/books/123/content-2.html',
        ]));

    expect(book.scheme.manifest.length, 17);
    expect(
      book.scheme.manifest[0],
      equals(ManifestItem(
        id: 'item-front',
        type: 'application/xhtml+xml',
        href: 'front.html',
      )),
    );

    expect(book.navigation.chapterCount, 5);
    expect(
        book.navigation.chapters[0],
        equals(Chapter(title: 'Test span header 1', children: [
          Chapter(title: 'Chapter 1', href: 'chapter1.html', children: []),
        ])));
    expect(
        book.navigation.chapters[1],
        equals(Chapter(title: 'Test span header 2', children: [
          Chapter(title: 'Chapter 2', href: 'chapter2.html', children: []),
          Chapter(title: 'Chapter 3', href: 'chapter3.html', children: []),
        ])));
  });

  void dumpChapter(Chapter c, {int depth = 1}) {
    final char = '#'.codeUnits[0];
    final prefix = String.fromCharCodes(List.generate(depth, (index) => char));
    expect(c.title.contains('\n'), isFalse);
    expect(c.title.startsWith(' '), isFalse);

    print('$prefix ${c.title}');
    for (var cc in c.children) {
      dumpChapter(cc, depth: depth + 1);
    }
  }

  test('std-read', () {
    for (var f in fs) {
      print('epub: $f');
      final book = readFile(f);
      expect(book!.scheme, isNotNull);

      print(' title: ${book.title} ${book.version}');
      print(' author: ${book.author}');

      for (var c in book.navigation.chapters) {
        dumpChapter(c);
      }
    }
  });

  test('malformed', () {
    csharput.forEach((f) {
      print('epub: $f');
      final book = readFile(f);
      expect(book!.scheme, isNotNull);
      // expect(book.catalog.title, isNotEmpty);
      print(' ver: ${book.version}');
      print(' title: ${book.title}');
      // print('author: ${book.author}');
      print(' cc: ${book.navigation.chapterCount}');
    });
  });
}
