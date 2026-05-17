import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../widgets/journal_dialog.dart';
import 'calendar_screen.dart';
import 'responsibility_grid_screen.dart';
import 'residents_panel.dart';
import '../widgets/room_ledger.dart';
import '../widgets/discoveries_content.dart';
import '../widgets/agreements_content.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1612),
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.7),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
            onPressed: () => Navigator.pop(context),
          ),
          title: TabBar(
            isScrollable: true,
            indicatorColor: const Color(0xFFC4B89B),
            labelColor: const Color(0xFFE5D5B0),
            unselectedLabelColor: Colors.white24,
            labelStyle: GoogleFonts.playfairDisplay(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            tabs: const [
              Tab(text: "JOURNAL"),
              Tab(text: "LOG"),
              Tab(text: "SCHEDULE"),
              Tab(text: "RESPONSIBILITIES"),
              Tab(text: "DOSSIERS"),
              Tab(text: "HOLDINGS"),
              Tab(text: "DISCOVERIES"),
              Tab(text: "AGREEMENTS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Master's Journal
            _buildJournalTab(context),
            // 2. Chronicle of Events
            _buildChronicleOfEventsTab(context),
            // 3. Chronicle of Time
            const CalendarScreen(isTab: true),
            // 4. Responsibility Assignment
            const ResponsibilityGridScreen(isTab: true),
            // 5. Residents
            const ResidentsPanel(isTab: true),
            // 6. Manor Holdings
            _buildManorHoldingsTab(context),
            // 7. Discoveries
            _buildDiscoveriesTab(context),
            // 8. Agreements
            _buildAgreementsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalTab(BuildContext context) {
    return Container(
      color: const Color(0xFF241F1A),
      padding: const EdgeInsets.all(24.0),
      child: JournalContent(), // Reusing JournalDialog's internal or we use the dialog widget itself
    );
  }

  Widget _buildChronicleOfEventsTab(BuildContext context) {
    final state = Provider.of<GameState>(context);
    return Container(
      color: const Color(0xFF241F1A),
      padding: const EdgeInsets.all(24.0),
      child: state.announcementHistory.isEmpty
          ? Center(
              child: Text(
                'The journals are empty.',
                style: GoogleFonts.outfit(color: Colors.white24),
              ),
            )
          : ListView.builder(
              itemCount: state.announcementHistory.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    state.announcementHistory[index].toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFC4B89B),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildManorHoldingsTab(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final roomsWithContent = state.rooms.where((r) {
      final ledger = RoomLedger(room: r, state: state);
      return ledger.getLedgerItems().isNotEmpty;
    }).toList();

    return Container(
      color: const Color(0xFF241F1A),
      padding: const EdgeInsets.all(24.0),
      child: (roomsWithContent.isEmpty && state.chickens.isEmpty)
          ? Center(
              child: Text(
                'No items possessed.',
                style: GoogleFonts.oldStandardTt(color: Colors.white24),
              ),
            )
          : ListView.separated(
              separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 32),
              itemCount: roomsWithContent.length,
              itemBuilder: (context, index) {
                final room = roomsWithContent[index];
                final ledgerWidget = RoomLedger(room: room, state: state);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                      child: Text(
                        room.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFC4B89B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    ledgerWidget,
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDiscoveriesTab(BuildContext context) {
    return Container(
      color: const Color(0xFF241F1A),
      padding: const EdgeInsets.all(24.0),
      child: const DiscoveriesContent(),
    );
  }

  Widget _buildAgreementsTab(BuildContext context) {
    return Container(
      color: const Color(0xFF241F1A),
      padding: const EdgeInsets.all(24.0),
      child: const AgreementsContent(),
    );
  }
}
