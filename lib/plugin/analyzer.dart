import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class DartAnalyzer {
  final String code;
  late CompilationUnit unit;

  DartAnalyzer(this.code) {
    var parseResult = parseString(
      content: code,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    unit = parseResult.unit;
  }

  bool doesExtend(String className, String superclassName) {
    var visitor = ExtensionVisitor(className, superclassName);
    unit.visitChildren(visitor);
    return visitor.extendsClass;
  }
}

class ExtensionVisitor extends RecursiveAstVisitor<void> {
  final String className;
  final String superclassName;
  bool extendsClass = false;

  ExtensionVisitor(this.className, this.superclassName);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);

    if (node.name.lexeme == className && node.extendsClause != null) {
      var extendedClassName = node.extendsClause?.superclass.name2.lexeme;
      if (extendedClassName == superclassName) {
        extendsClass = true;
      }
    }
  }
}
