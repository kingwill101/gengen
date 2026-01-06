typedef HandleFunc<T> = void Function(T);

class Pipeline<T> {
  final List<Handle<T>> handlers;
  final T? data;

  const Pipeline([this.data, this.handlers = const []]);

  Pipeline<T> add(Handle<T> handle) {
    handlers.add(handle);

    return this;
  }

  Pipeline<T> addAll(List<Handle<T>> handles) {
    handlers.addAll(handles);

    return this;
  }

  void handle() {
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

abstract class Handle<T> {
  void handle(T data, HandleFunc<T> next);
}
