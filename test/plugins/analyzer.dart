import 'package:gengen/plugin/analyzer.dart';
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
  });
}
