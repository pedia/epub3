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
        identifier: [],
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
  final String? id;
  final String? scheme;
  const MetaIdentifier(this.identifier, {this.id, this.scheme});

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

/// manifest item
class ManifestItem {
  final String? id;
  final String? type;
  final String? href;
  final String? mediaOverlay;
  final String? requiredNamespace;
  final String? requiredModules;
  final String? fallback;
  final String? fallbackStyle;
  final String? properties;

  const ManifestItem({
    this.id,
    this.type,
    this.href,
    this.mediaOverlay,
    this.requiredNamespace,
    this.requiredModules,
    this.fallback,
    this.fallbackStyle,
    this.properties,
  });

  @override
  bool operator ==(Object other) =>
      other is ManifestItem &&
      other.id == id &&
      other.type == type &&
      other.href == href &&
      other.mediaOverlay == mediaOverlay &&
      other.requiredNamespace == requiredNamespace &&
      other.requiredModules == requiredModules &&
      other.fallback == fallback &&
      other.fallbackStyle == fallbackStyle &&
      other.properties == properties;
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
  final bool linear;
  const ItemRef(this.idref, this.linear);
}

class Scheme {
  final Version version;
  final Metadata metadata;
  final List<ManifestItem> manifest;
  final Spine spine;
  // TODO: guide
  Scheme({
    required this.version,
    required this.metadata,
    required this.manifest,
    required this.spine,
  });

  String tocFile() {
    ManifestItem? entry;
    if (version == Version.epub2) {
      entry = manifest.where((element) => element.id == spine.toc).firstOrNull;
    } else if (version == Version.epub3) {
      // TODO: this is better?
      // id="nav" first
      // properties="nav" second
      entry = manifest
          .where((i) => i.id == 'ncx' || i.properties == 'nav')
          .firstOrNull;
      // entry ??= manifest.where((i) => i.properties == 'nav').firstOrNull;

      if (entry == null) {
        for (var i in manifest) {
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

  int get chapterCount => children.fold<int>(
        children.length,
        (prev, c) => prev + c.chapterCount,
      );

  const Chapter({
    required this.title,
    this.href,
    required this.children,
  });

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

class Book {
  final Scheme scheme;
  final Navigation navigation;
  Book(this.scheme, this.navigation);

  factory Book.create(String title, String author) {
    return Book(
      Scheme(
        version: Version.epub3,
        metadata: Metadata.create(title, author),
        manifest: [],
        spine: Spine.empty(),
      ),
      Navigation(title: title, author: author, chapters: []),
    );
  }

  Version get version => scheme.version;
  String get title {
    if (navigation.title != null) {
      return navigation.title!;
    }
    return scheme.metadata.title.isNotEmpty ? scheme.metadata.title[0] : '';
  }

  String get author {
    if (navigation.author != null) {
      return navigation.author!;
    }
    return scheme.metadata.creator.isNotEmpty
        ? scheme.metadata.creator[0].creator
        : '';
  }

  String? get cover =>
      scheme.manifest.firstWhereOrNull((i) => i.id == 'cover')?.href;
  String? get coverImage => scheme.manifest
      .firstWhereOrNull(
          (i) => i.properties == 'cover-image' || i.id == 'cover-image')
      ?.href;

  List<Chapter> get chapters => navigation.chapters;
}
