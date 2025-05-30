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
  final Map<String, _ProxyResource> _proxyMap = {};
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
  Future<String> registerUrl(String url, {Map<String, String>? headers}) async {
    if (!_isRunning) {
      await start();
    }

    // Create unique ID for this video URL
    String videoId = base64Encode(url.codeUnits);
    _proxyMap[videoId] = _ProxyResource(url, headers ?? {});

    // Log to help with debugging
    log('Registered proxy URL for: $url');

    // Always use HTTP for localhost - HTTPS won't work without proper certificates
    return 'http://localhost:$_port/$videoId';
  }

  /// Handles incoming HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path.substring(1); // Remove leading slash
    final resource = _proxyMap[path];

    if (resource == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final originalUrl = resource.url;

    try {
      // Check if file is already in cache and fully downloaded
      final fileInfo = await _cacheManager.getFileFromCache(originalUrl);
      if (fileInfo != null) {
        // File is completely cached, serve directly from cache
        log('Serving video from cache: $originalUrl');
        await _streamFromCache(request, fileInfo, originalUrl);
        return;
      }
    } catch (e) {
      log('Error checking cache: $e');
    }

    // Not fully cached, stream and cache simultaneously
    log('Streaming video content: $originalUrl');
    await _streamAndCache(request, resource);
  }

  /// Serves content directly from the cache
  Future<void> _streamFromCache(
    HttpRequest request,
    FileInfo fileInfo,
    String url,
  ) async {
    final response = request.response;
    final File file = fileInfo.file;
    final rangeHeader = request.headers.value('range');

    try {
      final stat = await file.stat();
      final fileSize = stat.size;

      if (rangeHeader == null) {
        // Full file request
        response.statusCode = HttpStatus.ok;
        response.headers.set('Content-Type', 'video/mp4');
        response.headers.set('Content-Length', fileSize.toString());
        response.headers.set('Accept-Ranges', 'bytes');
        response.headers.set('Access-Control-Allow-Origin', '*');

        await response.addStream(file.openRead());
      } else {
        // Handle range request
        final regExp = RegExp(r'bytes=(\d+)-(\d+)?');
        final match = regExp.firstMatch(rangeHeader);

        if (match != null) {
          final startByte = int.parse(match.group(1)!);
          final endByte = match.group(2) != null
              ? int.parse(match.group(2)!)
              : fileSize - 1;

          final contentLength = endByte - startByte + 1;

          response.statusCode = HttpStatus.partialContent;
          response.headers.set('Content-Type', 'video/mp4');
          response.headers.set('Content-Length', contentLength.toString());
          response.headers.set(
            'Content-Range',
            'bytes $startByte-$endByte/$fileSize',
          );
          response.headers.set('Accept-Ranges', 'bytes');
          response.headers.set('Access-Control-Allow-Origin', '*');

          await response.addStream(file.openRead(startByte, endByte + 1));
        }
      }
    } catch (e) {
      log('Error streaming from cache: $e');
      response.statusCode = HttpStatus.internalServerError;
    } finally {
      await response.close();
    }
  }

  /// Streams content from the original URL while caching it
  Future<void> _streamAndCache(
    HttpRequest request,
    _ProxyResource resource,
  ) async {
    final response = request.response;
    final client = http.Client();
    try {
      final rangeHeader = request.headers.value('range');

      final req = http.Request('GET', Uri.parse(resource.url));

      // Apply the original headers to the request
      req.headers.addAll(resource.headers);

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

      // Only cache if we're not handling a range request or we're handling the full file
      final shouldCache =
          rangeHeader == null || streamedResponse.statusCode == HttpStatus.ok;
      final cacheSink = shouldCache ? BytesBuilder() : null;

      await for (final chunk in streamedResponse.stream) {
        response.add(chunk);
        await response.flush(); // stream to player
        if (shouldCache) cacheSink?.add(chunk);
      }

      // Save full content to cache only if it wasn't a partial range request
      if (shouldCache && cacheSink != null) {
        _cacheManager
            .putFile(resource.url, cacheSink.takeBytes(), fileExtension: 'mp4')
            .then((f) => log('✅ Cached file: ${f.path}'))
            .catchError((e) => log('❌ Cache error: $e'));
      }

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

/// Class to store both URL and headers for a proxied resource
class _ProxyResource {
  final String url;
  final Map<String, String> headers;

  _ProxyResource(this.url, this.headers);
}
