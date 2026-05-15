import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/observability/analytics_events.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../shared/models/incident.dart';
import '../../../views/results.dart';
import '../../../views/select_persona.dart';
import '../../../views/tell_about_persona/view.dart';
import '../../voice_capture/presentation/voice_recording_sheet.dart';
import '../../voice_capture/presentation/voice_processing_screen.dart';

class AddIncidentScreen extends StatefulWidget {
  final String profileId;
  final String profileName;
  final String? existingIncidentId; // for viewing/editing, null for new
  /// Persona type for AI plan generation. Defaults to child when not known.
  final PersonaType personaType;

  const AddIncidentScreen({
    super.key,
    required this.profileId,
    required this.profileName,
    this.existingIncidentId,
    this.personaType = PersonaType.child,
  });

  @override
  State<AddIncidentScreen> createState() => _AddIncidentScreenState();
}

class _AddIncidentScreenState extends State<AddIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _whatHappenedController = TextEditingController();
  final _triggerController = TextEditingController();
  final _alreadyTriedController = TextEditingController();
  final _desiredOutcomeController = TextEditingController();
  IncidentCategory _category = IncidentCategory.behavior;
  int _intensity = 3;
  bool _isLoading = false;
  bool _showAdvancedFields = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _whatHappenedController.dispose();
    _triggerController.dispose();
    _alreadyTriedController.dispose();
    _desiredOutcomeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final incident = Incident(
        id: '',
        profileId: widget.profileId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        intensity: _intensity,
        whatHappened: _whatHappenedController.text.trim().isEmpty
            ? null
            : _whatHappenedController.text.trim(),
        possibleTrigger: _triggerController.text.trim().isEmpty
            ? null
            : _triggerController.text.trim(),
        whatWasAlreadyTried: _alreadyTriedController.text.trim().isEmpty
            ? null
            : _alreadyTriedController.text.trim(),
        desiredOutcome: _desiredOutcomeController.text.trim().isEmpty
            ? null
            : _desiredOutcomeController.text.trim(),
        createdAt: DateTime.now(),
      );
      final incidentId =
          await FirestoreService.createIncident(widget.profileId, incident);
      CrucueAnalytics.logIncidentLogged(
        category: incident.category.name,
        intensity: incident.intensity,
      );
      showMessage('Logged. Generating your support plan…',
          type: MessageType.success);
      if (mounted) {
        Navigator.pop(context, incidentId);
        navigateTo(
          ResultsView(
            title: incident.title,
            challengesList: [incident.title, ...?incident.whatHappened?.split(' ').take(3).toList()].take(3).toList(),
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
        title: Text(
          'Log a moment',
          style: TextStyle(
              fontSize: 17.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            Text(
              'What happened with ${widget.profileName}?',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: AppTheme.fontFamily2,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'A brief note helps Crucue create a more relevant support plan.',
              style: TextStyle(
                  fontSize: 13.sp, color: Theme.of(context).hintColor),
            ),
            SizedBox(height: 20.h),

            // ─── Title ────────────────────────────────────────────
            _FieldLabel('What\'s the moment in one line?'),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 15.sp),
              decoration: InputDecoration(
                hintText: 'e.g. Morning meltdown before school',
                hintStyle: TextStyle(
                    color: Theme.of(context).hintColor, fontSize: 14.sp),
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
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please add a title'
                  : null,
            ),

            SizedBox(height: 16.h),

            // ─── What happened (short description) ───────────────
            _FieldLabel('Brief description (optional)'),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              style: TextStyle(fontSize: 14.sp),
              decoration: _textAreaDecoration(
                'A few words about what you observed…',
              ),
            ),

            SizedBox(height: 20.h),

            // ─── Category chips ───────────────────────────────────
            _FieldLabel('Category'),
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20.h),

            // ─── Intensity slider ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FieldLabel('How intense was it?'),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _intensityColor(_intensity).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _intensityLabel(_intensity),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _intensityColor(_intensity),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primary,
                thumbColor: AppTheme.primary,
                inactiveTrackColor: Theme.of(context).dividerColor,
                trackHeight: 4,
              ),
              child: Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setState(() => _intensity = v.round()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mild',
                    style: TextStyle(
                        fontSize: 11.sp, color: Theme.of(context).hintColor)),
                Text('Very intense',
                    style: TextStyle(
                        fontSize: 11.sp, color: Theme.of(context).hintColor)),
              ],
            ),

            SizedBox(height: 24.h),

            // ─── Advanced context toggle ──────────────────────────
            GestureDetector(
              onTap: () =>
                  setState(() => _showAdvancedFields = !_showAdvancedFields),
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showAdvancedFields
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppTheme.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showAdvancedFields
                                ? 'Hide extra context'
                                : 'Add more context',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            'Triggers, what you tried, desired outcome',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16.sp,
                      color: AppTheme.primary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),

            if (_showAdvancedFields) ...[
              SizedBox(height: 16.h),

              // What happened in detail
              _FieldLabel('What happened in more detail? (optional)'),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _whatHappenedController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                style: TextStyle(fontSize: 14.sp),
                decoration: _textAreaDecoration(
                  'Walk through the sequence of events, what you observed, how it unfolded…',
                ),
              ),
              SizedBox(height: 14.h),

              // Possible trigger
              _FieldLabel('What might have triggered it? (optional)'),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _triggerController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                style: TextStyle(fontSize: 14.sp),
                decoration: _textAreaDecoration(
                  'e.g. Skipped nap, transition between activities, hunger',
                ),
              ),
              SizedBox(height: 14.h),

              // What was already tried
              _FieldLabel('What did you already try? (optional)'),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _alreadyTriedController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                style: TextStyle(fontSize: 14.sp),
                decoration: _textAreaDecoration(
                  'e.g. Distraction, verbal prompts, leaving the room',
                ),
              ),
              SizedBox(height: 14.h),

              // Desired outcome
              _FieldLabel('What would a good outcome look like? (optional)'),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _desiredOutcomeController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                style: TextStyle(fontSize: 14.sp),
                decoration: _textAreaDecoration(
                  'e.g. Calm enough to go to school, reconnect before bed',
                ),
              ),
            ],

            SizedBox(height: 20.h),

            // ─── Attachment options ────────────────────────────────
            Row(
              children: [
                if (FeatureFlags.voiceCaptureEnabled)
                  _AttachmentChip(
                    icon: Icons.mic_rounded,
                    label: 'Voice note',
                    highlighted: true,
                    onTap: () async {
                      CrucueAnalytics.logVoiceRecordingStarted();
                      final voiceNoteId = await showVoiceRecordingSheet(
                        context: context,
                        profileId: widget.profileId,
                        profileName: widget.profileName,
                      );
                      if (voiceNoteId != null && context.mounted) {
                        CrucueAnalytics.logVoiceProcessingCompleted(success: true);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoiceProcessingScreen(
                              profileId: widget.profileId,
                              profileName: widget.profileName,
                              voiceNoteId: voiceNoteId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                SizedBox(width: 10.w),
                _AttachmentChip(
                  icon: Icons.image_outlined,
                  label: 'Photo',
                  onTap: () => showMessage(
                    'Photo attachments coming soon.',
                    type: MessageType.warning,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            FilledButton.icon(
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              onPressed: _isLoading ? null : _save,
              label: Text(
                  _isLoading ? 'Saving…' : 'Save & Get Support Plan'),
            ),
            SizedBox(height: 8.h),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  InputDecoration _textAreaDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 13.sp),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      alignLabelWithHint: true,
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
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  Color _intensityColor(int intensity) {
    if (intensity <= 2) return CrucueTokens.success;
    if (intensity <= 3) return CrucueTokens.warning;
    return AppTheme.warmCoral;
  }

  String _intensityLabel(int intensity) {
    switch (intensity) {
      case 1:
        return 'Very mild';
      case 2:
        return 'Mild';
      case 3:
        return 'Moderate';
      case 4:
        return 'Intense';
      default:
        return 'Very intense';
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

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

class _AttachmentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _AttachmentChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: highlighted
              ? CrucueTokens.brandPrimary.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: highlighted
                ? CrucueTokens.brandPrimary.withValues(alpha: 0.4)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: highlighted
                  ? CrucueTokens.brandPrimary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                color: highlighted
                    ? CrucueTokens.brandPrimary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
