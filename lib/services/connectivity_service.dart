import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Wraps connectivity_plus to provide a reactive online/offline stream and
/// automatically retries the pending lookup queue when connectivity is restored.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService(this._api) {
    _init();
  }

  final ApiService _api;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    // Check current connectivity immediately.
    final results = await Connectivity().checkConnectivity();
    _isOnline = _hasConnection(results);
    notifyListeners();

    // Listen for changes.
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final wasOffline = !_isOnline;
      _isOnline = _hasConnection(results);
      notifyListeners();

      // When going from offline → online, retry queued lookups.
      if (wasOffline && _isOnline) {
        await _api.retryPending();
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
