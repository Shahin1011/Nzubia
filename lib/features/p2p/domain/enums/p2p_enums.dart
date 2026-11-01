// P2P enums — kept in sync with backend `src/p2p-shipping/enums/index.ts`.
//
// Wire format is always the SCREAMING_SNAKE_CASE string the backend emits.
// Use `fromJson` / `toJson` for serialization; `label` for user-facing copy.

// ─── Courier verification ─────────────────────────────────────────────────────

enum CourierVerificationState {
  draft,
  submitted,
  pendingReview,
  approved,
  active,
  suspended,
  rejected;

  static CourierVerificationState fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'DRAFT':
        return CourierVerificationState.draft;
      case 'SUBMITTED':
        return CourierVerificationState.submitted;
      case 'PENDING_REVIEW':
      case 'PENDING':
        return CourierVerificationState.pendingReview;
      case 'APPROVED':
        return CourierVerificationState.approved;
      case 'ACTIVE':
      case 'VERIFIED':
        return CourierVerificationState.active;
      case 'SUSPENDED':
        return CourierVerificationState.suspended;
      case 'REJECTED':
        return CourierVerificationState.rejected;
      default:
        return CourierVerificationState.draft;
    }
  }

  String toJson() {
    switch (this) {
      case CourierVerificationState.draft:
        return 'DRAFT';
      case CourierVerificationState.submitted:
        return 'SUBMITTED';
      case CourierVerificationState.pendingReview:
        return 'PENDING_REVIEW';
      case CourierVerificationState.approved:
        return 'APPROVED';
      case CourierVerificationState.active:
        return 'ACTIVE';
      case CourierVerificationState.suspended:
        return 'SUSPENDED';
      case CourierVerificationState.rejected:
        return 'REJECTED';
    }
  }

  String get label {
    switch (this) {
      case CourierVerificationState.draft:
        return 'Draft';
      case CourierVerificationState.submitted:
        return 'Submitted';
      case CourierVerificationState.pendingReview:
        return 'Pending Review';
      case CourierVerificationState.approved:
        return 'Approved';
      case CourierVerificationState.active:
        return 'Active';
      case CourierVerificationState.suspended:
        return 'Suspended';
      case CourierVerificationState.rejected:
        return 'Rejected';
    }
  }

  /// Whether the courier may publish routes and accept work.
  bool get canTakeWork => this == CourierVerificationState.active;

  /// Whether the courier has cleared identity review.
  bool get isApproved =>
      this == CourierVerificationState.approved ||
      this == CourierVerificationState.active;
}

// ─── Route status ─────────────────────────────────────────────────────────────

enum RouteStatus {
  draft,
  published,
  paused,
  expired,
  removed;

  static RouteStatus fromJson(String? value) {
    switch (value) {
      case 'DRAFT':
        return RouteStatus.draft;
      case 'PUBLISHED':
        return RouteStatus.published;
      case 'PAUSED':
        return RouteStatus.paused;
      case 'EXPIRED':
        return RouteStatus.expired;
      case 'REMOVED':
        return RouteStatus.removed;
      default:
        return RouteStatus.draft;
    }
  }

  String toJson() {
    switch (this) {
      case RouteStatus.draft:
        return 'DRAFT';
      case RouteStatus.published:
        return 'PUBLISHED';
      case RouteStatus.paused:
        return 'PAUSED';
      case RouteStatus.expired:
        return 'EXPIRED';
      case RouteStatus.removed:
        return 'REMOVED';
    }
  }

  String get label {
    switch (this) {
      case RouteStatus.draft:
        return 'Draft';
      case RouteStatus.published:
        return 'Published';
      case RouteStatus.paused:
        return 'Paused';
      case RouteStatus.expired:
        return 'Expired';
      case RouteStatus.removed:
        return 'Removed';
    }
  }
}

// ─── Shipment request status ─────────────────────────────────────────────────

