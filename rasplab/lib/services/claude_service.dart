import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/constants.dart';
import '../models/message.dart';

const String _defaultSystemPrompt = '''
너는 "RaspLab" 이라는 라즈베리파이 하드웨어 교육 앱의 AI 튜터야.

## 역할
- 사용자가 원하는 하드웨어 동작을 Python 코드로 만들어줘
- 초보자도 이해할 수 있게 코드마다 한글 주석을 달아줘
- 에러가 발생하면 원인을 설명하고 수정 코드를 제공해

## 환경
- Raspberry Pi 5 (Bookworm OS, Python 3.13)
- ⚠️ RPi.GPIO는 Pi 5에서 동작하지 않음 — 절대 사용 금지
- GPIO 제어: 반드시 gpiozero 라이브러리 사용 (lgpio 백엔드 자동 사용됨)
- I2C: smbus2
- SPI: spidev
- 코드는 반드시 ```python 블록 안에 작성해

## gpiozero 사용 예시
```python
from gpiozero import LED, Button, PWMOutputDevice
from time import sleep

led = LED(17)   # BCM 핀 번호 사용
led.on()
sleep(1)
led.off()
```

## 규칙
1. 코드는 항상 단일 파일, 독립 실행 가능하게 작성
2. gpiozero 객체는 with문 또는 try/finally로 cleanup
3. 무한루프 사용 시 KeyboardInterrupt 처리 포함
4. 핀 번호는 BCM 번호 사용
5. 위험한 작업(과전류 등) 경고 메시지 포함
6. 필요한 배선 정보를 코드 실행 전에 안내
''';

class ClaudeService {
  Map<String, String> get _headers => {
    'x-api-key': dotenv.env['CLAUDE_API_KEY'] ?? '',
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
  };

  /// 대화 히스토리를 포함하여 Claude에게 메시지 전송
  /// [systemPrompt] 기기별 커스텀 프롬프트 (기본값: Pi용 프롬프트)
  Future<String> sendMessage(
    List<Message> messages, {
    String? systemPrompt,
  }) async {
    final history = messages
        .where((m) => m.role != MessageRole.system)
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    final uri = Uri.parse(kClaudeApiUrl);
    final body = jsonEncode({
      'model': kClaudeModel,
      'max_tokens': kClaudeMaxTokens,
      'system': systemPrompt ?? _defaultSystemPrompt,
      'messages': history,
    });

    try {
      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        final data = jsonDecode(response.body);
        final errMsg = data['error']?['message'] ?? response.body;
        throw Exception('Claude API 오류: HTTP ${response.statusCode}\n$errMsg');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Claude API 오류: $e');
    }
  }
}
