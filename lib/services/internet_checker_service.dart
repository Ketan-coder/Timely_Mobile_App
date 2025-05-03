import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timely/components/custom_snack_bar.dart';

class InternetChecker {
  bool _isConnected = true;
  late Timer _timer;
  final BuildContext context;

  InternetChecker(this.context);

  // Public getter to access internet status
  bool get isConnected => _isConnected;

  void startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      print('Checking internet connection...');
      bool currentlyConnected = await _isConnectedToInternet();

      if (!currentlyConnected && _isConnected) {
        _isConnected = false;
        print('Disconnected from the internet');
        showAnimatedSnackBar(
          context,
          "You're offline. Please check your internet connection.",
          isError: true,
          isTop: true,
        );
      } else if (currentlyConnected && !_isConnected) {
        _isConnected = true;
        print('Back online');
        showAnimatedSnackBar(
          context,
          "Back online! You're connected to the internet.",
          isSuccess: true,
          isTop: true,
        );
      }
    });
  }

  void stopMonitoring() {
    _timer.cancel();
  }

  Future<bool> _isConnectedToInternet() async {
    if (kIsWeb) {
      try {
        final response = await http.get(
            Uri.parse('https://www.timely.pythonanywhere.com'));
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    } else {
      try {
        final result = await InternetAddress.lookup(
            'timely.pythonanywhere.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException {
        return false;
      }
    }
  }

}
