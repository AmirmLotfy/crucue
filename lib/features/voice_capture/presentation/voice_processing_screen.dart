import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/ai/ai_engine_registry.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../features/profiles/data/profiles_repository.dart';
import '../../../shared/models/care_profile.dart';
import '../../../shared/models/voice_note.dart';
import '../../../views/select_persona.dart';
import 'transcript_review_screen.dart';

PersonaType _relationshipToPersona(CareRelationship r) {
  switch (r) {
    case CareRelationship.child:
      return PersonaType.child;
    case CareRelationship.parent:
      return PersonaType.parent;
    case CareRelationship.partner:
      return PersonaType.partner;
    case CareRelationship.sibling:
      return PersonaType.sibling;
    case CareRelationship.familyMember:
      return PersonaType.friend;
  }
}

/// Shows the voice pipeline status as the backend processes the recording.
///
/// Polls the VoiceNote Firestore document and transitions to
/// [TranscriptReviewScreen] once processing is complete.
class VoiceProcessingScreen extends ConsumerStatefulWidget {
  final String profileId;
  final String profileName;
  final String voiceNoteId;

  const VoiceProcessingScreen({
    super.key,
    required this.profileId,
    required this.profileName,
    required this.voiceNoteId,
  });

  @override
  ConsumerState<VoiceProcessingScreen> createState() =>
      _VoiceProcessingScreenState();
}

class _VoiceProcessingScreenState extends ConsumerState<VoiceProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  bool _triggerCalled = false;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _triggerProcessing();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  /// Calls the processVoiceIncident Cloud Function once, then lets Firestore
  /// polling drive the state updates.
  Future<void> _triggerProcessing() async {
    if (_triggerCalled) return;
    _triggerCalled = true;

    // Small delay to allow the Firestore VoiceNote to be fully written
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final voiceNote = await FirestoreService.getVoiceNote(
        widget.profileId,
        widget.voiceNoteId,
      );
      if (voiceNote?.storagePath == null) {
        _setError('Audio upload incomplete. Please try again.');
        return;
      }

      await ref.read(aiEngineProvider).processVoiceIncident(
        voiceNoteId: widget.voiceNoteId,
        profileId: widget.profileId,
        audioStoragePath: voiceNote!.storagePath!,
      );
    } catch (e) {
      _setError('Processing failed. Please try again.');
    }
  }

  Future<void> _setError(String msg) async {
    await FirestoreService.updateVoiceNote(widget.profileId, widget.voiceNoteId, {
      'status': 'failed',
      'errorMessage': msg,
    });
  }

  @override
  Widget build(BuildContext context) {
    final voiceNoteStream = FirestoreService.watchVoiceNote(
      widget.profileId,
      widget.voiceNoteId,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Processing your recording',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<VoiceNote?>(
        stream: voiceNoteStream,
        builder: (context, snapshot) {
          final voiceNote = snapshot.data;
          final status = voiceNote?.status ?? VoiceNoteStatus.uploading;

          // Transition to review when done
          if (status == VoiceNoteStatus.completed && voiceNote != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Resolve persona type from cached profiles list
                final profiles = ref.read(profilesStreamProvider).valueOrNull;
                final profile = profiles?.firstWhere(
                  (p) => p.id == widget.profileId,
                  orElse: () => CareProfile(
                    id: widget.profileId,
                    name: widget.profileName,
                    relationship: CareRelationship.child,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                final personaType = _relationshipToPersona(
                  profile?.relationship ?? CareRelationship.child,
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TranscriptReviewScreen(
                      profileId: widget.profileId,
                      profileName: widget.profileName,
                      voiceNote: voiceNote,
                      personaType: personaType,
                    ),
                  ),
                );
              }
            });
          }

          if (status == VoiceNoteStatus.failed) {
            return _ErrorState(
              message: voiceNote?.errorMessage ??
                  'Processing failed. Please try recording again.',
              onRetry: () => Navigator.pop(context),
            );
          }

          return _ProcessingStages(status: status, dotController: _dotController);
        },
      ),
    );
  }
}

class _ProcessingStages extends StatelessWidget {
  final VoiceNoteStatus status;
  final AnimationController dotController;

  const _ProcessingStages({
    required this.status,
    required this.dotController,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      (VoiceNoteStatus.uploading, 'Uploading your recording', Icons.upload_rounded),
      (VoiceNoteStatus.uploaded, 'Preparing to transcribe', Icons.queue_rounded),
      (VoiceNoteStatus.transcribing, 'Listening to what you said', Icons.hearing_rounded),
      (VoiceNoteStatus.extracting, 'Understanding the situation', Icons.psychology_rounded),
    ];

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Central indicator
          AnimatedBuilder(
            animation: dotController,
            builder: (_, child) => Transform.rotate(
              angle: dotController.value * 2 * 3.14159,
              child: child,
            ),
            child: Container(
              width: 72.h,
              height: 72.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: CrucueTokens.brandPrimary,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: Icon(
                Icons.mic_rounded,
                size: 32.sp,
                color: CrucueTokens.brandPrimary,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Crucue is preparing your support plan.\nThis usually takes 10–20 seconds.',
            style: TextStyle(
              fontSize: 13.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48.h),

          // Stage list
          ...stages.map((stage) {
            final stageStatus = stage.$1;
            final label = stage.$2;
            final icon = stage.$3;
            final isDone = _isDoneOrPast(status, stageStatus);
            final isActive = status == stageStatus;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    width: 32.h,
                    height: 32.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? CrucueTokens.brandPrimary
                          : isActive
                              ? CrucueTokens.brandPrimary.withValues(alpha: 0.12)
                              : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : icon,
                      size: 16.sp,
                      color: isDone
                          ? Colors.white
                          : isActive
                              ? CrucueTokens.brandPrimary
                              : Theme.of(context).hintColor,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isDone || isActive
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 32.h),
          Text(
            'Your recording is processed privately and securely.\nNo data is shared with third parties.',
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context).hintColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _isDoneOrPast(VoiceNoteStatus current, VoiceNoteStatus target) {
    final order = [
      VoiceNoteStatus.uploading,
      VoiceNoteStatus.uploaded,
      VoiceNoteStatus.transcribing,
      VoiceNoteStatus.extracting,
      VoiceNoteStatus.completed,
    ];
    final currentIndex = order.indexOf(current);
    final targetIndex = order.indexOf(target);
    return currentIndex > targetIndex;
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 52.sp,
            color: CrucueTokens.warning,
          ),
          SizedBox(height: 16.h),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.h),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
