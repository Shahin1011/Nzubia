import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/courier_dashboard/courier_dashboard_bloc.dart';

class CourierLocationSheet extends StatefulWidget {
  /// Current home coordinates from the profile (may be null if not yet set).
  final double? currentLatitude;
  final double? currentLongitude;

  const CourierLocationSheet({
    super.key,
    this.currentLatitude,
    this.currentLongitude,
  });

  @override
  State<CourierLocationSheet> createState() => _CourierLocationSheetState();
}

class _CourierLocationSheetState extends State<CourierLocationSheet> {
  double? _latitude;
  double? _longitude;
  String? _resolvedAddress;
  bool _fetching = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _latitude = widget.currentLatitude;
    _longitude = widget.currentLongitude;
    if (_latitude != null && _longitude != null) {
      _reverseGeocode(_latitude!, _longitude!);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _fetching = true;
      _error = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied. Please enable it in Settings.';
          _fetching = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _fetching = false;
      });

      await _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _error = 'Could not get location. Please try again.';
        _fetching = false;
      });
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        setState(() => _resolvedAddress = parts.isEmpty ? null : parts);
      }
    } catch (_) {
      // Non-fatal — coordinates are still valid without a readable address.
    }
  }

  Future<void> _save() async {
    if (_latitude == null || _longitude == null) return;
    setState(() => _saving = true);
    context.read<CourierDashboardBloc>().add(
          CourierDashboardLocationUpdated(
            latitude: _latitude!,
            longitude: _longitude!,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCoords = _latitude != null && _longitude != null;
    final isNew = widget.currentLatitude == null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                isNew ? 'Set Home Location' : 'Update Home Location',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your home location helps us show you shipments nearby. It is only used to match you with opportunities.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // Current / detected location card
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: hasCoords
                ? _LocationCard(
                    key: const ValueKey('coords'),
                    latitude: _latitude!,
                    longitude: _longitude!,
                    address: _resolvedAddress,
                    theme: theme,
                  )
                : _EmptyLocationCard(theme: theme),
          ),

          const SizedBox(height: 16),

          // Detect button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetching ? null : _fetchCurrentLocation,
              icon: _fetching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryColor),
                    )
                  : const Icon(Icons.my_location_outlined),
              label: Text(
                  _fetching ? 'Detecting location…' : 'Use My Current Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    size: 15, color: theme.colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (hasCoords && !_saving) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Location',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final ThemeData theme;

  const _LocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on,
              color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address != null)
                  Text(
                    address!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                Text(
                  '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLocationCard extends StatelessWidget {
  final ThemeData theme;
  const _EmptyLocationCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined,
              color: theme.colorScheme.outline, size: 20),
          const SizedBox(width: 10),
          Text(
            'No location set yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
