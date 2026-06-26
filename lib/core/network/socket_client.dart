import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class SocketClient {
  late IO.Socket _socket;
  final FlutterSecureStorage _storage;
  
  // Stream controller to broadcast socket connection status if needed
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  final _shipmentUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get shipmentUpdates => _shipmentUpdateController.stream;

  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatMessages => _chatMessageController.stream;

  final _newOfferController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get newOfferUpdates => _newOfferController.stream;

  // P2P-specific stream: consolidates p2p_shipment_updated, p2p_offer_received,
  // p2p_pickup_confirmed, p2p_status_update events into one stream so screens can
  // react without subscribing to multiple sources.
  final _p2pStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get p2pStatusUpdates => _p2pStatusController.stream;

  SocketClient(this._storage);

  IO.Socket get socket => _socket;

  Future<void> init() async {
    final token = await _storage.read(key: 'accessToken');

    final socketUrl = '${ApiConstants.socketUrl}/chat';

    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .setAuth({'token': token})
        .setExtraHeaders({
          'Origin': 'http://localhost', // Bypass strict CORS on iOS
          'Connection': 'Upgrade',
          'Upgrade': 'websocket'
        })
        .enableAutoConnect()
        .enableForceNewConnection()
        .build());

    _socket.onConnect((_) {
      if (kDebugMode) debugPrint('Socket Client Connected: ${_socket.id}');
      if (!_connectionStatusController.isClosed) _connectionStatusController.add(true);
    });

    _socket.on('shipment_updated', (data) {
      if (!_shipmentUpdateController.isClosed) _shipmentUpdateController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('shipment_status_update', (data) {
      if (!_shipmentUpdateController.isClosed) _shipmentUpdateController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('new_message', (data) {
      if (!_chatMessageController.isClosed) _chatMessageController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('new_offer', (data) {
      if (data is Map && !_newOfferController.isClosed) _newOfferController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('p2p_offer', (data) {
      if (data is Map && !_newOfferController.isClosed) _newOfferController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('p2p_offer_received', (data) {
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        if (!_newOfferController.isClosed) _newOfferController.add(m);
        if (!_p2pStatusController.isClosed) _p2pStatusController.add(m);
      }
    });

    _socket.on('p2p_shipment_updated', (data) {
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        if (!_shipmentUpdateController.isClosed) _shipmentUpdateController.add(m);
        if (!_p2pStatusController.isClosed) _p2pStatusController.add(m);
      }
    });

    _socket.on('p2p_pickup_confirmed', (data) {
      if (data is Map && !_p2pStatusController.isClosed) _p2pStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('p2p_status_update', (data) {
      if (data is Map && !_p2pStatusController.isClosed) _p2pStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket.onDisconnect((_) {
      if (kDebugMode) debugPrint('Socket Client Disconnected');
      if (!_connectionStatusController.isClosed) _connectionStatusController.add(false);
    });

    _socket.onConnectError((err) {
      if (kDebugMode) debugPrint('Socket Connection Error: $err');
      if (!_connectionStatusController.isClosed) _connectionStatusController.add(false);
    });

    _socket.onError((err) {
      if (kDebugMode) debugPrint('Socket Error: $err');
    });
  }

  void disconnect() {
    _socket.disconnect();
    // Do not close StreamControllers here — the socket may be re-initialised
    // (e.g. after token refresh). Closing them permanently prevents add() calls.
  }

  void joinThread(String threadId) {
    if (_socket.connected) {
      _socket.emit('join_thread', {'thread_id': threadId});
    }
  }

  void sendChatMessage(String threadId, Map<String, dynamic> payload) {
    if (_socket.connected) {
      _socket.emit('send_message', {'thread_id': threadId, ...payload});
    }
  }

  void markThreadRead(String threadId) {
    if (_socket.connected) {
      _socket.emit('read_thread', {'thread_id': threadId});
    }
  }
  
  void dispose() {
    disconnect();
  }
}
