import 'package:test/test.dart';
import 'package:untitled/liquid/template.dart';

void main() {
  test('template', () async {
    var template = Template("{% include 'header.html' %}", "", {});
    var result =  await template.render();
    print(result);
  });
}
