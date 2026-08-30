import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/recorded_audio_bytes.dart';

class CommunicationPracticeScreen extends StatefulWidget {
  const CommunicationPracticeScreen({super.key});

  @override
  State<CommunicationPracticeScreen> createState() =>
      _CommunicationPracticeScreenState();
}

class _CommunicationPracticeScreenState
    extends State<CommunicationPracticeScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final List<Map<String, dynamic>> _prompts = [];
  Map<String, dynamic>? _selectedPrompt;
  Map<String, dynamic>? _result;
  Timer? _timer;
  String? _recordedPath;
  String? _error;
  int _seconds = 0;
  bool _loading = true;
  bool _recording = false;
  bool _evaluating = false;

  String? get _accessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recorder.dispose());
    unawaited(deleteRecordedAudio(_recordedPath));
    super.dispose();
  }

  Future<void> _loadPrompts() async {
    final token = _accessToken;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Your session expired. Sign in again to practise.';
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.appApiUrl}/api/communication/evaluate'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(body['error'] ?? 'Unable to load practice prompts.');
      }
      final prompts = (body['prompts'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (!mounted) return;
      setState(() {
        _prompts
          ..clear()
          ..addAll(prompts);
        _selectedPrompt = prompts.isEmpty ? null : prompts.first;
        _loading = false;
        _error = prompts.isEmpty
            ? 'No communication prompts are available right now.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is TimeoutException
            ? 'The practice service took too long to respond.'
            : error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _startRecording() async {
    if (kIsWeb) {
      setState(() => _error =
          'Audio recording is available in the Android app. On desktop, use the PSGMX web portal.');
      return;
    }
    if (_selectedPrompt == null || _recording || _evaluating) return;
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => _error =
            'Microphone permission is required for communication practice.');
        return;
      }
      await deleteRecordedAudio(_recordedPath);
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/psgmx_answer_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _recordedPath = null;
        _result = null;
        _error = null;
        _seconds = 0;
        _recording = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_seconds >= 119) {
          unawaited(_stopRecording());
        } else {
          setState(() => _seconds++);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'The microphone could not start. Check permission and try again.');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _timer?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordedPath = path;
      if (_seconds < 1 || path == null) {
        _error = 'Record at least one second of clear speech.';
      }
    });
  }

  Future<void> _evaluateAudio() async {
    final token = _accessToken;
    final promptId = _selectedPrompt?['id']?.toString();
    final path = _recordedPath;
    if (token == null || promptId == null || path == null || _seconds < 1) {
      setState(() => _error = 'Record an answer before requesting feedback.');
      return;
    }
    setState(() {
      _evaluating = true;
      _error = null;
    });
    try {
      final bytes = await readRecordedAudio(path);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${SupabaseConfig.appApiUrl}/api/communication/evaluate'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['prompt_id'] = promptId
        ..fields['duration_seconds'] = _seconds.toString()
        ..files.add(http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'answer.m4a',
          contentType: MediaType('audio', 'mp4'),
        ));
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(
            body['error'] ?? 'Evaluation is temporarily unavailable.');
      }
      if (!mounted) return;
      setState(() {
        _result = body;
        _evaluating = false;
      });
      await deleteRecordedAudio(path);
      _recordedPath = null;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _evaluating = false;
        _error = error is TimeoutException
            ? 'Evaluation timed out. Your clip was not retained; please retry.'
            : error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatTime(int totalSeconds) =>
      '${(totalSeconds ~/ 60).toString().padLeft(2, '0')}:${(totalSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scores = _result?['scores'] as Map<String, dynamic>?;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Communication Practice',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPrompts,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _promptCard(),
              const SizedBox(height: 20),
              _recorderCard(),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _messageCard(_error!, Colors.red.shade700, Icons.info_outline),
              ],
              if (scores != null) ...[
                const SizedBox(height: 20),
                _feedbackCard(scores),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _promptCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('YOUR PRACTICE PROMPT',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                  letterSpacing: .6)),
          const SizedBox(height: 10),
          if (_prompts.isNotEmpty)
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: _selectedPrompt,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _prompts
                  .map((prompt) => DropdownMenuItem(
                        value: prompt,
                        child: Text(prompt['prompt_text']?.toString() ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: _recording
                  ? null
                  : (prompt) => setState(() {
                        _selectedPrompt = prompt;
                        _result = null;
                        _error = null;
                      }),
            ),
          if (_selectedPrompt != null) ...[
            const SizedBox(height: 10),
            Text(
              '${_selectedPrompt!['category'] ?? 'Interview'} · ${_selectedPrompt!['difficulty'] ?? 'adaptive'} · 2 minute maximum',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ]),
      );

  Widget _recorderCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: _cardDecoration(),
        child: Column(children: [
          Text(_formatTime(_seconds),
              style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: _recording ? Colors.red : AppTheme.textMain)),
          const Text('/ 02:00',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          IconButton.filled(
            onPressed: _selectedPrompt == null || _evaluating
                ? null
                : (_recording ? _stopRecording : _startRecording),
            iconSize: 38,
            padding: const EdgeInsets.all(20),
            style: IconButton.styleFrom(
                backgroundColor:
                    _recording ? Colors.red : AppTheme.primaryPurple),
            icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
          ),
          const SizedBox(height: 12),
          Text(
            _recording
                ? 'Speak naturally, then tap stop'
                : _recordedPath != null
                    ? 'Recording ready for private evaluation'
                    : 'Tap to start recording',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted),
          ),
          if (_recordedPath != null && _result == null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _evaluating ? null : _evaluateAudio,
                child: _evaluating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Evaluate with AI Senior'),
              ),
            ),
          ],
        ]),
      );

  Widget _feedbackCard(Map<String, dynamic> scores) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('EVIDENCE-BASED FEEDBACK',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _scoreChip('Clarity', scores['clarity_score']),
            _scoreChip('Structure', scores['structure_score']),
            _scoreChip('Relevance', scores['relevance_score']),
            _scoreChip('Fillers', scores['filler_word_count'], outOfTen: false),
          ]),
          const SizedBox(height: 16),
          Text(scores['brief_feedback']?.toString() ?? '',
              style: const TextStyle(height: 1.45)),
          const SizedBox(height: 10),
          Text('Next attempt: ${scores['suggested_improvement'] ?? ''}',
              style: const TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryPurple)),
          if ((_result?['transcript']?.toString() ?? '').isNotEmpty) ...[
            const Divider(height: 28),
            const Text('TRANSCRIPT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 6),
            Text(_result!['transcript'].toString(),
                style: const TextStyle(color: AppTheme.textMuted, height: 1.4)),
          ],
        ]),
      );

  Widget _scoreChip(String label, dynamic value, {bool outOfTen = true}) =>
      Chip(label: Text('$label: ${value ?? 0}${outOfTen ? '/10' : ''}'));

  Widget _messageCard(String message, Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: color))),
        ]),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      );
}
