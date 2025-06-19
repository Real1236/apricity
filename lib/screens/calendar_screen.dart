import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// CalendarScreen renders a monthly view where each day that has at least
/// one gratitude entry shows the first photo as a thumbnail. Tapping a day
/// opens a modal with the list of that day’s entries.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final String _uid;
  final _dayEntries =
      <DateTime, List<QueryDocumentSnapshot>>{}; // UTC‑date -> entries
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _loadMonth(_focused);
  }

  Future<void> _loadMonth(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('entries')
        .where('createdAt', isGreaterThanOrEqualTo: first)
        .where('createdAt', isLessThanOrEqualTo: last)
        .orderBy('createdAt')
        .get();

    final map = <DateTime, List<QueryDocumentSnapshot>>{};
    for (var doc in snap.docs) {
      final ts = (doc['createdAt'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final dayKey = DateTime.utc(ts.year, ts.month, ts.day);
      map.putIfAbsent(dayKey, () => []).add(doc);
    }

    setState(
      () => _dayEntries
        ..clear()
        ..addAll(map),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: TableCalendar(
        firstDay: DateTime.utc(2015, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focused,
        selectedDayPredicate: (d) =>
            _selected != null && isSameDay(d, _selected),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: _dayBuilder,
          selectedBuilder: _dayBuilder,
          todayBuilder: _dayBuilder,
        ),
        onPageChanged: (newFocused) {
          _focused = newFocused;
          _loadMonth(newFocused);
        },
        onDaySelected: (selected, focused) {
          setState(() => _selected = selected);
          _showDayEntries(selected);
        },
      ),
    );
  }

  Widget _dayBuilder(BuildContext context, DateTime day, DateTime _) {
    final key = DateTime.utc(day.year, day.month, day.day);
    final list = _dayEntries[key];
    if (list == null || list.isEmpty) {
      return Center(child: Text('${day.day}'));
    }
    final photoUrl = list.first['photoUrl'] as String?;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (photoUrl != null)
          Positioned.fill(
            child: CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(2),
          child: Text(
            '${day.day}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Bottom‑sheet with larger photo & caption
  void _showDayEntries(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    final entries = _dayEntries[key] ?? [];
    if (entries.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView.separated(
          controller: controller,
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) {
            final data = entries[i].data() as Map<String, dynamic>;
            final url = data['photoUrl'] as String?;
            final caption = data['caption'] as String? ?? '';
            final ts = (data['createdAt'] as Timestamp?)?.toDate();

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (url != null)
                    CachedNetworkImage(
                      imageUrl: url,
                      height: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox(
                        height: 220,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caption,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (ts != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${ts.year}/${ts.month.toString().padLeft(2, '0')}/${ts.day.toString().padLeft(2, '0')} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
