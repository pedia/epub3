part of epubrs;

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
  ///   META-INF/container.xml
  ///   EPUB/package.opf
  ///   EPUB/xhtml/nav.xhtml
  void write(Archive a) {
    a.addFile(ArchiveFile.noCompress(
        'mimetype', 20, utf8.encode('application/epub+zip')));
    a.addFile(ArchiveFile.string(Reader.root, container));

    a.addFile(xmlFile('EPUB/package.opf', buildScheme(book.scheme)));
    a.addFile(
        xmlFile('EPUB/xhtml/nav.xhtml', buildNavigation(book.navigation)));
  }

  xml.XmlBuilder buildScheme(Scheme scheme) {
    final out = xml.XmlBuilder();
    out.processing('xml', 'version="1.0"');
    out.element(
      'package',
      namespaces: {Reader.opfNS: null},
      attributes: {
        'version': '3.0',
        'unique-identifier': 'etextno',
      },
      nest: () {
        const dcuri = 'http://purl.org/dc/elements/1.1/';
        out.element('metadata', nest: () {
          out.namespace(dcuri, 'dc');
          out.element('title', namespace: dcuri, nest: book.title);
          // <dc:language>en</dc:language>
          out.element('language', namespace: dcuri, nest: 'en'); // TODO:
          // <meta property="dcterms:modified">2012-02-27T16:38:35Z</meta>
        });

        out.element('manifest', nest: () {
          out.element('item', attributes: {
            'href': 'xhtml/nav.xhtml',
            'id': 'nav',
            'media-type': 'application/xhtml+xml',
            'properties': 'nav',
          });
        });

        out.element('spine', nest: () {});
      },
    );
    return out;
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
        // TODO: title, css
      });
      out.element('body', nest: () {
        if (nav.title != null) {
          out.element('docTitle', nest: () {
            out.element('text', nest: nav.title);
          });
        }

        //
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
    out.element('li', nest: () {
      if (chapter.href != null) {
        out.element('a', attributes: {'href': chapter.href!}, nest: () {
          out.text(chapter.title);
        });
      } else {
        out.element('span', nest: chapter.title);
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
}
