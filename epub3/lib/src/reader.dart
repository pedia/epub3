import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart' as xml;
import 'package:xml/xpath.dart' as xml;

import 'model.dart';

/// [Reader] read `package document` and content from zip file.
class Reader extends ContentReader {
  factory Reader.open(Archive archive) {
    final rootFile = extractRootFileName(archive);
    return Reader(archive, rootFile!);
  }

  final Archive archive;

  // like OEBPS/content.opf
  final String rootFile;

  Reader(this.archive, this.rootFile);

  static const opfNS = 'http://www.idpf.org/2007/opf';

  Book? read({bool extractContent = false}) {
    final package = parsePackage(rootFile);
    if (package == null) {
      return null;
    }

    final navfile = package.manifest.tocFile(package.version);
    final nav = package.version == Version.epub2
        ? readNavigation2(navfile)
        : readNavigation3(navfile);
    final book = Book(package.version, package.manifest, package.metadata,
        package.spine, nav ?? Navigation(chapters: []), this);

    if (extractContent) {
      book.chapters.forEach((ch) => _loadContent(book, ch));
    }
    return book;
  }

  void _loadContent(Book book, Chapter ch) {
    ch.content = book.readString(ch.href!);
    for (Chapter sub in ch.children) {
      _loadContent(book, sub);
    }
  }

  static const containerFN = 'META-INF/container.xml';

  /// extract rootfile from META-INF/container.xml
  ///
  /// <?xml version='1.0' encoding='utf-8'?>
  /// <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  ///   <rootfiles>
  ///     <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  ///   </rootfiles>
  /// </container>
  static String? extractRootFileName(Archive archive) {
    final af = archive.files
        .firstWhereOrNull((ArchiveFile file) => file.name == containerFN);
    if (af != null) {
      final doc = xml.XmlDocument.parse(utf8.decode(af.content)).rootElement;
      return _findNodeAttr(doc, '/container/rootfiles/rootfile', 'full-path');
    }
    return null;
  }

  /// Parse Package document normal as OEBPS/content.opf
  Package? parsePackage(String path) {
    // root element, <package>
    var doc = _readAsXml(path);
    if (doc == null) return null;

    late Version version;

    final vs = doc.getAttribute('version');
    if (vs == '2.0') {
      version = Version.epub2;
    } else if (vs == '3.0') {
      version = Version.epub3;
    } else {
      throw Exception('Unsupported EPUB version: $vs.');
    }

    return Package(
      version,
      _extractMetadata(
          doc.findElements('metadata', namespace: opfNS).first, version),
      Manifest(_extractManifest(
          doc.findElements('manifest', namespace: opfNS).first)),
      _extractSpine(doc.findElements('spine', namespace: opfNS).first),
    );
  }

  /// replace \r\n as space in title
  String clean(String s) {
    return s
        .split('\n')
        .map((i) => i.trim())
        .join(' ')
        .replaceAll('\u00a0', ' ') // U+00A0	 	0xc2 0xa0	NO-BREAK SPACE
        .replaceAll('  ', ' ')
        .trim();
  }

  Metadata _extractMetadata(xml.XmlElement parent, Version version) {
    return Metadata(
      title: _texts(parent.findElements('dc:title')),
      creator: _extractMetaCreator(parent.findElements('dc:creator')),
      subject: _texts(parent.findElements('dc:subject')),
      description: _texts(parent.findElements('dc:description')),
      publisher: _texts(parent.findElements('dc:publisher')),
      contributor: _extractMetaCreator(parent.findElements('dc:contributor')),
      type: _texts(parent.findElements('dc:type')),
      format: _texts(parent.findElements('dc:format')),
      identifier: _extractMetaIdentifier(parent.findElements('dc:identifier')),
      source: _texts(parent.findElements('dc:source')),
      language: _texts(parent.findElements('dc:language')),
      relation: _texts(parent.findElements('dc:relation')),
      coverage: _texts(parent.findElements('dc:coverage')),
      rights: _texts(parent.findElements('dc:rights')),
      meta: _extractMeta(parent.findElements('meta'), version),
      dates: _extractMetaDate(parent.findElements('dc:date')),
    );
  }

  Map<String, String> _extractMeta(
      Iterable<xml.XmlElement> es, Version version) {
    // v2
    if (version == Version.epub2) {
      return Map.fromEntries(
        es.map(
          (e) => MapEntry(
            e.getAttribute('name')!,
            e.getAttribute('content')!,
          ),
        ),
      );
    } else {
      // for (var e in es) {
      //   print('meta: ${e.toXmlString()}');
      // }
      return Map.fromEntries(
        es.map(
          (e) {
            final p = e.getAttribute('property');
            if (p != null) {
              return MapEntry(p, e.innerText);
            } else {
              return MapEntry(
                e.getAttribute('name')!,
                e.getAttribute('content')!,
              );
            }
          },
        ),
      );
    }
  }

  List<Item> _extractManifest(xml.XmlElement parent) {
    return parent.childElements
        .map((e) => Item(
              id: e.getAttribute('id') ?? '',
              mediaType:
                  e.getAttribute('media-type') ?? 'application/xhtml+xml',
              href: e.getAttribute('href'),
              mediaOverlay: e.getAttribute('media-overlay'),
              fallback: e.getAttribute('fallback'),
              properties: e.getAttribute('properties'),
            ))
        .toList();
  }

