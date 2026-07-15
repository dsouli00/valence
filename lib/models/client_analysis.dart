import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// A coach-facing AI read of one client's recent logs —
/// `client_analyses/{clientId}` (one doc per client: the latest analysis).
///
/// PRIVACY — the reason this is its own collection and NOT a field on the user
/// doc: `firestore.rules` lets any signed-in user read `users/{uid}`, including
/// the client themselves. An analysis can legitimately say "his logging looks
/// inconsistent, he may be under-reporting" — that is written FOR THE COACH and
/// the client must never be able to read it. The rules for this collection gate
/// read+write on `coachId == request.auth.uid`.
///
/// The doc id is the clientId (same deterministic-id convention as daily logs),
/// so the card fetches with a direct get and there is exactly one current
/// analysis per client.
class ClientAnalysis {
  final String clientId;
  final String coachId;
  final DateTime createdAt;

  /// Language the text was GENERATED in ('en'/'ar'/…). The prose is baked, not
  /// translatable after the fact — if the coach switches language, the card
  /// says so and offers a re-analysis rather than showing the wrong language.
  final String locale;

  /// How many days of logs were read.
  final int windowDays;

  /// Stable hash of the data the analysis was built from. Drives the "nothing
  /// new since the last analysis" hint. Deliberately a HINT, never a lock —
  /// re-analyzing is always allowed, so a hash collision can never trap a coach
  /// with a stale read.
  final String fingerprint;

  /// The single most important sentence — what the coach reads first.
  final String headline;

  final List<AnalysisPoint> wins;
  final List<AnalysisPoint> risks;

  /// Concrete things the coach could do or say next.
  final List<String> actions;

  /// How much data backed this read (coverage, not certainty about a photo).
  final AnalysisConfidence confidence;

  const ClientAnalysis({
    required this.clientId,
    required this.coachId,
    required this.createdAt,
    required this.locale,
    required this.windowDays,
    required this.fingerprint,
    required this.headline,
    required this.wins,
    required this.risks,
    required this.actions,
    required this.confidence,
  });

  factory ClientAnalysis.fromJson(Map<String, dynamic> json, String id) {
    return ClientAnalysis(
      clientId: json['clientId'] as String? ?? id,
      coachId: json['coachId'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      locale: json['locale'] as String? ?? 'en',
      windowDays: (json['windowDays'] as num?)?.toInt() ?? 14,
      fingerprint: json['fingerprint'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      wins: _points(json['wins']),
      risks: _points(json['risks']),
      actions: (json['actions'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      confidence: analysisConfidenceFromValue(json['confidence'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'coachId': coachId,
        'createdAt': Timestamp.fromDate(createdAt),
        'locale': locale,
        'windowDays': windowDays,
        'fingerprint': fingerprint,
        'headline': headline,
        'wins': wins.map((p) => p.toJson()).toList(),
        'risks': risks.map((p) => p.toJson()).toList(),
        'actions': actions,
        'confidence': confidence.name,
      };

  static List<AnalysisPoint> _points(dynamic raw) =>
      (raw as List<dynamic>? ?? const [])
          .map((e) => AnalysisPoint.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

  /// True when the analysis was written in a different language than the coach
  /// is now reading the app in.
  bool isStaleForLocale(String currentLocale) => locale != currentLocale;
}

/// One observation, with the data that backs it.
class AnalysisPoint {
  final String text;

  /// The receipt. Every point must cite the numbers it came from so the coach
  /// can verify it against the charts right below the card — this is a product
  /// requirement (Yassine: "the coach can go check and confirm it"), not a
  /// nice-to-have, so it is non-nullable.
  final String evidence;

  /// Only set on risks; wins have no severity.
  final AnalysisSeverity? severity;

  const AnalysisPoint({
    required this.text,
    required this.evidence,
    this.severity,
  });

  factory AnalysisPoint.fromJson(Map<String, dynamic> json) => AnalysisPoint(
        text: (json['text'] as String? ?? '').trim(),
        evidence: (json['evidence'] as String? ?? '').trim(),
        severity: analysisSeverityFromValue(json['severity'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'evidence': evidence,
        if (severity != null) 'severity': severity!.name,
      };
}

// Firestore/Gemini string codecs. Unknown or absent values degrade to the
// safest reading rather than throwing — a malformed model response should
// never crash a coach's screen.

AnalysisConfidence analysisConfidenceFromValue(String? v) {
  switch (v) {
    case 'high':
      return AnalysisConfidence.high;
    case 'medium':
      return AnalysisConfidence.medium;
    default:
      return AnalysisConfidence.low;
  }
}

AnalysisSeverity? analysisSeverityFromValue(String? v) {
  switch (v) {
    case 'alert':
      return AnalysisSeverity.alert;
    case 'watch':
      return AnalysisSeverity.watch;
    default:
      return null;
  }
}
