library epub3;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import "src/model.dart";
export "src/model.dart";
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
    Reader.open(ZipDecoder().decodeBuffer(InputFileStream(filepath))).read();

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

class LocalFileReader extends ContentReader {
  final String root;
  LocalFileReader({this.root = '.'});

  @override
  ArchiveFile readFile(String path) {
    return ArchiveFile(path, 0, File(p.join(root, path)).readAsBytesSync());
  }
}
