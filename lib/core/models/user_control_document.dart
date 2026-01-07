import 'package:cloud_firestore/cloud_firestore.dart';

/// User lifecycle states for subscription-based access control
/// 
/// Flow: PENDING → TRIAL → ACTIVE → EXPIRED (or BLOCKED/CANCELED at any time)
enum UserStatus {
  /// Just registered, waiting for admin approval
  /// Cannot access the app
  pending,

  /// Trial period active (free trial for new users)
  /// Full access until trial ends
  trial,

  /// Approved by admin and subscription is valid
  /// Full access to the app
  active,

  /// Subscription has ended
  /// App is locked, needs renewal
  expired,

  /// User canceled subscription
  /// App is locked, can reactivate by paying
  canceled,

  /// Manually blocked by admin
  /// No access, may have a reason
  blocked,
}

// ============================================================
// SUBSCRIPTION PLAN TYPES
// ============================================================
enum SubscriptionPlan {
  trial,
  monthly,
  quarterly,
  yearly,
  lifetime,
  custom,
}

// ============================================================
// USER ROLES (for in-app permissions)
// ============================================================
enum UserRole {
  administrator,
  stockManager,
  salesProfessional,
  accountant,
}

// ============================================================
// USER CONTROL DOCUMENT
// ============================================================
/// The control document stored in Firebase that determines access
/// This is the source of truth synced from Firebase
class UserControlDocument {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? companyName;

  // Core access control fields
  final UserStatus status;
  final bool isApproved;

  // Subscription details
  final SubscriptionPlan? subscriptionPlan;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime? trialEndDate;  // For trial users

  // Admin notes
  final String? adminNotes;
  final String? blockedReason;

  // Security settings (from admin)
  final int maxOfflineDays;

  // Control metadata (set by admin actions)
  final DateTime? controlLastUpdatedAt;
  final String? controlLastUpdatedByAdmin;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final DateTime? lastLoginAt;
  final DateTime? lastSyncAt;

  UserControlDocument({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.companyName,
    required this.status,
    required this.isApproved,
    this.subscriptionPlan,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.trialEndDate,
    this.adminNotes,
    this.blockedReason,
    this.maxOfflineDays = 7,
    this.controlLastUpdatedAt,
    this.controlLastUpdatedByAdmin,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.lastLoginAt,
    this.lastSyncAt,
  });

  // ========================================
  // ACCESS CONTROL CHECKS
  // ========================================

  /// Can the user access the app right now?
  bool get canAccess {
    if (status == UserStatus.pending) return false;
    if (status == UserStatus.blocked) return false;
    if (status == UserStatus.expired) return false;
    if (status == UserStatus.canceled) return false;
    if (!isApproved && status != UserStatus.trial) return false;
    if (status == UserStatus.trial) return isTrialValid;
    if (!isSubscriptionValid) return false;
    return true;
  }

