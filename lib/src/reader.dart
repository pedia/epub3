part of epubrs;

/// [Reader] read scheme and content from epub file.
class Reader {
  factory Reader.open(Archive archive) {
    final rootFile = readRootFile(archive);
    return Reader(archive, rootFile!);
  }

  final Archive archive;

  // like OEBPS/content.opf
  final String rootFile;

  Reader(this.archive, this.rootFile);

  static const opfNS = 'http://www.idpf.org/2007/opf';
  static const root = 'META-INF/container.xml';

  Book? read() {
    final scheme = readSchema(rootFile);
    if (scheme == null) {
      return null;
    }

    final navfile = pathOf(scheme.tocFile());
    final nav = scheme.version == Version.epub2
        ? readNavigation2(navfile)
        : readNavigation3(navfile);
    return Book(scheme, nav ?? Navigation(chapters: []));
  }

  String pathOf(String fp) => p.join(p.dirname(rootFile), fp);

  /// read META-INF/container.xml extract rootfile
  ///
  /// <?xml version='1.0' encoding='utf-8'?>
  /// <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  ///   <rootfiles>
  ///     <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  ///   </rootfiles>
  /// </container>
  static String? readRootFile(Archive archive) {
    final container =
        archive.files.firstWhereOrNull((ArchiveFile file) => file.name == root);
    if (container != null) {
      final doc =
          xml.XmlDocument.parse(utf8.decode(container.content)).rootElement;
      return _findNodeAttr(doc, '/container/rootfiles/rootfile', 'full-path');
    }
    return null;
  }

  /// Read [Scheme] from OEBPS/content.opf
  Scheme? readSchema(String path) {
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

    return Scheme(
      version: version,
      metadata: _extractMetadata(
          doc.findElements('metadata', namespace: opfNS).first, version),
      manifest: _extractManifest(
          doc.findElements('manifest', namespace: opfNS).first),
      spine: _extractSpine(doc.findElements('spine', namespace: opfNS).first),
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

  List<ManifestItem> _extractManifest(xml.XmlElement parent) {
    return parent.childElements
        .map((e) => ManifestItem(
              id: e.getAttribute('id'),
              type: e.getAttribute('media-type'),
              href: e.getAttribute('href'),
              mediaOverlay: e.getAttribute('media-overlay'),
              requiredNamespace: e.getAttribute('required-namespace'),
              requiredModules: e.getAttribute('required-modules'),
              fallback: e.getAttribute('fallback'),
              fallbackStyle: e.getAttribute('fallback-style'),
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
                      ? false
                      : bool.tryParse(e.getAttribute('linear')!) ?? false,
                ))
            .toList());
  }

  List<String> _texts(Iterable<xml.XmlElement> es) =>
      es.map((e) => clean(e.innerText)).toList();

  List<MetaIdentifier> _extractMetaIdentifier(Iterable<xml.XmlElement> es) => es
      .map((e) => MetaIdentifier(
            e.innerText,
            scheme: e.getAttribute('opf:scheme'),
            id: e.getAttribute('id'),
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
    final doc = _readAsXml(path);
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
    );
  }

  /// nav / ol / li / span|a
  Navigation? readNavigation3(String path) {
    final doc = _readAsXml(path);
    if (doc == null) return null;

    if (doc.localName == 'ncx') {
      return _readNav2(doc);
    }

    // TODO: epub:type="toc"
    final nav = doc.findAllElements('nav').first;
    return Navigation(chapters: _readOl(nav));
  }

  List<Chapter> _readOl(xml.XmlElement parent) {
    final ol = parent.findElements('ol').firstOrNull;
    return ol == null ? [] : ol.findElements('li').map(_readLi).toList();
  }

  Chapter _readLi(xml.XmlElement li) {
    final span = li.findElements('span').firstOrNull;
    final a = li.findElements('a').firstOrNull;

    return Chapter(
      title: clean(span != null ? span.innerText : a?.innerText ?? ''),
      href: a?.getAttribute('href'),
      children: _readOl(li),
    );
  }

  /// read [ArchiveFile]
  ArchiveFile? readFile(String href) {
    // file#hash
    final pos = href.indexOf('#');
    final path = pathOf(pos == -1 ? href : href.substring(0, pos));

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

  /// Fnd node by xpath, return the attribute's value by name
  static String? _findNodeAttr(
      xml.XmlElement node, String xpath, String attrName) {
    final elements = node.xpath(xpath);
    if (elements.isEmpty) {
      return null;
    }
    return elements.first.getAttribute(attrName);
  }

  /// get child node's attribute value
  // static String? getNodeAttr(
  //     xml.XmlElement node, String nodeName, String attrName) {
  //   final elements = node.findElements(nodeName);
  //   if (elements.isEmpty) {
  //     return null;
  //   }
  //   return elements.first.getAttribute(attrName);
  // }
}
