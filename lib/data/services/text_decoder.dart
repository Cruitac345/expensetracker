// SPDX-License-Identifier: BSD-3-Clause
import 'dart:convert';
import 'dart:typed_data';

/// Декодирование текстовых файлов импорта: UTF-8 или Windows-1251,
/// кодировка определяется автоматически.
class TextDecoder {
  const TextDecoder._();

  /// Декодирует байты CSV-файла, подбирая кодировку.
  static String decode(Uint8List bytes) {
    Uint8List data = bytes;
    // Метка порядка байтов UTF-8.
    if (data.length >= 3 &&
        data[0] == 0xEF &&
        data[1] == 0xBB &&
        data[2] == 0xBF) {
      data = Uint8List.sublistView(data, 3);
    }
    try {
      return const Utf8Decoder(allowMalformed: false).convert(data);
    } on FormatException {
      return _decodeWindows1251(data);
    }
  }

  static String _decodeWindows1251(Uint8List bytes) {
    final StringBuffer buffer = StringBuffer();
    for (final int byte in bytes) {
      if (byte < 0x80) {
        buffer.writeCharCode(byte);
      } else if (byte >= 0xC0) {
        // А…я идут подряд начиная с U+0410.
        buffer.writeCharCode(0x0410 + (byte - 0xC0));
      } else {
        buffer.writeCharCode(_highRange[byte - 0x80]);
      }
    }
    return buffer.toString();
  }

  /// Таблица символов Windows-1251 для диапазона 0x80…0xBF.
  static const List<int> _highRange = <int>[
    0x0402, 0x0403, 0x201A, 0x0453, 0x201E, 0x2026, 0x2020, 0x2021, //
    0x20AC, 0x2030, 0x0409, 0x2039, 0x040A, 0x040C, 0x040B, 0x040F,
    0x0452, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0x0098, 0x2122, 0x0459, 0x203A, 0x045A, 0x045C, 0x045B, 0x045F,
    0x00A0, 0x040E, 0x045E, 0x0408, 0x00A4, 0x0490, 0x00A6, 0x00A7,
    0x0401, 0x00A9, 0x0404, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x0407,
    0x00B0, 0x00B1, 0x0406, 0x0456, 0x0491, 0x00B5, 0x00B6, 0x00B7,
    0x0451, 0x2116, 0x0454, 0x00BB, 0x0458, 0x0405, 0x0455, 0x0457,
  ];
}
