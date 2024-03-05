part of epub3;

///
class Writer {
  final Book book;
  final bool pretty;
  const Writer(this.book, {this.pretty = true});

  List<int>? encode() {
    final a = Archive();
    write(a);
    return ZipEncoder().encode(a);
  }

  /// files:
  ///   mimetype
  ///   META-INF/container.xml
  ///   EPUB/package.opf
  ///   EPUB/nav.xhtml
  void write(Archive a) {
    a.addFile(ArchiveFile.noCompress(
        'mimetype', 20, utf8.encode('application/epub+zip')));
    a.addFile(ArchiveFile.string(Reader.container, container));

    a.addFile(xmlFile(
      'EPUB/package.opf',
      buildManifest(book.manifest),
    ));
    a.addFile(xmlFile(
      'EPUB/nav.xhtml',
      buildNavigation(book.navigation),
    ));

    // manifest to archive?
    // chapters to archive?
    final fnset = Set<String>();
    for (var ch in book.chapters) {
      writeChapter(a, ch, fnset);
    }
  }

  writeChapter(Archive ar, Chapter ch, Set<String> fnset) {
    if (ch.content != null) {
      final fn = ch.item?.href;
      if (fn != null && !fnset.contains(fn)) {
        ar.addFile(ArchiveFile.string('EPUB/$fn', chapterToHtml(ch)));
        fnset.add(fn);
      }
    }

    for (var sub in ch.children) {
      writeChapter(ar, sub, fnset);
    }
  }

  xml.XmlBuilder buildManifest(Manifest manifest) {
    final out = xml.XmlBuilder();
    out.processing('xml', 'version="1.0"');

    final uid = manifest.metadata.identifier.first.id;
    out.element(
      'package',
      namespaces: {Reader.opfNS: null},
      attributes: {'version': '3.0', 'unique-identifier': uid}, // [1]
      nest: () {
        const dcuri = 'http://purl.org/dc/elements/1.1/';
        out.element('metadata', nest: () {
          out.namespace(dcuri, 'dc');
          out.element(
            'identifier',
            namespace: dcuri,
            attributes: {'id': uid}, // same id as [1]
            nest: manifest.metadata.identifier.first.identifier,
          );
          out.element('title', namespace: dcuri, nest: book.title);
          out.element('language', namespace: dcuri, nest: 'en');
          out.element('creator', namespace: dcuri, nest: 'epubrs in dart');

          // <meta property="dcterms:modified">2012-02-27T16:38:35Z</meta>
          final now = DateTime.now().toUtc();
          out.element(
            'meta',
            attributes: {'property': 'dcterms:modified'},
            nest: now.toIsoString(), // CCYY-MM-DDThh:mm:ssZ
          );
        });

        out.element('manifest', nest: () {
          out.element('item', attributes: {
            'id': 'nav',
            'href': 'nav.xhtml',
            'media-type': 'application/xhtml+xml',
            'properties': 'nav',
          });

          for (var i in manifest.items) {
            out.element('item', attributes: i.attributes);
          }
        });

        out.element('spine', // attributes: {'toc': manifest.spine.toc},
            nest: () {
          for (var i in manifest.spine.refs) {
            out.element('itemref', attributes: i.attributes);
          }
          out.element('itemref', attributes: {'idref': 'nav'});

          for (var ch in book.chapters) {
            buildShpineItem(out, ch);
          }
        });
      },
    );
    return out;
  }

  void buildShpineItem(xml.XmlBuilder out, Chapter ch) {
    final i = ch.item;
    if (i != null) {
      out.element('itemref', attributes: {'idref': i.id});
    }

    for (var c in ch.children){
      buildShpineItem(out, c);
    }
  }

  xml.XmlBuilder buildNavigation(Navigation nav) {
    final out = xml.XmlBuilder();
    out.processing('xml', 'version="1.0"');
    out.element('html', namespaces: {
      'http://www.w3.org/1999/xhtml': null,
      'http://www.idpf.org/2007/ops': 'epub',
    }, nest: () {
      out.element('head', nest: () {
        out.element('meta', attributes: {'charset': 'utf-8'});
        out.element('title', nest: book.title);
      });
      out.element('body', nest: () {
        out.element('nav', attributes: {'epub:type': 'toc', 'id': 'toc'},
            nest: () {
          // <h1 class="title">Table of Contents</h1>
          out.element(
            'h1',
            attributes: {'class': 'title'},
            nest: 'Table of Contents',
          );

          // outside ol
          out.element('ol', nest: () {
            for (var c in nav.chapters) {
              buildChapter(out, c);
            }
          });
        });
      });
    });

    return out;
  }

  void buildChapter(xml.XmlBuilder out, Chapter chapter) {
    // TODO: <li id="?">
    out.element('li', nest: () {
      final i = chapter.item;
      if (i == null) {
        out.element('span', nest: chapter.title);
      } else {
        out.element('a', attributes: {'href': i.href!}, nest: () {
          out.text(chapter.title);
        });
      }

      if (chapter.children.isNotEmpty) {
        out.element('ol', nest: () {
          for (var c in chapter.children) {
            buildChapter(out, c);
          }
        });
      }
    });
  }

  ArchiveFile xmlFile(String name, xml.XmlBuilder builder) {
    final bytes =
        utf8.encode(builder.buildDocument().toXmlString(pretty: pretty));
    return ArchiveFile(name, bytes.length, bytes);
  }

  static const container = '''<?xml version="1.0" encoding="UTF-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
   <rootfiles>
      <rootfile full-path="EPUB/package.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>''';

  static String chapterToHtml(Chapter ch) {
    final content =
        ch.content?.split('\n').map((line) => '<p>$line</p>').join('\n');

    return '''<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8"/>
<title>${ch.title}</title></head>
<body>
$content
</body>
</html>
''';
  }
}
