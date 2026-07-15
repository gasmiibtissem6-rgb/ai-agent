import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dio/dio.dart';
import '../domain/chat_provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/file_saver.dart';
import '../../../shared/ideal_ui.dart';
import 'scan_contract_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentLocale = 'fr-FR';

  final List<Map<String, String>> _locales = [
    {'code': 'fr-FR', 'label': 'FR'},
    {'code': 'en-US', 'label': 'EN'},
    {'code': 'ar-SA', 'label': 'AR'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n
                  .trp('chatai.voiceError', {'msg': error.errorMsg})),
            ),
          );
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tr('chatai.voiceUnavailable')),
        ),
      );
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: _currentLocale),
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  void _cycleLocale() {
    setState(() {
      final idx = _locales.indexWhere((l) => l['code'] == _currentLocale);
      _currentLocale = _locales[(idx + 1) % _locales.length]['code']!;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 800),
        content: Text(
          context.l10n.trp('chatai.voiceLang', {
            'lang': _locales.firstWhere(
                (l) => l['code'] == _currentLocale)['label']!,
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  String? _pendingImage;

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final image = _pendingImage;
    _pendingImage = null;
    ref.read(chatProvider.notifier).sendMessage(text, image: image);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _downloadPdf(String content) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}/chat/generate-pdf',
        data: {'content': content, 'title': 'Contract'},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data is Uint8List
          ? response.data as Uint8List
          : Uint8List.fromList(List<int>.from(response.data as List));
      await savePdfBytes(bytes, 'contract.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tr('chatai.pdfFailed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    final messages = state.messages;
    final isLoading = state.isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final hasAiMessages = messages.any((m) => m.role != 'user');

    return IdealAppScaffold(
      activeRoute: 'chat',
      actions: [
        if (hasAiMessages)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: context.l10n.tr('chatai.downloadPdf'),
            color: Colors.red.shade400,
            onPressed: () {
              final aiMessages = messages
                  .where(
                    (m) =>
                        m.role != 'user' &&
                        (m.content.contains('CONTRAT') ||
                            m.content.contains('ARTICLE') ||
                            m.content.contains('contrat')),
                  )
                  .toList();
              if (aiMessages.isNotEmpty) _downloadPdf(aiMessages.last.content);
            },
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: context.l10n.tr('chatai.clear'),
          onPressed: () => ref.read(chatProvider.notifier).clearChat(),
        ),
      ],
      body: IdealGradientBackground(
        child: Column(
          children: [
            if (state.error != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade900.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Expanded(
              child: messages.isEmpty && !isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 64,
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.tr('chatai.title'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.tr('chatai.subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.tr('chatai.thinking'),
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final msg = messages[index];
                        final isUser = msg.role == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 16),
                              ),
                            ),
                            child: isUser
                                ? Text(
                                    msg.content,
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 15,
                                    ),
                                  )
                                : MarkdownBody(
                                    data: msg.content,
                                    styleSheet: MarkdownStyleSheet(
                                      p: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 15,
                                      ),
                                      strong: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ScanContractButton(
                      onTextExtracted: (text, imageBase64) {
                        setState(() => _pendingImage = imageBase64);
                        _controller.text = text.isNotEmpty
                            ? 'Voici le contrat scanné, analyse-le et aide-moi à le comprendre :\n\n$text'
                            : 'Voici une photo de mon document, analyse-le et aide-moi à le comprendre.';
                      },
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onLongPress: _cycleLocale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                          color: _isListening
                              ? Colors.red
                              : colorScheme.primary,
                          tooltip: context.l10n.trp('chatai.micTooltip', {
                            'lang': _locales.firstWhere(
                                (l) => l['code'] == _currentLocale)['label']!,
                          }),
                          onPressed: _toggleListening,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? context.l10n.tr('chatai.listening')
                              : context.l10n.tr('chatai.inputHint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: colorScheme.primary,
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
