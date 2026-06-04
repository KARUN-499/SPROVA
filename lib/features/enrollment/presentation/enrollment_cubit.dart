import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/core/config/app_config.dart';
import 'package:sprova/features/enrollment/domain/entities/enrollment.dart';
import 'package:sprova/features/enrollment/domain/repositories/enrollment_repository_interface.dart';
import 'package:sprova/features/enrollment/data/repositories/enrollment_repository.dart';
import 'package:sprova/features/enrollment/presentation/enrollment_state.dart';

class EnrollmentCubit extends Cubit {
  final EnrollmentRepository _repository;

  EnrollmentCubit(this._repository) : super(const EnrollmentInitial());

  TrackType? get currentTrack {
    final s = state;
    if (s is EnrollmentInitial) return s.selectedTrack;
    if (s is EnrollmentPaymentProcessing) return s.track;
    return null;
  }

  void selectTrack(TrackType track) {
    emit(EnrollmentInitial(selectedTrack: track));
  }

  Future<void> startEnrollment() async {
    final track = currentTrack;
    if (track == null) return;

    final sessionEmail =
        Supabase.instance.client.auth.currentSession?.user.email ?? '';

    emit(const EnrollmentLoading());

    final orderResult = await _repository.createOrder(
      track: track,
      amount: AppConfig.pricePaise,
    );

    orderResult.fold(
      (failure) => emit(EnrollmentError(failure)),
      (orderId) {
        emit(EnrollmentPaymentProcessing(orderId, track));
        _repository.openRazorpayCheckout(
          orderId: orderId,
          track: track,
          userEmail: sessionEmail,
        );
      },
    );
  }

  void onPaymentSuccess(String orderId, String paymentId, String signature, String userEmail) async {
    final track = currentTrack;
    if (track == null) return;

    final result = await _repository.verifyPayment(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      track: track,
      userEmail: userEmail,
    );

    result.fold(
      (failure) => emit(EnrollmentError(failure)),
      (enrollment) => emit(EnrollmentSuccess(enrollment)),
    );
  }

  void onPaymentError(String message) {
    emit(EnrollmentError(
        EnrollmentFailure(message: message, code: 'PAYMENT_FAILED')));
  }

  void onExternalWallet(String walletName) {
    debugPrint('External wallet selected: $walletName');
  }

  void reset() {
    emit(const EnrollmentInitial());
  }
}