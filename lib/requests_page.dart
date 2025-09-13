import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/requests/presentation/pages/driver_request_page.dart';
import 'package:hop_eir/features/requests/presentation/pages/sent_request_page.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final LinearGradient gradient = const LinearGradient(
    colors: [Color(0xFF213693), Colors.tealAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final Color darkBlue = const Color(0xFF213693);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromRGBO(137, 177, 98, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Text(
                    "Requests",
                    style: GoogleFonts.luckiestGuy(
                      fontWeight: FontWeight.w300,
                      fontSize: 28,
                      color: primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton(
                      onPressed: () {
                        // _logout();
                      },
                      icon: const Icon(
                        FontAwesomeIcons.signOut,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                'View and manage your ride requests',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: darkBlue.withOpacity(0.065),
                ),
                labelPadding: const EdgeInsets.symmetric(vertical: 12),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: List.generate(2, (index) {
                  final label = index == 0 ? 'Received' : 'Sent';
                  final selected = _selectedIndex == index;

                  return Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return (selected
                                ? gradient
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.shade600,
                                      Colors.grey.shade600,
                                    ],
                                  ))
                            .createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        );
                      },
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // Needed for ShaderMask
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [ReceivedRequestsPage(), SentRequestsPage()],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
