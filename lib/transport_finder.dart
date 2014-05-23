part of connection_manager;

class TransportFinder {

  List<TransportBuilder> _availableConnectionsInfoSorted = new List();
  HashMap<int, TransportBuilder> _supportedConnections;

  StreamController _connectionsStreamController;

  Completer _futureConnection;

  Duration _timeout;

  Logger _log = new Logger('TransportFinder');

  set connections(HashMap<int, TransportBuilder> connections) {
    List<int> sortedMapKeys = connections.keys.toList()..sort();
    _availableConnectionsInfoSorted = new List();

    for (int key in sortedMapKeys) {
      _availableConnectionsInfoSorted.add({
          'conn': connections[key]
      });
    }
  }

  bool get alreadyFound => (_futureConnection == null) ? false : _futureConnection.isCompleted;

  TransportFinder({int timeout: 3}) {
    _timeout = new Duration(seconds: timeout);
  }

  Future findConnection() {
    _futureConnection = new Completer();

    for (Map tb in _availableConnectionsInfoSorted) {
      tb['isSupported'] = null;
    }

    _fireConnectionsInParallel();

    _listenToConnectionsResponses();
    _waitUntilSupportedConnectionIsFound();

    return _futureConnection.future;
  }

  void _fireConnectionsInParallel() {
    _connectionsStreamController = new StreamController.broadcast();

    for (Map connInfo in _availableConnectionsInfoSorted) {
      Future isSupportedResponse = connInfo['conn']().supported;
      isSupportedResponse.then((bool supported) {
        if (_connectionsStreamController.isClosed) {
          return;
        } else {
          connInfo['isSupported'] = supported;
          _connectionsStreamController.add(connInfo);
        }
      });
    }
  }

  void _listenToConnectionsResponses() {
    _supportedConnections = {};

    _connectionsStreamController.stream.listen((connInfo) {
      if (!connInfo['isSupported']) {
        return;
      }

      Map firstPossibleByPriority;
      try {
        firstPossibleByPriority = _availableConnectionsInfoSorted.firstWhere((Map connInfo) {
          return (connInfo['isSupported'] || (connInfo['isSupported'] == null));
        });
      } on StateError {
        return;
      }

      // ak som nasiel najprioritnejsi podporovany transport
      if (connInfo['conn'] == firstPossibleByPriority['conn']) {
        _futureConnection.complete(connInfo['conn']);
      }
    });
  }

  void _waitUntilSupportedConnectionIsFound() {
    new Timer(_timeout, () {
      if (!alreadyFound) {
        List supportedConnections = _availableConnectionsInfoSorted.where((Map connInfo) {
          return connInfo['isSupported'];
        });

        if (supportedConnections.isEmpty) {
          _log.shout('No supported connection transports found!');
          _futureConnection.complete(null);
        } else {
          _futureConnection.complete(supportedConnections.first);
        }
      }

      _connectionsStreamController.close();
    });
  }

  List _sortMapToList(Map map) {
    List sortedMapKeys = map.keys.toList()..sort();
    List sortedList = new List();

    for (var key in sortedMapKeys) {
      sortedList.add(map[key]);
    }

    return sortedList;
  }
}
