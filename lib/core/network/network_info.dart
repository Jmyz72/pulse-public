import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;
  final Duration checkTimeout;
  final Duration cacheTtl;
  final Duration connectedGracePeriod;
  final DateTime Function() _now;

  NetworkInfoImpl(
    this.connectionChecker, {
    this.checkTimeout = const Duration(seconds: 3),
    this.cacheTtl = const Duration(seconds: 5),
    this.connectedGracePeriod = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Completer<bool>? _inFlightCheck;
  bool? _lastKnownConnectionStatus;
  DateTime? _lastCheckAt;

  @override
  Future<bool> get isConnected async {
    if (_hasFreshCachedResult) {
      final cachedResult = _lastKnownConnectionStatus!;
      if (kDebugMode) {
        developer.log(
          'using cached connectivity result: $cachedResult',
          name: 'NetworkInfo',
        );
      }
      return cachedResult;
    }

    // If a check is already in progress, wait for it instead of starting another
    if (_inFlightCheck != null) {
      if (kDebugMode) {
        developer.log(
          'using in-flight connectivity check',
          name: 'NetworkInfo',
        );
      }
      return _inFlightCheck!.future;
    }

    final inFlightCheck = Completer<bool>();
    _inFlightCheck = inFlightCheck;

    try {
      if (kDebugMode) {
        developer.log('checking connection...', name: 'NetworkInfo');
      }
      final result = await connectionChecker.hasConnection.timeout(
        checkTimeout,
        onTimeout: () {
          if (kDebugMode) {
            developer.log(
              'connection check TIMED OUT after ${checkTimeout.inSeconds}s',
              name: 'NetworkInfo',
            );
          }
          return _fallbackResult();
        },
      );
      if (kDebugMode) {
        developer.log('connection check result: $result', name: 'NetworkInfo');
      }
      _storeResult(result);
      inFlightCheck.complete(result);
      return result;
    } catch (e) {
      if (kDebugMode) {
        developer.log('connection check ERROR', error: e, name: 'NetworkInfo');
      }
      final fallbackResult = _fallbackResult();
      inFlightCheck.complete(fallbackResult);
      return fallbackResult;
    } finally {
      _inFlightCheck = null;
    }
  }

  bool get _hasFreshCachedResult {
    if (_lastKnownConnectionStatus == null || _lastCheckAt == null) {
      return false;
    }

    return _now().difference(_lastCheckAt!) <= cacheTtl;
  }

  void _storeResult(bool result) {
    _lastKnownConnectionStatus = result;
    _lastCheckAt = _now();
  }

  bool _fallbackResult() {
    final shouldTrustRecentSuccess =
        _lastKnownConnectionStatus == true &&
        _lastCheckAt != null &&
        _now().difference(_lastCheckAt!) <= connectedGracePeriod;

    final fallbackResult = shouldTrustRecentSuccess;
    _storeResult(fallbackResult);

    if (kDebugMode) {
      developer.log(
        'using fallback connectivity result: $fallbackResult',
        name: 'NetworkInfo',
      );
    }

    return fallbackResult;
  }
}
