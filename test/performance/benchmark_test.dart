import 'dart:async';

import 'package:gengen/performance/benchmark.dart';
import 'package:test/test.dart';

void main() {
  group('Benchmark', () {
    setUp(() {
      Benchmark.reset();
      Benchmark.setEnabled(true);
    });

    test('tracks sync and async timings', () async {
      Benchmark.start();

      final result = Benchmark.timeSync('sync', () => 42);
      expect(result, 42);

      final asyncResult = await Benchmark.timeAsync('async', () async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 'done';
      });
      expect(asyncResult, 'done');

      Benchmark.stop();

      expect(Benchmark.getElapsed('sync'), isNotNull);
      expect(Benchmark.getElapsed('async'), isNotNull);
      expect(Benchmark.getAllTimings().keys, contains('sync'));
    });

    test('counts and reports counters', () {
      Benchmark.increment('files_processed');
      Benchmark.increment('files_processed', 2);

      expect(Benchmark.getCounter('files_processed'), 3);
      expect(Benchmark.getAllCounters()['files_processed'], 3);
    });

    test('printReport does not throw', () async {
      Benchmark.start();
      await Benchmark.timeAsync('render', () async {
        await Future<void>.delayed(const Duration(milliseconds: 2));
      });
      Benchmark.increment('files_processed', 5);
      Benchmark.stop();

      Benchmark.printReport();
    });

    test('disabled mode bypasses tracking', () {
      Benchmark.setEnabled(false);
      final result = Benchmark.timeSync('noop', () => 5);
      expect(result, 5);
      expect(Benchmark.getElapsed('noop'), isNull);
    });
  });
}
