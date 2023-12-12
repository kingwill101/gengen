import 'package:gengen/logging.dart';
import 'package:gengen/pipeline/pipeline.dart';

class Manager<T> {
  List<Pipeline<T>> pipelines;

  Function? onError;

  Manager({this.pipelines = const [], this.onError});

  void addPipeline(Pipeline<T> pipeline) {
    pipelines.add(pipeline);
  }

  void processAll() {
    for (var pipeline in pipelines) {
      try {
        pipeline.handle();
      } catch (e) {
        if (onError != null) {
          onError!(e);
        } else {
          log.severe('An error occurred while processing the pipeline: $e');
        }
      }
    }
  }
}
