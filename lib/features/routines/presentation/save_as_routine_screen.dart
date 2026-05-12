import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/logic/helper_methods.dart';
import '../../../core/theme.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/support_plan.dart';
import '../data/routines_repository.dart';

class SaveAsRoutineScreen extends StatefulWidget {
  final String profileId;
  final SupportPlan? plan; // pre-fill from plan if available
  final List<String>? suggestedSteps;
  final String? aiPrefilledTitle;
  final String? aiPrefilledDescription;
  final RoutineFrequency? aiPrefilledFrequency;
  final List<String>? aiPrefilledTags;

  const SaveAsRoutineScreen({
    super.key,
    required this.profileId,
    this.plan,
    this.suggestedSteps,
    this.aiPrefilledTitle,
    this.aiPrefilledDescription,
    this.aiPrefilledFrequency,
    this.aiPrefilledTags,
  });

  @override
  State<SaveAsRoutineScreen> createState() => _SaveAsRoutineScreenState();
}

class _SaveAsRoutineScreenState extends State<SaveAsRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  RoutineFrequency _frequency = RoutineFrequency.daily;
  String? _timeOfDay;
  late List<TextEditingController> _stepControllers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.aiPrefilledTitle != null &&
        widget.aiPrefilledTitle!.trim().isNotEmpty) {
      _titleController.text = widget.aiPrefilledTitle!.trim();
    }
    if (widget.aiPrefilledDescription != null &&
        widget.aiPrefilledDescription!.trim().isNotEmpty) {
      _descriptionController.text = widget.aiPrefilledDescription!.trim();
    }
    if (widget.aiPrefilledFrequency != null) {
      _frequency = widget.aiPrefilledFrequency!;
    }
    // Pre-fill steps from plan or suggestions
    final steps = widget.suggestedSteps ??
        (widget.plan != null
            ? [...widget.plan!.whatToDoNow, ...widget.plan!.followUpTasks]
                .where((s) => s.isNotEmpty)
                .take(6)
                .toList()
            : ['']);
    _stepControllers =
        steps.map((s) => TextEditingController(text: s)).toList();
    if (_stepControllers.isEmpty) {
      _stepControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() => _stepControllers.add(TextEditingController()));
  }

  void _removeStep(int index) {
    if (_stepControllers.length <= 1) return;
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final routine = Routine(
        id: '',
        profileId: widget.profileId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        frequency: _frequency,
        timeOfDay: _timeOfDay,
        steps: steps,
        basedOnPlanId: widget.plan?.id.isEmpty == true
            ? null
            : widget.plan?.id,
        tags: widget.aiPrefilledTags ?? const [],
        createdAt: DateTime.now(),
      );

      final repo = RoutinesRepository();
      await repo.createRoutine(widget.profileId, routine);
      showMessage('Routine saved!', type: MessageType.success);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showMessage('Could not save routine. Please try again.');
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
        title: const Text('Save as Routine'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            Text(
              'Create a reusable routine',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: AppTheme.fontFamily2,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Give this routine a name and refine the steps. You can start it anytime from the profile hub.',
              style: TextStyle(
                  fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5),
            ),
            SizedBox(height: 20.h),

            // ─── Title ────────────────────────────────────────────
            _Label('Routine name'),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 15.sp),
              decoration: _inputDecoration('e.g. Bedtime calm-down routine'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please add a name'
                  : null,
            ),

            SizedBox(height: 14.h),
            _Label('Description (optional)'),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              style: TextStyle(fontSize: 14.sp),
              decoration: _inputDecoration('What is this routine for?'),
            ),

            SizedBox(height: 20.h),

            // ─── Frequency ────────────────────────────────────────
            _Label('How often?'),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: RoutineFrequency.values.map((f) {
                final selected = f == _frequency;
                return GestureDetector(
                  onTap: () => setState(() => _frequency = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color:
                            selected ? AppTheme.primary : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20.h),

            // ─── Steps ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Label('Steps'),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add step'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 4.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _stepControllers.removeAt(oldIndex);
                  _stepControllers.insert(newIndex, item);
                });
              },
              itemCount: _stepControllers.length,
              itemBuilder: (context, i) => _StepRow(
                key: ValueKey(i),
                index: i,
                controller: _stepControllers[i],
                onRemove: () => _removeStep(i),
                canRemove: _stepControllers.length > 1,
              ),
            ),

            SizedBox(height: 32.h),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Routine'),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 13.sp),
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
        borderSide:
            BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
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

class _StepRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final VoidCallback onRemove;
  final bool canRemove;

  const _StepRow({
    super.key,
    required this.index,
    required this.controller,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(Icons.drag_handle_rounded,
              size: 20.sp, color: Theme.of(context).hintColor),
          SizedBox(width: 8.w),
          Container(
            width: 24.h,
            height: 24.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextFormField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Step ${index + 1}…',
                hintStyle:
                    TextStyle(color: Theme.of(context).hintColor, fontSize: 13.sp),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                      color: AppTheme.primary, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 10.h),
              ),
            ),
          ),
          if (canRemove) ...[
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.remove_circle_outline_rounded,
                  size: 20.sp, color: Theme.of(context).hintColor),
            ),
          ],
        ],
      ),
    );
  }
}
