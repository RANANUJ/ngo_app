import 'dart:io';
import 'package:flutter/material.dart';

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
      debugPrint('Network error (SocketException): $e');
      if (context != null && context.mounted) {
        showNetworkErrorSnackbar(context, e);
      }
      onNetworkError?.call();
      return null;
    } on HttpException catch (e) {
      debugPrint('Network error (HttpException): $e');
      if (context != null && context.mounted) {
        showNetworkErrorSnackbar(context, e);
      }
      onNetworkError?.call();
      return null;
    } catch (e) {
      if (isNetworkError(e)) {
        debugPrint('Network error: $e');
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
