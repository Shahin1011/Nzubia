import 'package:flutter/material.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';
import 'package:customer_nzubia_global/core/services/agent_status_update_service.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class UpdateStatusButton extends StatelessWidget {
  final ShipmentEntity shipment;
  final VoidCallback onRefresh;

  const UpdateStatusButton({
    super.key,
    required this.shipment,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();
    final primaryColor = colors?.neonCyan ?? theme.colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor.withValues(alpha: 0.15),
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () {
          AgentStatusUpdateService.showUpdateStatusDialog(
            context: context,
            shipment: shipment,
            onRefresh: onRefresh,
          );
        },
        child: Text(
          AppLocalizations.of(context)!.updateStatus,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
