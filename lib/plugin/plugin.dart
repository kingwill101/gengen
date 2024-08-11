mixin APlugin {}

abstract class Converter with APlugin {
  String convert(String content);
}

abstract class Generator with APlugin {
  void generate();
}
