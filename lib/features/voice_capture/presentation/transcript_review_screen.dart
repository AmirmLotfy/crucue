import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/logic/helper_methods.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../shared/models/incident.dart';
import '../../../shared/models/voice_note.dart';
import '../../../views/results.dart';
import '../../../views/select_persona.dart';
import '../../../views/tell_about_persona/view.dart';

/// Displays the transcript and extracted incident fields for user review.
///
/// The user can:
/// - Read / edit the transcript
/// - See what Gemma 4 extracted
/// - Edit the title, category, intensity
/// - Confirm → creates Incident in Firestore → navigates to ResultsView
class TranscriptReviewScreen extends StatefulWidget {
  final String profileId;
  final String profileName;
  final VoiceNote voiceNote;
  /// Persona type resolved from the care profile relationship.
  final PersonaType personaType;

  const TranscriptReviewScreen({
    super.key,
    required this.profileId,
    required this.profileName,
    required this.voiceNote,
    this.personaType = PersonaType.child,
  });

  @override
  State<TranscriptReviewScreen> createState() => _TranscriptReviewScreenState();
}

class _TranscriptReviewScreenState extends State<TranscriptReviewScreen> {
  late TextEditingController _titleController;
  late TextEditingController _transcriptController;
  late TextEditingController _triggerController;
  late TextEditingController _triedController;
  late TextEditingController _outcomeController;
  late IncidentCategory _category;
  late int _intensity;
  bool _isSaving = false;
  bool _showFullTranscript = false;

  Map<String, dynamic> get _extracted =>
      widget.voiceNote.extractedIncident ?? {};

  @override
  void initState() {
    super.initState();
    final extracted = _extracted;
    _titleController = TextEditingController(
      text: extracted['incident_title'] as String? ?? '',
    );
    _transcriptController = TextEditingController(
      text: widget.voiceNote.transcript ?? '',
    );
    _triggerController = TextEditingController(
      text: extracted['possible_trigger'] as String? ?? '',
    );
    _triedController = TextEditingController(
      text: extracted['what_user_already_tried'] as String? ?? '',
    );
    _outcomeController = TextEditingController(
      text: extracted['desired_outcome'] as String? ?? '',
    );
    _category = _parseCategory(extracted['incident_category'] as String?);
    _intensity = (extracted['intensity'] as num?)?.toInt() ?? 3;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    _triggerController.dispose();
    _triedController.dispose();
    _outcomeController.dispose();
    super.dispose();
  }

