library epub3_io;

import 'dart:io';

import 'package:archive/archive_io.dart';

import "model.dart";
export "model.dart";
import 'src/reader.dart';
export 'src/reader.dart';
import 'src/writer.dart';
export 'src/writer.dart';

/// Global function for open file as epub and read content to [Book].
/// ```dart
/// import 'package:epubrs/epubrs.dart' as epub;
/// final book = epub.openFile('path-to-file.epub');
/// ```
Book? readFile(String filepath) =>
    Reader(ZipDecoder().decodeBuffer(InputFileStream(filepath)))
        .parse(extractContent: true);

/// Global function for open file as epub and read content to [Book].
/// ```dart
/// import 'package:epubrs/epubrs.dart' as epub;
/// final book = epub.openFile('path-to-file.epub');
/// ```
void writeFile(Book book, String fn) {
  File(fn)
    ..createSync()
    ..writeAsBytesSync(Writer(book).encode()!);
}