  Spine _extractSpine(xml.XmlElement parent) {
    return Spine(
        parent.getAttribute('toc') ?? 'ncx',
        parent.childElements
            .map((e) => ItemRef(
                  e.getAttribute('idref')!,
                  e.getAttribute('linear') == null
                      ? null
                      : e.getAttribute('linear') == 'no'
                          ? false
                          : true,
                ))
            .toList());
  }

  List<String> _texts(Iterable<xml.XmlElement> es) =>
      es.map((e) => clean(e.innerText)).toList();

  List<MetaIdentifier> _extractMetaIdentifier(Iterable<xml.XmlElement> es) => es
      .map((e) => MetaIdentifier(
            identifier: e.innerText,
            id: e.getAttribute('id') ?? 'pub-id',
            scheme: e.getAttribute('opf:scheme'),
          ))
      .toList();

  List<MetaCreator> _extractMetaCreator(Iterable<xml.XmlElement> es) => es
      .map(
        (e) => MetaCreator(
          e.innerText,
          fileAs: e.getAttribute('opf:file-as'),
          role: e.getAttribute('opf:role'),
        ),
      )
      .toList();

  List<MetaDate> _extractMetaDate(Iterable<xml.XmlElement> es) => es
      .map(
        (e) => MetaDate(
          e.innerText,
          event: e.getAttribute('opf:event'),
        ),
      )
      .toList();

  Navigation? readNavigation2(String path) {
    final doc = _readAsXml(pathOf(path));
    if (doc == null) return null;

    return _readNav2(doc);
  }

  Navigation? _readNav2(xml.XmlElement doc) {
    final title = doc.findElements('docTitle').firstOrNull?.innerText;
    final author = doc.findElements('docAuthor').firstOrNull?.innerText.trim();
    final map = doc.findElements('navMap').firstOrNull;
    final links = map?.findElements('navPoint').map(_readNavPoint).toList();
    return Navigation(
      title: title != null ? clean(title) : null,
      author: author,
      chapters: links ?? [],
    );
  }

  Chapter _readNavPoint(xml.XmlElement e) {
    return Chapter(
      title: clean(e.findAllElements('navLabel').firstOrNull?.innerText ?? ''),
      href: e.findAllElements('content').firstOrNull?.getAttribute('src'),
      children: e.findAllElements('navPoint').map(_readNavPoint).toList(),
      // TODO: content, #2
    );
  }

  /// path maybe "EPUB/xhtml/epub30-nav.xhtml"
  /// nav / ol / li / span|a
  Navigation? readNavigation3(String path) {
    final doc = _readAsXml(pathOf(path));
    if (doc == null) return null;

    if (doc.localName == 'ncx') {
      return _readNav2(doc);
    }

    // lot: epub:type="toc" or epub:type="lot"?
    // page-list
    // landmarks

    final nav = doc.findAllElements('nav').first;
    return Navigation(chapters: _readOl(nav));
  }

  List<Chapter> _readOl(xml.XmlElement parent) {
    final ol = parent.findElements('ol').firstOrNull;
    return ol == null
        ? []
        : ol.findElements('li').map((e) => _readLi(e)).toList();
  }

  Chapter _readLi(xml.XmlElement li) {
    final span = li.findElements('span').firstOrNull;
    final a = li.findElements('a').firstOrNull;

    final id = li.getAttribute('id');
    final href = id != null ? id : a?.getAttribute('href');

    return Chapter(
      title: clean(span != null ? span.innerText : a?.innerText ?? ''),
      href: href,
      children: _readOl(li),
    );
  }

  /// Relative path by rootfile
  String pathOf(String fp) => p.join(p.dirname(rootFile), fp);

  /// Read an [ArchiveFile]
  ArchiveFile? readFile(String path) {
    assert(path.indexOf('#') == -1);

    // pathOf for relative path
    // normalize for avoid ./
    path = pathOf(p.normalize(path));

    return archive.files
        .firstWhereOrNull((ArchiveFile file) => file.name == path);
  }

  /// Open archive file as xml
  xml.XmlElement? _readAsXml(String path) {
    final container =
        archive.files.firstWhereOrNull((ArchiveFile file) => file.name == path);
    if (container != null) {
      return xml.XmlDocument.parse(utf8.decode(container.content)).rootElement;
    }
    return null;
  }

  /// Returns the first String property with this name or null
  /// ```xml
  /// <name ns="ns">return part</name>
  /// ```
  // static String? getTextSafe(
  //   xml.XmlElement node,
  //   String name, {
  //   String? namespace,
  // }) {
  //   final elements = node.findElements(name, namespace: namespace);
  //   if (elements.isEmpty) {
  //     return null;
  //   }
  //   return elements.first.innerText;
  // }

  /// Find first node by xpath, return the attribute's value by name
  static String? _findNodeAttr(
      xml.XmlElement node, String xpath, String attrName) {
    final elements = node.xpath(xpath);
    if (elements.isEmpty) {
      return null;
    }
    return elements.first.getAttribute(attrName);
  }
}
