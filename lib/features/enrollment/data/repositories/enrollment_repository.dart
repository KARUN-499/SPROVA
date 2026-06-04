import 'package:fpdart/fpdart.dart';
import 'package:sprova/core/config/app_config.dart';
import 'package:sprova/features/enrollment/domain/entities/enrollment.dart';
import 'package:sprova/features/enrollment/domain/repositories/enrollment_repository_interface.dart';
import 'package:sprova/features/enrollment/data/sources/razorpay_service.dart';
import 'package:sprova/features/enrollment/data/sources/supabase_enrollment_source.dart';

class EnrollmentRepository implements IEnrollmentRepository {
  final RazorpayService _razorpayService;
  final SupabaseEnrollmentSource _enrollmentSource;

  EnrollmentRepository({
    required RazorpayService razorpayService,
    required SupabaseEnrollmentSource enrollmentSource,
  })  : _razorpayService = razorpayService,
        _enrollmentSource = enrollmentSource;

  @override
  Future<Either<EnrollmentFailure, String>> createOrder({
    required TrackType track,
    required int amount,
  }) {
    return _enrollmentSource.createOrder(track: track, amount: amount);
  }

  @override
  Future<Either<EnrollmentFailure, Enrollment>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required TrackType track,
    String? userEmail,
  }) {
    return _enrollmentSource.verifyPayment(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      track: track,
      userEmail: userEmail,
    );
  }

  void setPaymentCallbacks({
    PaymentSuccessCallback? onSuccess,
    PaymentFailureCallback? onError,
    ExternalWalletCallback? onExternalWallet,
  }) {
    _razorpayService.setCallbacks(
      onSuccess: onSuccess,
      onError: onError,
      onExternalWallet: onExternalWallet,
    );
  }

  void openRazorpayCheckout({
    required String orderId,
    required TrackType track,
    String? userEmail,
  }) {
    _razorpayService.openCheckout(
      keyId: _razorpayService.razorpayKeyId,
      amount: AppConfig.pricePaise,
      orderId: orderId,
      name: 'Sprova Cohort 1',
      description: '30-day startup program - ${track.toDisplayName()} track',
      prefill: {'contact': '', 'email': userEmail ?? ''},
      timeout: AppConfig.paymentTimeoutSeconds,
    );
  }

  void dispose() {
    _razorpayService.dispose();
  }
}
