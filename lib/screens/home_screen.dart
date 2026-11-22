import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../app_state.dart';
import 'advanced_features_screen.dart';
import '../l10n/app_localizations.dart';
import 'members_screen.dart';
import 'add_member_screen.dart';
import 'more_screen.dart';
import 'add_transaction_screen.dart';
import 'collection_screen.dart';
import 'constitution_screen.dart';
import 'late_fee_screen.dart';
import 'meeting_screen.dart';
import 'due_list_screen.dart';
import 'report_screen.dart';
import 'transaction_list_screen.dart';
import 'investment_screen.dart';
import 'installment_product_screen.dart';
import 'committee_screen.dart';
import 'notice_screen.dart';
import 'bank_screen.dart';
import 'app_settings_screen.dart';
import 'entrepreneur_settings_screen.dart';
import 'video_tutorial_screen.dart';
import 'guide_screen.dart';
import 'transaction_history_screen.dart';
import 'financial_management_screen.dart';
import 'loss_project_screen.dart';
import '../services/loss_project_service.dart';
import 'pledge_documents_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final GlobalKey<HomeContentState> _homeKey =
      GlobalKey<HomeContentState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeContent(key: _homeKey),
      const MembersScreen(),
      const CollectionScreen(),
      const ReportScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF142F52),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "বিনিয়োগ উদ্যোক্তা",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "সব হিসাব এক অ্যাপে",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF142F52)),
              title: const Text("আর্থিক ব্যবস্থাপনা"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (c) => const FinancialManagementScreen()));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: Color(0xFF142F52),
              ),
              title: const Text("সভা (মিটিং)"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const MeetingScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.money_off,
                color: Colors.red,
              ),
              title: const Text("বিলম্ব ফী"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const LateFeeScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Color(0xFFD0A522)),
              title: const Text("অঙ্গীকারনামা"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (c) => const PledgeDocumentsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.menu_book,
                color: Colors.blue,
              ),
              title: const Text("গঠনতন্ত্র"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const ConstitutionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        // IndexedStack keeps each tab alive; switching tabs no longer
        // destroys its State or triggers initState/API reloads.
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == _selectedIndex) return;
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: AppLocalizations.of(context).home),
          NavigationDestination(icon: const Icon(Icons.people_outline), selectedIcon: const Icon(Icons.people_rounded), label: AppLocalizations.of(context).members),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet), label: AppLocalizations.of(context).collection),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: AppLocalizations.of(context).reports),
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: AppLocalizations.of(context).more),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  String userName = "Admin";
  String userRole = "Member";

  bool _isLoadingStats = true;
  bool _isBalanceVisible = false;

  double totalAssets = 0.0;

  Timer? _balanceTimer;

  String _profilePicUrl = '';
  String _userPhone = '';

  double cashInHand = 0.0;
  double todayDeposit = 0.0;
  double todayExpense = 0.0;
  double thisMonthCollection = 0.0;

  int totalTransactions = 0;
  int pendingMembersCount = 0;

  List<dynamic> recentTransactions = [];

  List<dynamic> recentInvestments = [];

  // Admin Permission Check
  bool get isAdmin =>
      userRole.trim().toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _loadUser();
    fetchDashboardData();
  }

  @override
  void dispose() {
    _balanceTimer?.cancel();
    super.dispose();
  }

  void _loadUser() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userName = prefs.getString('userName') ?? "User";
      userRole = prefs.getString('userRole') ?? "Member";
      _userPhone = prefs.getString('userPhone') ?? '';
      _profilePicUrl = prefs.getString('userPic') ?? '';
    });
    _refreshOwnProfilePhoto();
  }

  Future<void> _refreshOwnProfilePhoto() async {
    if (_userPhone.isEmpty) return;
    try {
      final result = await ApiService.getAllMembers();
      if (result is! List) return;
      String clean(String v) => v.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^880'), '').replaceFirst(RegExp(r'^0'), '');
      final me = result.cast<dynamic>().whereType<Map>().firstWhere((m) => clean('${m['Phone'] ?? ''}') == clean(_userPhone), orElse: () => <String,dynamic>{});
      final url = (me['ProfilePicUrl'] ?? '').toString();
      if (url.isNotEmpty && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userPic', url);
        setState(() => _profilePicUrl = url.contains('?') ? '$url&t=${DateTime.now().millisecondsSinceEpoch}' : '$url?t=${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (_) {}
  }

  void _toggleBalance() {
    setState(() => _isBalanceVisible = true);

    _balanceTimer?.cancel();

    _balanceTimer = Timer(
      const Duration(seconds: 3),
      () {
        if (mounted) {
          setState(() => _isBalanceVisible = false);
        }
      },
    );
  }

  String getGreeting() {
    var hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) return "শুভ সকাল";
    if (hour >= 12 && hour < 16) return "শুভ দুপুর";
    if (hour >= 16 && hour < 18) return "শুভ বিকাল";
    if (hour >= 18 && hour < 20) return "শুভ সন্ধ্যা";

    return "শুভ রাত্রি";
  }

  // ================= DASHBOARD DATA =================

  Future<void> fetchDashboardData({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (forceRefresh) {
      ApiService.clearCache();
      setState(() => _isLoadingStats = true);
    } else if (recentTransactions.isEmpty && recentInvestments.isEmpty) {
      setState(() => _isLoadingStats = true);
    }

    try {
      final results = await Future.wait<dynamic>([
        ApiService.getTransactions(),
        ApiService.getAllMembers(),
        ApiService.getInvestments().catchError((_) => null),
        ApiService.getInstallmentData().catchError((_) => null),
        LossProjectService.load(),
      ]);
      final response = results[0];
      final membersRes = results[1];
      final investmentsRes = results[2];
      final installmentRes = results[3];
      final lossRows = results[4] is List ? (results[4] as List).whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];

      if (!mounted) return;

      if (investmentsRes is List) {
        final sortedInvestments = List<dynamic>.from(investmentsRes);
        sortedInvestments.sort((a, b) {
          final da = DateTime.tryParse(a['StartDate']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db = DateTime.tryParse(b['StartDate']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        recentInvestments = sortedInvestments.take(3).toList();
      } else {
        recentInvestments = [];
      }

      if (response is List) {
        double tempCash = 0.0;
        double tempTodayDeposit = 0.0;
        double tempTodayExpense = 0.0;
        double tempMonthCollection = 0.0;

        // শুধু Paid লেনদেন গণনা হবে
        int tempTotalTx = response.where((tx) {
          String status =
              tx['Status']?.toString().trim() ?? 'Paid';
          return status == 'Paid';
        }).length;

        List<dynamic> tempRecent = [];

        double tempTotalAssets = 0.0;

        String todayDate =
            DateFormat('yyyy-MM-dd').format(DateTime.now());

        String currentMonth =
            DateFormat('yyyy-MM').format(DateTime.now());

        List<String> membersWhoPaid = [];

        for (var tx in response) {
          String type = tx['Type'].toString().trim();

          double amount =
              double.tryParse(tx['Amount'].toString()) ?? 0.0;

          String fullDateStr =
              tx['Date'].toString().trim();

          String formattedTxDate =
              fullDateStr.length >= 10
                  ? fullDateStr.substring(0, 10)
                  : fullDateStr;

          String status =
              tx['Status']?.toString().trim() ?? 'Paid';

          String paymentMethod =
              tx['PaymentMethod']?.toString().trim() ??
                  'HAND CASH';

          String txMemberName =
              tx['MemberName'].toString().trim().toLowerCase();

          if (status == 'Paid') {
            if (type == 'জমা' ||
                type == 'আয়' ||
                type == 'বিলম্ব ফী') {
              tempTotalAssets += amount;
            } else if (type == 'বিনিয়োগ' ||
                type == 'খরচ') {
              tempTotalAssets -= amount;
            }
          }

          if (status == 'Paid') {
            if (type == 'জমা' ||
                type == 'আয়' ||
                type == 'বিলম্ব ফী') {
              if (paymentMethod == 'HAND CASH') {
                tempCash += amount;
              }
            } else if (type == 'খরচ') {
              tempCash -= amount;
            }
          }

          if (formattedTxDate == todayDate &&
              status == 'Paid') {
            if (type == 'জমা') {
              tempTodayDeposit += amount;
            }

            if (type == 'খরচ') {
              tempTodayExpense += amount;
            }
          }

          if (formattedTxDate.contains(currentMonth) &&
              type == 'জমা' &&
              status == 'Paid') {
            tempMonthCollection += amount;
            membersWhoPaid.add(txMemberName);
          }
        }

        // কিস্তিতে পণ্যের সম্ভাব্য নিট মুনাফা (মোট মুনাফা - ব্যবসায়িক ব্যয়)
        // এবং লোকাল Loss Project-এর নিট ক্ষতি মোট সম্পদে একবারই সমন্বয় হবে।
        double installmentNetProfit = 0;
        if (installmentRes is Map && installmentRes['error'] == null) {
          final contracts = (installmentRes['contracts'] as List? ?? []);
          final expenses = (installmentRes['expenses'] as List? ?? []);
          final grossProfit = contracts.fold<double>(0, (sum, item) {
            if (item is! Map) return sum;
            final sale = double.tryParse((item['SalePrice'] ?? '0').toString().replaceAll(',', '')) ?? 0;
            final cost = double.tryParse((item['CostPrice'] ?? '0').toString().replaceAll(',', '')) ?? 0;
            return sum + sale - cost;
          });
          final installmentExpenses = expenses.fold<double>(0, (sum, item) {
            if (item is! Map) return sum;
            return sum + (double.tryParse((item['Amount'] ?? '0').toString().replaceAll(',', '')) ?? 0);
          });
          installmentNetProfit = grossProfit - installmentExpenses;
        }
        final localNetLoss = LossProjectService.netLoss(lossRows);
        tempTotalAssets += installmentNetProfit - localNetLoss;

        int tempPendingCount = 0;

        if (membersRes is List) {
          for (var mem in membersRes) {
            String mName =
                mem['Name'].toString().trim().toLowerCase();

            if (mName.isEmpty) continue;

            if (!membersWhoPaid.contains(mName)) {
              tempPendingCount++;
            }
          }
        }

        // 🔥 এখানে আপনার দেওয়া নতুন কোডটি বসানো হয়েছে 🔥
        // শুধুমাত্র Paid (সফল) লেনদেনগুলো ফিল্টার করে সাম্প্রতিক লেনদেন দেখানো হবে
        List<dynamic> paidTransactions = response.where((tx) {
          String status = tx['Status']?.toString().trim() ?? 'Paid';
          return status == 'Paid';
        }).toList();

        if (paidTransactions.length > 5) {
          tempRecent = paidTransactions.sublist(paidTransactions.length - 5).reversed.toList();
        } else {
          tempRecent = paidTransactions.reversed.toList();
        }
        // 🔥 নতুন কোড শেষ 🔥

        setState(() {
          cashInHand = tempCash;
          todayDeposit = tempTodayDeposit;
          todayExpense = tempTodayExpense;
          thisMonthCollection = tempMonthCollection;
          totalTransactions = tempTotalTx;
          pendingMembersCount = tempPendingCount;
          recentTransactions = tempRecent;
          totalAssets = tempTotalAssets;
          _isLoadingStats = false;
        });
      } else {
        setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }

      debugPrint("Dashboard Error: $e");
    }
  }

  Widget _buildRecentInvestments(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF183153);
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2EAF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF142F52), size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "সাম্প্রতিক বিনিয়োগ",
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvestmentScreen(userRole: userRole),
                    ),
                  );
                },
                child: const Text("সব দেখুন"),
              ),
            ],
          ),
          if (_isLoadingStats && recentInvestments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (recentInvestments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "এখনো কোনো বিনিয়োগের তথ্য পাওয়া যায়নি",
                style: TextStyle(color: mutedColor, fontSize: 13),
              ),
            )
          else
            ...recentInvestments.map((investment) {
              final project = investment['ProjectName']?.toString() ?? 'নাম উল্লেখ নেই';
              final sector = investment['Sector']?.toString() ?? '';
              final amount = investment['InvestAmount']?.toString() ?? '0';
              final status = investment['Status']?.toString() ?? 'অজানা';
              final isActive = status == 'সক্রিয়';
              return Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Row(
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF142F52).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF142F52),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (sector.isNotEmpty)
                            Text(
                              sector,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: mutedColor, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "৳ $amount",
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            color: isActive ? Colors.green : mutedColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => fetchDashboardData(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. টপ বার

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 48, height: 48,
                    child: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Color(0xFF142F52),
                        size: 30,
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )),

                  GestureDetector(
                    onTap: _toggleBalance,
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isBalanceVisible
                            ? Colors.white
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: _isBalanceVisible
                            ? [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                )
                              ]
                            : [],
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "মোট সম্পদ",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isBalanceVisible
                                  ? const Color(0xFF142F52)
                                  : Colors.black54,
                            ),
                          ),
                          if (_isBalanceVisible) ...[
                            const SizedBox(height: 4),
                            Text(
                              "৳ ${totalAssets.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 48, height: 48,
                    child: IconButton(
                      tooltip: 'Smart Search',
                      icon: const Icon(Icons.search_rounded, color: Color(0xFF142F52), size: 28),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartSearchScreen())),
                    ),
                  ),
                  SizedBox(
                    width: 48, height: 48,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (c) => const MoreScreen())); await _refreshOwnProfilePhoto(); },
                      child: CircleAvatar(
                        radius: 20, backgroundColor: const Color(0xFF142F52),
                        backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : null,
                        child: _profilePicUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 23) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // সাম্প্রতিক বিনিয়োগ
            _buildRecentInvestments(isDark),

            const SizedBox(height: 12),

            // ৪. বকেয়া বক্স

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const DueListScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_clock,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "সদস্য যাদের জমা বকেয়া আছে",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "এই মাসে $pendingMembersCount জন জমা দেননি। দেখতে ট্যাপ করুন।",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            // ৫. শুভেচ্ছা

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Text(
                    "${getGreeting()}, ",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "$userName ",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "বিনিয়োগ উদ্যোক্তা",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ৬. চারটি কার্ড

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              child: _isLoadingStats
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            "হাতে নগদ",
                            "৳ ${cashInHand.toStringAsFixed(0)}",
                            Icons.account_balance_wallet,
                            Colors.blue,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            "আজকের জমা",
                            "৳ ${todayDeposit.toStringAsFixed(0)}",
                            Icons.arrow_downward,
                            Colors.green,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            "আজকের খরচ",
                            "৳ ${todayExpense.toStringAsFixed(0)}",
                            Icons.arrow_upward,
                            Colors.orange,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) =>
                                      const TransactionHistoryScreen(),
                                ),
                              );
                            },
                            child: _buildInfoCard(
                              "সব লেনদেন",
                              "$totalTransactions টি",
                              Icons.receipt_long,
                              Colors.red,
                              isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // ৭. চারটি অ্যাকশন বাটন

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _buildActionButton(
                    context,
                    "জমা",
                    Icons.money,
                    const Color(0xFF43A047),
                    "জমা",
                  ),
                  _buildActionButton(
                    context,
                    "খরচ",
                    Icons.shopping_bag,
                    const Color(0xFFE53935),
                    "খরচ",
                  ),
                  _buildActionButton(
                    context,
                    "আয়",
                    Icons.savings,
                    const Color(0xFF00897B),
                    "আয়",
                  ),
                  _buildActionButton(
                    context,
                    "বিনিয়োগ",
                    Icons.menu_book,
                    const Color(0xFF8E24AA),
                    "বিনিয়োগ",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ৮. মডিউল ও ফিচার

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "মডিউল ও ফিচার",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1,
                children: [
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const MembersScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(15),
                    child: _buildModuleIcon(
                      Icons.people,
                      "সদস্য",
                      Colors.blue,
                      isDark,
                    ),
                  ),

                  // শুধু Admin সদস্য যোগ করতে পারবে।

                  if (isAdmin)
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) =>
                              const AddMemberScreen(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(15),
                      child: _buildModuleIcon(
                        Icons.person_add,
                        "সদস্য যোগ",
                        Colors.green,
                        isDark,
                      ),
                    ),

                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) =>
                            CommitteeScreen(userRole: userRole),
                      ),
                    ),
                    child: _buildModuleIcon(
                      Icons.group,
                      "কমিটি",
                      Colors.orange,
                      isDark,
                    ),
                  ),

                  _buildModuleIcon(
                    Icons.assignment_ind,
                    "দায়িত্ব",
                    Colors.purple,
                    isDark,
                  ),

                  _buildModuleIcon(
                    Icons.pie_chart,
                    "শেয়ার",
                    Colors.deepPurple,
                    isDark,
                  ),

                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const ReportScreen(),
                      ),
                    ),
                    child: _buildModuleIcon(
                      Icons.bar_chart,
                      "রিপোর্ট",
                      Colors.indigo,
                      isDark,
                    ),
                  ),

                  InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (c) => InstallmentProductScreen(userRole: userRole)));
                      if (mounted) fetchDashboardData(forceRefresh: true);
                    },
                    child: _buildModuleIcon(
                      Icons.account_balance_wallet,
                      "কিস্তিতে পণ্য",
                      Colors.blueAccent,
                      isDark,
                    ),
                  ),

                  InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LossProjectScreen()));
                      if (mounted) fetchDashboardData(forceRefresh: true);
                    },
                    child: _buildModuleIcon(Icons.trending_down, 'লস প্রজেক্ট', Colors.redAccent, isDark),
                  ),

                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const BankScreen(),
                      ),
                    ),
                    child: _buildModuleIcon(
                      Icons.account_balance,
                      "ব্যাংক",
                      Colors.lightBlue,
                      isDark,
                    ),
                  ),

                  _buildModuleIcon(
                    Icons.receipt,
                    "ভাউচার",
                    Colors.blue,
                    isDark,
                  ),

                  _buildModuleIcon(
                    Icons.fact_check,
                    "অনুমোদন",
                    Colors.green,
                    isDark,
                  ),

                  _buildModuleIcon(
                    Icons.point_of_sale,
                    "ক্যাশ ক্রজিং",
                    Colors.orange,
                    isDark,
                  ),

                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const NoticeScreen(),
                      ),
                    ),
                    child: _buildModuleIcon(
                      Icons.campaign,
                      "নোটিশ",
                      Colors.deepOrange,
                      isDark,
                    ),
                  ),

                  _buildModuleIcon(
                    Icons.inventory,
                    "স্টক",
                    Colors.purple,
                    isDark,
                  ),

                  _buildModuleIcon(
                    Icons.people_outline,
                    "পরিচালক",
                    Colors.blue,
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ৯. সাম্প্রতিক লেনদেন

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "সাম্প্রতিক লেনদেন",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              child: recentTransactions.isEmpty
                  ? const Center(
                      child: Text("কোনো লেনদেন নেই"),
                    )
                  : Column(
                      children:
                          recentTransactions.map((tx) {
                        bool isDeposit =
                            tx['Type'] == 'জমা';

                        return Card(
                          color: isDark
                              ? Colors.grey[800]
                              : Colors.white,
                          margin: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDeposit
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              child: Icon(
                                isDeposit
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isDeposit
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Text(
                              tx['Type'].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDeposit
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              "${tx['MemberName']} | ${tx['Date'].toString().split(' ')[0]}",
                            ),
                            trailing: Text(
                              "৳ ${tx['Amount']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDeposit
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 30),

            // SMS

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "SMS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _buildSmsIcon(
                    Icons.sms,
                    "SMS ক্রেডিট",
                    const Color(0xFF43A047),
                  ),
                  _buildSmsIcon(
                    Icons.chat_bubble_outline,
                    "SMS টেম্পলেট",
                    Colors.blue,
                  ),
                  _buildSmsIcon(
                    Icons.campaign,
                    "বাংক SMS",
                    Colors.orange,
                  ),
                  _buildSmsIcon(
                    Icons.history,
                    "SMS ইতিহাস",
                    const Color(0xFF142F52),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // চার্ট ও বিশ্লেষণ

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "চার্ট ও বিশ্লেষণ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.show_chart,
                              color: Color(0xFF142F52),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "আদায় প্রবণতা",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF142F52),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "৭ দিন",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "৩০ দিন",
                                style: TextStyle(
                                  color: Color(0xFF142F52),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "এই মাসের মোট আদায়",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "৳ ${thisMonthCollection.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.greenAccent
                                  : const Color(0xFF142F52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // সেটিংস, শেখা ও সাহায্য

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "সেটিংস, শেখা ও সাহায্য",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSettingsCard(
                      Icons.settings,
                      "অ্যাপ সেটিংস",
                      "শব্দ ও কম্পন",
                      const Color(0xFF142F52),
                      isDark,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                const AppSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildSettingsCard(
                      Icons.settings_suggest,
                      "উদ্যোক্তা সেটিংস",
                      "ভাষা, দশমিক ও নিয়ম",
                      Colors.green,
                      isDark,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                const EntrepreneurSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSettingsCard(
                      Icons.play_circle_fill,
                      "ভিডিও টিউটোরিয়াল",
                      "দেখে দেখে শিখুন",
                      Colors.red,
                      isDark,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                const VideoTutorialScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildSettingsCard(
                      Icons.menu_book,
                      "নির্দেশিকা",
                      "প্রতিটি পাতার ম্যানুয়াল",
                      Colors.orange,
                      isDark,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                const GuideScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ভাষা পরিবর্তন

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.translate,
                      color: Color(0xFF142F52),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        "অ্যাপের ভাষা",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<Locale>(
                      valueListenable: localeNotifier,
                      builder: (context, locale, _) => SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'bn', label: Text('বাংলা')),
                          ButtonSegment(value: 'en', label: Text('English')),
                        ],
                        selected: {locale.languageCode},
                        onSelectionChanged: (values) async {
                          final value = values.first;
                          localeNotifier.value = Locale(value);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('app_language', value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= কাস্টম উইজেটসমূহ =================

  Widget _buildInfoCard(
    String title,
    String amount,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? Colors.white70
                    : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String type,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          if (type == "বিনিয়োগ") {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => InvestmentScreen(
                  userRole: userRole,
                ),
              ),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => TransactionListScreen(
                  type: type,
                  userRole: userRole,
                ),
              ),
            );
          }

          // Successful POST operations invalidate the shared API cache.
          // Re-entering the dashboard can reuse cached data without a spinner.
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 5),
              FittedBox(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleIcon(
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsIcon(
    IconData icon,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}