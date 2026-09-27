class OfflineCompanionContext {
  final String? firstName;
  final String? batchCode;
  final bool isSenior;

  const OfflineCompanionContext({
    this.firstName,
    this.batchCode,
    this.isSenior = false,
  });
}

/// Deterministic, privacy-safe guidance available without a network.
///
/// It intentionally does not invent live placement facts, student scores or
/// company eligibility. Those require the authenticated, evidence-grounded
/// online AI Senior.
class OfflineCompanion {
  static String answer(
    String message, {
    OfflineCompanionContext context = const OfflineCompanionContext(),
  }) {
    final query = message.trim().toLowerCase();
    final hello = context.firstName?.trim().isNotEmpty == true
        ? '${context.firstName!.trim()}, '
        : '';
    final stage = context.isSenior
        ? 'Since you are in the senior preparation stage, turn every session into interview evidence.'
        : 'Since you are building your foundation, favour consistency over long one-off sessions.';

    String guidance;
    if (_hasAny(query, const ['dsa', 'data structure', 'leetcode', 'coding'])) {
      guidance = '''$hello$stage

Try this focused DSA loop:
1. Pick one pattern: arrays, two pointers, sliding window, stack, binary search, trees, graphs, or DP.
2. Review one worked example for 10 minutes.
3. Solve one easy and one medium problem without copying.
4. Write the invariant, time complexity, and the mistake you made.
5. Re-solve the medium problem tomorrow.

For an interview answer, first state the simple approach, then improve it, test edge cases, and finally give time and space complexity.''';
    } else if (_hasAny(query, const ['aptitude', 'quant', 'reasoning'])) {
      guidance =
          '''$hello use a 30-minute aptitude cycle: 8 minutes to recall formulas, 15 minutes for a timed set, and 7 minutes to analyse mistakes. Separate errors into concept, calculation, and time-pressure. Reattempt only the failed questions tomorrow. Start with percentages, ratios, averages, time-work, probability, and logical arrangements.''';
    } else if (_hasAny(
        query, const ['mock interview', 'interview tip', 'hr round'])) {
      guidance =
          '''$hello practise answers with this structure: context, your action, measurable result, and what you learned. Keep the opening under 20 seconds. For technical questions, clarify assumptions, explain the trade-off, test an edge case, and close with complexity. Record one two-minute answer and remove filler words on the second attempt.''';
    } else if (_hasAny(query, const ['resume', 'cv'])) {
      guidance =
          '''$hello review every resume bullet with this formula: action + technology + problem + result. Remove vague words such as “worked on” and “familiar with”. Keep only skills you can explain and prove. Put the strongest relevant project first, add links that open correctly, and prepare a 60-second explanation for every claim.''';
    } else if (_hasAny(query, const ['dbms', 'database', 'sql'])) {
      guidance =
          '''DBMS interview core: a primary key uniquely identifies a row; a foreign key preserves relationships; normalization reduces update anomalies; an index speeds reads but adds storage and write cost; and a transaction follows atomicity, consistency, isolation, and durability. Practise joins, GROUP BY/HAVING, subqueries, indexes, and transaction isolation with one example each.''';
    } else if (_hasAny(query,
        const ['operating system', ' os ', 'deadlock', 'process', 'thread'])) {
      guidance =
          '''OS interview core: a process owns resources, while threads share process memory. Context switching changes the running execution state. Deadlock needs mutual exclusion, hold-and-wait, no pre-emption, and circular wait. Be ready to compare paging vs segmentation, process vs thread, and mutex vs semaphore with a concrete example.''';
    } else if (_hasAny(query, const ['network', 'tcp', 'udp', 'http'])) {
      guidance =
          '''Networking interview core: TCP is connection-oriented and reliable; UDP prioritises low overhead. DNS resolves names, TLS protects transport, and HTTP carries application requests. Practise explaining what happens after entering a URL: DNS lookup, connection, TLS, HTTP request, server response, then rendering.''';
    } else if (_hasAny(query, const ['oops', 'oop', 'object oriented'])) {
      guidance =
          '''OOP interview core: encapsulation protects state, abstraction exposes essentials, inheritance reuses behaviour, and polymorphism lets one interface support multiple implementations. Explain each using one small project example, then discuss composition versus inheritance and why composition is often safer.''';
    } else if (_hasAny(query, const ['project', 'final year', 'fyp'])) {
      guidance =
          '''$hello present your project in five parts: user problem, your responsibility, architecture, hardest trade-off, and verified result. Prepare one diagram, one failure you fixed, one security decision, and one improvement you would make next. Never claim a metric you cannot demonstrate.''';
    } else if (_hasAny(query, const ['communication', 'speak', 'english'])) {
      guidance =
          '''Use PREP for a clear two-minute answer: state your Point, give the Reason, add one Example, then repeat the Point as a conclusion. Pause instead of using filler words. Record once for structure, once for clarity, and once for confident pace.''';
    } else if (_hasAny(query, const ['daily five', 'daily 5', 'streak'])) {
      guidance =
          '''Daily Five works best as diagnosis, not a score chase. Answer without switching apps, note the weakest topic, review the explanation, and do one follow-up problem from that topic. A short honest daily rhythm is more useful than memorising answers.''';
    } else {
      guidance =
          '''$hello I can still help while offline, but I will not invent live placement details or personal scores. Break the question into: what is known, what must be produced, constraints, a simple approach, edge cases, and how you will verify the result. If this is a technical topic, include a small example and complexity; if it is an interview question, use context, action, result, and learning.

Ask again with a keyword such as DSA, aptitude, DBMS, OS, networking, OOP, project, resume, interview, or communication for a focused offline answer.''';
    }

    return 'Offline companion\n\n$guidance\n\nReconnect for a personalised plan using your latest PSGMX evidence.';
  }

  static bool _hasAny(String value, List<String> terms) =>
      terms.any(value.contains);
}
