part of connection_manager;

class Session {

  static String _cookieName = 'sessionID';

  static String id;

  static Logger _log = new Logger('Session');

  static void set(String id) {
    Session.id = id;

    _log.info('setting session cookie');

    cookie.remove(_cookieName);
    cookie.set(_cookieName, id);
  }

  static void forget() {
    Session.id = null;

    _log.info('removing session cookie');
    cookie.remove(_cookieName);
  }
}