  IncidentCategory _parseCategory(String? value) {
    if (value == null) return IncidentCategory.other;
    return IncidentCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IncidentCategory.other,
    );
  }

  Future<void> _saveAndContinue() async {
    if (_titleController.text.trim().isEmpty) {
      showMessage('Please add a title.', type: MessageType.warning);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final incident = Incident(
        id: '',
        profileId: widget.profileId,
        title: _titleController.text.trim(),
        description: _extracted['cleaned_summary'] as String? ??
            _transcriptController.text.trim(),
        category: _category,
        intensity: _intensity,
        whatHappened: _transcriptController.text.trim().isNotEmpty
            ? _transcriptController.text.trim()
            : null,
        possibleTrigger: _triggerController.text.trim().isEmpty
            ? null
            : _triggerController.text.trim(),
        whatWasAlreadyTried: _triedController.text.trim().isEmpty
            ? null
            : _triedController.text.trim(),
        desiredOutcome: _outcomeController.text.trim().isEmpty
            ? null
            : _outcomeController.text.trim(),
        voiceNoteRef: widget.voiceNote.id,
        createdAt: DateTime.now(),
      );
      final incidentId =
          await FirestoreService.createIncident(widget.profileId, incident);

      // Link voice note to incident
      await FirestoreService.linkVoiceNoteToIncident(
        profileId: widget.profileId,
        voiceNoteId: widget.voiceNote.id,
        incidentId: incidentId,
      );

      if (mounted) {
        // Navigate to support plan generation with resolved persona type
        navigateTo(
          ResultsView(
            title: _titleController.text.trim(),
            challengesList: [_titleController.text.trim()],
            personaModelData: PersonaModelData(
              name: widget.profileName,
              type: widget.personaType,
            ),
            personaType: widget.personaType,
            profileId: widget.profileId,
            incidentId: incidentId,
          ),
        );
      }
    } catch (e) {
      showMessage('Could not save. Please try again.');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final confidence = (_extracted['confidence'] as num?)?.toDouble() ?? 0.0;
    final safetyFlag = _extracted['safety_flag'] as bool? ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Review your note'),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          // Safety banner
          if (safetyFlag) ...[
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: context.decor.warningSubtle,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: CrucueTokens.warning),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: CrucueTokens.warning, size: 18.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'This situation may benefit from professional support. Please reach out to a qualified care provider if needed.',
                      style: TextStyle(fontSize: 13.sp, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Confidence indicator
          Row(
            children: [
              Text(
                'What Crucue understood',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _confidenceColor(confidence).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '${(confidence * 100).round()}% confident',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _confidenceColor(confidence),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Review and adjust the details below — Crucue\'s understanding gets better with more context.',
            style: TextStyle(
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),

          // Title
          _Label('What happened (title)'),
          SizedBox(height: 6.h),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 15.sp),
            decoration: _inputDecoration(context, 'Short title for this moment'),
          ),

          SizedBox(height: 16.h),

          // Category
          _Label('Category'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: IncidentCategory.values.map((cat) {
              final selected = cat == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: selected ? CrucueTokens.brandPrimary : cs.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: selected
                          ? CrucueTokens.brandPrimary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? cs.onPrimary
                          : cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 16.h),

          // Intensity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Label('Intensity'),
              Text(
                '$_intensity / 5',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: CrucueTokens.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: CrucueTokens.brandPrimary,
            inactiveColor: Theme.of(context).dividerColor,
            onChanged: (v) => setState(() => _intensity = v.round()),
          ),

          SizedBox(height: 12.h),

          // Optional extracted fields
          if (_triggerController.text.isNotEmpty ||
              _triedController.text.isNotEmpty ||
              _outcomeController.text.isNotEmpty) ...[
            _Label('What Crucue picked up'),
            SizedBox(height: 8.h),
            if (_triggerController.text.isNotEmpty) ...[
              _ExtractedField(
                label: 'Possible trigger',
                controller: _triggerController,
                context: context,
              ),
              SizedBox(height: 8.h),
            ],
            if (_triedController.text.isNotEmpty) ...[
              _ExtractedField(
                label: 'Already tried',
                controller: _triedController,
                context: context,
              ),
              SizedBox(height: 8.h),
            ],
            if (_outcomeController.text.isNotEmpty) ...[
              _ExtractedField(
                label: 'Desired outcome',
                controller: _outcomeController,
                context: context,
              ),
            ],
            SizedBox(height: 16.h),
          ],

          // Transcript toggle
          GestureDetector(
            onTap: () =>
                setState(() => _showFullTranscript = !_showFullTranscript),
            child: Row(
              children: [
                Icon(
                  _showFullTranscript
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18.sp,
                  color: CrucueTokens.brandPrimary,
                ),
                SizedBox(width: 6.w),
                Text(
                  _showFullTranscript
                      ? 'Hide transcript'
                      : 'See full transcript',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: CrucueTokens.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_showFullTranscript) ...[
            SizedBox(height: 8.h),
            TextFormField(
              controller: _transcriptController,
              maxLines: null,
              style: TextStyle(fontSize: 13.sp, height: 1.5),
              decoration: _inputDecoration(context, 'Transcript'),
            ),
          ],

          SizedBox(height: 32.h),

          FilledButton.icon(
            icon: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            onPressed: _isSaving ? null : _saveAndContinue,
            label: Text(
                _isSaving ? 'Creating plan…' : 'Looks right — get support plan'),
          ),
          SizedBox(height: 8.h),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit manually instead'),
          ),
          SizedBox(height: 28.h),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: Theme.of(context).hintColor, fontSize: 13.sp),
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
        borderSide: const BorderSide(color: CrucueTokens.brandPrimary, width: 1.5),
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return CrucueTokens.success;
    if (confidence >= 0.6) return CrucueTokens.warning;
    return CrucueTokens.error;
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _ExtractedField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final BuildContext context;

  const _ExtractedField({
    required this.label,
    required this.controller,
    required this.context,
  });

  @override
  Widget build(BuildContext buildContext) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Edit if needed',
        hintStyle:
            TextStyle(color: Theme.of(buildContext).hintColor, fontSize: 12.sp),
        filled: true,
        fillColor: Theme.of(buildContext).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Theme.of(buildContext).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide:
              const BorderSide(color: CrucueTokens.brandPrimary, width: 1.5),
        ),
      ),
    );
  }
}
