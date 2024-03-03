part of epubrs;

/// epub2 2.0 2.0.1
/// epub3 3.0 3.0.1 3.2
enum Version { epub2, epub3 }

class Metadata {
  final List<String> title;
  final List<MetaCreator> creator;
  final List<String> subject;
  final List<String> description;
  final List<String> publisher;
  final List<MetaCreator> contributor;
  final List<String> type;
  final List<String> format;
  final List<MetaIdentifier> identifier;
  final List<String> source;
  final List<String> language;
  final List<String> relation;
  final List<String> coverage;
  final List<String> rights;
  final List<MetaDate> dates;
  final Map<String, String> meta;

  Metadata({
    required this.title,
    required this.creator,
    required this.subject,
    required this.description,
    required this.publisher,
    required this.contributor,
    required this.type,
    required this.format,
    required this.identifier,
    required this.source,
    required this.language,
    required this.relation,
    required this.coverage,
    required this.rights,
    required this.meta,
    required this.dates,
  });

  factory Metadata.create(String title, String author) => Metadata(
        title: [title],
        creator: [MetaCreator(author)],
        subject: [],
        description: [],
        publisher: [],
        contributor: [],
        type: [],
        format: [],
        identifier: [
          MetaIdentifier(identifier: 'urn:uuid:' + Uuid().v4(), id: 'pub-id'),
        ],
        source: [],
        language: [],
        relation: [],
        coverage: [],
        rights: [],
        meta: {},
        dates: [],
      );
}

class MetaIdentifier {
  final String identifier;
  final String id;
  final String? scheme;
  const MetaIdentifier({
    required this.identifier,
    required this.id,
    this.scheme,
  });

  @override
  bool operator ==(Object other) =>
      other is MetaIdentifier &&
      other.identifier == identifier &&
      other.id == id &&
      other.scheme == scheme;
}

class MetaCreator {
  final String creator;
  final String? fileAs;
  final String? role;
  const MetaCreator(this.creator, {this.fileAs, this.role});

  @override
  bool operator ==(Object other) =>
      other is MetaCreator &&
      other.creator == creator &&
      other.fileAs == fileAs &&
      other.role == role;
}

class MetaDate {
  final String date;
  final String? event;
  const MetaDate(this.date, {this.event});
}

/// Manifest Item
class Item {
  final String id;
  final String? href;
  final String mediaType;
  final String? mediaOverlay;
  final String? fallback;
  final String? properties;

  const Item({
    required this.id,
    this.href,
    required this.mediaType,
    this.mediaOverlay,
    this.fallback,
    this.properties,
  });

  // to xml attributes for this Manifest Item
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
      other is Item &&
      other.id == id &&
      other.href == href &&
      other.mediaType == mediaType &&
      other.mediaOverlay == mediaOverlay &&
      other.fallback == fallback &&
      other.properties == properties;

  @override
  String toString() => 'ManifestItem($id, $mediaType, $href)';
}

class Spine {
  final String toc;
  final List<ItemRef> refs;
  const Spine(this.toc, this.refs);

  factory Spine.empty() => Spine('toc', []);
}

/// Spine ItemRef
class ItemRef {
  final String idref;
  final bool? linear;
  const ItemRef(this.idref, this.linear);

  // to xml attributes for this ItemRef
  Map<String, String> get attributes {
    return {
      if (linear != null) 'linear': linear! ? 'yes' : 'no',
      'idref': idref,
    };
  }
}

class Manifest {
  final Version version;
  final Metadata metadata;
  final List<Item> items;
  final Spine spine;
  // TODO: guide
  Manifest({
    required this.version,
    required this.metadata,
    required this.items,
    required this.spine,
  });

  String get identifier => metadata.identifier.first.identifier;

  String tocFile() {
    Item? entry;
    if (version == Version.epub2) {
      entry = items.where((element) => element.id == spine.toc).firstOrNull;
    } else if (version == Version.epub3) {
      // TODO: this is better?
      // id="nav" first
      // properties="nav" second
      entry = items
          .where((i) => i.id == 'ncx' || i.properties == 'nav')
          .firstOrNull;
      // entry ??= manifest.where((i) => i.properties == 'nav').firstOrNull;

      if (entry == null) {
        for (var i in items) {
          print(i);
        }
      }
    }
    return p.join('', entry?.href ?? '');
  }
}

class Chapter {
  final String title;
  final String? href;
  final List<Chapter> children;
  final String? content;

  int get chapterCount => children.fold<int>(
        children.length,
        (prev, c) => prev + c.chapterCount,
      );

  const Chapter({
    required this.title,
    this.href,
    this.children = const [],
    this.content,
  });

  factory Chapter.content(String title, String content) {
    return Chapter(title: title, content: content);
  }

  /// Generate a manifest item if [Chapter] has content
  Item? get item {
    // TODO:
    if (content == null) {
      return null;
    }

    // convert title to default href
    final fn = href ?? '${title.replaceAll(' ', '-')}.html';
    return Item(
      id: 'h' + Object.hash(title, href).toRadixString(16),
      href: fn,
      mediaType: 'application/xhtml+xml',
    );
  }

  List<Item> get items {
    final cs = <Item>[];
    final i = item;
    if (i != null) {
      cs.add(i);
    }

    for (var c in children) {
      cs.addAll(c.items);
    }
    return cs;
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

class Navigation {
  final String? title;
  final String? author;
  final List<Chapter> chapters;

  Navigation({
    this.title,
    this.author,
    required this.chapters,
  });

  int get chapterCount => chapters.fold<int>(
        chapters.length,
        (prev, link) => prev + link.chapterCount,
      );
}

abstract class ContentReader {
  ArchiveFile readFile(String path);
}

class Book {
  final Manifest manifest;
  final Navigation navigation;
  final ContentReader? reader;
  Book(this.manifest, this.navigation, this.reader);

  factory Book.create(
      {required String title, required String author, ContentReader? reader}) {
    return Book(
      Manifest(
        version: Version.epub3,
        metadata: Metadata.create(title, author),
        items: [],
        spine: Spine.empty(),
      ),
      Navigation(title: title, author: author, chapters: []),
      reader,
    );
  }

  void add(Chapter chapter) {
    navigation.chapters.add(chapter);
    manifest.items.addAll(chapter.items);
  }

  Version get version => manifest.version;
  String get title {
    if (navigation.title != null) {
      return navigation.title!;
    }
    return manifest.metadata.title.isNotEmpty ? manifest.metadata.title[0] : '';
  }

  String get author {
    if (navigation.author != null) {
      return navigation.author!;
    }
    return manifest.metadata.creator.isNotEmpty
        ? manifest.metadata.creator[0].creator
        : '';
  }

  String? get cover =>
      manifest.items.firstWhereOrNull((i) => i.id == 'cover')?.href;
  String? get coverImage => manifest.items
      .firstWhereOrNull(
          (i) => i.properties == 'cover-image' || i.id == 'cover-image')
      ?.href;

  List<Chapter> get chapters => navigation.chapters;

  /// Navigation item
  Item? get nav {
    if (version == Version.epub2) {
      return manifest.items
          .where((element) => element.id == manifest.spine.toc)
          .firstOrNull;
    } else if (version == Version.epub3) {
      return manifest.items
          .where((i) => i.id == 'ncx' || i.properties == 'nav')
          .firstOrNull;
    }
    return null;
  }
}
