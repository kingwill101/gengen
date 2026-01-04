import 'dart:collection';

/// A utility class for tracking performance metrics during the build process
class Benchmark {
  static final Benchmark _instance = Benchmark._internal();
  factory Benchmark() => _instance;
  Benchmark._internal();

  final Map<String, _TimingData> _timings = {};
  final Map<String, List<int>> _counters = {};
  final Stopwatch _globalStopwatch = Stopwatch();
  bool _isEnabled = true;

  /// Enable or disable benchmarking
  static void setEnabled(bool enabled) {
    _instance._isEnabled = enabled;
  }

  /// Start global benchmarking
  static void start() {
    if (!_instance._isEnabled) return;
    _instance._globalStopwatch.start();
  }

  /// Stop global benchmarking
  static void stop() {
    if (!_instance._isEnabled) return;
    _instance._globalStopwatch.stop();
  }

  /// Start timing a specific operation
  static void startTiming(String operation) {
    if (!_instance._isEnabled) return;
    _instance._timings[operation] = _TimingData()..start();
  }

  /// End timing a specific operation
  static void endTiming(String operation) {
    if (!_instance._isEnabled) return;
    final timing = _instance._timings[operation];
    if (timing != null) {
      timing.stop();
    }
  }

  /// Time a future operation
  static Future<T> timeAsync<T>(String operation, Future<T> Function() fn) async {
    if (!_instance._isEnabled) return await fn();
    
    startTiming(operation);
    try {
      return await fn();
    } finally {
      endTiming(operation);
    }
  }

  /// Time a synchronous operation
  static T timeSync<T>(String operation, T Function() fn) {
    if (!_instance._isEnabled) return fn();
    
    startTiming(operation);
    try {
      return fn();
    } finally {
      endTiming(operation);
    }
  }

  /// Increment a counter
  static void increment(String counter, [int value = 1]) {
    if (!_instance._isEnabled) return;
    _instance._counters.putIfAbsent(counter, () => []).add(value);
  }

  /// Get timing for a specific operation
  static Duration? getElapsed(String operation) {
    return _instance._timings[operation]?.elapsed;
  }

  /// Get counter value
  static int getCounter(String counter) {
    final values = _instance._counters[counter];
    return values?.fold<int>(0, (sum, value) => sum + value) ?? 0;
  }

  /// Get all timing results
  static Map<String, Duration> getAllTimings() {
    return UnmodifiableMapView(_instance._timings.map(
      (key, value) => MapEntry(key, value.elapsed ?? Duration.zero),
    ));
  }

  /// Get all counter values
  static Map<String, int> getAllCounters() {
    return UnmodifiableMapView(_instance._counters.map(
      (key, values) => MapEntry(key, values.fold<int>(0, (sum, value) => sum + value)),
    ));
  }

  /// Get total build time
  static Duration getTotalTime() {
    return _instance._globalStopwatch.elapsed;
  }

  /// Print comprehensive benchmark report
  static void printReport() {
    if (!_instance._isEnabled) return;
    
    print('\n=== BUILD PERFORMANCE REPORT ===');
    print('Total Build Time: ${getTotalTime().inMilliseconds}ms');
    print('\n--- Phase Timings ---');
    
    final timings = getAllTimings();
    final sortedTimings = timings.entries.toList()
      ..sort((a, b) => b.value.inMilliseconds.compareTo(a.value.inMilliseconds));
    
    for (final entry in sortedTimings) {
      final percentage = timings.isNotEmpty && getTotalTime().inMilliseconds > 0
          ? (entry.value.inMilliseconds / getTotalTime().inMilliseconds * 100)
          : 0.0;
      print('  ${entry.key}: ${entry.value.inMilliseconds}ms (${percentage.toStringAsFixed(1)}%)');
    }
    
    print('\n--- Counters ---');
    final counters = getAllCounters();
    for (final entry in counters.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
    
    print('\n--- Performance Insights ---');
    _printInsights(timings, counters);
    print('=================================\n');
  }

  static void _printInsights(Map<String, Duration> timings, Map<String, int> counters) {
    final readTime = timings['read'] ?? Duration.zero;
    final renderTime = timings['render'] ?? Duration.zero;
    final writeTime = timings['write'] ?? Duration.zero;
    
    final totalFiles = counters['files_processed'] ?? 0;
    final totalTime = getTotalTime();
    
    if (totalFiles > 0 && totalTime.inMilliseconds > 0) {
      final avgTimePerFile = totalTime.inMilliseconds / totalFiles;
      print('  Average time per file: ${avgTimePerFile.toStringAsFixed(2)}ms');
    }
    
    // Identify bottlenecks
    final bottlenecks = <String>[];
    if (renderTime.inMilliseconds > totalTime.inMilliseconds * 0.4) {
      bottlenecks.add('rendering (${renderTime.inMilliseconds}ms)');
    }
    if (readTime.inMilliseconds > totalTime.inMilliseconds * 0.3) {
      bottlenecks.add('reading (${readTime.inMilliseconds}ms)');
    }
    if (writeTime.inMilliseconds > totalTime.inMilliseconds * 0.2) {
      bottlenecks.add('writing (${writeTime.inMilliseconds}ms)');
    }
    
    if (bottlenecks.isNotEmpty) {
      print('  Potential bottlenecks: ${bottlenecks.join(', ')}');
    }
    
    // Parallelization opportunities
    if (totalFiles > 4) {
      print('  Parallelization opportunity: $totalFiles files could be processed in parallel');
    }
  }

  /// Reset all benchmarks
  static void reset() {
    _instance._timings.clear();
    _instance._counters.clear();
    _instance._globalStopwatch.reset();
  }
}

class _TimingData {
  final Stopwatch _stopwatch = Stopwatch();
  
  void start() => _stopwatch.start();
  void stop() => _stopwatch.stop();
  Duration? get elapsed => _stopwatch.isRunning ? null : _stopwatch.elapsed;
} 