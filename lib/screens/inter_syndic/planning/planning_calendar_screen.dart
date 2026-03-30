import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../models/reunion_model.dart';
import '../../../services/reunion_service.dart';
import '../../../services/finance_service.dart';
import '../../../utils/temp_session.dart';
import 'dart:ui';

class PlanningCalendarScreen extends StatefulWidget {
  final int trancheId;
  final int residenceId;

  const PlanningCalendarScreen({
    super.key,
    required this.trancheId,
    required this.residenceId,
  });

  @override
  State<PlanningCalendarScreen> createState() => _PlanningCalendarScreenState();
}

class _PlanningCalendarScreenState extends State<PlanningCalendarScreen> {
  final _reunionService = ReunionService();
  final _financeService = FinanceService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<ReunionModel> _reunions = [];
  List<Map<String, dynamic>> _mandats = [];
  Map<DateTime, String> _userNotes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notesJson = prefs.getString('user_notes_${widget.trancheId}');
      if (notesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(notesJson);
        final Map<DateTime, String> loadedNotes = {};
        decoded.forEach((key, value) {
          loadedNotes[DateTime.parse(key)] = value.toString();
        });
        setState(() => _userNotes = loadedNotes);
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> toSave = {};
      _userNotes.forEach((key, value) {
        toSave[key.toIso8601String()] = value;
      });
      await prefs.setString('user_notes_${widget.trancheId}', jsonEncode(toSave));
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final reunions = await _reunionService.getReunionsByTranche(widget.trancheId);
      final mandats = await _financeService.getInterSyndicMandates(TempSession.interSyndicId, widget.residenceId);
      
      setState(() {
        _reunions = reunions;
        _mandats = mandats.where((m) => m['tranche_id'] == widget.trancheId).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final List<dynamic> events = [];
    
    // Check for meetings
    final dayMeetings = _reunions.where((r) => isSameDay(r.date, day)).toList();
    events.addAll(dayMeetings);
    
    // Check for notes
    final normalizedDay = DateTime(day.year, day.month, day.day);
    if (_userNotes.containsKey(normalizedDay)) {
      events.add({'type': 'note', 'content': _userNotes[normalizedDay]});
    }

    return events;
  }

  bool _isDayInMandate(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    for (var m in _mandats) {
      final sData = DateTime.parse(m['date_debut']);
      final start = DateTime(sData.year, sData.month, sData.day);
      
      DateTime? end;
      if (m['date_fin'] != null) {
        final eData = DateTime.parse(m['date_fin']);
        end = DateTime(eData.year, eData.month, eData.day);
      }
      
      // Check if start <= d <= end (or end null)
      if ((d.isAtSameMomentAs(start) || d.isAfter(start))) {
        if (end == null || d.isAtSameMomentAs(end) || d.isBefore(end)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Planning & Calendrier', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8603C)))
              : Column(
                  children: [
                    _buildCalendarCard(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _buildDayDetails(),
                    ),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: const Color(0xFFE8603C),
        child: const Icon(Icons.note_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: Colors.white70),
              holidayTextStyle: const TextStyle(color: Color(0xFFE8603C)),
              todayDecoration: BoxDecoration(
                color: const Color(0xFFE8603C).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFE8603C),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF4B6BFB),
                shape: BoxShape.circle,
              ),
              // Ajout d'indicateurs personnalisés via Builders, on laisse vide ici
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              formatButtonTextStyle: TextStyle(color: Colors.white),
              formatButtonDecoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final inMandate = _isDayInMandate(day);
                return Container(
                  margin: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: inMandate ? const Color(0xFF34C98B).withOpacity(0.12) : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _getMandateForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    for (var m in _mandats) {
      final sData = DateTime.parse(m['date_debut']);
      final start = DateTime(sData.year, sData.month, sData.day);
      
      DateTime? end;
      if (m['date_fin'] != null) {
        final eData = DateTime.parse(m['date_fin']);
        end = DateTime(eData.year, eData.month, eData.day);
      }
      
      if ((d.isAtSameMomentAs(start) || d.isAfter(start))) {
        if (end == null || d.isAtSameMomentAs(end) || d.isBefore(end)) {
          return m;
        }
      }
    }
    return null;
  }

  Widget _buildDayDetails() {
    if (_selectedDay == null) return const SizedBox();
    
    final events = _getEventsForDay(_selectedDay!);
    final currentMandate = _getMandateForDay(_selectedDay!);
    final inMandate = currentMandate != null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDay!),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (inMandate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C98B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF34C98B).withOpacity(0.5)),
                ),
                child: const Text('Mandat Actif', 
                  style: TextStyle(color: Color(0xFF34C98B), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        if (inMandate)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: Colors.white38, size: 12),
                const SizedBox(width: 6),
                Text(
                  "Mandat : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(currentMandate['date_debut']))} → ${currentMandate['date_fin'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(currentMandate['date_fin'])) : 'En cours'}",
                  style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (events.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text('Aucun événement pour ce jour', 
                style: TextStyle(color: Colors.white38, fontSize: 14)),
            ),
          )
        else
          ...events.map((e) {
            if (e is ReunionModel) {
              return _buildMeetingCard(e);
            } else if (e is Map && e['type'] == 'note') {
              return _buildNoteCard(e['content']);
            }
            return const SizedBox();
          }),
      ],
    );
  }

  Widget _buildMeetingCard(ReunionModel reunion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4B6BFB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4B6BFB).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4B6BFB).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF4B6BFB), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reunion.titre, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white54, size: 12),
                    const SizedBox(width: 4),
                    Text(reunion.heureFormatee, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, color: Colors.white54, size: 12),
                    const SizedBox(width: 4),
                    Text(reunion.lieu, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8603C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8603C).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8603C).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.note_rounded, color: Color(0xFFE8603C), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ma Note', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(content, 
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
            onPressed: () {
              setState(() {
                final normalizedDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
                _userNotes.remove(normalizedDay);
              });
              _saveNotes();
            },
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    final controller = TextEditingController();
    final normalizedDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    if (_userNotes.containsKey(normalizedDay)) {
      controller.text = _userNotes[normalizedDay]!;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter une note', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Saisissez votre note ici...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _userNotes[normalizedDay] = controller.text;
                });
                _saveNotes();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8603C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
