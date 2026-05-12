import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme.dart';
import '../providers/voice_capture_providers.dart';

/// Shows the voice recording bottom sheet and returns the voiceNoteId
/// once the user stops and uploads their recording.
///
/// Returns null if the user cancels.
Future<String?> showVoiceRecordingSheet({
  required BuildContext context,
  required String profileId,
  required String profileName,
}) async {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VoiceRecordingSheet(
      profileId: profileId,
      profileName: profileName,
    ),
  );
}

class VoiceRecordingSheet extends ConsumerStatefulWidget {
  final String profileId;
  final String profileName;

  const VoiceRecordingSheet({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  @override
  ConsumerState<VoiceRecordingSheet> createState() =>
      _VoiceRecordingSheetState();
}

class _VoiceRecordingSheetState extends ConsumerState<VoiceRecordingSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _checkAndStartIfPermitted();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAndStartIfPermitted() async {
    final notifier = ref.read(voiceRecordingProvider.notifier);
    final hasPermission = await notifier.checkPermission();
    if (hasPermission) {
      await notifier.startRecording();
    } else {
      final granted = await notifier.requestPermission();
      if (granted) {
        await notifier.startRecording();
      } else {
        setState(() => _permissionDenied = true);
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceRecordingProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          if (_permissionDenied) ...[
            _PermissionDeniedState(
              onOpenSettings: () {
                openAppSettings();
                Navigator.pop(context);
              },
              onCancel: () => Navigator.pop(context),
            ),
          ] else if (state.isUploading) ...[
            _UploadingState(),
          ] else if (state.hasStopped && state.hasRecording) ...[
            _ReviewState(
              elapsed: state.elapsed,
              onUpload: () async {
                final id = await ref
                    .read(voiceRecordingProvider.notifier)
                    .uploadAndCreateVoiceNote(profileId: widget.profileId);
                if (context.mounted) Navigator.pop(context, id);
              },
              onRetry: () =>
                  ref.read(voiceRecordingProvider.notifier).cancelRecording(),
              onCancel: () {
                ref.read(voiceRecordingProvider.notifier).cancelRecording();
                Navigator.pop(context);
              },
            ),
          ] else ...[
            _RecordingState(
              state: state,
              pulseController: _pulseController,
              profileName: widget.profileName,
              isDark: isDark,
              onStop: () =>
                  ref.read(voiceRecordingProvider.notifier).stopRecording(),
              onPause: () =>
                  ref.read(voiceRecordingProvider.notifier).pauseRecording(),
              onResume: () =>
                  ref.read(voiceRecordingProvider.notifier).resumeRecording(),
              onCancel: () {
                ref.read(voiceRecordingProvider.notifier).cancelRecording();
                Navigator.pop(context);
              },
              formatDuration: _formatDuration,
            ),
          ],

          if (state.errorMessage != null) ...[
            SizedBox(height: 12.h),
            Text(
              state.errorMessage!,
              style: TextStyle(
                fontSize: 12.sp,
                color: CrucueTokens.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _RecordingState extends StatelessWidget {
  final VoiceRecordingState state;
  final AnimationController pulseController;
  final String profileName;
  final bool isDark;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final String Function(Duration) formatDuration;

  const _RecordingState({
    required this.state,
    required this.pulseController,
    required this.profileName,
    required this.isDark,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = state.isRecording;

    return Column(
      children: [
        Text(
          'What happened with $profileName?',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        Text(
          'Speak naturally — describe the situation in your own words.',
          style: TextStyle(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32.h),

        // Animated recording indicator
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, child) {
            final scale = isRecording
                ? 1.0 + 0.12 * pulseController.value
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 80.h,
            height: 80.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecording
                  ? CrucueTokens.brandPrimary
                  : Theme.of(context).dividerColor,
              boxShadow: isRecording
                  ? [
                      BoxShadow(
                        color: CrucueTokens.brandPrimary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isRecording ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: Colors.white,
              size: 36.sp,
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Timer
        Text(
          formatDuration(state.elapsed),
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w300,
            fontFamily: 'Roboto',
            color: isRecording
                ? CrucueTokens.brandPrimary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),

        // Simple waveform bars
        if (isRecording) ...[
          SizedBox(height: 8.h),
          _SimpleWaveform(),
        ],

        SizedBox(height: 8.h),

        Text(
          'Max 3 minutes',
          style: TextStyle(
            fontSize: 11.sp,
            color: Theme.of(context).hintColor,
          ),
        ),

        SizedBox(height: 28.h),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cancel
            _CircleButton(
              icon: Icons.close_rounded,
              label: 'Cancel',
              onTap: onCancel,
              outlined: true,
            ),
            SizedBox(width: 20.w),

            // Pause / Resume
            _CircleButton(
              icon: isRecording
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              label: isRecording ? 'Pause' : 'Resume',
              onTap: isRecording ? onPause : onResume,
              size: 52,
              outlined: true,
            ),
            SizedBox(width: 20.w),

            // Stop
            _CircleButton(
              icon: Icons.stop_rounded,
              label: 'Done',
              onTap: state.elapsed.inSeconds >= 2 ? onStop : null,
              filled: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewState extends StatelessWidget {
  final Duration elapsed;
  final VoidCallback onUpload;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _ReviewState({
    required this.elapsed,
    required this.onUpload,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final m = elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 56.sp,
          color: CrucueTokens.success,
        ),
        SizedBox(height: 12.h),
        Text(
          'Recording complete',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          '$m:$s recorded',
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Upload your recording to get a support plan.',
          style: TextStyle(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 28.h),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.upload_rounded, size: 18),
            onPressed: onUpload,
            label: const Text('Upload & Process'),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                onPressed: onRetry,
                label: const Text('Record again'),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UploadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        SizedBox(height: 16.h),
        Text(
          'Uploading your recording…',
          style: TextStyle(
            fontSize: 15.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'This just takes a moment.',
          style: TextStyle(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}

class _PermissionDeniedState extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onCancel;

  const _PermissionDeniedState({
    required this.onOpenSettings,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.mic_off_rounded,
          size: 52.sp,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        SizedBox(height: 16.h),
        Text(
          'Microphone access needed',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Crucue needs microphone access to record voice notes. '
          'Your recordings stay private and are only used to help generate your care plan.',
          style: TextStyle(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onOpenSettings,
            child: const Text('Open Settings'),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool outlined;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.filled = false,
    this.outlined = false,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size.h,
            height: size.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? CrucueTokens.brandPrimary
                  : outlined
                      ? Colors.transparent
                      : Colors.transparent,
              border: outlined
                  ? Border.all(
                      color: onTap != null
                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                          : Theme.of(context).dividerColor,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              color: filled
                  ? Colors.white
                  : onTap != null
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                      : Theme.of(context).dividerColor,
              size: (size * 0.46).sp,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Simple animated waveform using random-height bars.
class _SimpleWaveform extends StatefulWidget {
  @override
  State<_SimpleWaveform> createState() => _SimpleWaveformState();
}

class _SimpleWaveformState extends State<_SimpleWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();
  final List<double> _heights = List.generate(20, (_) => 0.3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        if (mounted) {
          setState(() {
            for (var i = 0; i < _heights.length; i++) {
              _heights[i] = 0.15 + _random.nextDouble() * 0.75;
            }
          });
        }
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_heights.length, (i) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 3.w,
              height: 36.h * _heights[i],
              decoration: BoxDecoration(
                color: CrucueTokens.brandPrimary.withValues(
                    alpha: 0.4 + 0.6 * _heights[i]),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          );
        }),
      ),
    );
  }
}
