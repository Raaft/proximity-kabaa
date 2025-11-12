import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_settings/app_settings.dart';
import 'package:intl/intl.dart';
import '../cubit/location_cubit.dart';
import '../cubit/location_state.dart';
import '../../domain/enums/location_mode.dart';

class MeccaProximityPage extends StatelessWidget {
  const MeccaProximityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MeccaProximityView();
  }
}

class _MeccaProximityView extends StatefulWidget {
  const _MeccaProximityView();

  @override
  State<_MeccaProximityView> createState() => _MeccaProximityViewState();
}

class _MeccaProximityViewState extends State<_MeccaProximityView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final bool _showDebugPanel = false;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationCubit>().startLocationUpdates();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final cubit = context.read<LocationCubit>();
      final currentState = cubit.state;
      if (currentState is LocationPermissionDenied ||
          currentState is LocationPermissionPermanentlyDenied) {
        cubit.retryPermissionCheck();
      }
    }
  }

  bool _isPermissionDenied(LocationState state) {
    return state is LocationPermissionDenied || state is LocationPermissionPermanentlyDenied;
  }

  bool _isPermissionPermanentlyDenied(LocationState state) {
    return state is LocationPermissionPermanentlyDenied;
  }

  bool _isLoading(LocationState state) {
    return state is StartLocationUpdatesLoading ||
        state is UpdateLocationLoading ||
        state is ToggleManualPowerSavingLoading ||
        state is SetSimulationModeLoading ||
        state is StopSimulationLoading;
  }

  UpdateLocationSuccess? _getLocationUpdated(LocationState state) {
    if (state is UpdateLocationSuccess) return state;
    if (state is UpdateLocationLoading && state.previousState != null) {
      return state.previousState;
    }
    if (state is UpdateLocationError && state.previousState != null) {
      return state.previousState;
    }
    if (state is ToggleManualPowerSavingLoading) {
      return null;
    }
    if (state is SetSimulationModeLoading) {
      return null;
    }
    if (state is StopSimulationLoading) {
      return null;
    }
    if (state is ToggleManualPowerSavingError && state.previousState != null) {
      return state.previousState;
    }
    if (state is SetSimulationModeError && state.previousState != null) {
      return state.previousState;
    }
    if (state is StopSimulationError && state.previousState != null) {
      return state.previousState;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/Kabaa.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text('Mecca Proximity'),
          ],
        ),
        elevation: 0,
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          if (_isPermissionDenied(state)) {
            return _buildPermissionDeniedView(context, state);
          }

          final locationState = _getLocationUpdated(state);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (locationState?.isSimulationActive ?? false)
                    _buildSimulationBanner(),
                  _buildInfoBar(state),
                  const SizedBox(height: 16),
                  _buildModeSelector(context, state),
                  const SizedBox(height: 16),
                  _buildPowerSavingSwitch(context, state),
                  const SizedBox(height: 16),
                  _buildMessageList(state),
                  const SizedBox(height: 16),
                  _buildMiniLog(state),
                  if (_showDebugPanel) ...[
                    const SizedBox(height: 16),
                    _buildDebugPanel(context),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionDeniedView(BuildContext context, LocationState state) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: child,
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off, size: 64, color: Colors.red),
              ),
              const SizedBox(height: 24),
              Text(
                _isPermissionPermanentlyDenied(state)
                    ? 'Location permission permanently denied'
                    : 'Location permission denied',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please enable location permission in settings to use this app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      AppSettings.openAppSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Settings'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading(state)
                        ? null
                        : () {
                            context.read<LocationCubit>().retryPermissionCheck();
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading(state)) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.3),
              Colors.orange.withOpacity(0.1),
            ],
          ),
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            RotationTransition(
              turns: _pulseController,
              child: const Icon(Icons.science, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 8),
            const Text(
              'Simulation Mode Active',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                context.read<LocationCubit>().stopSimulation();
              },
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar(LocationState state) {
    final locationState = _getLocationUpdated(state);
    final distance = locationState != null
        ? '${locationState.distance.toStringAsFixed(0)} m'
        : '--';
    final bearing = locationState != null
        ? '${locationState.bearing.toStringAsFixed(0)}°'
        : '--';
    final mode = _getPowerModeText(locationState?.powerMode ?? PowerMode.lowPower);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Distance', distance, locationState != null, null),
          _buildInfoItem('Bearing', bearing, locationState != null, locationState?.bearing),
          _buildInfoItem('Mode', mode, true, null),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool hasValue, double? bearingValue) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Column(
        key: ValueKey(value),
        children: [
          if (label == 'Bearing' && hasValue && bearingValue != null)
            AnimatedRotation(
              turns: bearingValue / 360,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: Icon(
                Icons.navigation,
                color: Colors.blue.shade700,
                size: 28,
              ),
            )
          else
            ScaleTransition(
              scale: hasValue ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: hasValue ? Colors.blue.shade700 : Colors.grey,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getPowerModeText(PowerMode mode) {
    return switch (mode) {
      PowerMode.lowPower => 'Low',
      PowerMode.medium => 'Medium',
      PowerMode.boost => 'Boost',
    };
  }

  Widget _buildModeSelector(BuildContext context, LocationState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Location Mode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildModeButton(
                  context,
                  state,
                  'Real Location',
                  LocationMode.real,
                  _getLocationUpdated(state)?.isSimulationActive == true ? null : LocationMode.real,
                  Icons.my_location,
                ),
                _buildModeButton(
                  context,
                  state,
                  'Sim: Inside Mataf',
                  LocationMode.insideMataf,
                  _getLocationUpdated(state)?.isSimulationActive == true &&
                          _getLocationUpdated(state)?.simulationMode == LocationMode.insideMataf
                      ? LocationMode.insideMataf
                      : null,
                  Icons.location_on,
                ),
                _buildModeButton(
                  context,
                  state,
                  'Sim: Inside Haram',
                  LocationMode.insideHaram,
                  _getLocationUpdated(state)?.isSimulationActive == true &&
                          _getLocationUpdated(state)?.simulationMode == LocationMode.insideHaram
                      ? LocationMode.insideHaram
                      : null,
                  Icons.mosque,
                ),
                _buildModeButton(
                  context,
                  state,
                  'Sim: Outside',
                  LocationMode.outsideHaram,
                  _getLocationUpdated(state)?.isSimulationActive == true &&
                          _getLocationUpdated(state)?.simulationMode == LocationMode.outsideHaram
                      ? LocationMode.outsideHaram
                      : null,
                  Icons.explore,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    LocationState state,
    String label,
    LocationMode mode,
    LocationMode? selectedMode,
    IconData icon,
  ) {
    final isSelected = selectedMode == mode;
    final locationState = _getLocationUpdated(state);
    final isRealModeSelected = mode == LocationMode.real && (locationState?.isSimulationActive != true);
    final isActive = isSelected || isRealModeSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedScale(
        scale: isActive ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
          child: ElevatedButton.icon(
            onPressed: () {
              final cubit = context.read<LocationCubit>();
              final locationState = _getLocationUpdated(state);
              if (mode == LocationMode.real) {
                if (locationState?.isSimulationActive == true) {
                  cubit.stopSimulation();
                } else {
                  cubit.startLocationUpdates();
                }
              } else {
                if (locationState?.isSimulationActive != true || locationState?.simulationMode != mode) {
                  cubit.setSimulationMode(mode);
                }
              }
            },
          icon: AnimatedRotation(
            turns: isActive ? 0.1 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, size: 18),
          ),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            foregroundColor: isActive
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.grey.shade700,
            elevation: isActive ? 4 : 1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPowerSavingSwitch(BuildContext context, LocationState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               child: AnimatedContainer(
                 duration: const Duration(milliseconds: 300),
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(16),
                   gradient: (_getLocationUpdated(state)?.manualPowerSaving ?? false)
                       ? LinearGradient(
                           colors: [
                             Colors.orange.withOpacity(0.1),
                             Colors.orange.withOpacity(0.05),
                           ],
                         )
                       : null,
                 ),
                 child: SwitchListTile(
                   title: Row(
                     children: [
                       Icon(
                         Icons.battery_saver,
                         color: (_getLocationUpdated(state)?.manualPowerSaving ?? false) ? Colors.orange : Colors.grey,
                         size: 20,
                       ),
                       const SizedBox(width: 8),
                       const Text(
                         'Manual Power Saving',
                         style: TextStyle(fontWeight: FontWeight.w600),
                       ),
                     ],
                   ),
                   subtitle: const Text('Force Low power mode'),
                   value: _getLocationUpdated(state)?.manualPowerSaving ?? false,
                   onChanged: (value) {
                     context.read<LocationCubit>().toggleManualPowerSaving(value);
                   },
                 ),
               ),
    );
  }

  Widget _buildMessageList(LocationState state) {
    final messages = <Widget>[];
    final locationState = _getLocationUpdated(state);

    if (locationState != null) {
      final classification = locationState.classification;
      final distance = locationState.distance;
      final bearing = locationState.bearing;

      String message;
      IconData icon;
      Color color;

      switch (classification) {
        case LocationClassification.insideMataf:
          message = '📍 You are inside Mataf (≈ ${distance.toStringAsFixed(0)} m)';
          icon = Icons.location_on;
          color = Colors.green;
          break;
        case LocationClassification.insideHaram:
          message = '🕋 You are inside Haram (≈ ${distance.toStringAsFixed(0)} m)';
          icon = Icons.mosque;
          color = Colors.blue;
          break;
        case LocationClassification.outsideRange:
          message = '↔ You are outside the range (≈ ${distance.toStringAsFixed(0)} m)';
          icon = Icons.explore;
          color = Colors.grey;
          break;
      }

      messages.add(
        _buildMessageBubble(message, icon, color, 0),
      );

      messages.add(
        _buildMessageBubble(
          'Bearing to Kaaba: ${bearing.toStringAsFixed(0)}°',
          Icons.navigation,
          Colors.orange,
          1,
        ),
      );
    } else if (_isLoading(state)) {
      messages.add(
        _buildMessageBubble(
          'Loading location...',
          Icons.hourglass_empty,
          Colors.grey,
          0,
        ),
      );
    }

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...messages,
      ],
    );
  }

  Widget _buildMessageBubble(String message, IconData icon, Color color, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLog(LocationState state) {
    final locationState = _getLocationUpdated(state);
    if (locationState == null || locationState.readings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Mini Log (Last 10 readings)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: locationState.readings.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final reading = locationState.readings[index];
              final distance = _calculateDistance(reading.lat, reading.lon);
              final timeFormat = DateFormat('HH:mm:ss');
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(10 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${reading.lat.toStringAsFixed(6)}, ${reading.lon.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Dist: ${distance.toStringAsFixed(0)}m | '
                    'Acc: ${reading.accuracy.toStringAsFixed(1)}m | '
                    '${timeFormat.format(reading.timestamp)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double _calculateDistance(double lat, double lon) {
    const kaabaLat = 21.422487;
    const kaabaLon = 39.826206;
    return _haversine(lat, lon, kaabaLat, kaabaLon);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * 3.141592653589793 / 180.0;

  Widget _buildDebugPanel(BuildContext context) {
    return Card(
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Simulation Buttons:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<LocationCubit>()
                        .setSimulationMode(LocationMode.insideMataf);
                  },
                  child: const Text('Sim A (Mataf)'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<LocationCubit>()
                        .setSimulationMode(LocationMode.insideHaram);
                  },
                  child: const Text('Sim B (Haram)'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<LocationCubit>()
                        .setSimulationMode(LocationMode.outsideHaram);
                  },
                  child: const Text('Sim C (Outside)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

