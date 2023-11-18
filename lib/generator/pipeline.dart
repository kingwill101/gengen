typedef HandleFunc<T> = void Function(T);

abstract class Handle<T> {
  void handle(T data, HandleFunc<T> next);
}

class Pipeline<T> {
  final List<Handle<T>> handlers;
  final T? data;

  const Pipeline([
    this.data,
    this.handlers = const [],
  ]);

  Pipeline add(Handle<T> handle) {
    handlers.add(handle);
    return this;
  }

  Pipeline addAll(List<Handle<T>> handles) {
    handlers.addAll(handles);
    return this;
  }

  Future<void> handle() async {
    if (data != null) {
      _processHandler(data as T);
    }
  }

  void _processHandler(T data, [int index = 0]) {
    // Check if the index is within the range of the handler list
    if (index < handlers.length) {
      // Call the handle method of the handler, passing the data and a callback
      // to the next handler
      handlers[index].handle(data, (T modifiedData) {
        // Recursive call to process the next handler
        _processHandler(modifiedData, index + 1);
      });
    }
  }
}

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
