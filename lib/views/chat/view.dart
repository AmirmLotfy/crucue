import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/ai/ai_engine_registry.dart';
import '../../core/audio/audio_recorder_service.dart';
import '../../core/design/app_back.dart';
import '../../core/logic/helper_methods.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme.dart';
import 'view_model.dart';

class ChatView extends ConsumerStatefulWidget {
  final String? profileId;
  final String? planId;
  final String? profileName;
  final String? personaTypeKey;

  const ChatView({
    super.key,
    this.profileId,
    this.planId,
    this.profileName,
    this.personaTypeKey,
  });

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.profileId != null || widget.planId != null) {
      ref.read(chatProvider.notifier).setContext(
            profileId: widget.profileId,
            planId: widget.planId,
            personaTypeKey: widget.personaTypeKey,
          );
    }
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).ensureWelcomeMessage(
            profileName: widget.profileName,
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    setState(() => _isSending = true);
    await ref.read(chatProvider.notifier).sendMessage(text);
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const AppBack(),
        title: Row(
          children: [
            Container(
              width: 36.h,
              height: 36.h,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crucue',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: CrucueTokens.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Here for you',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 20.sp),
            tooltip: 'New conversation',
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              _addWelcomeMessage();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _SafetyBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              itemCount: messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length && _isSending) {
                  return _TypingIndicator();
                }
                final isUser = messages[i].startsWith('You:');
                final text = messages[i]
                    .replaceFirst('You: ', '')
                    .replaceFirst('AI: ', '');
                return _MessageBubble(text: text, isUser: isUser);
              },
            ),
          ),
          _InputBar(
            controller: _controller,
            isSending: _isSending,
            onSend: _sendMessage,
            profileId: widget.profileId,
          ),
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: CrucueTokens.brandPrimary.withValues(alpha: 0.06),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        'Crucue offers supportive guidance only — not professional care.',
        style: TextStyle(
          fontSize: 11.sp,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isUser ? Radius.circular(16.r) : Radius.circular(4.r),
            bottomRight: isUser ? Radius.circular(4.r) : Radius.circular(16.r),
          ),
          border: isUser ? null : Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            SizedBox(width: 4.w),
            _Dot(delay: 150),
            SizedBox(width: 4.w),
            _Dot(delay: 300),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8.h,
          height: 8.h,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final String? profileId;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    this.profileId,
  });

  @override
  ConsumerState<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<_InputBar> {
  final RecordAudioService _recorder = RecordAudioService();
  bool _isVoiceRecording = false;
  bool _isTranscribing = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startVoiceInput() async {
    final hasPermission = await _recorder.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _recorder.requestMicrophonePermission();
      if (!granted) return;
    }
    setState(() => _isVoiceRecording = true);
    try {
      await _recorder.startRecording();
    } catch (_) {
      setState(() => _isVoiceRecording = false);
    }
  }

  Future<void> _stopVoiceInput() async {
    final path = await _recorder.stopRecording();
    setState(() {
      _isVoiceRecording = false;
      _isTranscribing = true;
    });

    if (path == null) {
      setState(() => _isTranscribing = false);
      return;
    }

    try {
      // Upload the short clip to a temp Storage location
      final file = File(path);
      const tempProfileId = 'voice_chat';
      const tempVoiceNoteId = 'temp_chat_clip';
      final uploaded = await StorageService.uploadVoiceNoteForProfile(
        file: file,
        profileId: tempProfileId,
        voiceNoteId:
            '${tempVoiceNoteId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Transcribe via Cloud Function
      final transcript = await ref
          .read(aiEngineProvider)
          .transcribeShortClip(audioStoragePath: uploaded.path);

      if (transcript.isNotEmpty) {
        widget.controller.text = transcript;
      }

      // Clean up local file
      try {
        file.deleteSync();
      } catch (_) {}
    } catch (e) {
      // Transcription failed — user can type manually
      if (mounted) {
        showMessage(
          'Could not transcribe. Please type your message.',
          type: MessageType.warning,
        );
      }
    }
    if (mounted) setState(() => _isTranscribing = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          children: [
            // Voice input button
            GestureDetector(
              onLongPressStart: (_) => _startVoiceInput(),
              onLongPressEnd: (_) => _stopVoiceInput(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40.h,
                height: 40.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isVoiceRecording
                      ? CrucueTokens.brandPrimary.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Icon(
                  _isTranscribing
                      ? Icons.hourglass_empty_rounded
                      : _isVoiceRecording
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                  size: 22.sp,
                  color: _isVoiceRecording
                      ? CrucueTokens.brandPrimary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: TextField(
                controller: widget.controller,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: _isVoiceRecording
                      ? 'Recording… release to transcribe'
                      : _isTranscribing
                          ? 'Transcribing…'
                          : 'Type or hold mic to speak',
                  hintStyle: TextStyle(
                      color: _isVoiceRecording
                          ? CrucueTokens.brandPrimary
                          : Theme.of(context).hintColor,
                      fontSize: 14.sp),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 10.h),
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: widget.isSending ? null : widget.onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44.h,
                height: 44.h,
                decoration: BoxDecoration(
                  color: widget.isSending
                      ? CrucueTokens.brandPrimary.withValues(alpha: 0.4)
                      : CrucueTokens.brandPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
