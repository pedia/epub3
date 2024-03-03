library epubrs;

import 'dart:convert';
// ignore: unused_import
import 'dart:typed_data';

import 'src/base.dart';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:path/path.dart' as p;
import 'package:quiver/collection.dart' show listsEqual;
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xml/xpath.dart' as xml;

part 'src/model.dart';
part 'src/reader.dart';
part 'src/writer.dart';
