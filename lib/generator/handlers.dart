import 'package:gengen/generator/generator.dart';
import 'package:gengen/generator/pipeline.dart';

class CollectHandler<T> extends Handle<Generator<T>> {
  @override
  void handle(Generator<T> data, HandleFunc<Generator<T>> next) async {
    await data.collect();
    next(data);
  }
}

class TransformHandler<T> extends Handle<Generator<T>> {
  @override
  void handle(Generator<T> data, HandleFunc<Generator<T>> next) async {
    await data.transform();
    next(data);
  }
}

class WriteHandler<T> extends Handle<Generator<T>> {
  @override
  void handle(Generator<T> data, HandleFunc<Generator<T>> next) async {
    await data.write();
    next(data);
  }
}
