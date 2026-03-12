import 'package:flutter_test/flutter_test.dart';
import 'package:rasplab/models/code_block.dart';

void main() {
  group('CodeBlock', () {
    test('마크다운에서 python 코드블록 파싱', () {
      const markdown = '''
안녕하세요! 아래 코드를 사용해 보세요.

```python
import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)
```

위 코드를 실행하면 됩니다.
''';
      final blocks = CodeBlock.parseFromMarkdown(markdown);
      expect(blocks.length, 1);
      expect(blocks.first.language, 'python');
      expect(blocks.first.code, contains('import RPi.GPIO'));
    });

    test('코드블록 없을 때 빈 리스트 반환', () {
      const markdown = '단순 텍스트만 있는 메시지입니다.';
      final blocks = CodeBlock.parseFromMarkdown(markdown);
      expect(blocks, isEmpty);
    });

    test('여러 코드블록 파싱', () {
      const markdown = '''
```python
print("hello")
```
설명
```bash
pip install gpiozero
```
''';
      final blocks = CodeBlock.parseFromMarkdown(markdown);
      expect(blocks.length, 2);
      expect(blocks[0].language, 'python');
      expect(blocks[1].language, 'bash');
    });
  });
}

