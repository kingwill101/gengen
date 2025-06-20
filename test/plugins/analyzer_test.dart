import 'package:gengen/plugin/eval/analyzer.dart';
import 'package:test/test.dart';

void main() {
  final source = '''
  class  MetadataPlugin extends Generator {}
  class  MetadataPlugin2 extends Converter {}
    ''';
  final analyzer = DartAnalyzer(source);

  group('plugin check', () {
    test('Generator check', () {
      expect(analyzer.doesExtend('MetadataPlugin', 'Generator'), isTrue);
      expect(analyzer.doesExtend('MetadataPlugin2', 'Generator'), isFalse);
    });

    test('Converter check', () {
      expect(analyzer.doesExtend('MetadataPlugin', 'Converter'), isFalse);
      expect(analyzer.doesExtend('MetadataPlugin2', 'Converter'), isTrue);
    });

    test('Method override checks', () {
      final source = '''
      class BaseClass {
        void methodA() {}
        void methodB() {}
      }

      class ChildClass extends BaseClass {
        @override
        void methodA() {}

        void methodC() {}
      }

      class AnotherClass {
        void methodA() {}
      }
      ''';
      final analyzer = DartAnalyzer(source);

      expect(analyzer.doesOverrideMethod('ChildClass', 'methodA'), isTrue);
      expect(analyzer.doesOverrideMethod('ChildClass', 'methodB'), isFalse);
      expect(analyzer.doesOverrideMethod('ChildClass', 'methodC'), isFalse);
      expect(analyzer.doesOverrideMethod('AnotherClass', 'methodA'), isFalse);
      expect(analyzer.doesOverrideMethod('BaseClass', 'methodA'), isFalse);
    });
  });
}
