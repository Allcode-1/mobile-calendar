import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';

class AppProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    final providerLabel = provider.name ?? provider.runtimeType.toString();
    AppLogger.debug('provider=$providerLabel changed', scope: 'provider');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final providerLabel = provider.name ?? provider.runtimeType.toString();
    AppLogger.error(
      'provider=$providerLabel failed',
      error: error,
      stackTrace: stackTrace,
      scope: 'provider',
    );
  }
}
