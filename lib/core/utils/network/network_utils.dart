import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
/// Secure logging utility to mask sensitive data
void secureLog(String message) {
  // Mask emails, phone numbers, tokens (simple regex)
  final masked = message
    .replaceAll(RegExp(r'[\w.-]+@[\w.-]+'), '[REDACTED_EMAIL]')
    .replaceAll(RegExp(r'\b\d{10,}\b'), '[REDACTED_PHONE]')
    .replaceAll(RegExp(r'(token|key|secret)[=: ]+[^\s]+', caseSensitive: false), r'[31m[REDACTED][0m');
    print(masked);
}
/// Secure HTTP wrapper enforcing HTTPS
class SecureHttp {
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    _enforceHttps(url);
    return http.get(url, headers: headers);
  }
  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    _enforceHttps(url);
    return http.post(url, headers: headers, body: body, encoding: encoding);
  }
  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    _enforceHttps(url);
    return http.put(url, headers: headers, body: body, encoding: encoding);
  }
  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    _enforceHttps(url);
    return http.delete(url, headers: headers, body: body, encoding: encoding);
  }
  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    _enforceHttps(url);
    return http.patch(url, headers: headers, body: body, encoding: encoding);
  }
  static void _enforceHttps(Uri url) {
    if (url.scheme != 'https') {
      throw ArgumentError('Insecure HTTP is not allowed. Use HTTPS URLs only.');
    }
  }
}


/// Utility class for handling network-related operations and errors
class NetworkUtils {
  /// Check if an exception is a network-related error
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
           errorString.contains('failed host lookup') ||
           errorString.contains('network is unreachable') ||
           errorString.contains('connection refused') ||
           errorString.contains('connection reset') ||
           errorString.contains('connection timed out') ||
           errorString.contains('no address associated') ||
           errorString.contains('no internet');
  }

  /// Get user-friendly error message for network errors
  static String getNetworkErrorMessage(dynamic error) {
    if (isNetworkError(error)) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Show a snackbar with network error message
  static void showNetworkErrorSnackbar(BuildContext context, dynamic error) {
    if (!context.mounted) return;
    
    final message = getNetworkErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isNetworkError(error) ? Icons.wifi_off : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // User can retry manually
          },
        ),
      ),
    );
  }

  /// Execute a network operation with proper error handling
  /// Returns null if the operation fails due to network issues
  static Future<T?> executeWithNetworkCheck<T>(
    Future<T> Function() operation, {
    BuildContext? context,
    VoidCallback? onNetworkError,
  }) async {
    try {
      return await operation();
    } on SocketException catch (e) {
      secureLog('Network error (SocketException): $e');
      if (context != null && context.mounted) {
        showNetworkErrorSnackbar(context, e);
      }
      onNetworkError?.call();
      return null;
    } on HttpException catch (e) {
      secureLog('Network error (HttpException): $e');
      if (context != null && context.mounted) {
        showNetworkErrorSnackbar(context, e);
      }
      onNetworkError?.call();
      return null;
    } catch (e) {
      if (isNetworkError(e)) {
        secureLog('Network error: $e');
        if (context != null && context.mounted) {
          showNetworkErrorSnackbar(context, e);
        }
        onNetworkError?.call();
        return null;
      }
      rethrow;
    }
  }
}

/// Extension on BuildContext for easy network error handling
extension NetworkContextExtension on BuildContext {
  void showNetworkError(dynamic error) {
    NetworkUtils.showNetworkErrorSnackbar(this, error);
  }
}
