import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/providers.dart';
import '../../../core/ai/ai_engine_registry.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/audio/audio_recorder_service.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/observability/analytics_events.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme.dart';
import '../../../features/routines/presentation/save_as_routine_screen.dart';
import '../../../shared/models/checkin.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/support_plan.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  final String profileId;
  final SupportPlan plan;

  const CheckInScreen({
    super.key,
    required this.profileId,
    required this.plan,
  });

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final RecordAudioService _reflectionRecorder = RecordAudioService();
  bool _isRecordingReflection = false;
  bool _isTranscribingReflection = false;
  bool? _didHelp;
  int _outcomeRating = 3;
  final List<bool> _stepsCompleted = [];
  final List<bool> _stepsHelpedMost = [];
  final _notesController = TextEditingController();
  final _whatMadeWorseController = TextEditingController();
  bool _shouldBecomeRoutine = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stepsCompleted
        .addAll(List.filled(widget.plan.whatToDoNow.length, false));
    _stepsHelpedMost
        .addAll(List.filled(widget.plan.whatToDoNow.length, false));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _whatMadeWorseController.dispose();
    _reflectionRecorder.dispose();
    super.dispose();
  }

  Future<void> _startVoiceReflection() async {
    final hasPermission = await _reflectionRecorder.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _reflectionRecorder.requestMicrophonePermission();
      if (!granted) return;
    }
    setState(() => _isRecordingReflection = true);
    await _reflectionRecorder.startRecording();
  }

  Future<void> _stopVoiceReflection() async {
    final path = await _reflectionRecorder.stopRecording();
    setState(() {
      _isRecordingReflection = false;
      _isTranscribingReflection = true;
    });

    if (path == null) {
      setState(() => _isTranscribingReflection = false);
      return;
    }

    try {
      final file = File(path);
      final uploaded = await StorageService.uploadVoiceNoteForProfile(
        file: file,
        profileId: widget.profileId,
        voiceNoteId: 'reflection_${DateTime.now().millisecondsSinceEpoch}',
      );

      final transcript = await ref
          .read(aiEngineProvider)
          .transcribeShortClip(audioStoragePath: uploaded.path);

      if (transcript.isNotEmpty && _notesController.text.isEmpty) {
        _notesController.text = transcript;
      } else if (transcript.isNotEmpty) {
        _notesController.text = '${_notesController.text} $transcript';
      }

      try {
        file.deleteSync();
      } catch (_) {}
    } catch (_) {
      showMessage('Could not transcribe. Please type your reflection.');
    }
    if (mounted) setState(() => _isTranscribingReflection = false);
  }

  Future<void> _save() async {
    if (_didHelp == null) {
      showMessage('Let us know if this helped.',
          type: MessageType.warning);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final completedSteps = <String>[];
      final helpedMostSteps = <String>[];
      for (var i = 0; i < widget.plan.whatToDoNow.length; i++) {
        if (_stepsCompleted[i]) completedSteps.add(widget.plan.whatToDoNow[i]);
        if (_stepsHelpedMost[i]) helpedMostSteps.add(widget.plan.whatToDoNow[i]);
      }

      final checkIn = CheckIn(
        id: '',
        profileId: widget.profileId,
        planId: widget.plan.id,
        didThisHelp: _didHelp!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        stepsCompleted: completedSteps,
        stepsHelpedMost: helpedMostSteps,
        whatMadeItWorse: _whatMadeWorseController.text.trim().isEmpty
            ? null
            : _whatMadeWorseController.text.trim(),
        shouldBecomeRoutine: _shouldBecomeRoutine,
        outcomeRating: _outcomeRating,
        createdAt: DateTime.now(),
      );

      await FirestoreService.createCheckIn(widget.profileId, checkIn);
      CrucueAnalytics.logReflectionSaved(
        didHelp: checkIn.didThisHelp,
        outcomeRating: checkIn.outcomeRating,
        becameRoutine: checkIn.shouldBecomeRoutine,
      );
      showMessage('Reflection saved. Well done.', type: MessageType.success);

      if (mounted && checkIn.shouldBecomeRoutine) {
        Map<String, dynamic>? aiSuggestion;
        if (FeatureFlags.aiRoutineSuggestionEnabled) {
          try {
            aiSuggestion =
                await ref.read(aiEngineProvider).suggestRoutineFromReflection(
                      profileId: widget.profileId,
                      planId: widget.plan.id,
                      reflectionNotes: checkIn.notes,
                      stepsHelpedMost: checkIn.stepsHelpedMost.isNotEmpty
                          ? checkIn.stepsHelpedMost
                          : checkIn.stepsCompleted,
                      personaTypeKey:
                          ref.read(activeProfileProvider)?.relationship.name,
                    );
          } catch (_) {}
        }

        final fallbackSteps = checkIn.stepsHelpedMost.isNotEmpty
            ? checkIn.stepsHelpedMost
            : checkIn.stepsCompleted;

        List<String>? stepList;
        final rawSteps = aiSuggestion?['steps'];
        if (rawSteps is List &&
            rawSteps.map((e) => e.toString().trim()).any((s) => s.isNotEmpty)) {
          stepList = rawSteps
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (fallbackSteps.isNotEmpty) {
          stepList = fallbackSteps;
        }

        List<String>? tagsFromAi;
        final rawTags = aiSuggestion?['tags'];
        if (rawTags is List) {
          tagsFromAi = rawTags
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }

        RoutineFrequency? aiFreq;
        final freqRaw = aiSuggestion?['frequency']?.toString();
        if (freqRaw != null && freqRaw.isNotEmpty) {
          aiFreq = Routine.frequencyFromApi(freqRaw);
        }

        if (mounted) {
          Navigator.pop(context, checkIn);
          await navigateTo(SaveAsRoutineScreen(
            profileId: widget.profileId,
            plan: widget.plan,
            suggestedSteps: stepList,
            aiPrefilledTitle: aiSuggestion?['title'] as String?,
            aiPrefilledDescription: aiSuggestion?['rationale'] as String?,
            aiPrefilledFrequency: aiFreq,
            aiPrefilledTags: tagsFromAi,
          ));
        }
      } else if (mounted) {
        Navigator.pop(context, checkIn);
      }
    } catch (e) {
      showMessage('Could not save. Please try again.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reflect & Check In'),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          // ─── Header ───────────────────────────────────────────
          Text(
            'How did it go?',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: AppTheme.fontFamily2,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Your reflection helps Crucue learn what works best for you and your loved one.',
            style: TextStyle(
                fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5),
          ),

          SizedBox(height: 24.h),

          // ─── Did it help? ─────────────────────────────────────
          _SectionLabel('Did this support plan help?'),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _HelpButton(
                  label: 'Yes, it helped',
                  emoji: '✅',
                  selected: _didHelp == true,
                  onTap: () => setState(() => _didHelp = true),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _HelpButton(
                  label: 'Not this time',
                  emoji: '🔄',
                  selected: _didHelp == false,
                  onTap: () => setState(() => _didHelp = false),
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // ─── Outcome rating ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel('How did it resolve overall?'),
              Text(
                '${_outcomeRating}/5',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Text('Still hard',
                  style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primary,
                    thumbColor: AppTheme.primary,
                    inactiveTrackColor: Theme.of(context).dividerColor,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _outcomeRating.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) =>
                        setState(() => _outcomeRating = v.round()),
                  ),
                ),
              ),
              Text('Resolved well',
                  style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor)),
            ],
          ),

          SizedBox(height: 20.h),

          // ─── Steps tried ─────────────────────────────────────
          if (widget.plan.whatToDoNow.isNotEmpty) ...[
            _SectionLabel('Which steps did you try?'),
            SizedBox(height: 8.h),
            ...List.generate(widget.plan.whatToDoNow.length, (i) {
              return CheckboxListTile(
                value: _stepsCompleted[i],
                onChanged: (v) =>
                    setState(() => _stepsCompleted[i] = v ?? false),
                title: Text(
                  widget.plan.whatToDoNow[i],
                  style: TextStyle(
                      fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurface),
                ),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              );
            }),
            SizedBox(height: 20.h),

            // ─── Which helped most ─────────────────────────────
            _SectionLabel('Which of those helped most? (optional)'),
            SizedBox(height: 4.h),
            Text(
              'This helps Crucue learn what to suggest first next time.',
              style: TextStyle(fontSize: 12.sp, color: Theme.of(context).hintColor),
            ),
            SizedBox(height: 8.h),
            ...List.generate(widget.plan.whatToDoNow.length, (i) {
              if (!_stepsCompleted[i]) return const SizedBox.shrink();
              return CheckboxListTile(
                value: _stepsHelpedMost[i],
                onChanged: (v) =>
                    setState(() => _stepsHelpedMost[i] = v ?? false),
                title: Text(
                  widget.plan.whatToDoNow[i],
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: CrucueTokens.success,
                checkColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              );
            }),
            SizedBox(height: 20.h),
          ],

          // ─── What made it worse ───────────────────────────────
          _SectionLabel('What made things harder? (optional)'),
          SizedBox(height: 6.h),
          TextFormField(
            controller: _whatMadeWorseController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'e.g. Rushing them, loud environment, my own stress',
              hintStyle:
                  TextStyle(fontSize: 13.sp, color: Theme.of(context).hintColor),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                    color: AppTheme.primary, width: 1.5),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // ─── Voice reflection ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel('Any other notes? (optional)'),
              GestureDetector(
                onLongPressStart: (_) => _startVoiceReflection(),
                onLongPressEnd: (_) => _stopVoiceReflection(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _isRecordingReflection
                        ? CrucueTokens.brandPrimary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: _isRecordingReflection
                          ? CrucueTokens.brandPrimary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTranscribingReflection
                            ? Icons.hourglass_empty_rounded
                            : _isRecordingReflection
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                        size: 14.sp,
                        color: _isRecordingReflection
                            ? CrucueTokens.brandPrimary
                            : Theme.of(context).hintColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _isRecordingReflection
                            ? 'Recording…'
                            : _isTranscribingReflection
                                ? 'Transcribing…'
                                : 'Hold to speak',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _isRecordingReflection
                              ? CrucueTokens.brandPrimary
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText:
                  'What did you notice? What would you do differently?',
              hintStyle:
                  TextStyle(fontSize: 13.sp, color: Theme.of(context).hintColor),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                    color: AppTheme.primary, width: 1.5),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // ─── Reflection prompt ────────────────────────────────
          if (widget.plan.reflectionPrompt.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: CrucueTokens.planReflect,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.self_improvement_rounded,
                      color: AppTheme.primary, size: 18.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.plan.reflectionPrompt,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // ─── Save as routine toggle ───────────────────────────
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: _shouldBecomeRoutine
                  ? AppTheme.primary.withValues(alpha: 0.08)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _shouldBecomeRoutine
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save as a reusable routine',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Create a named routine from these steps for next time.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _shouldBecomeRoutine,
                  onChanged: (v) => setState(() => _shouldBecomeRoutine = v),
                  activeThumbColor: AppTheme.primary,
                ),
              ],
            ),
          ),

          SizedBox(height: 28.h),

          FilledButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Reflection'),
          ),
          SizedBox(height: 8.h),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _HelpButton({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppTheme.primary : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 26.sp)),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppTheme.primary
                    : Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
