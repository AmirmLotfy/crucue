import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/core/theme.dart';
import 'package:crucue/views/chat/view.dart';
import 'package:crucue/views/home/view.dart';
import 'package:crucue/views/select_persona.dart';

import '../core/audio/speech_output_service.dart';
import '../core/audio/tts_provider.dart';
import '../core/design/second_app_bar.dart';
import '../core/observability/analytics_events.dart';
import '../core/services/cloud_functions_service.dart';
import '../core/services/firestore_service.dart';
import '../features/plans/presentation/checkin_screen.dart';
import '../shared/models/support_plan.dart';
import 'tell_about_persona/view.dart';

class ResultsView extends ConsumerStatefulWidget {
  final String title;
  final String? result; // legacy: pre-generated raw text
  final PersonaType personaType;
  final List<String> challengesList;
  final PersonaModelData personaModelData;

  // New: wired profile + incident context
  final String? profileId;
  final String? incidentId;

  const ResultsView({
    super.key,
    required this.title,
    this.result,
    required this.challengesList,
    required this.personaModelData,
    required this.personaType,
    this.profileId,
    this.incidentId,
  });

  @override
  ConsumerState<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends ConsumerState<ResultsView> {
  SupportPlan? _plan;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSaved = false;
  String? _error;
  String? _savedPlanId;

  @override
  void initState() {
    super.initState();
    if (widget.result != null && widget.result!.isNotEmpty) {
      _plan = _legacyPlan(widget.result!);
      _isLoading = false;
    } else {
      _generatePlan();
    }
  }

  SupportPlan _legacyPlan(String text) {
    return SupportPlan(
      id: '',
      profileId: null,
      summary: text,
      whatMightBeHappening: '',
      whatToDoNow: [],
      whatToAvoid: [],
      messageDraft: '',
      followUpTasks: [],
      reflectionPrompt: '',
      createdAt: DateTime.now(),
    );
  }

  Future<void> _generatePlan() async {
    try {
      final plan = await CloudFunctionsService.generateSupportPlan(
        profileId: widget.profileId ?? '',
        incidentId: widget.incidentId,
        personaData: widget.personaModelData.toMap(),
        challenges: widget.challengesList,
        personaTypeKey: widget.personaType.policyKey,
      );
      CrucueAnalytics.logPlanGenerated(
        personaType: widget.personaType.policyKey,
        hasProfileId: widget.profileId?.isNotEmpty == true,
      );
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      CrucueAnalytics.recordError(e, StackTrace.current, reason: 'plan_generation_failed');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not generate plan. Please try again.';
        });
      }
    }
  }

  Future<void> _savePlan() async {
    if (_plan == null) return;
    setState(() => _isSaving = true);
    try {
      final savedId = await FirestoreService.savePlanWithContext(
        profileId: widget.profileId,
        plan: _plan!,
        personaModel: widget.personaModelData.toMap(),
        selectedChallenges: widget.challengesList,
        incidentId: widget.incidentId,
      );

      CrucueAnalytics.logPlanSaved(personaType: widget.personaType.policyKey);
      showMessage('Care plan saved.', type: MessageType.success);
      if (mounted) {
        setState(() {
          _isSaved = true;
          _savedPlanId = savedId;
        });
      }
    } catch (e) {
      showMessage('Could not save. Please try again.');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SecondAppBar(
        text: 'Your Support Plan',
        actions: [
          // TTS listen button
          if (!_isLoading && _plan != null)
            _TtsAppBarButton(plan: _plan!),
          if (!_isLoading && _plan != null && !_isSaved)
            _isSaving
                ? Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _savePlan,
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    tooltip: 'Save plan',
                  ),
          if (_isSaved)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: const Icon(Icons.bookmark_rounded, color: AppTheme.primary),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isLoading || _plan == null
          ? null
          : _ActionBar(
              plan: _plan!,
              profileId: widget.profileId,
              savedPlanId: _savedPlanId,
              personaName: widget.personaModelData.name,
              personaTypeKey: widget.personaType.policyKey,
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 20.h),
            Text(
              'Creating your care plan…',
              style: TextStyle(fontSize: 16.sp, color: Theme.of(context).hintColor),
            ),
            SizedBox(height: 8.h),
            Text(
              'This takes a moment.',
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 48.sp, color: Theme.of(context).hintColor),
              SizedBox(height: 16.h),
              Text(
                _error!,
                style: TextStyle(
                    fontSize: 15.sp, color: Theme.of(context).hintColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _generatePlan();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_plan == null) return const SizedBox.shrink();

    final plan = _plan!;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.r, 16.r, 20.r, 20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(
            name: widget.personaModelData.name,
            type: widget.personaType,
          ),
          SizedBox(height: 20.h),
          if (plan.escalationFlag) _SafetyBanner(),
          _PlanCard(
            icon: Icons.lightbulb_outline_rounded,
            title: "What's happening",
            color: CrucueTokens.planWhatHappening,
            iconColor: CrucueTokens.warning,
            content: _TextContent(plan.whatMightBeHappening),
          ),
          SizedBox(height: 12.h),
          _PlanCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'What to do now',
            color: CrucueTokens.planWhatToDo,
            iconColor: CrucueTokens.success,
            content: _ChecklistContent(plan.whatToDoNow),
          ),
          SizedBox(height: 12.h),
          if (plan.whatToAvoid.isNotEmpty) ...[
            _PlanCard(
              icon: Icons.do_not_disturb_outlined,
              title: 'What to avoid',
              color: CrucueTokens.planWhatToAvoid,
              iconColor: CrucueTokens.error,
              content: _ListContent(plan.whatToAvoid),
            ),
            SizedBox(height: 12.h),
          ],
          if (plan.messageDraft.isNotEmpty) ...[
            _PlanCard(
              icon: Icons.chat_outlined,
              title: 'Something you could say',
              color: CrucueTokens.planMessage,
              iconColor: CrucueTokens.info,
              content: _QuoteContent(plan.messageDraft),
            ),
            SizedBox(height: 12.h),
          ],
          if (plan.followUpTasks.isNotEmpty) ...[
            _PlanCard(
              icon: Icons.task_alt_rounded,
              title: 'Follow-up steps',
              color: CrucueTokens.planTasks,
              iconColor: const Color(0xff7C3AED),
              content: _ChecklistContent(plan.followUpTasks),
            ),
            SizedBox(height: 12.h),
          ],
          if (plan.reflectionPrompt.isNotEmpty) ...[
            _PlanCard(
              icon: Icons.self_improvement_rounded,
              title: 'Reflect later',
              color: CrucueTokens.planReflect,
              iconColor: AppTheme.primary,
              content: _TextContent(plan.reflectionPrompt),
            ),
            SizedBox(height: 12.h),
          ],
          _SafetyDisclaimer(),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }
}

// ─── Action Bar ───────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final SupportPlan plan;
  final String? profileId;
  final String? savedPlanId;
  final String personaName;
  final String personaTypeKey;

  const _ActionBar({
    required this.plan,
    required this.profileId,
    required this.savedPlanId,
    required this.personaName,
    required this.personaTypeKey,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 16),
                    onPressed: () => navigateTo(ChatView(
                      profileId: profileId,
                      planId: savedPlanId ?? plan.id,
                      profileName: personaName,
                      personaTypeKey: personaTypeKey,
                    )),
                    label: const Text('Continue Chat'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 16),
                    onPressed: () {
                      navigateTo(CheckInScreen(
                        profileId: profileId ?? '',
                        plan: plan,
                      ));
                    },
                    label: const Text('Reflect'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              icon: const Icon(Icons.home_outlined, size: 16),
              onPressed: () =>
                  navigateTo(const HomeView(), keepHistory: false),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).hintColor,
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final PersonaType type;

  const _ProfileHeader({required this.name, required this.type});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52.h,
          height: 52.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: type.color.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(type.icon, color: AppTheme.primary, size: 26.sp),
        ),
        SizedBox(width: 14.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: AppTheme.fontFamily2,
              ),
            ),
            Text(
              type.label,
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: CrucueTokens.warningSubtle,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: CrucueTokens.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: CrucueTokens.warning, size: 20),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'This situation may benefit from professional support. Please consider reaching out to a qualified counselor or therapist.',
              style: TextStyle(
                fontSize: 13.sp,
                color: CrucueTokens.warning,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;
  final Widget content;

  const _PlanCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          content,
        ],
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  final String text;
  const _TextContent(this.text);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style:
          TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface, height: 1.6),
    );
  }
}

