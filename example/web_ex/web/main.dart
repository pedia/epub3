import 'dart:html';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:epubrs/epubrs.dart' as epub;

void main() async {
  querySelector('#output')?.text = 'Your Dart app is running.';

  var epubRes = await http.get(Uri.parse('/alicesAdventuresUnderGround.epub'));
  if (epubRes.statusCode == 200) {
    final a = ZipDecoder().decodeBytes(epubRes.bodyBytes);
    final book = epub.Reader.open(a).read()!;
    querySelector('#title')?.text = book.title;
    querySelector('#author')?.text = book.author;
    // var chapters = await book.getChapters();
    querySelector('#nchapters')?.text = book.chapters.length.toString();
    querySelectorAll('h2').style.visibility = 'visible';
  }
}
