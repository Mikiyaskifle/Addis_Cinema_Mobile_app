// dart run tool/generate_payment_icons.dart
// Generates placeholder PNG files for payment logos.
// Replace the output files with real logos when ready.
import 'dart:io';
import 'dart:typed_data';

void main() {
  final icons = {
    'telebirr': [0xFF, 0x15, 0x65, 0xC0],    // blue
    'cbe_birr': [0xFF, 0x8E, 0x24, 0xAA],    // purple
    'awash': [0xFF, 0xE6, 0x51, 0x00],        // orange
    'abyssinia': [0xFF, 0xF9, 0xA8, 0x25],   // gold
  };

  for (final entry in icons.entries) {
    final bytes = _makeSolidPng(entry.value[0], entry.value[1], entry.value[2], entry.value[3]);
    final file = File('assets/icons/${entry.key}.png');
    file.writeAsBytesSync(bytes);
    print('Created ${file.path}');
  }
}

Uint8List _makeSolidPng(int a, int r, int g, int b) {
  const w = 128, h = 128;
  final pixels = Uint32List(w * h);
  for (var i = 0; i < pixels.length; i++) {
    pixels[i] = (a << 24) | (b << 16) | (g << 8) | r;
  }
  return _encodePng(pixels, w, h);
}

Uint8List _encodePng(Uint32List pixels, int width, int height) {
  final rows = <Uint8List>[];
  for (var y = 0; y < height; y++) {
    final row = Uint8List(width * 4);
    for (var x = 0; x < width; x++) {
      final p = pixels[y * width + x];
      row[x * 4] = p & 0xFF;
      row[x * 4 + 1] = (p >> 8) & 0xFF;
      row[x * 4 + 2] = (p >> 16) & 0xFF;
      row[x * 4 + 3] = (p >> 24) & 0xFF;
    }
    rows.add(row);
  }
  final out = BytesBuilder();
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);
  final ihdr = ByteData(13);
  ihdr.setUint32(0, width); ihdr.setUint32(4, height);
  ihdr.setUint8(8, 8); ihdr.setUint8(9, 6);
  _writeChunk(out, 'IHDR', ihdr.buffer.asUint8List());
  final raw = BytesBuilder();
  for (final row in rows) { raw.addByte(0); raw.add(row); }
  _writeChunk(out, 'IDAT', _deflate(raw.toBytes()));
  _writeChunk(out, 'IEND', Uint8List(0));
  return out.toBytes();
}

void _writeChunk(BytesBuilder out, String type, Uint8List data) {
  final len = ByteData(4)..setUint32(0, data.length);
  out.add(len.buffer.asUint8List());
  out.add(type.codeUnits);
  out.add(data);
  final crc = ByteData(4)..setUint32(0, _crc([...type.codeUnits, ...data]));
  out.add(crc.buffer.asUint8List());
}

int _crc(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) { c ^= b; for (var i = 0; i < 8; i++) c = (c & 1) != 0 ? (c >> 1) ^ 0xEDB88320 : c >> 1; }
  return c ^ 0xFFFFFFFF;
}

Uint8List _deflate(Uint8List data) {
  final out = BytesBuilder();
  out.addByte(0x78); out.addByte(0x01);
  var offset = 0;
  while (offset < data.length) {
    final end = (offset + 65535).clamp(0, data.length);
    final len = end - offset;
    final isLast = end == data.length;
    out.addByte(isLast ? 0x01 : 0x00);
    out.addByte(len & 0xFF); out.addByte((len >> 8) & 0xFF);
    out.addByte((~len) & 0xFF); out.addByte(((~len) >> 8) & 0xFF);
    out.add(data.sublist(offset, end));
    offset = end;
  }
  var s1 = 1, s2 = 0;
  for (final b in data) { s1 = (s1 + b) % 65521; s2 = (s2 + s1) % 65521; }
  final adler = ByteData(4)..setUint32(0, (s2 << 16) | s1);
  out.add(adler.buffer.asUint8List());
  return out.toBytes();
}
