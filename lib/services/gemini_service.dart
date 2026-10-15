import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Common transport for text and image requests.
/// API key is provided through --dart-define.
class GeminiService {
  final http.Client? client;
  final String apiKey;
  final String model;

  GeminiService({
    this.client,
    this.apiKey = const String.fromEnvironment('GEMINI_API_KEY'),
    this.model = const String.fromEnvironment(
      'GEMINI_MODEL',
      defaultValue: 'gemini-3.5-flash-lite',
    ),
  });

  Future<String> generateText(String prompt) {
    return generate(
      parts: [
        {
          'text': prompt,
        }
      ],
    );
  }

  Future<String> generate({
    required List<Map<String, dynamic>> parts,
    Map<String, dynamic>? schema,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception(
        'ไม่พบ GEMINI_API_KEY กรุณารันด้วย '
        '--dart-define=GEMINI_API_KEY=YOUR_API_KEY',
      );
    }

    final ownedClient = client ?? http.Client();

    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent';

      final requestBody = {
        'contents': [
          {
            'parts': parts,
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 4096,
          if (schema != null) ...{
            'responseMimeType': 'application/json',
            'responseSchema': schema,
          },
        },
      };

      final response = await ownedClient
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint('GEMINI STATUS: ${response.statusCode}');
      debugPrint('GEMINI MODEL: $model');

      if (response.statusCode != 200) {
        debugPrint('GEMINI RESPONSE: ${response.body}');

        final message = switch (response.statusCode) {
          400 =>
            'คำขอไม่ถูกต้องจาก Gemini: ${response.body}',
          401 =>
            'API key ไม่ถูกต้องหรือหมดอายุ: ${response.body}',
          403 =>
            'API key ไม่มีสิทธิ์ใช้งาน: ${response.body}',
          404 =>
            'ไม่พบโมเดล $model: ${response.body}',
          429 =>
            'ใช้งาน Gemini เกินโควตา: ${response.body}',
          500 =>
            'Gemini Server Error: ${response.body}',
          503 =>
            'Gemini ไม่พร้อมให้บริการชั่วคราว: ${response.body}',
          _ =>
            'เรียก Gemini API ไม่สำเร็จ: ${response.body}',
        };

        throw Exception(
          '$message (สถานะ ${response.statusCode})',
        );
      }

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (data is! Map<String, dynamic>) {
        throw const FormatException(
          'รูปแบบข้อมูลจาก Gemini ไม่ถูกต้อง',
        );
      }

      final feedback = data['promptFeedback'];

      if (feedback is Map &&
          feedback['blockReason'] != null) {
        throw Exception(
          'คำขอถูกบล็อกโดยระบบความปลอดภัยของ Gemini',
        );
      }

      final candidates = data['candidates'];

      if (candidates is! List || candidates.isEmpty) {
        throw Exception(
          'AI ไม่ส่งผลลัพธ์กลับมา',
        );
      }

      final candidate = candidates.first;

      if (candidate is! Map) {
        throw const FormatException(
          'ข้อมูล candidate จาก Gemini ไม่ถูกต้อง',
        );
      }

      final reason = candidate['finishReason'];

      if ([
        'SAFETY',
        'PROHIBITED_CONTENT',
        'BLOCKLIST',
        'SPII',
        'IMAGE_SAFETY',
      ].contains(reason)) {
        throw Exception(
          'เนื้อหาถูกบล็อกโดยระบบความปลอดภัยของ Gemini',
        );
      }

      if (reason == 'MAX_TOKENS') {
        throw Exception(
          'คำตอบ AI ถูกตัด กรุณาลองใหม่',
        );
      }

      final content = candidate['content'];

      final responseParts =
          content is Map ? content['parts'] : null;

      if (responseParts is! List) {
        throw const FormatException(
          'ไม่พบข้อมูลคำตอบจาก Gemini',
        );
      }

      final text = responseParts
          .whereType<Map>()
          .where(
            (part) =>
                part['thought'] != true &&
                part['text'] is String,
          )
          .map(
            (part) => part['text'] as String,
          )
          .join()
          .trim();

      if (text.isEmpty) {
        throw const FormatException(
          'Gemini ส่งข้อความว่างกลับมา',
        );
      }

      debugPrint('GEMINI SUCCESS');

      return text;
    } on TimeoutException {
      throw Exception(
        'Gemini ใช้เวลานานเกิน 20 วินาที กรุณาลองใหม่',
      );
    } on http.ClientException {
      throw Exception(
        'ไม่สามารถเชื่อมต่อ Gemini ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
      );
    } on FormatException catch (e) {
      throw Exception(
        'ข้อมูลคำตอบจาก Gemini ไม่ถูกต้อง: $e',
      );
    } finally {
      if (client == null) {
        ownedClient.close();
      }
    }
  }
}