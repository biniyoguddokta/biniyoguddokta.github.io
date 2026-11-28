
import 'package:flutter/material.dart';

import '../controllers/stock_controller.dart';
import '../models/stock_model.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final StockController _controller = StockController();

  static const Color _navy = Color(0xFF142B4A);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFFF4F7FB);
  static const Color _green = Color(0xFF0F9D75);
  static const Color _orange = Color(0xFFE58A20);
  static const Color _red = Color(0xFFD9485F);

  String _search = '';
  String _category = 'সব';
  String _location = 'সব';
  String _report = 'Stock valuation';
  bool _alertsOnly = false;

  List<StockItem> get _items =>
      _controller.items.where((e) => !e.isArchived).toList();

  List<StockTransaction> get _transactions => _controller.transactions;
  List<StockExpense> get _expenses => _controller.expenses;
  List<StockParty> get _parties => _controller.parties;
  List<StockLocation> get _locations => _controller.locations;
  List<StockAuditLog> get _audit => _controller.auditLogs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _controller.addListener(_onControllerChanged);
    _loadData();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData({bool refresh = false}) async {
    await _controller.load(forceRefresh: refresh);
    if (!mounted) return;
    if (_controller.errorMessage != null) {
      _snack(_controller.errorMessage!);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save(Future<bool> Function() action) async {
    final success = await action();
    if (!mounted) return;
    if (success) {
      _snack('সফলভাবে সংরক্ষণ হয়েছে');
    } else {
      _snack(_controller.errorMessage ?? 'সংরক্ষণ করা যায়নি');
    }
  }

  double get _stockValue => _controller.totalStockValue;
  double get _salesValue => _controller.expectedSalesValue;
  double get _profit => _controller.expectedGrossProfit;
  int get _lowStock => _controller.lowStockCount;
  int get _expiring => _controller.expiringSoonCount;

  List<StockItem> get _filteredItems {
    final query = _search.toLowerCase();
    return _items.where((item) {
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query) ||
          item.batchNumber.toLowerCase().contains(query) ||
          item.barcode.toLowerCase().contains(query);

      final matchesCategory =
          _category == 'সব' || item.category == _category;
      final matchesLocation =
          _location == 'সব' || item.warehouseName == _location;
      final matchesAlert = !_alertsOnly ||
          item.isLowStock ||
          item.damagedQuantity > 0 ||
          item.isExpiringSoon;

      return matchesSearch &&
          matchesCategory &&
          matchesLocation &&
          matchesAlert;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Stock Business',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _controller.isLoading
                ? null
                : () => _loadData(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Alerts',
            onPressed: () {
              setState(() => _alertsOnly = !_alertsOnly);
              _tabs.animateTo(2);
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (_lowStock + _expiring > 0)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: _red,
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: _blue,
          unselectedLabelColor: Colors.blueGrey,
          indicatorColor: _blue,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Inventory'),
            Tab(text: 'Alerts'),
            Tab(text: 'Purchase'),
            Tab(text: 'Sales'),
            Tab(text: 'Expenses'),
            Tab(text: 'Reports'),
            Tab(text: 'More'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_controller.isLoading) const LinearProgressIndicator(),
          if (_controller.errorMessage != null)
            MaterialBanner(
              content: Text(_controller.errorMessage!),
              leading: const Icon(Icons.error_outline, color: _red),
              actions: [
                TextButton(
                  onPressed: () => _loadData(refresh: true),
                  child: const Text('আবার চেষ্টা'),
                ),
                TextButton(
                  onPressed: _controller.clearError,
                  child: const Text('বন্ধ'),
                ),
              ],
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _dashboard(),
                _inventory(),
                _alerts(),
                _purchasePage(),
                _salesPage(),
                _expensesPage(),
                _reportsPage(),
                _morePage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        onPressed: _quickAdd,
        icon: const Icon(Icons.add),
        label: const Text('নতুন এন্ট্রি'),
      ),
    );
  }

  Widget _dashboard() {
    return RefreshIndicator(
      onRefresh: () => _loadData(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_navy, Color(0xFF285A91)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ব্যবসার স্টক সারসংক্ষেপ',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '৳${_money(_stockValue)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'বর্তমান মজুদের ক্রয়মূল্য (Landed Cost)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _heroMetric('পণ্য', '${_items.length}'),
                    _heroMetric('সম্ভাব্য বিক্রয়', '৳${_money(_salesValue)}'),
                    _heroMetric('সম্ভাব্য লাভ', '৳${_money(_profit)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _metricCard('কম স্টক', '$_lowStock',
                  Icons.inventory_2_outlined, _orange),
              _metricCard('মেয়াদ শেষের সতর্কতা', '$_expiring',
                  Icons.event_busy_outlined, _red),
              _metricCard('লেনদেন', '${_transactions.length}',
                  Icons.swap_horiz_rounded, _blue),
              _metricCard('লোকেশন', '${_locations.length}',
                  Icons.warehouse_outlined, _green),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('দ্রুত কাজ'),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _actionChip('পণ্য যোগ', Icons.add_box_outlined, _showItemForm),
              _actionChip('ক্রয় এন্ট্রি', Icons.shopping_cart_outlined,
                  () => _tabs.animateTo(3)),
              _actionChip('বিক্রয় এন্ট্রি', Icons.point_of_sale,
                  () => _tabs.animateTo(4)),
              _actionChip('খরচ যোগ', Icons.receipt_long_outlined,
                  _showExpenseForm),
              _actionChip('স্টক ট্রান্সফার', Icons.move_up,
                  _showTransferForm),
              _actionChip('স্টক গণনা', Icons.fact_check_outlined,
                  _showStockCount),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('সাম্প্রতিক স্টক'),
          if (_items.isEmpty)
            _empty('কোনো পণ্য পাওয়া যায়নি')
          else
            ..._items.take(5).map(_itemTile),
          const SizedBox(height: 18),
          _sectionTitle('সাম্প্রতিক কার্যক্রম'),
          if (_audit.isEmpty)
            _empty('এখনো কোনো কার্যক্রম নেই')
          else
            ..._audit.take(5).map(_auditTile),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      );

  Widget _metricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _navy,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _inventory() {
    final items = _filteredItems;
    final categories = _items.map((e) => e.category).toSet().toList();
    final locations = _locations.map((e) => e.name).toSet().toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'পণ্যের নাম, SKU, ID বা Batch খুঁজুন',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _category,
                decoration: _filterDecoration('ক্যাটাগরি'),
                items: ['সব', ...categories]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'সব'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _location,
                decoration: _filterDecoration('লোকেশন'),
                items: ['সব', ...locations]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _location = v ?? 'সব'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '${items.length}টি পণ্য',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showItemForm,
              icon: const Icon(Icons.add),
              label: const Text('পণ্য যোগ'),
            ),
          ],
        ),
        if (items.isEmpty)
          _empty('কোনো পণ্য পাওয়া যায়নি')
        else
          ...items.map(_itemTile),
      ],
    );
  }

  InputDecoration _filterDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _itemTile(StockItem item) {
    final low = item.isLowStock;
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EDF4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showItemDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: _blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    Text(
                      '${item.sku} • ${item.category}',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${item.warehouseName} / ${item.shelf} • Batch: ${item.batchNumber}',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'মজুদ: ${_qty(item.availableQuantity)} ${item.unit} • ৳${_money(item.landedUnitCost)} / ${item.unit}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${_money(item.stockValuation)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _statusPill(
                    low ? 'কম স্টক' : 'সক্রিয়',
                    low ? _orange : _green,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _showItemForm(item: item);
                      if (value == 'archive') _archiveItem(item);
                      if (value == 'move') _showTransferForm(item: item);
                      if (value == 'reserve') _showReservationForm(item);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
                      PopupMenuItem(value: 'move', child: Text('লোকেশন বদল')),
                      PopupMenuItem(value: 'reserve', child: Text('স্টক সংরক্ষণ')),
                      PopupMenuItem(value: 'archive', child: Text('ডিলেট / আর্কাইভ')), 
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alerts() {
    final alerts = _items.where((item) =>
        item.isLowStock || item.damagedQuantity > 0 || item.isExpiringSoon);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('স্টক সতর্কতা ও করণীয়'),
        _metricCard('কম স্টক', '$_lowStock', Icons.trending_down, _orange),
        const SizedBox(height: 8),
        _metricCard('৩০ দিনের মধ্যে মেয়াদ', '$_expiring',
            Icons.hourglass_bottom, _red),
        const SizedBox(height: 12),
        ...alerts.map((item) => Card(
              color: Colors.white,
              child: ListTile(
                leading: Icon(
                  item.isLowStock
                      ? Icons.warning_amber_rounded
                      : Icons.error_outline,
                  color: _orange,
                ),
                title: Text(item.name),
                subtitle: Text(
                  'মজুদ ${_qty(item.availableQuantity)} ${item.unit} • Reorder ${_qty(item.reorderLevel)} • নষ্ট ${_qty(item.damagedQuantity)}',
                ),
                trailing: TextButton(
                  onPressed: () => _showTransactionForm(
                    type: 'Purchase',
                    prefill: item,
                  ),
                  child: const Text('ক্রয়'),
                ),
              ),
            )),
        _sectionTitle('সতর্কতার নিয়ম'),
        _infoCard('Low stock / Reorder',
            'Available stock reorder level-এর সমান বা কম হলে সতর্কতা।'),
        _infoCard('Expiry alert',
            'মেয়াদ শেষ হওয়ার ৩০ দিনের মধ্যে থাকা পণ্য এখানে দেখা যাবে।'),
        _infoCard('Due & payment alert',
            'Supplier due ও customer due-এর হিসাব Reports এবং Party Ledger-এ দেখা যাবে।'),
      ],
    );
  }

  Widget _purchasePage() {
    final purchases =
        _transactions.where((e) => e.type == 'Purchase').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _sectionTitle('ক্রয় ব্যবস্থাপনা'),
        _primaryButton(
          'নতুন ক্রয় এন্ট্রি',
          Icons.add_shopping_cart,
          () => _showTransactionForm(type: 'Purchase'),
        ),
        const SizedBox(height: 12),
        _sectionTitle('ক্রয় ইতিহাস'),
        if (purchases.isEmpty)
          _empty('ক্রয়ের কোনো রেকর্ড নেই')
        else
          ...purchases.map(_transactionTile),
        _sectionTitle('ক্রয় রেকর্ডে সংরক্ষিত তথ্য'),
        _infoCard('Supplier & Invoice',
            'সরবরাহকারীর নাম, ফোন, invoice number এবং purchase date।'),
        _infoCard('Purchase line items',
            'পণ্য, batch/lot, quantity, unit, unit price, subtotal, discount, tax ও total।'),
        _infoCard('Payment & Due',
            'Cash/bank/mobile payment, paid amount, due amount ও partial payment।'),
        _infoCard('Supplier ledger & returns',
            'Supplier-wise ledger, purchase return ও due settlement।'),
      ],
    );
  }

  Widget _salesPage() {
    final sales = _transactions.where((e) => e.type == 'Sale').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _sectionTitle('বিক্রয় ব্যবস্থাপনা'),
        _primaryButton(
          'নতুন বিক্রয় এন্ট্রি',
          Icons.point_of_sale,
          () => _showTransactionForm(type: 'Sale'),
        ),
        const SizedBox(height: 12),
        _sectionTitle('বিক্রয় ইতিহাস'),
        if (sales.isEmpty)
          _empty('বিক্রয়ের কোনো রেকর্ড নেই')
        else
          ...sales.map(_transactionTile),
        _sectionTitle('বিক্রয় রেকর্ডে সংরক্ষিত তথ্য'),
        _infoCard('Customer & Invoice',
            'Customer profile/contact, invoice number, sale date, item/batch/location।'),
        _infoCard('Price & Discount',
            'Quantity, unit price, discount, tax, total এবং price override reason।'),
        _infoCard('Collection & Due',
            'Paid/partial/due, payment method ও collection history।'),
        _infoCard('Returns & Refunds',
            'Sales return, exchange, refund এবং returned quantity-এর হিসাব।'),
      ],
    );
  }

  Widget _expensesPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _sectionTitle('ব্যবসার অতিরিক্ত খরচ'),
        _primaryButton(
          'খরচ যোগ করুন',
          Icons.add_card,
          _showExpenseForm,
        ),
        const SizedBox(height: 8),
        ..._expenses.map((expense) => Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: _orange),
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.category} • ${_date(expense.date)}',
                ),
                trailing: Text(
                  '৳${_money(expense.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )),
        _sectionTitle('খরচের ক্যাটাগরি'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'পরিবহন',
            'লোডিং/আনলোডিং',
            'শ্রমিক',
            'প্যাকেজিং',
            'গুদাম ভাড়া',
            'দোকান ভাড়া',
            'হ্যান্ডলিং',
            'ট্যাক্স/শুল্ক',
            'কমিশন',
            'অন্যান্য',
          ].map((e) => Chip(label: Text(e))).toList(),
        ),
        _infoCard(
          'Landed cost allocation',
          'পরিবহন, শ্রমিক, ভাড়া, প্যাকেজিং, handling, tax ও commission-এর খরচ পণ্য/ব্যাচে বরাদ্দ করার হিসাব রাখা যাবে।',
        ),
      ],
    );
  }

  Widget _reportsPage() {
    final reports = [
      'Stock valuation',
      'Purchase report',
      'Sales report',
      'Actual profit & loss',
      'Expected profit',
      'Warehouse-wise stock',
      'Supplier due',
      'Customer due',
      'Expense & landed cost',
      'Fast / Slow / Dead stock',
      'Damage / Expiry / Adjustment',
      'Payment collection',
    ];

    final totalPurchase = _transactions
        .where((e) => e.type == 'Purchase')
        .fold<double>(0, (sum, e) => sum + e.totalAmount);
    final totalSales = _transactions
        .where((e) => e.type == 'Sale')
        .fold<double>(0, (sum, e) => sum + e.totalAmount);
    final totalExpenses =
        _expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('ব্যবসায়িক রিপোর্ট'),
        DropdownButtonFormField<String>(
          value: _report,
          decoration: _filterDecoration('রিপোর্ট নির্বাচন'),
          items: reports
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _report = v ?? reports.first),
        ),
        const SizedBox(height: 12),
        _infoCard(_report, _reportDescription(_report)),
        _sectionTitle('বর্তমান সারাংশ'),
        _summaryRow('বর্তমান stock landed value', '৳${_money(_stockValue)}'),
        _summaryRow('সম্ভাব্য বিক্রয় মূল্য', '৳${_money(_salesValue)}'),
        _summaryRow('সম্ভাব্য gross profit', '৳${_money(_profit)}'),
        _summaryRow('মোট ক্রয়', '৳${_money(totalPurchase)}'),
        _summaryRow('মোট বিক্রয়', '৳${_money(totalSales)}'),
        _summaryRow('অতিরিক্ত খরচ', '৳${_money(totalExpenses)}'),
        _summaryRow('Supplier due', '৳${_money(_partyDue("Supplier"))}'),
        _summaryRow('Customer due', '৳${_money(_partyDue("Customer"))}'),
        const SizedBox(height: 12),
        _infoCard(
          'Profit calculation',
          'Expected profit = সম্ভাব্য বিক্রয় মূল্য − বর্তমান landed stock cost। Actual profit-এর জন্য বিক্রয়, discount, return, wastage ও expense-এর পূর্ণাঙ্গ হিসাব প্রয়োজন।',
        ),
        _infoCard(
          'Export',
          'PDF/Excel Export-এর জন্য আলাদা Export service প্রয়োজন। বর্তমান StockService-এ Export API নেই।',
        ),
      ],
    );
  }

  double _partyDue(String type) {
    return _parties
        .where((e) => e.type.toLowerCase() == type.toLowerCase())
        .fold<double>(0, (sum, e) => sum + e.currentBalance);
  }

  String _reportDescription(String name) {
    switch (name) {
      case 'Stock valuation':
        return 'পণ্য, batch এবং warehouse অনুযায়ী available quantity × landed unit cost।';
      case 'Actual profit & loss':
        return 'বিক্রিত পণ্যের revenue থেকে landed cost, discount, return ও expense বাদ।';
      case 'Expected profit':
        return 'বর্তমান বিক্রয় মূল্য ও landed cost ধরে সম্ভাব্য gross margin/profit।';
      case 'Fast / Slow / Dead stock':
        return 'বিক্রয়ের frequency ও শেষ বিক্রয়ের তারিখ ধরে stock movement analysis।';
      case 'Supplier due':
        return 'Supplier-wise purchase, payment, return ও outstanding balance।';
      case 'Customer due':
        return 'Customer-wise invoice, collection, return ও due balance।';
      default:
        return 'তারিখ, পণ্য, batch, location, party ও payment status অনুযায়ী রিপোর্ট।';
    }
  }

  Widget _morePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _sectionTitle('অন্যান্য ব্যবস্থাপনা'),
        _menuTile(
          'পণ্য ক্যাটাগরি ও ইউনিট',
          Icons.category_outlined,
          'Category, unit, brand, model, grade ও custom fields',
          onTap: _showItemForm,
        ),
        _menuTile(
          'Warehouse / Shop / Shelf',
          Icons.warehouse_outlined,
          'একাধিক গুদাম, দোকান, room, shelf ও rack',
          onTap: _showLocationForm,
        ),
        _menuTile(
          'লোকেশন ট্রান্সফার',
          Icons.compare_arrows,
          'এক লোকেশন থেকে অন্য লোকেশনে transfer ও movement ledger',
          onTap: _showTransferForm,
        ),
        _menuTile(
          'Stock count & reconciliation',
          Icons.fact_check_outlined,
          'Physical count, variance, adjustment reason ও approval',
          onTap: _showStockCount,
        ),
        _menuTile(
          'Supplier directory',
          Icons.local_shipping_outlined,
          'Supplier contact, ledger, due, purchase & return history',
          onTap: () => _showPartyForm(type: 'Supplier'),
        ),
        _menuTile(
          'Customer directory',
          Icons.people_outline,
          'Customer contact, sales, due, collection & return history',
          onTap: () => _showPartyForm(type: 'Customer'),
        ),
        _menuTile(
          'Adjustment / Damage / Write-off',
          Icons.rule_folder_outlined,
          'Lost, damaged, expired, returned, write-off ও approval',
          onTap: _showAdjustmentForm,
        ),
        _menuTile(
          'Stock reservation',
          Icons.bookmark_border,
          'অর্ডারের জন্য পণ্য সংরক্ষণ ও available quantity নিয়ন্ত্রণ',
          onTap: _showReservationForm,
        ),
        _menuTile(
          'Payment management',
          Icons.payments_outlined,
          'আংশিক/পূর্ণ পেমেন্ট ও collection history',
          onTap: _showPaymentForm,
        ),
        _menuTile(
          'Activity & Audit history',
          Icons.history,
          'Create/edit/archive/approval, actor, time ও reason',
          onTap: _showAudit,
        ),
        _menuTile(
          'Access control & privacy',
          Icons.admin_panel_settings_outlined,
          'Admin full access; staff-এর জন্য permission-based access',
        ),
        _menuTile(
          'Alerts & notification settings',
          Icons.notifications_active_outlined,
          'Low stock, reorder, expiry ও due alert',
          onTap: () => _tabs.animateTo(2),
        ),
        _sectionTitle('Audit history'),
        if (_audit.isEmpty)
          _empty('কোনো audit record নেই')
        else
          ..._audit.take(10).map(_auditTile),
      ],
    );
  }

  Widget _menuTile(
    String title,
    IconData icon,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: _blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? () => _snack('এই কাজের জন্য অতিরিক্ত Backend প্রয়োজন'),
      ),
    );
  }

  Widget _transactionTile(StockTransaction transaction) => Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: transaction.type == 'Purchase'
                ? const Color(0xFFE9F7F1)
                : const Color(0xFFEAF1FF),
            child: Icon(
              transaction.type == 'Purchase'
                  ? Icons.shopping_cart_outlined
                  : Icons.point_of_sale,
              color: transaction.type == 'Purchase' ? _green : _blue,
            ),
          ),
          title: Text(
            '${transaction.type} • ${transaction.partyName}',
          ),
          subtitle: Text(
            '${transaction.referenceNumber} • ${_date(transaction.date)} • ${transaction.paymentStatus}',
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('৳${_money(transaction.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            PopupMenuButton<String>(
              tooltip: 'বিকল্প',
              onSelected: (value) { if (value == 'archive') _archiveStockRecord('transactions', transaction.id, 'লেনদেন ডিলেট/আর্কাইভ'); },
              itemBuilder: (_) => const [PopupMenuItem(value: 'archive', child: Text('ডিলেট / আর্কাইভ'))],
            ),
          ]),
        ),
      );

  Widget _auditTile(StockAuditLog audit) => Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 7),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.history, color: Colors.blueGrey),
          title: Text(
            '${audit.action}: ${audit.entityId}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${audit.reason} • ${audit.actorName}\n${_dateTime(audit.timestamp)}',
          ),
          isThreeLine: true,
        ),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _empty(String text) => Container(
        padding: const EdgeInsets.all(22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.blueGrey)),
      );

  Widget _infoCard(String title, String body) => Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EDF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
                height: 1.45,
              ),
            ),
          ],
        ),
      );

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
          ],
        ),
      );

  Widget _statusPill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _actionChip(String label, IconData icon, VoidCallback action) =>
      ActionChip(
        avatar: Icon(icon, size: 17, color: _blue),
        label: Text(label),
        onPressed: action,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE4EAF2)),
      );

  Widget _primaryButton(
    String label,
    IconData icon,
    VoidCallback action,
  ) =>
      SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: action,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      );

  void _quickAdd() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            _sheetAction('নতুন পণ্য', Icons.inventory_2_outlined, _showItemForm),
            _sheetAction('ক্রয়', Icons.shopping_cart_outlined,
                () => _showTransactionForm(type: 'Purchase')),
            _sheetAction('বিক্রয়', Icons.point_of_sale,
                () => _showTransactionForm(type: 'Sale')),
            _sheetAction('ব্যবসার খরচ', Icons.receipt_long, _showExpenseForm),
            _sheetAction('স্টক ট্রান্সফার', Icons.move_up, _showTransferForm),
            _sheetAction('স্টক সমন্বয়', Icons.tune, _showAdjustmentForm),
          ],
        ),
      ),
    );
  }

  ListTile _sheetAction(
    String title,
    IconData icon,
    VoidCallback action,
  ) =>
      ListTile(
        leading: Icon(icon, color: _blue),
        title: Text(title),
        onTap: () {
          Navigator.pop(context);
          action();
        },
      );

  void _showItemForm({StockItem? item}) {
    final name = TextEditingController(text: item?.name ?? '');
    final sku = TextEditingController(text: item?.sku ?? '');
    final category = TextEditingController(text: item?.category ?? '');
    final unit = TextEditingController(text: item?.unit ?? 'পিস');
    final brand = TextEditingController(text: item?.brand ?? '');
    final model = TextEditingController(text: item?.model ?? '');
    final grade = TextEditingController(text: item?.grade ?? '');
    final batch = TextEditingController(text: item?.batchNumber ?? '');
    final lot = TextEditingController(text: item?.lotNumber ?? '');
    final qty = TextEditingController(text: '${item?.quantity ?? 0}');
    final reserved =
        TextEditingController(text: '${item?.reservedQuantity ?? 0}');
    final damaged =
        TextEditingController(text: '${item?.damagedQuantity ?? 0}');
    final reorder = TextEditingController(text: '${item?.reorderLevel ?? 0}');
    final cost =
        TextEditingController(text: '${item?.landedUnitCost ?? 0}');
    final price =
        TextEditingController(text: '${item?.expectedSalePrice ?? 0}');
    final description =
        TextEditingController(text: item?.description ?? '');
    final warehouse =
        TextEditingController(text: item?.warehouseName ?? '');
    final room = TextEditingController(text: item?.room ?? '');
    final shelf = TextEditingController(text: item?.shelf ?? '');
    final rack = TextEditingController(text: item?.rack ?? '');
    final barcode = TextEditingController(text: item?.barcode ?? '');
    final qr = TextEditingController(text: item?.qrCode ?? '');
    final expiry = TextEditingController(
      text: item?.expiryDate == null ? '' : _date(item!.expiryDate!),
    );
    final warranty = TextEditingController(
      text: item?.warrantyDetails ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'নতুন পণ্য যোগ' : 'পণ্য সম্পাদনা'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _field(name, 'পণ্যের নাম *', required: true),
                  _field(sku, 'SKU / Product Code *', required: true),
                  _field(category, 'ক্যাটাগরি *', required: true),
                  _field(description, 'বিবরণ / নোট', maxLines: 2),
                  _field(unit, 'Unit'),
                  _field(brand, 'Brand'),
                  _field(model, 'Model'),
                  _field(grade, 'Grade / Quality'),
                  _field(batch, 'Batch No.'),
                  _field(lot, 'Lot No.'),
                  _field(barcode, 'Barcode'),
                  _field(qr, 'QR Code'),
                  _field(qty, 'মোট পরিমাণ', number: true),
                  _field(reserved, 'Reserved quantity', number: true),
                  _field(damaged, 'Damaged quantity', number: true),
                  _field(reorder, 'Reorder level', number: true),
                  _field(cost, 'Landed unit cost (৳)', number: true),
                  _field(price, 'Expected sale price (৳)', number: true),
                  _field(warehouse, 'Warehouse / Shop'),
                  _field(room, 'Room'),
                  _field(shelf, 'Shelf'),
                  _field(rack, 'Rack'),
                  _field(expiry, 'Expiry date (YYYY-MM-DD)'),
                  _field(warranty, 'Warranty details'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final record = StockItem(
                id: item?.id ??
                    'STK-${DateTime.now().millisecondsSinceEpoch}',
                name: name.text.trim(),
                sku: sku.text.trim(),
                category: category.text.trim(),
                unit: unit.text.trim(),
                description: description.text.trim(),
                brand: brand.text.trim(),
                model: model.text.trim(),
                grade: grade.text.trim(),
                batchNumber: batch.text.trim(),
                lotNumber: lot.text.trim(),
                barcode: barcode.text.trim(),
                qrCode: qr.text.trim(),
                quantity: _num(qty.text),
                reservedQuantity: _num(reserved.text),
                damagedQuantity: _num(damaged.text),
                reorderLevel: _num(reorder.text),
                landedUnitCost: _num(cost.text),
                expectedSalePrice: _num(price.text),
                purchasePrice: item?.purchasePrice ?? _num(cost.text),
                warehouseName: warehouse.text.trim(),
                room: room.text.trim(),
                shelf: shelf.text.trim(),
                rack: rack.text.trim(),
                expiryDate: DateTime.tryParse(expiry.text),
                warrantyDetails: warranty.text.trim(),
                isActive: true,
                isArchived: false,
                createdAt: item?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              Navigator.pop(ctx);
              await _save(() => _controller.saveItem(record));
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'এই তথ্য প্রয়োজন'
                : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _showItemDetails(StockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('${item.id} • ${item.sku} • ${item.category}'),
              const Divider(),
              _summaryRow(
                'Available stock',
                '${_qty(item.availableQuantity)} ${item.unit}',
              ),
              _summaryRow(
                'Reserved',
                '${_qty(item.reservedQuantity)} ${item.unit}',
              ),
              _summaryRow(
                'Damaged',
                '${_qty(item.damagedQuantity)} ${item.unit}',
              ),
              _summaryRow(
                'Landed unit cost',
                '৳${_money(item.landedUnitCost)}',
              ),
              _summaryRow(
                'Expected sale price',
                '৳${_money(item.expectedSalePrice)}',
              ),
              _summaryRow(
                'Stock valuation',
                '৳${_money(item.stockValuation)}',
              ),
              _summaryRow(
                'Location',
                '${item.warehouseName} / ${item.room} / ${item.shelf} / ${item.rack}',
              ),
              _summaryRow('Batch / Lot', '${item.batchNumber} / ${item.lotNumber}'),
              _summaryRow(
                'Expiry',
                item.expiryDate == null ? 'N/A' : _date(item.expiryDate!),
              ),
              _summaryRow('Barcode / QR', '${item.barcode} / ${item.qrCode}'),
              _summaryRow('Warranty', item.warrantyDetails),
              _summaryRow('Description', item.description),
              const SizedBox(height: 10),
              _primaryButton('সম্পাদনা', Icons.edit, () {
                Navigator.pop(ctx);
                _showItemForm(item: item);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _archiveStockRecord(String entityType, String id, String label) async {
    final reason = await _askText('$label করার কারণ');
    if (reason == null || reason.trim().isEmpty) return;
    await _save(() => _controller.archiveRecord(entityType: entityType, id: id, reason: reason.trim()));
  }

  Future<void> _archiveItem(StockItem item) async {
    final reason = await _askText('পণ্য আর্কাইভের কারণ');
    if (reason == null || reason.trim().isEmpty) return;

    await _save(
      () => _controller.archiveRecord(
        entityType: 'items',
        id: item.id,
        reason: reason.trim(),
      ),
    );
  }

  void _showTransactionForm({
    required String type,
    StockItem? prefill,
  }) {
    final available = _items;
    StockItem? selected = prefill ??
        (available.isEmpty ? null : available.first);
    final party = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final invoice = TextEditingController();
    final qty = TextEditingController(text: '1');
    final price = TextEditingController(
      text: '${type == 'Purchase' ? selected?.landedUnitCost ?? 0 : selected?.expectedSalePrice ?? 0}',
    );
    final discount = TextEditingController(text: '0');
    final tax = TextEditingController(text: '0');
    final paid = TextEditingController(text: '0');
    final shipping = TextEditingController(text: '0');
    final other = TextEditingController(text: '0');
    final note = TextEditingController();
    final paymentMethod = ValueNotifier<String>('Cash');
    final date = TextEditingController(text: _date(DateTime.now()));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) {
          final quantity = _num(qty.text);
          final unitPrice = _num(price.text);
          final subtotal = quantity * unitPrice;
          final total = (subtotal -
                  _num(discount.text) +
                  _num(tax.text) +
                  _num(shipping.text) +
                  _num(other.text))
              .clamp(0, double.infinity)
              .toDouble();
          final due = total - _num(paid.text);

          return AlertDialog(
            title: Text(type == 'Purchase' ? 'নতুন ক্রয়' : 'নতুন বিক্রয়'),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<StockItem>(
                        value: selected,
                        decoration: const InputDecoration(labelText: 'পণ্য'),
                        items: available
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('${e.name} (${e.sku})'),
                                ))
                            .toList(),
                        onChanged: (v) => refresh(() {
                          selected = v;
                          price.text =
                              '${type == 'Purchase' ? v?.landedUnitCost ?? 0 : v?.expectedSalePrice ?? 0}';
                        }),
                      ),
                      const SizedBox(height: 8),
                      _field(
                        party,
                        type == 'Purchase'
                            ? 'Supplier name *'
                            : 'Customer name *',
                        required: true,
                      ),
                      _field(phone, 'Party phone'),
                      _field(address, 'Party address'),
                      _field(invoice, 'Invoice / reference number'),
                      _field(date, 'তারিখ (YYYY-MM-DD)'),
                      _field(qty, 'পরিমাণ *', required: true, number: true),
                      _field(price, 'প্রতি ইউনিট মূল্য (৳)', number: true),
                      _field(discount, 'Discount (৳)', number: true),
                      _field(tax, 'Tax (৳)', number: true),
                      _field(shipping, 'Transport / shipping (৳)', number: true),
                      _field(other, 'Other charges (৳)', number: true),
                      _field(paid, 'Paid amount (৳)', number: true),
                      DropdownButtonFormField<String>(
                        value: paymentMethod.value,
                        decoration:
                            const InputDecoration(labelText: 'Payment method'),
                        items: [
                          'Cash',
                          'Bank',
                          'Mobile Banking',
                          'Credit',
                          'Other',
                        ]
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            paymentMethod.value = v ?? 'Cash',
                      ),
                      _field(note, 'নোট / return terms', maxLines: 2),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _summaryRow('Subtotal', '৳${_money(subtotal)}'),
                            _summaryRow('Total', '৳${_money(total)}'),
                            _summaryRow('Due', '৳${_money(due)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate() ||
                      selected == null) {
                    return;
                  }
                  if (quantity <= 0) {
                    _snack('পরিমাণ শূন্যের বেশি হতে হবে');
                    return;
                  }
                  if (type == 'Sale' &&
                      quantity > selected!.availableQuantity) {
                    _snack('পর্যাপ্ত available stock নেই');
                    return;
                  }
                  if (due < 0) {
                    _snack('Paid amount total-এর বেশি হতে পারবে না');
                    return;
                  }

                  final txId =
                      'TX-${DateTime.now().millisecondsSinceEpoch}';
                  final parsedDate =
                      DateTime.tryParse(date.text) ?? DateTime.now();
                  final line = StockTransactionLine(
                    id: '$txId-L1',
                    productId: selected!.id,
                    productName: selected!.name,
                    sku: selected!.sku,
                    batchNumber: selected!.batchNumber,
                    lotNumber: selected!.lotNumber,
                    warehouseName: selected!.warehouseName,
                    quantity: quantity,
                    unit: selected!.unit,
                    unitPrice: unitPrice,
                    discountAmount: _num(discount.text),
                    taxAmount: _num(tax.text),
                    lineTotal: total,
                    landedCostAllocation:
                        type == 'Purchase' ? _num(other.text) : 0,
                    note: note.text.trim(),
                  );

                  final transaction = StockTransaction(
                    id: txId,
                    type: type,
                    date: parsedDate,
                    referenceNumber: invoice.text.trim(),
                    partyName: party.text.trim(),
                    partyPhone: phone.text.trim(),
                    partyAddress: address.text.trim(),
                    warehouseName: selected!.warehouseName,
                    subtotal: subtotal,
                    discountAmount: _num(discount.text),
                    taxAmount: _num(tax.text),
                    shippingAmount: _num(shipping.text),
                    otherCharges: _num(other.text),
                    totalAmount: total,
                    paidAmount: _num(paid.text),
                    dueAmount: due,
                    paymentStatus: due <= 0
                        ? 'Paid'
                        : (_num(paid.text) > 0 ? 'Partial' : 'Due'),
                    paymentMethod: paymentMethod.value,
                    note: note.text.trim(),
                    lines: [line],
                    status: 'Completed',
                  );

                  Navigator.pop(ctx);
                  await _save(
                    () => type == 'Purchase'
                        ? _controller.createPurchase(transaction)
                        : _controller.createSale(transaction),
                  );
                },
                child: const Text('সংরক্ষণ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExpenseForm() {
    final title = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();
    String category = 'পরিবহন';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('ব্যবসার খরচ যোগ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(title, 'খরচের বিবরণ *', required: true),
              _field(amount, 'পরিমাণ (৳) *', required: true, number: true),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
                items: [
                  'পরিবহন',
                  'লোডিং/আনলোডিং',
                  'শ্রমিক',
                  'প্যাকেজিং',
                  'গুদাম ভাড়া',
                  'দোকান ভাড়া',
                  'হ্যান্ডলিং',
                  'ট্যাক্স/শুল্ক',
                  'কমিশন',
                  'অন্যান্য',
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => refresh(() => category = v ?? category),
              ),
              _field(note, 'নোট'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.text.trim().isEmpty || _num(amount.text) <= 0) {
                  return;
                }
                final expense = StockExpense(
                  id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
                  title: title.text.trim(),
                  category: category,
                  amount: _num(amount.text),
                  date: DateTime.now(),
                  note: note.text.trim(),
                );
                Navigator.pop(ctx);
                await _save(() => _controller.saveExpense(expense));
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPartyForm({required String type}) {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final address = TextEditingController();
    final contact = TextEditingController();
    final opening = TextEditingController(text: '0');
    final note = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'Supplier' ? 'Supplier যোগ' : 'Customer যোগ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, 'নাম *', required: true),
              _field(phone, 'ফোন'),
              _field(email, 'ইমেইল'),
              _field(address, 'ঠিকানা'),
              _field(contact, 'Contact person'),
              _field(opening, 'Opening balance', number: true),
              _field(note, 'নোট'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final party = StockParty(
                id: 'PTY-${DateTime.now().millisecondsSinceEpoch}',
                name: name.text.trim(),
                type: type,
                phone: phone.text.trim(),
                email: email.text.trim(),
                address: address.text.trim(),
                contactPerson: contact.text.trim(),
                openingBalance: _num(opening.text),
                currentBalance: _num(opening.text),
                note: note.text.trim(),
              );
              Navigator.pop(ctx);
              await _save(() => _controller.saveParty(party));
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  void _showLocationForm() {
    final name = TextEditingController();
    final address = TextEditingController();
    final description = TextEditingController();
    final rent = TextEditingController(text: '0');
    String type = 'Warehouse';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('নতুন Warehouse / Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, 'নাম *', required: true),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'ধরন'),
                items: ['Warehouse', 'Shop', 'Room', 'Shelf', 'Rack']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => refresh(() => type = v ?? type),
              ),
              _field(address, 'ঠিকানা'),
              _field(description, 'বিবরণ'),
              _field(rent, 'মাসিক ভাড়া', number: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                final location = StockLocation(
                  id: 'LOC-${DateTime.now().millisecondsSinceEpoch}',
                  name: name.text.trim(),
                  type: type,
                  address: address.text.trim(),
                  description: description.text.trim(),
                  monthlyRent: _num(rent.text),
                );
                Navigator.pop(ctx);
                await _save(() => _controller.saveLocation(location));
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferForm({StockItem? item}) {
    if (_items.isEmpty) {
      _snack('প্রথমে পণ্য যোগ করুন');
      return;
    }

    StockItem? selected = item ?? _items.first;
    String destination = '';
    final qty = TextEditingController(text: '1');
    final reason = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('স্টক লোকেশন ট্রান্সফার'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StockItem>(
                value: selected,
                decoration: const InputDecoration(labelText: 'পণ্য'),
                items: _items
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (v) => refresh(() => selected = v),
              ),
              _field(qty, 'পরিমাণ', number: true),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'নতুন লোকেশন'),
                items: _locations
                    .where((e) => e.name != selected?.warehouseName)
                    .map((e) => DropdownMenuItem(
                          value: e.name,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (v) => destination = v ?? '',
              ),
              _field(reason, 'কারণ / reference'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selected == null ||
                    _num(qty.text) <= 0 ||
                    destination.isEmpty) {
                  return;
                }
                if (_num(qty.text) > selected!.availableQuantity) {
                  _snack('পর্যাপ্ত available stock নেই');
                  return;
                }
                final movement = StockMovement(
                  id: 'MOV-${DateTime.now().millisecondsSinceEpoch}',
                  productId: selected!.id,
                  quantity: _num(qty.text),
                  date: DateTime.now(),
                  batchNumber: selected!.batchNumber,
                  fromLocationName: selected!.warehouseName,
                  toLocationName: destination,
                  movementType: 'Transfer',
                  reason: reason.text.trim(),
                );
                Navigator.pop(ctx);
                await _save(() => _controller.transferStock(movement));
              },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReservationForm([StockItem? item]) {
    if (_items.isEmpty) {
      _snack('প্রথমে পণ্য যোগ করুন');
      return;
    }
    StockItem? selected = item ?? _items.first;
    final qty = TextEditingController(text: '1');
    final customer = TextEditingController();
    final reference = TextEditingController();
    final note = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Stock Reservation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StockItem>(
                value: selected,
                decoration: const InputDecoration(labelText: 'পণ্য'),
                items: _items
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (v) => refresh(() => selected = v),
              ),
              _field(qty, 'সংরক্ষিত পরিমাণ', number: true),
              _field(customer, 'Customer ID / Name'),
              _field(reference, 'Order reference'),
              _field(note, 'নোট'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selected == null ||
                    _num(qty.text) <= 0 ||
                    _num(qty.text) > selected!.availableQuantity) {
                  return;
                }
                final reservation = StockReservation(
                  id: 'RSV-${DateTime.now().millisecondsSinceEpoch}',
                  productId: selected!.id,
                  quantity: _num(qty.text),
                  createdAt: DateTime.now(),
                  customerId: customer.text.trim(),
                  referenceId: reference.text.trim(),
                  note: note.text.trim(),
                );
                Navigator.pop(ctx);
                await _save(() => _controller.saveReservation(reservation));
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustmentForm() {
    if (_items.isEmpty) {
      _snack('প্রথমে পণ্য যোগ করুন');
      return;
    }

    StockItem? selected = _items.first;
    String type = 'Damaged';
    final qty = TextEditingController(text: '1');
    final reason = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Stock adjustment / damage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StockItem>(
                value: selected,
                decoration: const InputDecoration(labelText: 'পণ্য'),
                items: _items
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (v) => refresh(() => selected = v),
              ),
              DropdownButtonFormField<String>(
                value: type,
                decoration:
                    const InputDecoration(labelText: 'Adjustment type'),
                items: [
                  'Damaged',
                  'Lost',
                  'Expired',
                  'Write-off',
                  'Returned',
                  'Correction',
                ]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => refresh(() => type = v ?? type),
              ),
              _field(qty, 'পরিমাণ', number: true),
              _field(reason, 'কারণ'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selected == null || _num(qty.text) <= 0) return;
                final adjustment = StockAdjustment(
                  id: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
                  productId: selected!.id,
                  type: type,
                  quantity: _num(qty.text),
                  date: DateTime.now(),
                  batchNumber: selected!.batchNumber,
                  reason: reason.text.trim(),
                  approvalStatus: 'Pending',
                );
                Navigator.pop(ctx);
                await _save(() => _controller.saveAdjustment(adjustment));
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockCount() {
    if (_items.isEmpty) {
      _snack('কোনো পণ্য নেই');
      return;
    }

    final controllers = <String, TextEditingController>{
      for (final item in _items)
        item.id: TextEditingController(text: '${item.quantity}'),
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Physical stock count'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              children: _items.map((item) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name}\nSystem: ${_qty(item.quantity)} ${item.unit}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: controllers[item.id],
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Counted'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              final counts = <MapEntry<StockItem, double>>[];
              for (final item in _items) {
                counts.add(
                  MapEntry(
                    item,
                    _num(controllers[item.id]!.text),
                  ),
                );
              }
              Navigator.pop(ctx);

              for (final entry in counts) {
                await _save(
                  () => _controller.reconcileStock(
                    productId: entry.key.id,
                    countedQuantity: entry.value,
                    reason: 'Physical stock count',
                    locationId: entry.key.warehouseId,
                    batchNumber: entry.key.batchNumber,
                  ),
                );
              }
            },
            child: const Text('Count & reconcile'),
          ),
        ],
      ),
    );
  }

  void _showPaymentForm() {
    if (_transactions.isEmpty) {
      _snack('পেমেন্ট করার জন্য কোনো লেনদেন নেই');
      return;
    }

    StockTransaction? selected = _transactions.first;
    final amount = TextEditingController();
    final reference = TextEditingController();
    final note = TextEditingController();
    String method = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Payment / Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StockTransaction>(
                value: selected,
                decoration: const InputDecoration(labelText: 'লেনদেন'),
                items: _transactions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.referenceNumber.isEmpty ? e.id : e.referenceNumber} • ${e.partyName}',
                          ),
                        ))
                    .toList(),
                onChanged: (v) => refresh(() => selected = v),
              ),
              _field(amount, 'Payment amount', number: true),
              _field(reference, 'Transaction reference'),
              DropdownButtonFormField<String>(
                value: method,
                decoration:
                    const InputDecoration(labelText: 'Payment method'),
                items: ['Cash', 'Bank', 'Mobile Banking', 'Other']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => refresh(() => method = v ?? method),
              ),
              _field(note, 'নোট'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selected == null || _num(amount.text) <= 0) return;
                final payment = StockPayment(
                  id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                  referenceId: selected!.id,
                  referenceType: selected!.type,
                  date: DateTime.now(),
                  amount: _num(amount.text),
                  partyName: selected!.partyName,
                  method: method,
                  transactionReference: reference.text.trim(),
                  note: note.text.trim(),
                );
                Navigator.pop(ctx);
                await _save(() => _controller.recordPayment(payment));
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askText(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'কারণ লিখুন',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('নিশ্চিত'),
          ),
        ],
      ),
    );
  }

  void _showAudit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .75,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('সম্পূর্ণ Activity & Audit History'),
              if (_audit.isEmpty)
                _empty('কোনো রেকর্ড নেই')
              else
                ..._audit.map(_auditTile),
            ],
          ),
        ),
      ),
    );
  }
}

String _money(num value) => value.toStringAsFixed(2);

String _qty(num value) => value % 1 == 0
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

double _num(String value) =>
    double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _dateTime(DateTime value) =>
    '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
