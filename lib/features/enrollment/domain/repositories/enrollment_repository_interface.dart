import 'package:fpdart/fpdart.dart';
import 'package:sprova/features/enrollment/domain/entities/enrollment.dart';

class EnrollmentFailure {
  final String message;
  final String? code;

  const EnrollmentFailure({required this.message, this.code});
}

abstract class IEnrollmentRepository {
  /// Creates a Razorpay order for the given track
  /// Returns order ID on success
  Future<Either<EnrollmentFailure, String>> createOrder({
    required TrackType track,
    required int amount,
  });

  /// Verifies payment signature and creates enrollment record
  Future<Either<EnrollmentFailure, Enrollment>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required TrackType track,
    String? userEmail,
  });
}
