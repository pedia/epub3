import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:path/path.dart' as p;
import 'package:quiver/collection.dart' show listsEqual;
import 'package:uuid/uuid.dart';

enum Version {
  /// epub2 2.0 2.0.1
  epub2,

  /// epub3 3.0 3.0.1 3.2
  epub3
}

///
class Chapter {
  final String title;
  final String? id;
  final String? href;
  final List<Chapter> children;

  /// raw content, always content of html file
  String? content;

  /// TODO: extract text from html document
  String get text => '';

  int get chapterCount => children.fold<int>(
        children.length,
        (prev, c) => prev + c.chapterCount,
      );

  Chapter({
    required this.title,
    this.id,
    this.href,
    this.children = const [],
    this.content,
  });

  factory Chapter.textContent(String title, String text) {
    return Chapter(
        title: title, content: Chapter.toHtml(title, text), children: []);
  }

// transform text to HTML
  static String toHtml(String title, String text) {
    final body = text
        .split('\n')
        .map((line) => '<p>' + HtmlEscape().convert(line.trim()) + '</p>')
        .join('\n\n');

    return '''<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8"/>
<title>$title</title></head>
<body>
$body
</body>
</html>
''';
  }

  /// Generate a manifest item if [Chapter] has content
  ManifestItem? get item {
    // TODO:
    if (content == null) {
      return null;
    }

    return ManifestItem(
      id: id ?? Object.hash(title, content).toRadixString(16),
      href: href ?? genhref(),
      mediaType: 'application/xhtml+xml',
    );
  }

  List<ManifestItem> get items {
    final cs = <ManifestItem>[];
    final i = item;
    if (i != null) {
      cs.add(i);
    }

    for (var c in children) {
      cs.addAll(c.items);
    }
    return cs;
  }

  /// Generate href for this Chapter
  /// maybe chapter index is right?
  String genhref() {
    return Object.hash(title, content).toRadixString(16) + '.html';
  }

  @override
  bool operator ==(Object other) =>
      other is Chapter &&
      other.title == title &&
      other.href == href &&
      listsEqual(other.children, children);

  @override
  String toString() => 'Chapter($title, $href, $children)';
}

class Book {
  final Version version;
  final List<ManifestItem> manifest;
  final Metadata metadata;
  final List<SpineItem> spine;
  final List<Chapter> chapters;

  /// Adapter to read content later
  final ContentReader? reader;

  Book({
    required this.version,
    required this.manifest,
    required this.metadata,
    required this.spine,
    required this.chapters,
    this.reader,
  });

  /// Create an empty book
  factory Book.create({
    required String title,
    required String author,
    ContentReader? reader,
  }) {
    return Book(
      version: Version.epub3,
      manifest: <ManifestItem>[],
      metadata: Metadata.create(title, author),
      spine: <SpineItem>[],
      chapters: [],
      reader: reader,
    );
  }

  void add(Chapter chapter) {
    chapters.add(chapter);
    manifest.addAll(chapter.items);
  }

  String get identifier => metadata.get('identifier')!;
  String get title => metadata.get('title') ?? '';
  String get author => metadata.get('creator') ?? '';

  String? get cover => manifest.firstWhereOrNull((i) => i.id == 'cover')?.href;
  String? get coverImage => manifest
      .firstWhereOrNull(
          (i) => i.properties == 'cover-image' || i.id == 'cover-image')
      ?.href;

  /// Navigation item
  ManifestItem? get nav {
    if (version == Version.epub2) {
      return manifest.firstWhereOrNull((element) => element.id == 'ncx');
    } else if (version == Version.epub3) {
      return manifest
          .firstWhereOrNull((i) => i.id == 'ncx' || i.properties == 'nav');
    }
    return null;
  }

  /// manifest id to href
  /// href normalize
  String hrefToPath(String href) {
    final pos = href.indexOf('#');
    String path = pos == -1 ? href : href.substring(0, pos);

    // id, not file
    if (p.extension(path).isEmpty) {
      final item = manifest.firstWhereOrNull((i) => i.id == path);
      if (item != null) {
        path = item.href!;
        // relative to opfroot
      }
    }
    return path;
  }

  String? readString(String href) {
    final buf = readBytes(href);
    if (buf != null) {
      return utf8.decode(buf);
    }
    return null;
  }

  Uint8List? readBytes(String href) {
    return reader?.extractFile(hrefToPath(href));
  }
}

/// Manifest Item
class ManifestItem {
  final String id;
  final String? href;
  final String mediaType;
  final String? mediaOverlay;
  final String? fallback;
  final String? properties;

  const ManifestItem({
    required this.id,
    this.href,
    required this.mediaType,
    this.mediaOverlay,
    this.fallback,
    this.properties,
  });

  /// return attributes in building xml
  Map<String, String> get attributes {
    return {
      'id': id,
      'href': href!,
      'media-type': mediaType,
      if (mediaOverlay != null) 'media-overlay': mediaOverlay!,
      if (fallback != null) 'fallback': fallback!,
      if (properties != null) 'properties': properties!,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ManifestItem &&
      other.id == id &&
      other.href == href &&
      other.mediaType == mediaType &&
      other.mediaOverlay == mediaOverlay &&
      other.fallback == fallback &&
      other.properties == properties;

  @override
  String toString() => 'ManifestItem($id, $mediaType, $href)';
}

/// Spine ItemRef
class SpineItem {
  final String idref;
  final bool? linear;
  const SpineItem({required this.idref, this.linear});

  /// return attributes in building xml
  Map<String, String> get attributes {
    return {
      if (linear != null) 'linear': linear! ? 'yes' : 'no',
      'idref': idref,
    };
  }
}

class Metadata {
  final Map<String, List<String>> meta;

  Metadata() : meta = Map();

  void add(String name, String value) {
    var vs = meta[name];
    if (vs == null) {
      vs = [value];
      meta[name] = vs;
    } else {
      vs.add(value);
    }
  }

  String? get(String name) {
    final vs = meta[name];
    return vs == null ? null : vs[0];
  }

  List<String>? gets(String name) => meta[name];

  factory Metadata.create(String title, String author) {
    final md = Metadata();
    md.add('title', title);
    md.add('creator', author);
    md.add('identifier', 'urn:uuid:' + Uuid().v4());
    return md;
  }
}

abstract class ContentReader {
  Uint8List? extractFile(String path);
}
