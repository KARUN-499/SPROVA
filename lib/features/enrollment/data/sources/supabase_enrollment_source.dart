// ignore_for_file: prefer_const_constructors

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sprova/features/enrollment/domain/entities/enrollment.dart';
import 'package:sprova/features/enrollment/domain/repositories/enrollment_repository_interface.dart';

class SupabaseEnrollmentSource {
  final SupabaseClient _supabase;

  SupabaseEnrollmentSource(this._supabase);

  Future<Either<EnrollmentFailure, String>> createOrder({
    required TrackType track,
    required int amount,
  }) async {
    try {
      final body = {
        'track': track.toDisplayName(),
        'amount': amount,
      };
      print('Supabase function createOrder: calling functions/v1/create-order with body: $body');
      final response = await _supabase.functions.invoke(
        'create-order',
        body: body,
      );

      final orderId = response.data['orderId'] as String?;
      if (orderId == null || orderId.isEmpty) {
        return left(const EnrollmentFailure(
          message: 'Failed to create order',
          code: 'ORDER_CREATION_FAILED',
        ));
      }

      return right(orderId);
    } on FunctionException catch (fe) {
      print('Supabase function error in createOrder: status=${fe.status}, exception=${fe}');
      return left(EnrollmentFailure(
        message: fe.toString(),
        code: 'FUNCTION_ERROR',
      ));
    } catch (e) {
      print('Unexpected error in createOrder: $e');
      return left(EnrollmentFailure(
        message: e.toString(),
        code: 'UNKNOWN_ERROR',
      ));
    }
  }

  Future<Either<EnrollmentFailure, Enrollment>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required TrackType track,
    String? userEmail,
  }) async {
    try {
      final body = {
        'order_id': orderId,
        'payment_id': paymentId,
        'signature': signature,
        'track': track.toDisplayName(),
        'user_email': userEmail,
      };
      print('Supabase function verifyPayment: calling functions/v1/verify-payment with body: $body');
      final response = await _supabase.functions.invoke(
        'verify-payment',
        body: body,
      );

      final success = response.data['success'] as bool?;
      if (success != true) {
        return left(EnrollmentFailure(
          message: 'Payment verification failed',
          code: 'VERIFICATION_FAILED',
        ));
      }

      return right(Enrollment(
        id: const Uuid().v4(),
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        track: track,
        userEmail: userEmail,
        amountPaid: 2999,
        status: EnrollmentStatus.completed,
        enrolledAt: DateTime.now(),
      ));
    } on FunctionException catch (fe) {
      print('Supabase function error in verifyPayment: status=${fe.status}, exception=${fe}');
      return left(EnrollmentFailure(
        message: fe.toString(),
        code: 'FUNCTION_ERROR',
      ));
    } catch (e) {
      print('Unexpected error in verifyPayment: $e');
      return left(EnrollmentFailure(
        message: e.toString(),
        code: 'UNKNOWN_ERROR',
      ));
    }
  }
}
