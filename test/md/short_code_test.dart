import 'package:gengen/md/md.dart';
import 'package:test/test.dart';

void main() {
  test('markdown shortcode inline syntax converts to liquid tag', () {
    final input = "Before [ shortcode 'partials/card' title='Hello' ] After";
    final output = renderMd(input);

    expect(output, contains("{% shortcode 'partials/card' title='Hello' %}"));
  });
}
