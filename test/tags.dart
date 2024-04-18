import 'package:gengen/liquid/template.dart';
import 'package:test/test.dart';

void main() {
  group('highlight', () {
    test('good', () async {
      var template = Template.r('{% highlight dart %}print("hello");{% endhighlight %}');
      expect(await template.render(), equals(r'<span class="hljs-built_in">print</span>(<span class="hljs-string">"hello"</span>);'));
    });

    test('unknown language', () async {
      var template = Template.r('{% highlight 23qr412f %}print("hello");{% endhighlight %}');
      expect(await template.render(), equals(r'print("hello");'));
    });
  });
}
