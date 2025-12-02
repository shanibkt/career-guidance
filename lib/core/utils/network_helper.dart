import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class NetworkHelper {
  /// Test if the backend API is reachable
  static Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing connection to: ${ApiConstants.baseUrl}');

      // Test the careers endpoint which is publicly accessible
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/recommendations/careers',
      );
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ Connection timeout - backend not responding');
              return http.Response('Timeout', 408);
            },
          );

      if (response.statusCode == 200) {
        debugPrint('✅ Backend is reachable!');
        return true;
      } else {
        debugPrint('! Backend responded with status: ${response.statusCode}');
        // 404 might mean the endpoint doesn't exist, but server is running
        // Try to be more forgiving
        if (response.statusCode == 404) {
          debugPrint('  Note: Server is responding but endpoint may not exist');
        }
        return response.statusCode <
            500; // Server errors are false, client errors might be OK
      }
    } on SocketException catch (e) {
      debugPrint('❌ Connection failed: ${e.message}');
      debugPrint('   Check:');
      debugPrint('   1. Backend server is running');
      debugPrint('   2. IP address is correct: ${ApiConstants.baseUrl}');
      debugPrint('   3. Device is on same WiFi network');
      debugPrint('   4. Firewall is not blocking port 5001');
      return false;
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      return false;
    }
  }

  /// Get current network info
  static Future<String> getNetworkInfo() async {
    try {
      final interfaces = await NetworkInterface.list();
      final info = StringBuffer();
      info.writeln('📱 Device Network Info:');

      for (var interface in interfaces) {
        info.writeln('  ${interface.name}:');
        for (var addr in interface.addresses) {
          info.writeln('    ${addr.address}');
        }
      }

      info.writeln('\n🔗 Backend URL: ${ApiConstants.baseUrl}');
      return info.toString();
    } catch (e) {
      return 'Error getting network info: $e';
    }
  }

  /// Show connection diagnostics
  static Future<void> runDiagnostics() async {
    debugPrint('\n' + '=' * 50);
    debugPrint('🔧 NETWORK DIAGNOSTICS');
    debugPrint('=' * 50);

    // Show network info
    final networkInfo = await getNetworkInfo();
    debugPrint(networkInfo);

    // Test connection
    debugPrint('\n🔍 Testing backend connection...');
    final isConnected = await testConnection();

    if (isConnected) {
      debugPrint('\n✅ All systems operational!');
    } else {
      debugPrint('\n❌ Cannot reach backend server');
      debugPrint('\n📋 Troubleshooting steps:');
      debugPrint('   1. Start your backend server');
      debugPrint(
        '   2. Get your PC IP: ipconfig (Windows) or ifconfig (Mac/Linux)',
      );
      debugPrint('   3. Update ApiConstants.baseUrl with your PC IP');
      debugPrint('   4. Make sure device and PC are on same WiFi');
      debugPrint('   5. Check firewall settings');
    }

    debugPrint('=' * 50 + '\n');
  }
}
