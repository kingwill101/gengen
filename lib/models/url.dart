import 'dart:core';

class URL {
  String? template;
  Map<String, dynamic>? placeholders;
  String? permalink;

  URL({this.template, this.placeholders, this.permalink});

  @override
  String toString() {
    return sanitizeUrl(generatedPermalink() ?? generatedUrl());
  }

  String? generatedPermalink() {
    return permalink != null ? generateUrl(permalink!) : null;
  }

  String generatedUrl() {
    return generateUrl(template!);
  }

  String generateUrl(String template) {
    placeholders!.forEach((key, value) {
      template = template.replaceAll(
        ":$key",
        Uri.encodeComponent(value as String),
      );
    });

    return template;
  }

  String sanitizeUrl(String str) {
    return "/${str.replaceAll("..", "/")}"
        .replaceAll("./", "")
        .replaceAll("//", "/");
  }

  static URL create({
    String? template,
    Map<String, dynamic>? placeholders,
    String? permalink,
  }) {
    return URL(
      template: template,
      placeholders: placeholders,
      permalink: permalink,
    );
  }
}
