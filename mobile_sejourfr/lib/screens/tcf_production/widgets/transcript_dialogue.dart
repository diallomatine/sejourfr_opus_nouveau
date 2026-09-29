import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Un tour de dialogue transcrit.
class TranscriptTurn {
  const TranscriptTurn({required this.candidate, required this.text});
  final bool candidate;
  final String text;
}

/// Parse une transcription realtime « Candidat : … / Examinateur : … » en tours.
/// Retourne `null` si aucun marqueur de dialogue (monologue Whisper classique)
/// → l'appelant l'affiche alors en texte simple.
List<TranscriptTurn>? parseTranscriptDialogue(String raw) {
  const cand = 'Candidat :';
  const exam = 'Examinateur :';
  final turns = <TranscriptTurn>[];
  var sawLabel = false;
  for (final line in raw.split('\n')) {
    final row = line.trim();
    if (row.isEmpty) continue;
    if (row.startsWith(cand)) {
      sawLabel = true;
      turns.add(TranscriptTurn(candidate: true, text: row.substring(cand.length).trim()));
    } else if (row.startsWith(exam)) {
      sawLabel = true;
      turns.add(TranscriptTurn(candidate: false, text: row.substring(exam.length).trim()));
    } else if (turns.isNotEmpty) {
      // Continuation d'un tour (rare) : on colle à la ligne précédente.
      final last = turns.removeLast();
      turns.add(TranscriptTurn(candidate: last.candidate, text: '${last.text} $row'));
    }
  }
  if (!sawLabel) return null;
  return turns.where((t) => t.text.isNotEmpty).toList();
}

/// Bulle de transcription : candidat à droite (rouge), examinateur à gauche (bleu).
class TranscriptBubble extends StatelessWidget {
  const TranscriptBubble({super.key, required this.candidate, required this.text});

  final bool candidate;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: candidate ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: candidate ? AppColors.redLight : AppColors.blueLight,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(candidate ? 14 : 4),
              bottomRight: Radius.circular(candidate ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate ? 'VOUS' : 'EXAMINATEUR',
                style: AppFonts.label(
                  size: 10,
                  color: candidate ? AppColors.redDark : AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(text, style: AppFonts.ui(size: 14, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Affiche une transcription (chaîne stockée) : en dialogue de bulles si c'est un
/// échange « Candidat/Examinateur » (realtime), sinon en texte simple (monologue).
class TranscriptDialogueView extends StatelessWidget {
  const TranscriptDialogueView({super.key, required this.transcription});

  final String transcription;

  @override
  Widget build(BuildContext context) {
    final turns = parseTranscriptDialogue(transcription);
    if (turns == null) {
      return SingleChildScrollView(
        child: Text(
          transcription,
          style: AppFonts.ui(size: 14, color: AppColors.ink),
        ),
      );
    }
    if (turns.isEmpty) {
      return Center(
        child: Text(
          'Transcription indisponible.',
          style: AppFonts.ui(size: 13, color: AppColors.muted),
        ),
      );
    }
    return ListView.separated(
      itemCount: turns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          TranscriptBubble(candidate: turns[i].candidate, text: turns[i].text),
    );
  }
}
