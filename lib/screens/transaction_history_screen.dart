
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const Color primaryPurple = Color(0xFF6515E8);
  static const Color deepPurple = Color(0xFF4510C8);
  static const Color navy = Color(0xFF171B50);
  static const Color pageBackground = Color(0xFFF8F6FF);

  List<dynamic> allTransactions = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final res = await ApiService.getTransactions();

      if (!mounted) return;

      setState(() {
        if (res is List) {
          allTransactions = res.reversed.toList();
        }
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<dynamic> get filteredTransactions {
    if (searchQuery.trim().isEmpty) return allTransactions;

    final query = searchQuery.toLowerCase().trim();

    return allTransactions.where((tx) {
      final type = (tx['Type'] ?? '').toString().toLowerCase();
      final member = (tx['MemberName'] ?? '').toString().toLowerCase();
      final note = (tx['Note'] ?? '').toString().toLowerCase();
      final date = (tx['Date'] ?? '').toString().toLowerCase();
      final amount = (tx['Amount'] ?? '').toString().toLowerCase();

      return type.contains(query) ||
          member.contains(query) ||
          note.contains(query) ||
          date.contains(query) ||
          amount.contains(query);
    }).toList();
  }

  double _amountOf(dynamic tx) {
    final value = (tx['Amount'] ?? '0')
        .toString()
        .replaceAll(',', '')
        .replaceAll('৳', '')
        .trim();

    return double.tryParse(value) ?? 0;
  }

  String _money(double amount) {
    final rounded = amount.round().toString();
    final result = StringBuffer();

    for (int i = 0; i < rounded.length; i++) {
      result.write(rounded[i]);

      final remaining = rounded.length - i - 1;
      if (remaining > 0 && remaining % 2 == 0 && remaining != 2) {
        result.write(',');
      }
    }

    return '৳ ${result.toString()}';
  }

  bool _isPaid(dynamic tx) {
    return (tx['Status'] ?? 'Paid').toString() == 'Paid';
  }

  double get totalAmount =>
      allTransactions.fold(0, (sum, tx) => sum + _amountOf(tx));

  double get paidAmount => allTransactions
      .where(_isPaid)
      .fold(0, (sum, tx) => sum + _amountOf(tx));

  double get pendingAmount => allTransactions
      .where((tx) => !_isPaid(tx))
      .fold(0, (sum, tx) => sum + _amountOf(tx));

  Color _typeColor(String type) {
    switch (type) {
      case 'জমা':
      case 'আয়':
        return const Color(0xFF079B70);
      case 'বিনিয়োগ':
        return const Color(0xFF6415E8);
      case 'বিলম্ব ফী':
        return const Color(0xFFE58A12);
      default:
        return const Color(0xFF3155D9);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'জমা':
        return Icons.south_west_rounded;
      case 'আয়':
        return Icons.trending_up_rounded;
      case 'বিনিয়োগ':
        return Icons.account_balance_wallet_rounded;
      case 'বিলম্ব ফী':
        return Icons.warning_amber_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF22233A) : Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: primaryPurple.withOpacity(0.13),
          ),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionCard(dynamic tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final type = (tx['Type'] ?? 'লেনদেন').toString();
    final member = (tx['MemberName'] ?? 'অজানা সদস্য').toString();
    final note = (tx['Note'] ?? '').toString();
    final date = (tx['Date'] ?? '').toString().split(' ')[0];
    final status = (tx['Status'] ?? 'Paid').toString();

    final paid = _isPaid(tx);
    final color = _typeColor(type);
    final icon = _typeIcon(type);
    final amount = (tx['Amount'] ?? '0').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22233A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryPurple.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.055),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 51,
                width: 51,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      member,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳ $amount',
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: paid
                          ? const Color(0xFF0BA875).withOpacity(0.11)
                          : const Color(0xFFE99519).withOpacity(0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      paid ? 'পরিশোধিত' : status == 'Paid' ? 'বকেয়া' : status,
                      style: TextStyle(
                        color: paid
                            ? const Color(0xFF079B70)
                            : const Color(0xFFD68A16),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.045)
                    : const Color(0xFFF7F5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    color: primaryPurple.withOpacity(0.8),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : navy,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : const Color(0xFFECE8F7),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 17,
                color: primaryPurple.withOpacity(0.8),
              ),
              const SizedBox(width: 7),
              Text(
                date.isEmpty ? 'তারিখ নেই' : date,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.blueGrey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: primaryPurple.withOpacity(0.7),
              ),
              const SizedBox(width: 5),
              Text(
                'লেনদেন',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.blueGrey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 55,
                color: primaryPurple,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              searchQuery.isEmpty
                  ? 'কোনো লেনদেন পাওয়া যায়নি!'
                  : 'কোনো মিল পাওয়া যায়নি!',
              style: TextStyle(
                color: isDark ? Colors.white : navy,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              searchQuery.isEmpty
                  ? 'নতুন লেনদেন যোগ হলে এখানে দেখা যাবে।'
                  : 'অন্য নামে বা তথ্য দিয়ে খুঁজে দেখুন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.blueGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = filteredTransactions;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF151525) : pageBackground,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: primaryPurple,
        toolbarHeight: 76,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'বিনিয়োগ উদ্যোক্তা',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'সাম্প্রতিক লেনদেন',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4B12D9),
                Color(0xFF7519F4),
                Color(0xFFB02DEB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'রিফ্রেশ',
            icon: const Icon(Icons.refresh_rounded, size: 27),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryPurple,
              ),
            )
          : RefreshIndicator(
              color: primaryPurple,
              onRefresh: _fetchData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3510C9),
                              Color(0xFF7118E8),
                              Color(0xFFC12CEB),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -5,
                              top: -5,
                              child: Icon(
                                Icons.trending_up_rounded,
                                size: 105,
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white70,
                                      size: 22,
                                    ),
                                    SizedBox(width: 9),
                                    Text(
                                      'মোট লেনদেন',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _money(totalAmount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.30),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_rounded,
                                      color: Colors.white70,
                                      size: 23,
                                    ),
                                    const SizedBox(width: 9),
                                    Text(
                                      'মোট ${allTransactions.length} টি লেনদেন',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF38E4A3),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'হিসাব',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                      child: Row(
                        children: [
                          _summaryCard(
                            title: 'পরিশোধিত',
                            amount: _money(paidAmount),
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFF079B70),
                          ),
                          const SizedBox(width: 9),
                          _summaryCard(
                            title: 'বকেয়া',
                            amount: _money(pendingAmount),
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFE34A4A),
                          ),
                          const SizedBox(width: 9),
                          _summaryCard(
                            title: 'মোট সংখ্যা',
                            amount: '${allTransactions.length} টি',
                            icon: Icons.receipt_long_rounded,
                            color: primaryPurple,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
                      child: TextField(
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : navy,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'সদস্য, ধরন বা তারিখ দিয়ে খুঁজুন...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.blueGrey.shade400,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: primaryPurple,
                            size: 25,
                          ),
                          filled: true,
                          fillColor:
                              isDark ? const Color(0xFF22233A) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide(
                              color: primaryPurple.withOpacity(0.13),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: primaryPurple,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 13),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            color: primaryPurple,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'সব লেনদেনের হিস্ট্রি',
                            style: TextStyle(
                              color: isDark ? Colors.white : navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryPurple.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${transactions.length} টি',
                              style: const TextStyle(
                                color: primaryPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (transactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _emptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 25),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _transactionCard(transactions[index]);
                          },
                          childCount: transactions.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
