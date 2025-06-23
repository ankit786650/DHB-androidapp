import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MonitorAnalyticsScreen extends StatefulWidget {
  const MonitorAnalyticsScreen({super.key});

  @override
  State<MonitorAnalyticsScreen> createState() => _MonitorAnalyticsScreenState();
}

class _MonitorAnalyticsScreenState extends State<MonitorAnalyticsScreen> {
  int selectedFeeling = -1;
  String? selectedMedication;
  final TextEditingController descriptionController = TextEditingController();
  final List<_MoodEntry> _entries = [];

  final List<String> medications = [
    'Paracetamol',
    'Ibuprofen',
    'Aspirin',
    'Metformin',
    'Atorvastatin',
  ];

  List<FlSpot> _buildMoodTrend() {
    if (_entries.isEmpty) return [];
    final Map<String, _MoodEntry> dayMap = {};
    for (final entry in _entries) {
      final key = "${entry.date.year}-${entry.date.month}-${entry.date.day}";
      dayMap[key] = entry;
    }
    final days = dayMap.keys.toList()..sort();
    return List.generate(
      days.length,
      (i) => FlSpot(i.toDouble(), (dayMap[days[i]]!.rating + 1).toDouble()),
    );
  }

  Map<String, double> _buildMedicationMoodAvg() {
    final Map<String, List<int>> medRatings = {};
    for (final e in _entries) {
      medRatings.putIfAbsent(e.medication, () => []).add(e.rating);
    }
    return medRatings.map(
      (k, v) => MapEntry(
        k,
        v.isNotEmpty ? v.reduce((a, b) => a + b) / v.length : 0.0,
      ),
    );
  }

