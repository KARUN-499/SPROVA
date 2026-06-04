import 'package:equatable/equatable.dart';

enum EnrollmentStatus {
  pending,
  completed,
  failed,
  refunded,
}

enum TrackType {
  digitalProduct,
  physicalProduct,
  localBusiness,
  noCode,
}

extension TrackTypeExtension on TrackType {
  String toDisplayName() {
    switch (this) {
      case TrackType.digitalProduct:
        return 'Digital Product';
      case TrackType.physicalProduct:
        return 'Physical Product';
      case TrackType.localBusiness:
        return 'Local Business';
      case TrackType.noCode:
        return 'No-Code';
    }
  }

  String toIcon() {
    switch (this) {
      case TrackType.digitalProduct:
        return '💻';
      case TrackType.physicalProduct:
        return '📦';
      case TrackType.localBusiness:
        return '📍';
      case TrackType.noCode:
        return '⚡';
    }
  }

  static TrackType? fromDisplayName(String name) {
    switch (name) {
      case 'Digital Product':
        return TrackType.digitalProduct;
      case 'Physical Product':
        return TrackType.physicalProduct;
      case 'Local Business':
        return TrackType.localBusiness;
      case 'No-Code':
        return TrackType.noCode;
      default:
        return null;
    }
  }
}

class Enrollment extends Equatable {
  final String id;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final TrackType track;
  final String? userEmail;
  final int amountPaid;
  final EnrollmentStatus status;
  final DateTime enrolledAt;

  const Enrollment({
    required this.id,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.track,
    this.userEmail,
    required this.amountPaid,
    required this.status,
    required this.enrolledAt,
  });

  @override
  List<Object?> get props => [
        id,
        razorpayOrderId,
        razorpayPaymentId,
        track,
        userEmail,
        amountPaid,
        status,
        enrolledAt,
      ];
}
