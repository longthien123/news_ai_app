import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Service kiểm tra kết nối mạng
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionStatusController;

  /// Stream để lắng nghe thay đổi trạng thái kết nối
  Stream<bool> get connectionStream {
    _connectionStatusController ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _connectionStatusController!.stream;
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((resultList) {
      final hasConnection = _checkConnectivity(resultList);
      _connectionStatusController?.add(hasConnection);
    });
  }

  void _stopListening() {
    _subscription?.cancel();
  }

  bool _checkConnectivity(List<ConnectivityResult> resultList) {
    if (resultList.isEmpty) return false;
    
    for (var result in resultList) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet) {
        return true;
      }
    }
    return false;
  }

  /// Kiểm tra trạng thái kết nối hiện tại
  Future<bool> checkConnection() async {
    try {
      final resultList = await _connectivity.checkConnectivity();
      return _checkConnectivity(resultList);
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return false;
    }
  }

  /// Dispose service
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController?.close();
  }
}