enum ShipmentRequestStatus {
  draft,
  open,
  matched,
  reserved,
  handoffPending,
  inTransit,
  delivered,
  completed,
  cancelled,
  disputed,
  rejected;

  static ShipmentRequestStatus fromJson(String? value) {
    switch (value) {
      case 'DRAFT':
        return ShipmentRequestStatus.draft;
      case 'OPEN':
        return ShipmentRequestStatus.open;
      case 'MATCHED':
        return ShipmentRequestStatus.matched;
      case 'RESERVED':
        return ShipmentRequestStatus.reserved;
      case 'HANDOFF_PENDING':
        return ShipmentRequestStatus.handoffPending;
      case 'IN_TRANSIT':
        return ShipmentRequestStatus.inTransit;
      case 'DELIVERED':
        return ShipmentRequestStatus.delivered;
      case 'COMPLETED':
        return ShipmentRequestStatus.completed;
      case 'CANCELLED':
        return ShipmentRequestStatus.cancelled;
      case 'DISPUTED':
        return ShipmentRequestStatus.disputed;
      case 'REJECTED':
        return ShipmentRequestStatus.rejected;
      default:
        return ShipmentRequestStatus.draft;
    }
  }

  String toJson() {
    switch (this) {
      case ShipmentRequestStatus.draft:
        return 'DRAFT';
      case ShipmentRequestStatus.open:
        return 'OPEN';
      case ShipmentRequestStatus.matched:
        return 'MATCHED';
      case ShipmentRequestStatus.reserved:
        return 'RESERVED';
      case ShipmentRequestStatus.handoffPending:
        return 'HANDOFF_PENDING';
      case ShipmentRequestStatus.inTransit:
        return 'IN_TRANSIT';
      case ShipmentRequestStatus.delivered:
        return 'DELIVERED';
      case ShipmentRequestStatus.completed:
        return 'COMPLETED';
      case ShipmentRequestStatus.cancelled:
        return 'CANCELLED';
      case ShipmentRequestStatus.disputed:
        return 'DISPUTED';
      case ShipmentRequestStatus.rejected:
        return 'REJECTED';
    }
  }

