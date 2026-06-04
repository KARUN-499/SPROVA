// ignore_for_file: unused_import

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sprova/features/enrollment/data/sources/razorpay_web.dart';
import 'package:sprova/features/enrollment/data/sources/razorpay_native.dart';

typedef PaymentSuccessCallback = void Function(String paymentId, String orderId, String signature);
typedef PaymentFailureCallback = void Function(String message);
typedef ExternalWalletCallback = void Function(String walletName);

class RazorpayService {
  PaymentSuccessCallback? _onPaymentSuccessCallback;
  PaymentFailureCallback? _onPaymentErrorCallback;
  ExternalWalletCallback? _onExternalWalletCallback;

  dynamic _razorpay;

  RazorpayService() {
    if (!kIsWeb) {
      _initNative();
    }
  }

  void _initNative() {
    try {
      final razorpay = RazorpayNativeWrapper.create();
      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
        _onPaymentSuccessCallback?.call(
          response.paymentId ?? '',
          response.orderId ?? '',
          response.signature ?? '',
        );
      });
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        _onPaymentErrorCallback?.call(response.message ?? 'Payment failed');
      });
      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        _onExternalWalletCallback?.call(response.walletName ?? '');
      });
      _razorpay = razorpay;
    } catch (e) {
      debugPrint('Razorpay native init error: $e');
    }
  }

  void setCallbacks({
    PaymentSuccessCallback? onSuccess,
    PaymentFailureCallback? onError,
    ExternalWalletCallback? onExternalWallet,
  }) {
    _onPaymentSuccessCallback = onSuccess;
    _onPaymentErrorCallback = onError;
    _onExternalWalletCallback = onExternalWallet;
  }

  void openCheckout({
    required String keyId,
    required int amount,
    required String orderId,
    required String name,
    required String description,
    Map<String, String>? prefill,
    int timeout = 600,
  }) {
    if (kIsWeb) {
      _openWeb(
        keyId: keyId,
        amount: amount,
        orderId: orderId,
        name: name,
        description: description,
        prefill: prefill,
        timeout: timeout,
      );
    } else {
      _openNative(
        keyId: keyId,
        amount: amount,
        orderId: orderId,
        name: name,
        description: description,
        prefill: prefill,
        timeout: timeout,
      );
    }
  }

  void _openWeb({
    required String keyId,
    required int amount,
    required String orderId,
    required String name,
    required String description,
    Map<String, String>? prefill,
    required int timeout,
  }) {
    if (!kIsWeb) return;
    RazorpayWebLauncher.open(
      keyId: keyId,
      amount: amount,
      orderId: orderId,
      name: name,
      description: description,
      prefill: prefill ?? {},
      timeout: timeout,
      onSuccess: _onPaymentSuccessCallback,
      onError: _onPaymentErrorCallback,
    );
  }

  void _openNative({
    required String keyId,
    required int amount,
    required String orderId,
    required String name,
    required String description,
    Map<String, String>? prefill,
    required int timeout,
  }) {
    final options = {
      'key': keyId,
      'amount': amount,
      'currency': 'INR',
      'order_id': orderId,
      'name': name,
      'description': description,
      'prefill': prefill ?? {'contact': '', 'email': ''},
      'timeout': timeout,
    };
    _razorpay?.open(options);
  }

  void dispose() {
    if (!kIsWeb) {
      _razorpay?.clear();
    }
  }

  // Reads from dart-define on web, from .env on native
  String get razorpayKeyId {
    if (kIsWeb) {
      return const String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: '');
    } else {
      return dotenv.env['RAZORPAY_KEY_ID'] ?? '';
    }
  }
}
