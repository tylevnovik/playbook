export 'connection_checker_unsupported.dart'
    if (dart.library.html) 'connection_checker_web.dart'
    if (dart.library.io) 'connection_checker_io.dart';
