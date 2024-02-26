# epub rs

[epubrs](https://github.com/pedia/epubrs) is an implement of [epub reading systems](https://www.w3.org/TR/epub-rs/).

Support epub2: 2.0 2.0.1 epub3: 3.0 3.0.1 3.2. Reader is fully tested, and writer is not finished yet.

## Example with dart:io
```dart
import 'package:archive/archive_io.dart' as epub;

final book = epub.readFile('test/res/epub3.epub')!;
print(book.version); // Version.epub3
print(book.title); // ce's Adventures Under Ground Being a facsimile of the original Ms. book afterwards developed into "Alice's Adventures in Wonderland"
print(book.author); // Lewis Carroll
print(book.chapters); // first level chapters
```

## Example without dart:io
```dart
import 'package:archive/archive.dart' as epub;

final book = epub.Reader.
  open(ZipDecoder().decodeBytes(bytes_or_file_content)).
  read();
```