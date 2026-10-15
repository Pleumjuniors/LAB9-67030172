import 'dart:convert';
import 'dart:typed_data';

import '../models/listing_draft.dart';
import 'gemini_service.dart';

class GeminiVisionService {
  final GeminiService service;

  GeminiVisionService({
    GeminiService? service,
  }) : service = service ?? GeminiService();

  Future<Map<String, dynamic>> analyzeProductImage({
    required Uint8List imageBytes,
    required String prompt,
    String mimeType = 'image/jpeg',
  }) async {
    // ตรวจสอบขนาดรูป
    if (imageBytes.isEmpty) {
      throw Exception('กรุณาเลือกรูปภาพ');
    }

    if (imageBytes.length > 10 * 1024 * 1024) {
      throw Exception('กรุณาเลือกรูปภาพขนาดไม่เกิน 10 MB');
    }

    // ตรวจสอบชนิดไฟล์
    const allowedMimeTypes = [
      'image/jpeg',
      'image/png',
      'image/webp',
    ];

    if (!allowedMimeTypes.contains(mimeType)) {
      throw Exception(
        'รองรับเฉพาะรูป JPEG, PNG และ WebP',
      );
    }

    // ส่งรูป + Prompt ไป Gemini
    final text = await service.generate(
      parts: [
        {
          'text': prompt,
        },
        {
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Encode(imageBytes),
          },
        },
      ],
      schema: {
        'type': 'OBJECT',
        'properties': {
          'title': {
            'type': 'STRING',
          },
          'category': {
            'type': 'STRING',
            'enum': ListingDraft.categories,
          },
          'description': {
            'type': 'STRING',
          },
        },
        'required': [
          'title',
          'category',
          'description',
        ],
      },
    );

    // แปลงข้อความ JSON ที่ Gemini ส่งกลับมา
    try {
      final decoded = jsonDecode(text);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }

      // ตรวจสอบว่าโครงสร้างตรงกับ ListingDraft
      final draft = ListingDraft.fromJson(decoded);

      if (draft.title.trim().isEmpty) {
        throw const FormatException();
      }

      if (draft.category.trim().isEmpty) {
        throw const FormatException();
      }

      if (draft.description.trim().isEmpty) {
        throw const FormatException();
      }

      return decoded;
    } on FormatException {
      throw Exception(
        'ร่างประกาศจาก AI ไม่ถูกต้อง กรุณาลองใหม่',
      );
    } catch (e) {
      throw Exception(
        'ไม่สามารถสร้างร่างประกาศจาก AI ได้: $e',
      );
    }
  }
}