  void _onSubmit() {
    if (selectedFeeling < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select how you feel')),
      );
      return;
    }
    if (selectedMedication == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select medication')));
      return;
    }
    setState(() {
      _entries.add(
        _MoodEntry(
          DateTime.now(),
          selectedFeeling,
          descriptionController.text.trim(),
          selectedMedication!,
        ),
      );
      selectedFeeling = -1;
      descriptionController.clear();
      selectedMedication = null;
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const emojis = ['😄', '😊', '😐', '😟', '😢'];
    const feelingsText = ['Great', 'Good', 'Okay', 'Sad', 'Bad'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final total = _entries.length;
    final positiveCount = _entries.where((e) => e.rating <= 1).length;
    final neutralCount = _entries.where((e) => e.rating == 2).length;
    final negativeCount = total - positiveCount - neutralCount;

    double pct(int count) => total > 0 ? count / total * 100 : 0;

    final medMood = _buildMedicationMoodAvg();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Health Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () =>
                _showAnalyticsReport(context, medMood, emojis, feelingsText),
            tooltip: 'Show Analytics Report',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entry Form Card
                  Card(
                    elevation: 6,
                    margin: const EdgeInsets.only(bottom: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.sentiment_satisfied_alt,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'How are you feeling today?',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // One-line emoji selector
                          SizedBox(
                            height: 64,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: emojis.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, i) {
                                final selected = selectedFeeling == i;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedFeeling = i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: selected ? 32 : 27,
                                      backgroundColor: selected
                                          ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.15)
                                          : Colors.grey.shade200,
                                      child: Text(
                                        emojis[i],
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (selectedFeeling >= 0) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                feelingsText[selectedFeeling],
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          // Medication dropdown
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Medication Taken',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            isExpanded: true,
                            value: selectedMedication,
                            items: medications
                                .map(
                                  (med) => DropdownMenuItem(
                                    value: med,
                                    child: Text(med),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedMedication = val),
                            hint: const Text('Select medication'),
                          ),
                          const SizedBox(height: 18),

                          TextField(
                            controller: descriptionController,
                            maxLines: isWide ? 4 : 3,
                            decoration: InputDecoration(
                              hintText: 'Describe any symptoms or feelings...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Log Feedback'),
                              onPressed: _onSubmit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white, // <-- Add this!
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Realtime Analytics Cards
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildMoodSummary(emojis, feelingsText),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: _buildMedicationMoodCard(medMood, emojis),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildMoodSummary(emojis, feelingsText),
                            const SizedBox(height: 22),
                            _buildMedicationMoodCard(medMood, emojis),
                          ],
                        ),
                  const SizedBox(height: 30),
                  // Timeline + Trend
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTimelineCard(emojis, feelingsText),
                            ),
                            const SizedBox(width: 22),
                            Expanded(child: _buildTrendCard(emojis)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildTimelineCard(emojis, feelingsText),
                            const SizedBox(height: 28),
                            _buildTrendCard(emojis),
                          ],
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodSummary(List<String> emojis, List<String> feelingsText) {
    final total = _entries.length;
    final positiveCount = _entries.where((e) => e.rating <= 1).length;
    final neutralCount = _entries.where((e) => e.rating == 2).length;
    final negativeCount = total - positiveCount - neutralCount;

    double pct(int count) => total > 0 ? count / total * 100 : 0;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mood Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              total > 0
                  ? 'Your mood was positive ${pct(positiveCount).toStringAsFixed(0)}% of the time.'
                  : 'No mood feedback yet.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            _buildBar(
              'Positive',
              pct(positiveCount),
              Colors.greenAccent.shade700,
            ),
            _buildBar('Neutral', pct(neutralCount), Colors.amber.shade800),
            _buildBar(
              'Negative',
              pct(negativeCount),
              Colors.redAccent.shade200,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _showAnalyticsReport(
                  context,
                  _buildMedicationMoodAvg(),
                  emojis,
                  feelingsText,
                ),
                icon: const Icon(Icons.insights_outlined, size: 20),
                label: const Text('See Full Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationMoodCard(
    Map<String, double> medMood,
    List<String> emojis,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medication & Mood Correlation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            medMood.isEmpty
                ? Text(
                    'Log your feedback with medication to see correlation.',
                    style: TextStyle(color: Colors.grey.shade700),
                  )
                : Column(
                    children: medMood.entries.map((e) {
                      final avgMood = e.value;
                      final moodIdx = avgMood.round().clamp(0, 4);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                emojis[moodIdx],
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _moodTextFromIndex(moodIdx),
                              style: TextStyle(
                                color: _moodColor(moodIdx),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(List<String> emojis, List<String> feelingsText) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mood & Symptom Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: _entries.isEmpty
                  ? const Center(child: Text('No entries yet'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _entries.length,
                      itemBuilder: (context, i) {
                        final e = _entries[i];
                        return Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emojis[e.rating],
                                style: const TextStyle(fontSize: 30),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                feelingsText[e.rating],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _moodColor(e.rating),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${e.date.day}/${e.date.month}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              if (e.medication.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    e.medication,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.indigo,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (e.note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Tooltip(
                                    message: e.note,
                                    child: const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(List<String> emojis) {
    final spots = _buildMoodTrend();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Realtime Mood Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: spots.isEmpty
                  ? const Center(child: Text('No mood trend yet'))
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 5,
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, meta) => Text(
                                'D${v.toInt() + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (v, meta) {
                                if (v < 1 || v > 5) {
                                  return const SizedBox.shrink();
                                }
                                final idx = v.toInt() - 1;
                                return Text(
                                  emojis[idx],
                                  style: const TextStyle(fontSize: 14),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.deepPurpleAccent,
                            barWidth: 4,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.deepPurpleAccent.withOpacity(0.15),
                            ),
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

  Widget _buildBar(String label, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: color.withOpacity(0.18),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${pct.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  void _showAnalyticsReport(
    BuildContext context,
    Map<String, double> medMood,
    List<String> emojis,
    List<String> feelingsText,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        final moodStats = [
          ...List.generate(5, (i) {
            final count = _entries.where((e) => e.rating == i).length;
            final pct = _entries.isNotEmpty
                ? count / _entries.length * 100
                : 0.0;
            return {
              'emoji': emojis[i],
              'label': feelingsText[i],
              'count': count,
              'pct': pct,
            };
          }),
        ];
        return Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 28,
            bottom: 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analytics Report',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Mood Distribution',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...moodStats.map(
                  (m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          m['emoji'] as String,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(width: 70, child: Text(m['label'] as String)),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (m['pct'] as num) / 100, // <-- CORRECTED
                            backgroundColor: _moodColor(
                              moodStats.indexOf(m),
                            ).withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(
                              _moodColor(moodStats.indexOf(m)),
                            ),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(m['pct'] as num).toStringAsFixed(0)}%',
                        ), // <-- CORRECTED
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Medication & Average Mood',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                medMood.isEmpty
                    ? const Text(
                        'No medication-mood correlation data yet.',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Column(
                        children: medMood.entries.map((e) {
                          final idx = e.value.round().clamp(0, 4);
                          return Row(
                            children: [
                              SizedBox(width: 100, child: Text(e.key)),
                              Text(
                                emojis[idx],
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _moodTextFromIndex(idx),
                                style: TextStyle(
                                  color: _moodColor(idx),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 22),
                const Text(
                  'Recent Feedback',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _entries.isEmpty
                    ? const Text(
                        'No feedback submitted yet.',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Column(
                        children: _entries
                            .take(5)
                            .toList()
                            .reversed
                            .map(
                              (e) => Card(
                                elevation: 0,
                                color: Colors.blueGrey.withOpacity(0.04),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: _moodColor(
                                      e.rating,
                                    ).withOpacity(0.18),
                                    child: Text(emojis[e.rating]),
                                  ),
                                  title: Text(
                                    '${e.medication} (${_moodTextFromIndex(e.rating)})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    e.note.isEmpty
                                        ? '(No description)'
                                        : e.note,
                                  ),
                                  trailing: Text(
                                    '${e.date.day}/${e.date.month} ${e.date.hour}:${e.date.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Color _moodColor(int idx) {
    switch (idx) {
      case 0:
        return Colors.green.shade700;
      case 1:
        return Colors.lightGreen.shade700;
      case 2:
        return Colors.amber.shade700;
      case 3:
        return Colors.orange.shade700;
      case 4:
      default:
        return Colors.red.shade400;
    }
  }

  static String _moodTextFromIndex(int idx) {
    switch (idx) {
      case 0:
        return 'Great';
      case 1:
        return 'Good';
      case 2:
        return 'Okay';
      case 3:
        return 'Sad';
      case 4:
      default:
        return 'Bad';
    }
  }
}

class _MoodEntry {
  final DateTime date;
  final int rating;
  final String note;
  final String medication;

  _MoodEntry(this.date, this.rating, this.note, this.medication);
}
