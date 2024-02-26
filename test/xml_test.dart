import 'package:xml/xml.dart' as xml;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:test/test.dart';

void main() {
  void ensure(xml.XmlElement? e) {
    expect(e, isNotNull);
  }

  test('find', () {
    final doc =
        xml.XmlDocument.parse('<a><b c="d" /><e /><e /></a>').rootElement;
    final bs = doc.findElements('b');
    expect(bs.length, 1);

    final b0 = doc.findElements('b').first;
    expect(b0.getAttribute('c'), 'd');
    ensure(doc.findElements('b').first);

    final es = doc.findElements('e');
    expect(es.length, 2);

    final e0 = doc.findElements('e').first;
    expect(e0, isNotNull);
    ensure(doc.findElements('e').first);

    final f0 = doc.findElements('f').firstOrNull;
    expect(f0, isNull);
  });

  test('build', () {
    final out = xml.XmlBuilder();
    out.processing('xml', 'version="1.0"');
    out.element(
      'package',
      namespaces: {'http://www.idpf.org/2007/opf': null},
      attributes: {'version': '3.0'},
      nest: () {
        const dcuri = 'http://purl.org/dc/elements/1.1/';

        out.element('metadata', nest: () {
          out.namespace(dcuri, 'dc');
          out.element('title', namespace: dcuri, nest: 'hello');
        });
        out.element('manifest', nest: () {});
        out.element('spine', nest: () {});
      },
    );
    expect(
        out.buildDocument().toXmlString(pretty: true), '''<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"\>
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"\>
    <dc:title>hello</dc:title>
  </metadata>
  <manifest/>
  <spine/>
</package>''');
  });
}
