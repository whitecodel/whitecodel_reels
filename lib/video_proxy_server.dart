import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// A local proxy server that streams video content while caching it simultaneously.
class VideoProxyServer {
  static VideoProxyServer? _instance;
  HttpServer? _server;
  bool _isRunning = false;
  final Map<String, String> _proxyMap = {};
  final BaseCacheManager _cacheManager;
  int _port = 8080;

  // Default port range to try if specific port is unavailable
  static const int _minPort = 8080;
  static const int _maxPort = 8180;

  /// Factory constructor that returns the singleton instance
  factory VideoProxyServer(BaseCacheManager cacheManager) {
    _instance ??= VideoProxyServer._internal(cacheManager);
    return _instance!;
  }

  VideoProxyServer._internal(this._cacheManager);

  /// Gets whether the server is currently running
  bool get isRunning => _isRunning;

  /// Gets the port the server is running on
  int get port => _port;

  /// Starts the proxy server on an available port
  Future<void> start({int preferredPort = 0}) async {
    if (_isRunning) return;

    await _cacheManager.emptyCache();

    try {
      if (preferredPort > 0) {
        // First try the preferred port
        try {
          _server = await HttpServer.bind(
            InternetAddress.loopbackIPv4,
            preferredPort,
          );
          _port = preferredPort;
        } catch (e) {
          log('Preferred port $preferredPort unavailable, trying alternatives');
          await _findAvailablePort();
        }
      } else {
        // Try to find an available port in the range or let system choose
        await _findAvailablePort();
      }

      _isRunning = true;
      log('Video proxy server started on port $_port');

      _server!.listen((HttpRequest request) async {
        try {
          await _handleRequest(request);
        } catch (e) {
          log('Error handling request: $e');
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        }
      });
    } catch (e) {
      log('Failed to start video proxy server: $e');
      _isRunning = false;
    }
  }

  /// Find an available port to use
  Future<void> _findAvailablePort() async {
    // First try ports in our preferred range
    for (int p = _minPort; p <= _maxPort; p++) {
      try {
        _server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          p,
          shared: false,
        );
        _port = p;
        log('Found available port: $_port');
        return;
      } catch (e) {
        // Port is not available, continue to the next one
      }
    }

    // If all preferred ports are unavailable, let the system pick one
    log('No ports available in preferred range, letting system choose');
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
  }

  /// Stops the proxy server
  Future<void> stop() async {
    if (!_isRunning || _server == null) return;

    await _server!.close(force: true);
    _server = null;
    _isRunning = false;
    log('Video proxy server stopped');
  }

  /// Registers a URL with the proxy server and returns a local URL to access it
  Future<String> registerUrl(String url) async {
    if (!_isRunning) {
      await start();
    }

    // Create unique ID for this video URL
    String videoId = base64Encode(url.codeUnits);
    _proxyMap[videoId] = url;

    // Log to help with debugging
    log('Registered proxy URL for: $url');

    // Always use HTTP for localhost - HTTPS won't work without proper certificates
    return 'http://localhost:$_port/$videoId';
  }

  /// Handles incoming HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path.substring(1); // Remove leading slash
    final originalUrl = _proxyMap[path];

    if (originalUrl == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    // Always stream the content to ensure smooth playback
    log('Streaming video content: $originalUrl');
    await _streamAndCache(request, originalUrl);
  }

  /// Streams content from the original URL while caching it
  Future<void> _streamAndCache(HttpRequest request, String url) async {
    final response = request.response;
    final client = http.Client();
    try {
      final rangeHeader = request.headers.value('range');

      final req = http.Request('GET', Uri.parse(url));
      if (rangeHeader != null) {
        req.headers['Range'] = rangeHeader;
        log('📥 Requested range: $rangeHeader');
      }

      final streamedResponse = await client.send(req);
      final contentType =
          streamedResponse.headers['content-type'] ?? 'video/mp4';
      final contentLength = streamedResponse.headers['content-length'];
      final contentRange = streamedResponse.headers['content-range'];

      // Status: 206 for partial, 200 otherwise
      response.statusCode = streamedResponse.statusCode;
      response.headers.set('Content-Type', contentType);
      if (contentLength != null) {
        response.headers.set('Content-Length', contentLength);
      }
      if (contentRange != null) {
        response.headers.set('Content-Range', contentRange);
      }

      response.headers.set('Accept-Ranges', 'bytes');
      response.headers.set('Access-Control-Allow-Origin', '*');

      // Start streaming
      await response.flush();

      final cacheSink = BytesBuilder();
      await for (final chunk in streamedResponse.stream) {
        response.add(chunk);
        await response.flush(); // stream to player
        cacheSink.add(chunk);
      }

      // Save full/partial content to cache
      _cacheManager
          .putFile(url, cacheSink.takeBytes(), fileExtension: 'mp4')
          .then((f) => log('✅ Cached file: ${f.path}'))
          .catchError((e) => log('❌ Cache error: $e'));

      await response.close();
    } catch (e) {
      log('❌ Streaming error: $e');
      response.statusCode = HttpStatus.internalServerError;
      await response.close();
    } finally {
      client.close();
    }
  }
}