  /// Is the trial currently valid?
  bool get isTrialValid {
    if (status != UserStatus.trial) return false;
    if (trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Is the trial expired?
  bool get isTrialExpired {
    if (status != UserStatus.trial) return false;
    if (trialEndDate == null) return true;
    return DateTime.now().isAfter(trialEndDate!);
  }

  /// Days until trial expires
  int get daysUntilTrialExpiry {
    if (trialEndDate == null) return 0;
    return trialEndDate!.difference(DateTime.now()).inDays;
  }

  /// Is the subscription currently valid?
  bool get isSubscriptionValid {
    if (subscriptionPlan == SubscriptionPlan.lifetime) return true;
    if (subscriptionEndDate == null) return false;
    return DateTime.now().isBefore(subscriptionEndDate!);
  }

  /// Is the subscription expired?
  bool get isSubscriptionExpired {
    if (subscriptionPlan == SubscriptionPlan.lifetime) return false;
    if (subscriptionEndDate == null) return true;
    return DateTime.now().isAfter(subscriptionEndDate!);
  }

  /// Days until subscription expires (negative if expired)
  int get daysUntilExpiry {
    if (subscriptionPlan == SubscriptionPlan.lifetime) return 999999;
    if (subscriptionEndDate == null) return -999;
    return subscriptionEndDate!.difference(DateTime.now()).inDays;
  }

  /// Is the user pending approval?
  bool get isPending => status == UserStatus.pending || (!isApproved && status != UserStatus.trial);

  /// Is the user in trial?
  bool get isTrial => status == UserStatus.trial;

  /// Is the user blocked?
  bool get isBlocked => status == UserStatus.blocked;

  /// Is the subscription canceled?
  bool get isCanceled => status == UserStatus.canceled;

  // ========================================
  // FIRESTORE SERIALIZATION
  // ========================================

  factory UserControlDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserControlDocument.fromMap(doc.id, data);
  }

  factory UserControlDocument.fromMap(String id, Map<String, dynamic> data) {
    return UserControlDocument(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      companyName: data['companyName'],
      status: _parseStatus(data['status']),
      isApproved: data['approved'] ?? data['isApproved'] ?? false,
      subscriptionPlan: _parsePlan(data['subscription']?['plan'] ?? data['subscriptionPlan']),
      subscriptionStartDate: _parseDateTime(data['subscription']?['startDate'] ?? data['subscriptionStartDate']),
      subscriptionEndDate: _parseDateTime(data['subscription']?['endDate'] ?? data['subscriptionEndDate'] ?? data['subscriptionExpiry']),
      trialEndDate: _parseDateTime(data['trialEndDate'] ?? data['subscription']?['trialEndDate']),
      adminNotes: data['adminNotes'],
      blockedReason: data['blockedReason'],
      maxOfflineDays: data['security']?['maxOfflineDays'] ?? 7,
      controlLastUpdatedAt: _parseDateTime(data['control']?['lastUpdatedAt']),
      controlLastUpdatedByAdmin: data['control']?['lastUpdatedByAdmin'],
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']),
      approvedAt: _parseDateTime(data['approvedAt']),
      lastLoginAt: _parseDateTime(data['lastLoginAt']),
      lastSyncAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'companyName': companyName,
      'status': status.name,
      'approved': isApproved,
      'subscription': {
        'plan': subscriptionPlan?.name,
        'startDate': subscriptionStartDate,
        'endDate': subscriptionEndDate,
        'trialEndDate': trialEndDate,
      },
      'security': {
        'maxOfflineDays': maxOfflineDays,
      },
      'control': {
        'lastUpdatedAt': controlLastUpdatedAt,
        'lastUpdatedByAdmin': controlLastUpdatedByAdmin,
      },
      'adminNotes': adminNotes,
      'blockedReason': blockedReason,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'approvedAt': approvedAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  /// Convert to JSON for local caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'companyName': companyName,
      'status': status.name,
      'isApproved': isApproved,
      'subscriptionPlan': subscriptionPlan?.name,
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'adminNotes': adminNotes,
      'blockedReason': blockedReason,
      'maxOfflineDays': maxOfflineDays,
      'controlLastUpdatedAt': controlLastUpdatedAt?.toIso8601String(),
      'controlLastUpdatedByAdmin': controlLastUpdatedByAdmin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  factory UserControlDocument.fromJson(Map<String, dynamic> json) {
    return UserControlDocument(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      companyName: json['companyName'],
      status: _parseStatus(json['status']),
      isApproved: json['isApproved'] ?? false,
      subscriptionPlan: _parsePlan(json['subscriptionPlan']),
      subscriptionStartDate: json['subscriptionStartDate'] != null 
          ? DateTime.parse(json['subscriptionStartDate']) 
          : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null 
          ? DateTime.parse(json['subscriptionEndDate']) 
          : null,
      trialEndDate: json['trialEndDate'] != null 
          ? DateTime.parse(json['trialEndDate']) 
          : null,
      adminNotes: json['adminNotes'],
      blockedReason: json['blockedReason'],
      maxOfflineDays: json['maxOfflineDays'] ?? 7,
      controlLastUpdatedAt: json['controlLastUpdatedAt'] != null 
          ? DateTime.parse(json['controlLastUpdatedAt']) 
          : null,
      controlLastUpdatedByAdmin: json['controlLastUpdatedByAdmin'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt']) 
          : null,
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
      lastSyncAt: json['lastSyncAt'] != null 
          ? DateTime.parse(json['lastSyncAt']) 
          : null,
    );
  }

  // ========================================
  // HELPER PARSING METHODS
  // ========================================

  static UserStatus _parseStatus(dynamic value) {
    if (value == null) return UserStatus.pending;
    if (value is UserStatus) return value;
    
    final statusStr = value.toString().toLowerCase();
    return UserStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr,
      orElse: () => UserStatus.pending,
    );
  }

  static SubscriptionPlan? _parsePlan(dynamic value) {
    if (value == null) return null;
    if (value is SubscriptionPlan) return value;
    
    final planStr = value.toString().toLowerCase();
    return SubscriptionPlan.values.firstWhere(
      (e) => e.name.toLowerCase() == planStr,
      orElse: () => SubscriptionPlan.trial,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  UserControlDocument copyWith({
    String? name,
    String? phone,
    String? companyName,
    UserStatus? status,
    bool? isApproved,
    SubscriptionPlan? subscriptionPlan,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    String? adminNotes,
    String? blockedReason,
    int? maxOfflineDays,
    DateTime? controlLastUpdatedAt,
    String? controlLastUpdatedByAdmin,
    DateTime? updatedAt,
    DateTime? approvedAt,
    DateTime? lastLoginAt,
    DateTime? lastSyncAt,
  }) {
    return UserControlDocument(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
      isApproved: isApproved ?? this.isApproved,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      adminNotes: adminNotes ?? this.adminNotes,
      blockedReason: blockedReason ?? this.blockedReason,
      maxOfflineDays: maxOfflineDays ?? this.maxOfflineDays,
      controlLastUpdatedAt: controlLastUpdatedAt ?? this.controlLastUpdatedAt,
      controlLastUpdatedByAdmin: controlLastUpdatedByAdmin ?? this.controlLastUpdatedByAdmin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  String toString() => 
      'UserControlDocument(id: $id, email: $email, status: $status, '
      'approved: $isApproved, subscriptionEnd: $subscriptionEndDate)';
}
