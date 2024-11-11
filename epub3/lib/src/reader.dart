import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:epub3/epub3_io.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart' as xml;
import 'package:xml/xpath.dart' as xml;

import 'base.dart';
import '../model.dart';

class Reader implements ContentReader {
  final Archive archive;

  /// The path where the opf file placed
  late String opfroot;

  /// The path where nav file placed
  /// Href(s) relative it
  late String navfolder;

  Reader(this.archive);

  Book? parse({bool extractContent = false}) {
    // mimetype: application/epub+zip

    final opf = extractRootFilename(archive);
    if (opf == null) {
      throw Exception('Not an EPUB file');
    }

    opfroot = p.dirname(opf);

    // root element, <package>
    var package = _readAsXml(opf);
    if (package == null) return null;

    late Version version;

    final vs = package.getAttribute('version');
    if (vs == '2.0') {
      version = Version.epub2;
    } else if (vs == '3.0') {
      version = Version.epub3;
    } else {
      throw Exception('Unsupported EPUB version: $vs.');
    }

    final md = Metadata();
    for (var e in package
        .findElements('metadata', namespace: opfNS)
        .first
        .childElements) {
      // <dc:rights>Public domain in the USA.</dc:rights>
      md.add(e.localName, clean(e.innerText));

      // TODO: <meta name="cover" content="item1"/>
    }

    final manifest = <ManifestItem>[];
    for (var e in package
        .findElements('manifest', namespace: opfNS)
        .first
        .childElements) {
      manifest.add(ManifestItem(
        id: e.getAttribute('id') ?? '',
        mediaType: e.getAttribute('media-type') ?? 'application/xhtml+xml',
        href: e.getAttribute('href'),
        mediaOverlay: e.getAttribute('media-overlay'),
        fallback: e.getAttribute('fallback'),
        properties: e.getAttribute('properties'),
      ));
    }

    final spine = <SpineItem>[];
    for (var e in package
        .findElements('spine', namespace: opfNS)
        .first
        .childElements) {
      spine.add(SpineItem(
        idref: e.getAttribute('idref')!,
        linear: e.getAttribute('linear') == 'yes',
      ));
    }

    final chapters =
        version == Version.epub2 ? parseNav2(manifest) : parseNav3(manifest);

    final book = Book(
      version: version,
      metadata: md,
      manifest: manifest,
      spine: spine,
      chapters: chapters,
      reader: this,
    );

    if (extractContent) {
      for (Chapter ch in chapters) {
        readChapterContent(ch);
      }
    }

    return book;
  }

  void readChapterContent(Chapter ch) {
    if (ch.href != null) {
      final buf = extractFile(ch.href!);
      if (buf != null) {
        ch.content = utf8.decode(buf);
      }
    }

    for (Chapter ch in ch.children) {
      readChapterContent(ch);
    }
  }

  /// Container file name
  static const containerFN = 'META-INF/container.xml';

  /// Open Packaging Format namespace
  static const opfNS = 'http://www.idpf.org/2007/opf';

  /// Extract rootfile from META-INF/container.xml
  ///
  /// <?xml version='1.0' encoding='utf-8'?>
  /// <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  ///   <rootfiles>
  ///     <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  ///   </rootfiles>
  /// </container>
  String? extractRootFilename(Archive archive) {
    final doc = _readAsXml(containerFN);
    return doc != null
        ? _findNodeAttr(doc, '/container/rootfiles/rootfile', 'full-path')
        : null;
  }

  /// Find first node by xpath, return the attribute's value by name
  static String? _findNodeAttr(
      xml.XmlElement node, String xpath, String attrName) {
    final elements = node.xpath(xpath);
    if (elements.isEmpty) {
      return null;
    }
    return elements.first.getAttribute(attrName);
  }

  /// Read archive file as xml document, `fp` is absolute and full path
  xml.XmlElement? _readAsXml(String fp) {
    final container =
        archive.files.firstWhereOrNull((ArchiveFile file) => file.name == fp);
    if (container != null) {
      return xml.XmlDocument.parse(utf8.decode(container.content)).rootElement;
    }
    return null;
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

  List<Chapter> parseNav2(List<ManifestItem> manifest) {
    final nav = manifest.firstWhereOrNull((i) => i.id == 'ncx');
    if (nav == null) {
      return [];
    }
    final navfp = pjoin(opfroot, nav.href!);
    navfolder = p.dirname(navfp);

    final navdoc = _readAsXml(navfp);
    if (navdoc == null) {
      return [];
    }

    // final title = doc.findElements('docTitle').firstOrNull?.innerText;
    // final author = doc.findElements('docAuthor').firstOrNull?.innerText.trim();
    final map = navdoc.findElements('navMap').firstOrNull;
    return map?.findElements('navPoint').map(_readNavPoint).toList() ?? [];
  }

  Chapter _readNavPoint(xml.XmlElement e) {
    return Chapter(
      title: clean(e.findAllElements('navLabel').firstOrNull?.innerText ?? ''),
      href: e.findAllElements('content').firstOrNull?.getAttribute('src'),
      children: e.findAllElements('navPoint').map(_readNavPoint).toList(),
    );
  }

  /// path maybe "EPUB/xhtml/epub30-nav.xhtml"
  /// nav / ol / li / span|a
  List<Chapter> parseNav3(List<ManifestItem> manifest) {
    final nav = manifest.firstWhereOrNull((i) => i.properties == 'nav');
    if (nav == null) {
      return [];
    }
    final navfp = pjoin(opfroot, nav.href!);
    navfolder = p.dirname(navfp);

    final navdoc = _readAsXml(navfp);
    if (navdoc == null) {
      return [];
    }

    // lot: epub:type="toc" or epub:type="lot"?
    // page-list
    // landmarks

    final root = navdoc.findAllElements('nav').first;
    return _readOl(root);
  }

  List<Chapter> _readOl(xml.XmlElement parent) {
    final ol = parent.findElements('ol').firstOrNull;
    if (ol == null) {
      return [];
    }
    final res = <Chapter>[];
    ol.findElements('li').forEach((e) {
      final cs = _readLi(e);
      res.addAll(cs);
    });
    return res;
  }

  List<Chapter> _readLi(xml.XmlElement li) {
    // ignore span maybe better
    // final span = li.findElements('span').firstOrNull;
    final a = li.findElements('a').firstOrNull;
    if (a == null) {
      return _readOl(li);
    }
    final href = a.getAttribute('href');

    return [
      Chapter(
        title: clean(a.innerText),
        href: href,
        children: _readOl(li),
      )
    ];
  }

  Uint8List? extractFile(String path) {
    // most time, relative to nax
    String fp = pjoin(navfolder, path);
    var af =
        archive.files.firstWhereOrNull((ArchiveFile file) => file.name == fp);
    if (af == null) {
      // some time it's relative to opfroot, it a `ManifestItem.href`
      fp = pjoin(opfroot, path);
      af =
          archive.files.firstWhereOrNull((ArchiveFile file) => file.name == fp);
    }
    return af != null ? af.content : null;
  }
}
