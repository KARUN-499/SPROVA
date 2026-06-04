// Web-only Razorpay launcher using dart:js_interop
// ignore: avoid_web_libraries_in_flutter
// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';
import 'package:flutter/foundation.dart';

typedef PaymentSuccessCallback = void Function(String paymentId, String orderId, String signature);
typedef PaymentFailureCallback = void Function(String message);

@JS('Razorpay')
extension type RazorpayJS._(JSObject _) {
  external factory RazorpayJS(JSObject options);
  external void open();
}

@JS()
extension type RazorpayResponse._(JSObject _) {
  external String get razorpay_payment_id;
  external String get razorpay_order_id;
  external String get razorpay_signature;
}

class RazorpayWebLauncher {
  static void open({
    required String keyId,
    required int amount,
    required String orderId,
    required String name,
    required String description,
    required Map<String, String> prefill,
    required int timeout,
    PaymentSuccessCallback? onSuccess,
    PaymentFailureCallback? onError,
  }) {
    if (!kIsWeb) return;

    final options = {
      'key': keyId,
      'amount': amount,
      'currency': 'INR',
      'order_id': orderId,
      'name': name,
      'description': description,
      'prefill': prefill.isEmpty ? {'contact': '', 'email': ''} : prefill,
      'timeout': timeout,
      'handler': ((JSAny? jsResponse) {
        if (jsResponse == null) return;
        final response = jsResponse as RazorpayResponse;
        onSuccess?.call(
          response.razorpay_payment_id,
          response.razorpay_order_id,
          response.razorpay_signature,
        );
      }).toJS,
      'modal': {
        'ondismiss': (() {
          onError?.call('Payment cancelled');
        }).toJS,
      }.jsify(),
    }.jsify() as JSObject;

    final rzp = RazorpayJS(options);
    rzp.open();
  }
}