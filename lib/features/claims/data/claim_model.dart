import 'package:equatable/equatable.dart';

enum ClaimStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending Review';
      case ClaimStatus.approved:
        return 'Claim Approved';
      case ClaimStatus.rejected:
        return 'Claim Rejected';
      case ClaimStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

class ClaimModel extends Equatable {
  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.claimantUid,
    required this.claimantName,
    required this.claimantEmail,
    required this.verificationEvidence,
    required this.createdAt,
    this.claimantContact,
    this.evidencePhotoUrl,
    this.status = ClaimStatus.pending,
    this.reviewedAt,
    this.reviewNotes,
  });

  final String id;
  final String itemId;
  final String itemTitle;
  final String claimantUid;
  final String claimantName;
  final String claimantEmail;
  final String? claimantContact;
  final String verificationEvidence;
  final String? evidencePhotoUrl;
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  ClaimModel copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? claimantUid,
    String? claimantName,
    String? claimantEmail,
    String? claimantContact,
    String? verificationEvidence,
    String? evidencePhotoUrl,
    ClaimStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewNotes,
  }) {
    return ClaimModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      claimantUid: claimantUid ?? this.claimantUid,
      claimantName: claimantName ?? this.claimantName,
      claimantEmail: claimantEmail ?? this.claimantEmail,
      claimantContact: claimantContact ?? this.claimantContact,
      verificationEvidence: verificationEvidence ?? this.verificationEvidence,
      evidencePhotoUrl: evidencePhotoUrl ?? this.evidencePhotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'claimantUid': claimantUid,
      'claimantName': claimantName,
      'claimantEmail': claimantEmail,
      'claimantContact': claimantContact,
      'verificationEvidence': verificationEvidence,
      'evidencePhotoUrl': evidencePhotoUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNotes': reviewNotes,
    };
  }

  factory ClaimModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ClaimModel(
      id: id,
      itemId: data['itemId'] as String? ?? '',
      itemTitle: data['itemTitle'] as String? ?? '',
      claimantUid: data['claimantUid'] as String? ?? '',
      claimantName: data['claimantName'] as String? ?? 'Anonymous Claimant',
      claimantEmail: data['claimantEmail'] as String? ?? '',
      claimantContact: data['claimantContact'] as String?,
      verificationEvidence: data['verificationEvidence'] as String? ?? '',
      evidencePhotoUrl: data['evidencePhotoUrl'] as String?,
      status: ClaimStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ClaimStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      reviewedAt: data['reviewedAt'] != null
          ? DateTime.tryParse(data['reviewedAt'] as String)
          : null,
      reviewNotes: data['reviewNotes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemTitle,
        claimantUid,
        claimantName,
        claimantEmail,
        claimantContact,
        verificationEvidence,
        evidencePhotoUrl,
        status,
        createdAt,
        reviewedAt,
        reviewNotes,
      ];
}
