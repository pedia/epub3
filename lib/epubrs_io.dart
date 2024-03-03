library epubrs;

import 'dart:convert';
import 'dart:io';

import 'src/base.dart';

import 'package:archive/archive_io.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:path/path.dart' as p;
import 'package:quiver/collection.dart' show listsEqual;
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xml/xpath.dart' as xml;

part "src/model.dart";
part 'src/reader.dart';
part 'src/writer.dart';

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
    return ArchiveFile(path, 0, File(p.join(root,path)).readAsBytesSync());
  }
}
