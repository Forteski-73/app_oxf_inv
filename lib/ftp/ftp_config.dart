import 'package:ftpconnect/ftpconnect.dart';

class FTPConfigManager {
  static final FTPConfigManager _instance = FTPConfigManager._internal();

  factory FTPConfigManager() => _instance;

  FTPConfigManager._internal();

  final _host = "ftp.oxfordtec.com.br";
  final _user = "u700242432.oxfordftp";
  final _password = "OxforEstrutur@25";
  final _timeout = 60;

  // Getters
  String get host => _host;
  String get user => _user;
  String get password => _password;
  int get timeout => _timeout;

  FTPConnect createFTPConnect() {
    return FTPConnect(
      _host,
      user: _user,
      pass: _password,
      timeout: _timeout,
    );
  }
}
