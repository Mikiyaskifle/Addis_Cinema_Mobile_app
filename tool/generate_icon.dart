// dart run tool/generate_icon.dart
import 'dart:io';
import 'dart:typed_data';

// Generates a minimal 1024x1024 PNG with the cinema ticket icon
// Uses raw PNG encoding (no external deps needed)

void main() {
  final width = 1024;
  final height = 1024;
  final pixels = Uint32List(width * height);

  // Colors (ABGR format for little-endian)
  const bg = 0xFF20202B;       // dark brown bg
  const red = 0xFF3B38E5;      // red (0xFFE5383B in RGBA -> ABGR = 0xFF3B38E5)
  const white = 0xFFFFFFFF;
  const transparent = 0x00000000;

  // Fill background
  pixels.fillRange(0, pixels.length, bg);

  // Helper: set pixel
  void setPixel(int x, int y, int color) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      pixels[y * width + x] = color;
    }
  }

  // Fill rect
  void fillRect(int x, int y, int w, int h, int color) {
    for (var py = y; py < y + h; py++) {
      for (var px = x; px < x + w; px++) {
        setPixel(px, py, color);
      }
    }
  }

  // Fill circle
  void fillCircle(int cx, int cy, int r, int color) {
    for (var py = cy - r; py <= cy + r; py++) {
      for (var px = cx - r; px <= cx + r; px++) {
        final dx = px - cx;
        final dy = py - cy;
        if (dx * dx + dy * dy <= r * r) {
          setPixel(px, py, color);
        }
      }
    }
  }

  // Rounded rect
  void fillRoundRect(int x, int y, int w, int h, int r, int color) {
    fillRect(x + r, y, w - 2 * r, h, color);
    fillRect(x, y + r, w, h - 2 * r, color);
    fillCircle(x + r, y + r, r, color);
    fillCircle(x + w - r, y + r, r, color);
    fillCircle(x + r, y + h - r, r, color);
    fillCircle(x + w - r, y + h - r, r, color);
  }

  // Draw rounded background
  fillRoundRect(0, 0, 1024, 1024, 180, bg);

  // Draw ticket body (red)
  fillRoundRect(112, 312, 800, 400, 40, red);

  // Cut notches
  fillCircle(112, 512, 60, bg);
  fillCircle(912, 512, 60, bg);

  // Film holes top
  for (var i = 0; i < 7; i++) {
    final hx = 160 + i * 110;
    fillRoundRect(hx, 328, 70, 50, 8, bg);
  }
  // Film holes bottom
  for (var i = 0; i < 7; i++) {
    final hx = 160 + i * 110;
    fillRoundRect(hx, 646, 70, 50, 8, bg);
  }

  // Play triangle (white)
  for (var py = 420; py <= 604; py++) {
    final progress = (py - 420) / (604 - 420);
    final halfWidth = (progress * 95).round();
    final centerX = 525;
    if (py <= 512) {
      final w2 = ((py - 420) / (512 - 420) * 95).round();
      for (var px = 430; px <= 430 + w2 * 2; px++) {
        setPixel(px, py, white);
      }
    } else {
      final w2 = ((604 - py) / (604 - 512) * 95).round();
      for (var px = 430; px <= 430 + w2 * 2; px++) {
        setPixel(px, py, white);
      }
    }
  }

  // Encode as PNG
  final png = _encodePng(pixels, width, height);
  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/app_icon.png').writeAsBytesSync(png);
  File('assets/icon/app_icon_fg.png').writeAsBytesSync(png);
  print('Icon generated at assets/icon/app_icon.png');
}

Uint8List _encodePng(Uint32List pixels, int width, int height) {
  // Convert ABGR to RGBA rows
  final rows = <Uint8List>[];
  for (var y = 0; y < height; y++) {
    final row = Uint8List(width * 4);
    for (var x = 0; x < width; x++) {
      final p = pixels[y * width + x];
      final a = (p >> 24) & 0xFF;
      final b = (p >> 16) & 0xFF;
      final g = (p >> 8) & 0xFF;
      final r = p & 0xFF;
      row[x * 4] = r;
      row[x * 4 + 1] = g;
      row[x * 4 + 2] = b;
      row[x * 4 + 3] = a;
    }
    rows.add(row);
  }

  final out = BytesBuilder();

  // PNG signature
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR
  final ihdr = ByteData(13);
  ihdr.setUint32(0, width);
  ihdr.setUint32(4, height);
  ihdr.setUint8(8, 8);  // bit depth
  ihdr.setUint8(9, 6);  // RGBA
  ihdr.setUint8(10, 0);
  ihdr.setUint8(11, 0);
  ihdr.setUint8(12, 0);
  _writeChunk(out, 'IHDR', ihdr.buffer.asUint8List());

  // IDAT - compress rows
  final rawData = BytesBuilder();
  for (final row in rows) {
    rawData.addByte(0); // filter type None
    rawData.add(row);
  }
  final compressed = _zlibDeflate(rawData.toBytes());
  _writeChunk(out, 'IDAT', compressed);

  // IEND
  _writeChunk(out, 'IEND', Uint8List(0));

  return out.toBytes();
}

void _writeChunk(BytesBuilder out, String type, Uint8List data) {
  final len = ByteData(4)..setUint32(0, data.length);
  out.add(len.buffer.asUint8List());
  final typeBytes = type.codeUnits;
  out.add(typeBytes);
  out.add(data);
  final crc = _crc32([...typeBytes, ...data]);
  final crcBytes = ByteData(4)..setUint32(0, crc);
  out.add(crcBytes.buffer.asUint8List());
}

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc ^= b;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

// Minimal zlib/deflate using stored blocks (no compression, valid PNG)
Uint8List _zlibDeflate(Uint8List data) {
  final out = BytesBuilder();
  // zlib header: CMF=0x78, FLG=0x01 (no dict, check bits)
  out.addByte(0x78);
  out.addByte(0x01);

  const blockSize = 65535;
  var offset = 0;
  while (offset < data.length) {
    final end = (offset + blockSize).clamp(0, data.length);
    final isLast = end == data.length;
    final len = end - offset;
    out.addByte(isLast ? 0x01 : 0x00);
    out.addByte(len & 0xFF);
    out.addByte((len >> 8) & 0xFF);
    out.addByte((~len) & 0xFF);
    out.addByte(((~len) >> 8) & 0xFF);
    out.add(data.sublist(offset, end));
    offset = end;
  }

  // Adler-32 checksum
  var s1 = 1, s2 = 0;
  for (final b in data) {
    s1 = (s1 + b) % 65521;
    s2 = (s2 + s1) % 65521;
  }
  final adler = (s2 << 16) | s1;
  final adlerBytes = ByteData(4)..setUint32(0, adler);
  out.add(adlerBytes.buffer.asUint8List());

  return out.toBytes();
}
