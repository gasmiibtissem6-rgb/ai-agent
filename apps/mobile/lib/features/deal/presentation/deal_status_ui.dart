import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/deal_model.dart';

/// One place deciding how a [DealStatus] looks, shared by every deal surface.
Color dealStatusColor(DealStatus status) => switch (status) {
  DealStatus.draft => AppColors.textSecondary,
  DealStatus.negotiation => AppColors.accent,
  DealStatus.pendingApproval => AppColors.primary,
  DealStatus.approved => AppColors.success,
  DealStatus.locked => AppColors.success,
  DealStatus.changesRequested => AppColors.warning,
  DealStatus.rejected => AppColors.error,
  DealStatus.cancelled => AppColors.error,
  DealStatus.archived => AppColors.textSecondary,
};

IconData dealStatusIcon(DealStatus status) => switch (status) {
  DealStatus.draft => Icons.edit_note_outlined,
  DealStatus.negotiation => Icons.compare_arrows_outlined,
  DealStatus.pendingApproval => Icons.hourglass_empty_outlined,
  DealStatus.approved => Icons.check_circle_outline,
  DealStatus.locked => Icons.lock_outline,
  DealStatus.changesRequested => Icons.edit_outlined,
  DealStatus.rejected => Icons.cancel_outlined,
  DealStatus.cancelled => Icons.block_outlined,
  DealStatus.archived => Icons.inventory_2_outlined,
};

IconData dealContentTypeIcon(DealContentType type) => switch (type) {
  DealContentType.document => Icons.description_outlined,
  DealContentType.video => Icons.videocam_outlined,
  DealContentType.scanned => Icons.document_scanner_outlined,
};
