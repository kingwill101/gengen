// import 'dart:async';

// import 'package:gengen/logging.dart';
// import 'package:sentry/sentry.dart';

// /// Creates a new span and runs the action within it
// Future<T> withSpan<T>(
//   FutureOr<T> Function() action, {
//   required String operation,
//   String? description,
//   ISentrySpan? parentSpan,
// }) async {
//   final span = parentSpan?.startChild(operation, description: description) ??
//       Sentry.startTransaction(operation, operation);

//   final zone = Zone.current.fork(
//     specification: ZoneSpecification(
//       handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone,
//           Object error, StackTrace stackTrace) {
//         span.finish();
//         log.severe('Uncaught error', error, stackTrace);
//       },
//     ),
//     zoneValues: {#currentSpanTransaction: span},
//   );

//   try {
//     final result = await zone.run(action);
//     await span.finish();
//     return result;
//   } catch (e, stackTrace) {
//     span.finish();
//     rethrow;
//   }
// }

// /// Gets the current span from the Zone
// ISentrySpan? get currentSpan => Zone.current[#currentSpanTransaction] as ISentrySpan?;

// /// Creates a child span for the current operation
// Future<T> withChildSpan<T>(
//   FutureOr<T> Function() action, {
//   required String operation,
//   String? description,
// }) async {
//   final parentSpan = currentSpan;
//   if (parentSpan == null) {
//     return withSpan(action, operation: operation, description: description);
//   }

//   final childSpan = parentSpan.startChild(operation, description: description);
//   try {
//     final result = await action();
//     await childSpan.finish();
//     return result;
//   } catch (e, stackTrace) {
//     childSpan.finish();
//     rethrow;
//   }
// }