  String get label {
    switch (this) {
      case ShipmentRequestStatus.draft:
        return 'Draft';
      case ShipmentRequestStatus.open:
        return 'Open';
      case ShipmentRequestStatus.matched:
        return 'Matched';
      case ShipmentRequestStatus.reserved:
        return 'Reserved';
      case ShipmentRequestStatus.handoffPending:
        return 'Handoff Pending';
      case ShipmentRequestStatus.inTransit:
        return 'In Transit';
      case ShipmentRequestStatus.delivered:
        return 'Delivered';
      case ShipmentRequestStatus.completed:
        return 'Completed';
      case ShipmentRequestStatus.cancelled:
        return 'Cancelled';
      case ShipmentRequestStatus.disputed:
        return 'Disputed';
      case ShipmentRequestStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isTerminal =>
      this == ShipmentRequestStatus.completed ||
      this == ShipmentRequestStatus.cancelled ||
      this == ShipmentRequestStatus.rejected;
}

// ─── Offer status ────────────────────────────────────────────────────────────

enum OfferStatus {
  proposed,
  accepted,
  rejected,
  expired,
  cancelled;

  static OfferStatus fromJson(String? value) {
    switch (value) {
      case 'PROPOSED':
        return OfferStatus.proposed;
      case 'ACCEPTED':
        return OfferStatus.accepted;
      case 'REJECTED':
        return OfferStatus.rejected;
      case 'EXPIRED':
        return OfferStatus.expired;
      case 'CANCELLED':
        return OfferStatus.cancelled;
      default:
        return OfferStatus.proposed;
    }
  }

  String toJson() {
    switch (this) {
      case OfferStatus.proposed:
        return 'PROPOSED';
      case OfferStatus.accepted:
        return 'ACCEPTED';
      case OfferStatus.rejected:
        return 'REJECTED';
      case OfferStatus.expired:
        return 'EXPIRED';
      case OfferStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case OfferStatus.proposed:
        return 'Proposed';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.rejected:
        return 'Rejected';
      case OfferStatus.expired:
        return 'Expired';
      case OfferStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// ─── Waiver status ───────────────────────────────────────────────────────────

enum WaiverStatus {
  pending,
  accepted,
  declined,
  expired;

  static WaiverStatus fromJson(String? value) {
    switch (value) {
      case 'PENDING':
        return WaiverStatus.pending;
      case 'ACCEPTED':
        return WaiverStatus.accepted;
      case 'DECLINED':
        return WaiverStatus.declined;
      case 'EXPIRED':
        return WaiverStatus.expired;
      default:
        return WaiverStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case WaiverStatus.pending:
        return 'PENDING';
      case WaiverStatus.accepted:
        return 'ACCEPTED';
      case WaiverStatus.declined:
        return 'DECLINED';
      case WaiverStatus.expired:
        return 'EXPIRED';
    }
  }
}

// ─── Courier request status ───────────────────────────────────────────────────

enum CourierRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired;

  static CourierRequestStatus fromJson(String? value) {
    switch (value) {
      case 'ACCEPTED':
        return CourierRequestStatus.accepted;
      case 'DECLINED':
        return CourierRequestStatus.declined;
      case 'CANCELLED':
        return CourierRequestStatus.cancelled;
      case 'EXPIRED':
        return CourierRequestStatus.expired;
      default:
        return CourierRequestStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case CourierRequestStatus.pending:
        return 'PENDING';
      case CourierRequestStatus.accepted:
        return 'ACCEPTED';
      case CourierRequestStatus.declined:
        return 'DECLINED';
      case CourierRequestStatus.cancelled:
        return 'CANCELLED';
      case CourierRequestStatus.expired:
        return 'EXPIRED';
    }
  }

  String get label {
    switch (this) {
      case CourierRequestStatus.pending:
        return 'Pending';
      case CourierRequestStatus.accepted:
        return 'Accepted';
      case CourierRequestStatus.declined:
        return 'Declined';
      case CourierRequestStatus.cancelled:
        return 'Cancelled';
      case CourierRequestStatus.expired:
        return 'Expired';
    }
  }
}

// ─── Item category ───────────────────────────────────────────────────────────

enum ItemCategory {
  documents,
  clothing,
  electronics,
  accessories,
  food,
  medicine,
  other;

  static ItemCategory fromJson(String? value) {
    switch (value) {
      case 'DOCUMENTS':
        return ItemCategory.documents;
      case 'CLOTHING':
        return ItemCategory.clothing;
      case 'ELECTRONICS':
        return ItemCategory.electronics;
      case 'ACCESSORIES':
        return ItemCategory.accessories;
      case 'FOOD':
        return ItemCategory.food;
      case 'MEDICINE':
        return ItemCategory.medicine;
      default:
        return ItemCategory.other;
    }
  }

  String toJson() {
    switch (this) {
      case ItemCategory.documents:
        return 'DOCUMENTS';
      case ItemCategory.clothing:
        return 'CLOTHING';
      case ItemCategory.electronics:
        return 'ELECTRONICS';
      case ItemCategory.accessories:
        return 'ACCESSORIES';
      case ItemCategory.food:
        return 'FOOD';
      case ItemCategory.medicine:
        return 'MEDICINE';
      case ItemCategory.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case ItemCategory.documents:
        return 'Documents';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.accessories:
        return 'Accessories';
      case ItemCategory.food:
        return 'Food';
      case ItemCategory.medicine:
        return 'Medicine';
      case ItemCategory.other:
        return 'Other';
    }
  }

  /// Categories that warrant a compliance warning before submission.
  static const restricted = <ItemCategory>{
    ItemCategory.medicine,
    ItemCategory.food,
    ItemCategory.electronics,
  };
}
