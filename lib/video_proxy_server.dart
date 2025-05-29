import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
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

    // Check if the file is already in the cache
    FileInfo? fileInfo;
    try {
      fileInfo = await _cacheManager.getFileFromCache(originalUrl);
    } catch (e) {
      log('Error checking cache: $e');
    }

    if (fileInfo != null) {
      // File is in cache, serve directly from cache
      log('Serving from cache: $originalUrl');
      await _serveFromFile(request.response, fileInfo.file);
    } else {
      // File is not in cache, stream and cache simultaneously
      log('Serving from source URL (not cached): $originalUrl');
      await _streamAndCache(request.response, originalUrl);
    }
  }

  /// Serves content from a file
  Future<void> _serveFromFile(HttpResponse response, File file) async {
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.parse('video/mp4');
    response.headers.add('Access-Control-Allow-Origin', '*');

    final fileLength = await file.length();
    response.contentLength = fileLength;
    log(
      'Serving cached file of size: ${(fileLength / 1024).toStringAsFixed(2)} KB',
    );

    await response.addStream(file.openRead());
    await response.close();
  }

  /// Streams content from the original URL while caching it
  Future<void> _streamAndCache(HttpResponse response, String url) async {
    try {
      final client = http.Client();
      final req = http.Request('GET', Uri.parse(url));
      final streamedResponse = await client.send(req);

      response.statusCode = streamedResponse.statusCode;
      streamedResponse.headers.forEach((key, value) {
        response.headers.add(key, value);
      });

      // Set CORS headers
      response.headers.add('Access-Control-Allow-Origin', '*');

      // Stream to cache and client simultaneously
      log('Downloading and caching: $url');
      final bytes = await streamedResponse.stream.toBytes();
      log('Downloaded ${bytes.length / 1024} KB, saving to cache');

      final cacheFile = await _cacheManager.putFile(
        url,
        bytes,
        fileExtension: 'mp4',
      );

      log('File saved to cache: ${cacheFile.path}');
      await response.addStream(cacheFile.readAsBytes().asStream());
      await response.close();
      client.close();
    } catch (e) {
      log('Error streaming video: $e');
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } catch (_) {
        // Ignore if already closed
      }
    }
  }
}
