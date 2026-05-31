// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:compartarenta/debug/web_dev_host_session_format.dart';

/// Local dev session store for Flutter web (survives Ctrl+C / flutter clean).
///
/// Started by [run_dev_web.sh]. The web app PUTs JSON after onboarding and on
/// each Drift flush; GET restores on the next launch.
Future<void> main() async {
  final port =
      int.tryParse(Platform.environment['WEB_DEV_SESSION_PORT'] ?? '') ?? 18765;
  final home = Platform.environment['HOME'] ?? '.';
  final cacheDir = Directory('$home/.cache/compartarenta');
  cacheDir.createSync(recursive: true);
  final sessionFile = File('${cacheDir.path}/web-dev-session.json');

  HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  } on SocketException catch (e) {
    stderr.writeln(
      'web_dev_session_server: cannot bind 127.0.0.1:$port ($e). '
      'Run: dart run melos run stop:web-dev-session '
      '(or sudo fuser -k $port/tcp if the port is root-owned).',
    );
    exit(1);
  }

  print(
    'web_dev_session_server: listening on http://127.0.0.1:$port '
    '(session format v2..$kWebDevHostSessionVersion; '
    'use WEB_DEV_SESSION_URL=http://127.0.0.1:$port if localhost resolves to ::1) '
    'file=${sessionFile.path}',
  );
  await for (final request in server) {
    try {
      if (request.method == 'OPTIONS') {
        _writeCors(request.response);
        await request.response.close();
        continue;
      }

      final path = request.uri.path;
      if (path == '/session' || path == '/session/') {
        switch (request.method) {
          case 'GET':
            await _handleGet(request, sessionFile);
          case 'PUT':
            await _handlePut(request, sessionFile);
          case 'DELETE':
            await _handleDelete(request, sessionFile);
          default:
            request.response.statusCode = HttpStatus.methodNotAllowed;
            _writeCors(request.response);
            await request.response.close();
        }
        continue;
      }

      request.response.statusCode = HttpStatus.notFound;
      _writeCors(request.response);
      await request.response.close();
    } catch (e, st) {
      print('web_dev_session_server: request error: $e\n$st');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }
}

void _writeCors(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, PUT, DELETE, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type')
    // Required when Flutter web runs with COEP require-corp (Drift OPFS).
    ..set('Cross-Origin-Resource-Policy', 'cross-origin');
}

Future<void> _handleGet(HttpRequest request, File sessionFile) async {
  _writeCors(request.response);
  if (!await sessionFile.exists()) {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
    return;
  }
  request.response.statusCode = HttpStatus.ok;
  request.response.headers.contentType = ContentType.json;
  request.response.write(await sessionFile.readAsString());
  await request.response.close();
}

Future<void> _handlePut(HttpRequest request, File sessionFile) async {
  final body = await utf8.decoder.bind(request).join();
  if (body.isEmpty) {
    request.response.statusCode = HttpStatus.badRequest;
    _writeCors(request.response);
    await request.response.close();
    return;
  }

  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) throw const FormatException('map');
    final version = decoded['version'];
    if (!isAcceptedDevHostSessionVersion(version)) {
      throw FormatException('version $version (need int >= 2)');
    }
    if (version > kWebDevHostSessionVersion) {
      print(
        'web_dev_session_server: warning: client version $version > '
        'server kWebDevHostSessionVersion=$kWebDevHostSessionVersion (saving anyway)',
      );
    }
  } on FormatException catch (e) {
    request.response.statusCode = HttpStatus.badRequest;
    _writeCors(request.response);
    request.response.write('invalid session: $e');
    await request.response.close();
    return;
  }

  final tmp = File('${sessionFile.path}.tmp');
  await tmp.writeAsString(body);
  if (await sessionFile.exists()) {
    sessionFile.deleteSync();
  }
  tmp.renameSync(sessionFile.path);

  _writeCors(request.response);
  request.response.statusCode = HttpStatus.noContent;
  await request.response.close();
  print('web_dev_session_server: saved ${body.length} bytes');
}

Future<void> _handleDelete(HttpRequest request, File sessionFile) async {
  if (await sessionFile.exists()) {
    await sessionFile.delete();
    print('web_dev_session_server: deleted ${sessionFile.path}');
  }
  _writeCors(request.response);
  request.response.statusCode = HttpStatus.noContent;
  await request.response.close();
}