class _QuoteContent extends StatelessWidget {
  final String text;
  const _QuoteContent(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8.r),
        border:
            Border(left: BorderSide(color: CrucueTokens.info, width: 3)),
      ),
      child: Text(
        '"$text"',
        style: TextStyle(
          fontSize: 14.sp,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ListContent extends StatelessWidget {
  final List<String> items;
  const _ListContent(this.items);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6.h),
                    width: 6.h,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ChecklistContent extends StatefulWidget {
  final List<String> items;
  const _ChecklistContent(this.items);

  @override
  State<_ChecklistContent> createState() => _ChecklistContentState();
}

class _ChecklistContentState extends State<_ChecklistContent> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.items.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.items.length, (i) {
        return GestureDetector(
          onTap: () => setState(() => _checked[i] = !_checked[i]),
          child: Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _checked[i],
                  onChanged: (v) =>
                      setState(() => _checked[i] = v ?? false),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(
                      widget.items[i],
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _checked[i]
                            ? Theme.of(context).hintColor
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: _checked[i]
                            ? TextDecoration.lineThrough
                            : null,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SafetyDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16.sp, color: Theme.of(context).hintColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'This is supportive guidance, not professional medical or psychological advice. If you\'re concerned about safety, please contact emergency services or a qualified professional.',
              style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TTS App Bar Button ────────────────────────────────────────────────────────

class _TtsAppBarButton extends ConsumerWidget {
  final SupportPlan plan;

  const _TtsAppBarButton({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsState = ref.watch(ttsPlaybackProvider);

    return PopupMenuButton<String>(
      icon: Icon(
        ttsState.isPlaying
            ? Icons.stop_circle_outlined
            : Icons.play_circle_outline_rounded,
        color: ttsState.isPlaying ? CrucueTokens.brandPrimary : null,
      ),
      tooltip: 'Listen to plan',
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'summary',
          child: Row(children: [
            Icon(Icons.summarize_outlined, size: 16.sp),
            SizedBox(width: 8.w),
            const Text('Read summary'),
          ]),
        ),
        PopupMenuItem(
          value: 'steps',
          child: Row(children: [
            Icon(Icons.checklist_rounded, size: 16.sp),
            SizedBox(width: 8.w),
            const Text('Read action steps'),
          ]),
        ),
        PopupMenuItem(
          value: 'message',
          child: Row(children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 16.sp),
            SizedBox(width: 8.w),
            const Text('Read suggested message'),
          ]),
        ),
        if (ttsState.isPlaying)
          PopupMenuItem(
            value: 'stop',
            child: Row(children: [
              Icon(Icons.stop_circle_outlined, size: 16.sp,
                  color: CrucueTokens.error),
              SizedBox(width: 8.w),
              Text('Stop', style: TextStyle(color: CrucueTokens.error)),
            ]),
          ),
      ],
      onSelected: (value) async {
        final notifier = ref.read(ttsPlaybackProvider.notifier);
        if (value == 'stop') {
          await notifier.stop();
          return;
        }
        switch (value) {
          case 'summary':
            await notifier.speakText(
              plan.summary,
              sectionLabel: 'summary',
              rate: SpeakingRate.calm,
            );
            break;
          case 'steps':
            if (plan.whatToDoNow.isNotEmpty) {
              await notifier.speakList(
                plan.whatToDoNow,
                sectionLabel: 'steps',
                rate: SpeakingRate.calm,
              );
            }
            break;
          case 'message':
            if (plan.messageDraft.isNotEmpty) {
              await notifier.speakText(
                plan.messageDraft,
                sectionLabel: 'message',
                rate: SpeakingRate.calm,
              );
            }
            break;
        }
      },
    );
  }
}
