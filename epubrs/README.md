# epubrs(epub reading systems)

[epubrs](https://github.com/pedia/epubrs) is an implement of [epub reading systems](https://www.w3.org/TR/epub-rs/).

Support epub2: 2.0 2.0.1 epub3: 3.0 3.0.1 3.2.

Reader and Writer with content are fully tested.

## Example with dart:io
```dart
import 'package:epubrs/epubrs_io.dart' as epub;

final book = epub.readFile('test/res/alice.epub')!;
print(book.version); // Version.epub3
print(book.title); // ce's Adventures Under Ground Being a facsimile of the original Ms. book afterwards developed into "Alice's Adventures in Wonderland"
print(book.author); // Lewis Carroll
print(book.chapters); // first level chapters
```

## Example without dart:io
```dart
import 'package:epubrs/epubrs.dart' as epub;
import 'package:archive/archive_io.dart';

final book = epub.Reader.
  open(ZipDecoder().decodeBytes(bytes_or_file_content)).
  read();
```

## Write epub3.0 example

This example pass [epubcheck](https://www.w3.org/publishing/epubcheck/)

```dart
import 'package:epubrs/epubrs_io.dart' as epub;

final book = epub.Book.create(
  title: 'dream world',
  author: 'joe doe',
);

book.add(
  epub.Chapter(title: 'Part 1', children: [
    epub.Chapter.content('Chapter 1', 'Content of Chapter 1'),
    epub.Chapter.content('Chapter 2', 'Content of Chapter 2'),
  ]),
);

epub.writeFile(book, 'new.epub');
```
