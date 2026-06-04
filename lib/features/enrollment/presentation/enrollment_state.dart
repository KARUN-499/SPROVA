import 'package:equatable/equatable.dart';
import 'package:sprova/features/enrollment/domain/entities/enrollment.dart';
import 'package:sprova/features/enrollment/domain/repositories/enrollment_repository_interface.dart';

sealed class EnrollmentState extends Equatable {
  const EnrollmentState();

  @override
  List<Object?> get props => [];
}

class EnrollmentInitial extends EnrollmentState {
  final TrackType? selectedTrack;

  const EnrollmentInitial({this.selectedTrack});

  @override
  List<Object?> get props => [selectedTrack];
}

class EnrollmentLoading extends EnrollmentState {
  const EnrollmentLoading();
}

class EnrollmentPaymentProcessing extends EnrollmentState {
  final String orderId;
  final TrackType track;

  const EnrollmentPaymentProcessing(this.orderId, this.track);

  @override
  List<Object?> get props => [orderId, track];
}

class EnrollmentSuccess extends EnrollmentState {
  final Enrollment enrollment;

  const EnrollmentSuccess(this.enrollment);

  @override
  List<Object?> get props => [enrollment];
}

class EnrollmentError extends EnrollmentState {
  final EnrollmentFailure failure;

  EnrollmentError(this.failure);

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}