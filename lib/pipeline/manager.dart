import 'package:gengen/pipeline/pipeline.dart';

class PipelineManager<T> {
  List<Pipeline<T>> pipelines;

  PipelineManager([this.pipelines = const []]);

  void addPipeline(Pipeline<T> pipeline) {
    pipelines.add(pipeline);
  }

  Future<void> processAll(T data) async {
    for (var pipeline in pipelines) {
      await pipeline.handle();
    }
  }
}
