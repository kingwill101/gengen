import 'package:gengen/exceptions.dart';
import 'package:test/test.dart';

void main() {
  test('GenGenException formats message and cause', () {
    const base = GenGenException('Boom');
    expect(base.toString(), 'GenGenException: Boom');

    const withCause = GenGenException('Boom', 'Bad');
    expect(withCause.toString(), contains('Boom'));
    expect(withCause.toString(), contains('Bad'));
  });

  test('Derived exceptions inherit GenGenException', () {
    const exceptions = <GenGenException>[
      SiteInitializationException('init'),
      SiteBuildException('build'),
      ConfigurationException('config'),
      PluginException('plugin'),
      TemplateException('template'),
      FileSystemException('fs'),
    ];

    for (final exception in exceptions) {
      expect(exception.toString(), contains(exception.message));
    }
  });
}
