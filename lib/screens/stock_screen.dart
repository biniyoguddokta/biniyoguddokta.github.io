import 'package:flutter/material.dart';

/// Stock & Inventory module UI.
/// This screen currently keeps demo data in memory. Google Sheets persistence,
/// server-side authorization, file uploads and audit endpoints are integrated
/// in the service/backend phase.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final List<_StockItem> _items = [
    _StockItem(
      id: 'STK-001',
      name: 'Premium Rice',
      sku: 'RICE-001',
      category: 'খাদ্যপণ্য',
      unit: 'কেজি',
      brand: 'Local',
      batch: 'B-2026-01',
      warehouse: 'Main Store',
      shelf: 'A-01',
      quantity: 240,
      reserved: 15,
      damaged: 2,
      reorder: 50,
      landedCost: 62,
      salePrice: 75,
      expiry: DateTime.now().add(const Duration(days: 180)),
    ),
    _StockItem(
      id: 'STK-002',
      name: 'Soybean Oil',
      sku: 'OIL-002',
      category: 'ভোজ্য তেল',
      unit: 'লিটার',
      brand: 'Fresh',
      batch: 'O-2026-02',
      warehouse: 'Shop Floor',
      shelf: 'B-03',
      quantity: 36,
      reserved: 4,
      damaged: 0,
      reorder: 40,
      landedCost: 158,
      salePrice: 178,
    ),
    _StockItem(
      id: 'STK-003',
      name: 'Sugar',
      sku: 'SUG-003',
      category: 'খাদ্যপণ্য',
      unit: 'কেজি',
      brand: 'Local',
      batch: 'S-2026-01',
      warehouse: 'Main Store',
      shelf: 'A-04',
      quantity: 85,
      reserved: 0,
      damaged: 0,
      reorder: 30,
      landedCost: 112,
      salePrice: 125,
    ),
  ];
  final List<_StockTransaction> _transactions = [];
  final List<_StockExpense> _expenses = [];
  final List<_StockAudit> _audit = [];
  final List<_StockLocation> _locations = [
    _StockLocation('Main Store', 'Warehouse', 'A-Block'),
    _StockLocation('Shop Floor', 'Shop', 'Ground floor'),
  ];
  final List<_StockParty> _suppliers = [];
  final List<_StockParty> _customers = [];
  String _search = '';
  String _category = 'সব';
  String _locationFilter = 'সব';
  String _selectedReport = 'Stock valuation';
  bool _showAlertsOnly = false;

  static const Color _navy = Color(0xFF142B4A);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFFF4F7FB);
  static const Color _green = Color(0xFF0F9D75);
  static const Color _orange = Color(0xFFE58A20);
  static const Color _red = Color(0xFFD9485F);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  double get _stockValue =>
      _items.fold(0, (s, e) => s + e.available * e.landedCost);
  double get _potentialSales =>
      _items.fold(0, (s, e) => s + e.available * e.salePrice);
  double get _expectedProfit => _potentialSales - _stockValue;
  int get _lowStock =>
      _items.where((e) => e.available <= e.reorder).length;
  int get _expiring => _items.where((e) =>
      e.expiry != null &&
      e.expiry!.difference(DateTime.now()).inDays <= 30 &&
      e.expiry!.isAfter(DateTime.now())).length;

  List<_StockItem> get _filteredItems {
    return _items.where((e) {
      final q = _search.toLowerCase();
      final matchesSearch = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.sku.toLowerCase().contains(q) ||
          e.id.toLowerCase().contains(q) ||
          e.batch.toLowerCase().contains(q);
      final matchesCategory = _category == 'সব' || e.category == _category;
      final matchesLocation =
          _locationFilter == 'সব' || e.warehouse == _locationFilter;
      final matchesAlert = !_showAlertsOnly ||
          e.available <= e.reorder ||
          e.damaged > 0 ||
          (e.expiry != null &&
              e.expiry!.difference(DateTime.now()).inDays <= 30);
      return matchesSearch &&
          matchesCategory &&
          matchesLocation &&
          matchesAlert;
    }).toList();
  }

  void _record(String action, String ref, String detail) {
    _audit.insert(
      0,
      _StockAudit(
        action,
        ref,
        detail,
        DateTime.now(),
        'Current user',
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text('Stock Business',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Alerts',
            onPressed: () {
              setState(() => _showAlertsOnly = !_showAlertsOnly);
              _tabs.animateTo(2);
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (_lowStock + _expiring > 0)
                  Positioned(
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
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _tabs.animateTo(7),
            icon: const Icon(Icons.settings_outlined),
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
      body: TabBarView(
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
    return ListView(
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
              const Text('ব্যবসার স্টক সারসংক্ষেপ',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('৳${_money(_stockValue)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
              const Text('বর্তমান মজুদের ক্রয়মূল্য (Landed Cost)',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 18),
              Row(
                children: [
                  _heroMetric('পণ্য', '${_items.length}'),
                  _heroMetric('সম্ভাব্য বিক্রয়',
                      '৳${_money(_potentialSales)}'),
                  _heroMetric('সম্ভাব্য লাভ',
                      '৳${_money(_expectedProfit)}'),
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
            _metricCard('কম স্টক', '$_lowStock', Icons.inventory_2_outlined,
                _orange),
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
            _actionChip('পণ্য যোগ', Icons.add_box_outlined,
                () => _showItemForm()),
            _actionChip('ক্রয় এন্ট্রি', Icons.shopping_cart_outlined,
                () => _tabs.animateTo(3)),
            _actionChip('বিক্রয় এন্ট্রি', Icons.point_of_sale,
                () => _tabs.animateTo(4)),
            _actionChip('খরচ যোগ', Icons.receipt_long_outlined,
                () => _showExpenseForm()),
            _actionChip('স্টক ট্রান্সফার', Icons.move_up,
                () => _showTransferForm()),
            _actionChip('স্টক গণনা', Icons.fact_check_outlined,
                () => _showStockCount()),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('সাম্প্রতিক স্টক'),
        ..._items.take(4).map(_itemTile),
        const SizedBox(height: 18),
        _sectionTitle('সাম্প্রতিক কার্যক্রম'),
        if (_audit.isEmpty)
          _empty('এখনো কোনো কার্যক্রম নেই')
        else
          ..._audit.take(5).map(_auditTile),
      ],
    );
  }

  Widget _heroMetric(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
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
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: _navy)),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _inventory() {
    final items = _filteredItems;
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
                borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _category,
                decoration: _filterDecoration('ক্যাটাগরি'),
                items: ['সব', ..._items.map((e) => e.category).toSet()]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'সব'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _locationFilter,
                decoration: _filterDecoration('লোকেশন'),
                items: [
                  'সব',
                  ..._locations.map((e) => e.name),
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _locationFilter = v ?? 'সব'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('${items.length}টি পণ্য',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showItemForm(),
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
            borderSide: BorderSide.none),
      );

  Widget _itemTile(_StockItem item) {
    final low = item.available <= item.reorder;
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8EDF4))),
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
                    borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.inventory_2_outlined, color: _blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _navy)),
                    Text('${item.sku} • ${item.category}',
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 11)),
                    Text(
                        '${item.warehouse} / ${item.shelf} • Batch: ${item.batch}',
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 10)),
                    const SizedBox(height: 5),
                    Text(
                        'মজুদ: ${_qty(item.available)} ${item.unit}  •  ৳${_money(item.landedCost)} / ${item.unit}',
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('৳${_money(item.available * item.landedCost)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: _navy)),
                  const SizedBox(height: 5),
                  _statusPill(low ? 'কম স্টক' : 'সক্রিয়',
                      low ? _orange : _green),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _showItemForm(item: item);
                      if (v == 'delete') _archiveItem(item);
                      if (v == 'move') _showTransferForm(item: item);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
                      PopupMenuItem(value: 'move', child: Text('লোকেশন বদল')),
                      PopupMenuItem(value: 'delete', child: Text('আর্কাইভ')),
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
    final alerts = _items.where((e) =>
        e.available <= e.reorder ||
        e.damaged > 0 ||
        (e.expiry != null &&
            e.expiry!.difference(DateTime.now()).inDays <= 30)).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('স্টক সতর্কতা ও করণীয়'),
        _metricCard('কম স্টক', '$_lowStock', Icons.trending_down, _orange),
        const SizedBox(height: 8),
        _metricCard('৩০ দিনের মধ্যে মেয়াদ', '$_expiring',
            Icons.hourglass_bottom, _red),
        const SizedBox(height: 12),
        ...alerts.map((e) => Card(
              color: Colors.white,
              child: ListTile(
                leading: Icon(
                    e.available <= e.reorder
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    color: _orange),
                title: Text(e.name),
                subtitle: Text(
                    'মজুদ ${_qty(e.available)} ${e.unit} • Reorder ${_qty(e.reorder)} • নষ্ট ${_qty(e.damaged)}'),
                trailing: TextButton(
                    onPressed: () => _showPurchaseForm(prefill: e),
                    child: const Text('ক্রয়')),
              ),
            )),
        _sectionTitle('সতর্কতার নিয়ম'),
        _infoCard('Low stock / Reorder',
            'Available stock reorder level-এর সমান বা কম হলে সতর্কতা।'),
        _infoCard('Expiry alert',
            'মেয়াদ শেষ হওয়ার ৩০/৬০/৯০ দিন আগে সতর্কতা কনফিগার করা যাবে।'),
        _infoCard('Due & payment alert',
            'Supplier due, customer due এবং বকেয়া সংগ্রহের রিমাইন্ডার।'),
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
        _primaryButton('নতুন ক্রয় এন্ট্রি', Icons.add_shopping_cart,
            _showPurchaseForm),
        const SizedBox(height: 12),
        _sectionTitle('ক্রয় ইতিহাস'),
        if (purchases.isEmpty)
          _empty('ক্রয়ের কোনো রেকর্ড নেই')
        else
          ...purchases.map(_transactionTile),
        _sectionTitle('ক্রয় রেকর্ডে সংরক্ষিত তথ্য'),
        _infoCard('Supplier & Invoice',
            'সরবরাহকারীর নাম, ফোন, ঠিকানা, invoice number, invoice attachment এবং purchase date।'),
        _infoCard('Purchase line items',
            'পণ্য, batch/lot, quantity, unit, unit price, subtotal, discount, tax ও total।'),
        _infoCard('Payment & Due',
            'Cash/bank/mobile payment, paid amount, due amount, partial payment এবং payment history।'),
        _infoCard('Supplier ledger & returns',
            'Supplier-wise ledger, purchase return, debit/credit adjustment ও due settlement।'),
      ],
    );
  }

  Widget _salesPage() {
    final sales = _transactions.where((e) => e.type == 'Sale').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _sectionTitle('বিক্রয় ব্যবস্থাপনা'),
        _primaryButton('নতুন বিক্রয় এন্ট্রি', Icons.point_of_sale,
            _showSaleForm),
        const SizedBox(height: 12),
        _sectionTitle('বিক্রয় ইতিহাস'),
        if (sales.isEmpty)
          _empty('বিক্রয়ের কোনো রেকর্ড নেই')
        else
          ...sales.map(_transactionTile),
        _sectionTitle('বিক্রয় রেকর্ডে সংরক্ষিত তথ্য'),
        _infoCard('Customer & Invoice',
            'Customer profile/contact, invoice number, sale date, item/batch/location এবং invoice print/share।'),
        _infoCard('Price & Discount',
            'Quantity, unit price, line discount, overall discount, tax, total এবং price override reason।'),
        _infoCard('Collection & Due',
            'Paid/partial/due, payment method, collection history, due aging ও reminder।'),
        _infoCard('Returns & Refunds',
            'Sales return, exchange, refund, returned quantity, restock/damaged disposition এবং adjustment।'),
      ],
    );
  }

  Widget _expensesPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _sectionTitle('ব্যবসার অতিরিক্ত খরচ'),
        _primaryButton('খরচ যোগ করুন', Icons.add_card, _showExpenseForm),
        const SizedBox(height: 8),
        ..._expenses.map((e) => Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: _orange),
                title: Text(e.title),
                subtitle: Text('${e.category} • ${_date(e.date)}'),
                trailing: Text('৳${_money(e.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
        _infoCard('Landed cost allocation',
            'পরিবহন, শ্রমিক, ভাড়া, প্যাকেজিং, handling, tax ও commission পণ্য/ব্যাচে quantity, value বা manual ratio অনুযায়ী allocate করা হবে। একই খরচ যেন একাধিকবার profit calculation-এ যোগ না হয়।'),
      ],
    );
  }

  Widget _reportsPage() {
    final reportNames = [
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('ব্যবসায়িক রিপোর্ট'),
        DropdownButtonFormField<String>(
          value: _selectedReport,
          decoration: _filterDecoration('রিপোর্ট নির্বাচন'),
          items: reportNames
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedReport = v ?? reportNames[0]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _snack('তারিখ ফিল্টার সার্ভিস ধাপে যুক্ত হবে'),
                    icon: const Icon(Icons.date_range),
                    label: const Text('তারিখ সীমা'))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _snack('Export PDF/Excel সার্ভিস ধাপে যুক্ত হবে'),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export'))),
          ],
        ),
        const SizedBox(height: 12),
        _infoCard(_selectedReport, _reportDescription(_selectedReport)),
        _sectionTitle('বর্তমান সারাংশ'),
        _summaryRow('বর্তমান stock landed value', '৳${_money(_stockValue)}'),
        _summaryRow('সম্ভাব্য বিক্রয় মূল্য', '৳${_money(_potentialSales)}'),
        _summaryRow('সম্ভাব্য gross profit', '৳${_money(_expectedProfit)}'),
        _summaryRow('মোট purchase entries', '${_transactions.where((e) => e.type == 'Purchase').length}'),
        _summaryRow('মোট sales entries', '${_transactions.where((e) => e.type == 'Sale').length}'),
        _summaryRow('অতিরিক্ত খরচ', '৳${_money(_expenses.fold<double>(0, (s, e) => s + e.amount))}'),
        const SizedBox(height: 12),
        _infoCard('Profit calculation',
            'Expected profit = expected sale revenue − landed cost of sold quantity. Actual profit-এ discount, returns, wastage, stock adjustments এবং সংশ্লিষ্ট খরচ অন্তর্ভুক্ত হবে।'),
      ],
    );
  }

  String _reportDescription(String name) {
    switch (name) {
      case 'Stock valuation':
        return 'পণ্য, batch এবং warehouse অনুযায়ী available quantity × landed unit cost।';
      case 'Actual profit & loss':
        return 'বিক্রিত পণ্যের প্রকৃত revenue থেকে landed cost, discount, return, wastage ও expense বাদ।';
      case 'Expected profit':
        return 'বর্তমান বিক্রয় মূল্য ও landed cost ধরে সম্ভাব্য gross margin/profit।';
      case 'Fast / Slow / Dead stock':
        return 'বিক্রয়ের frequency ও শেষ বিক্রয়ের তারিখ ধরে stock movement analysis।';
      case 'Supplier due':
        return 'Supplier-wise purchase, payment, return, adjustment ও outstanding balance।';
      case 'Customer due':
        return 'Customer-wise invoice, collection, return, aging ও due balance।';
      default:
        return 'তারিখ, পণ্য, batch, location, party ও payment status অনুযায়ী বিস্তারিত রিপোর্ট।';
    }
  }

  Widget _morePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _sectionTitle('অন্যান্য ব্যবস্থাপনা'),
        _menuTile('পণ্য ক্যাটাগরি ও ইউনিট', Icons.category_outlined,
            'Category, unit, brand, model, grade ও custom fields'),
        _menuTile('Warehouse / Shop / Shelf', Icons.warehouse_outlined,
            'একাধিক গুদাম, দোকান, room, shelf ও rack'),
        _menuTile('লোকেশন ট্রান্সফার', Icons.compare_arrows,
            'এক লোকেশন থেকে অন্য লোকেশনে transfer ও movement ledger',
            onTap: _showTransferForm),
        _menuTile('Stock count & reconciliation', Icons.fact_check_outlined,
            'Physical count, variance, adjustment reason ও approval',
            onTap: _showStockCount),
        _menuTile('Batch / Barcode / QR', Icons.qr_code_2,
            'Batch/lot tracking, barcode/QR reference, expiry ও warranty'),
        _menuTile('Supplier directory', Icons.local_shipping_outlined,
            'Supplier contact, ledger, due, purchase & return history',
            onTap: () => _showPartyForm(isSupplier: true)),
        _menuTile('Customer directory', Icons.people_outline,
            'Customer contact, sales, due, collection & return history',
            onTap: () => _showPartyForm(isSupplier: false)),
        _menuTile('Adjustment / Damage / Write-off',
            Icons.rule_folder_outlined,
            'Lost, damaged, expired, returned, write-off ও reason/approval',
            onTap: _showAdjustmentForm),
        _menuTile('Activity & Audit history', Icons.history,
            'Create/edit/archive/approval, old/new value, actor, time ও reason',
            onTap: _showAudit),
        _menuTile('Access control & privacy', Icons.admin_panel_settings_outlined,
            'Admin full access; staff-এর জন্য permission-based access'),
        _menuTile('Alerts & notification settings', Icons.notifications_active_outlined,
            'Low stock, reorder, expiry, supplier/customer due ও expected-sale alert'),
        _menuTile('Data backup & restore', Icons.backup_outlined,
            'নিয়মিত backup, restore point ও data export'),
        _sectionTitle('Audit history'),
        if (_audit.isEmpty)
          _empty('কোনো audit record নেই')
        else
          ..._audit.take(10).map(_auditTile),
      ],
    );
  }

  Widget _menuTile(String title, IconData icon, String subtitle,
      {VoidCallback? onTap}) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: _blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? () => _snack('এই সেটিংসের বিস্তারিত পরবর্তী ধাপে যুক্ত হবে'),
      ),
    );
  }

  Widget _transactionTile(_StockTransaction t) => Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                t.type == 'Purchase' ? const Color(0xFFE9F7F1) : const Color(0xFFEAF1FF),
            child: Icon(
                t.type == 'Purchase'
                    ? Icons.shopping_cart_outlined
                    : Icons.point_of_sale,
                color: t.type == 'Purchase' ? _green : _blue),
          ),
          title: Text('${t.type} • ${t.itemName}'),
          subtitle: Text(
              '${t.party} • ${_date(t.date)} • ${t.paymentStatus} • ${t.location}'),
          trailing: Text('৳${_money(t.total)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );

  Widget _auditTile(_StockAudit a) => Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 7),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.history, color: Colors.blueGrey),
          title: Text('${a.action}: ${a.ref}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${a.detail}\n${a.actor} • ${_dateTime(a.time)}'),
          isThreeLine: true,
        ),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 8),
        child: Text(title,
            style: const TextStyle(
                color: _navy, fontSize: 16, fontWeight: FontWeight.w800)),
      );

  Widget _empty(String text) => Container(
        padding: const EdgeInsets.all(22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Text(text, style: const TextStyle(color: Colors.blueGrey)),
      );

  Widget _infoCard(String title, String body) => Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EDF4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _navy)),
          const SizedBox(height: 5),
          Text(body,
              style: const TextStyle(
                  fontSize: 12, color: Colors.blueGrey, height: 1.45)),
        ]),
      );

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        ]),
      );

  Widget _statusPill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _actionChip(String label, IconData icon, VoidCallback action) =>
      ActionChip(
        avatar: Icon(icon, size: 17, color: _blue),
        label: Text(label),
        onPressed: action,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE4EAF2)),
      );

  Widget _primaryButton(String label, IconData icon, VoidCallback action) =>
      SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: action,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
      );

  void _quickAdd() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          _sheetAction('নতুন পণ্য', Icons.inventory_2_outlined,
              () => _showItemForm()),
          _sheetAction('ক্রয়', Icons.shopping_cart_outlined,
              () => _showPurchaseForm()),
          _sheetAction('বিক্রয়', Icons.point_of_sale, _showSaleForm),
          _sheetAction('ব্যবসার খরচ', Icons.receipt_long, _showExpenseForm),
          _sheetAction('স্টক ট্রান্সফার', Icons.move_up, _showTransferForm),
          _sheetAction('স্টক সমন্বয়', Icons.tune, _showAdjustmentForm),
        ]),
      ),
    );
  }

  ListTile _sheetAction(String title, IconData icon, VoidCallback action) =>
      ListTile(
        leading: Icon(icon, color: _blue),
        title: Text(title),
        onTap: () {
          Navigator.pop(context);
          action();
        },
      );

  void _showItemForm({_StockItem? item}) {
    final name = TextEditingController(text: item?.name ?? '');
    final sku = TextEditingController(text: item?.sku ?? '');
    final category = TextEditingController(text: item?.category ?? '');
    final unit = TextEditingController(text: item?.unit ?? 'পিস');
    final brand = TextEditingController(text: item?.brand ?? '');
    final batch = TextEditingController(text: item?.batch ?? '');
    final qty = TextEditingController(text: '${item?.quantity ?? 0}');
    final reorder = TextEditingController(text: '${item?.reorder ?? 0}');
    final cost = TextEditingController(text: '${item?.landedCost ?? 0}');
    final price = TextEditingController(text: '${item?.salePrice ?? 0}');
    final desc = TextEditingController(text: item?.description ?? '');
    final warehouse = TextEditingController(text: item?.warehouse ?? 'Main Store');
    final shelf = TextEditingController(text: item?.shelf ?? '');
    final barcode = TextEditingController(text: item?.barcode ?? '');
    final model = TextEditingController(text: item?.model ?? '');
    final grade = TextEditingController(text: item?.grade ?? '');
    final expiry = TextEditingController(
        text: item?.expiry == null ? '' : _date(item!.expiry!));
    final warranty = TextEditingController(text: item?.warranty ?? '');
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
                  _field(desc, 'বিবরণ / নোট', maxLines: 2),
                  _field(unit, 'Unit (কেজি/লিটার/পিস)'),
                  _field(brand, 'Brand'),
                  _field(model, 'Model'),
                  _field(grade, 'Grade / Quality'),
                  _field(batch, 'Batch / Lot No.'),
                  _field(barcode, 'Barcode / QR Code'),
                  _field(qty, 'প্রাথমিক পরিমাণ', number: true),
                  _field(reorder, 'Reorder / Low stock level', number: true),
                  _field(cost, 'Landed unit cost (৳)', number: true),
                  _field(price, 'Expected sale price (৳)', number: true),
                  _field(warehouse, 'Warehouse / Shop'),
                  _field(shelf, 'Room / Shelf / Rack'),
                  _field(expiry, 'Expiry date (YYYY-MM-DD)'),
                  _field(warranty, 'Warranty details'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final old = item == null ? null : item.toMap().toString();
              setState(() {
                if (item == null) {
                  final newItem = _StockItem(
                    id: 'STK-${DateTime.now().millisecondsSinceEpoch}',
                    name: name.text.trim(),
                    sku: sku.text.trim(),
                    category: category.text.trim(),
                    unit: unit.text.trim(),
                    brand: brand.text.trim(),
                    batch: batch.text.trim(),
                    warehouse: warehouse.text.trim(),
                    shelf: shelf.text.trim(),
                    quantity: _num(qty.text),
                    reorder: _num(reorder.text),
                    landedCost: _num(cost.text),
                    salePrice: _num(price.text),
                    description: desc.text,
                    barcode: barcode.text,
                    model: model.text,
                    grade: grade.text,
                    warranty: warranty.text,
                    expiry: DateTime.tryParse(expiry.text),
                  );
                  _items.add(newItem);
                  _record('CREATE PRODUCT', newItem.id, 'পণ্য তৈরি');
                } else {
                  item
                    ..name = name.text.trim()
                    ..sku = sku.text.trim()
                    ..category = category.text.trim()
                    ..unit = unit.text.trim()
                    ..brand = brand.text.trim()
                    ..batch = batch.text.trim()
                    ..warehouse = warehouse.text.trim()
                    ..shelf = shelf.text.trim()
                    ..quantity = _num(qty.text)
                    ..reorder = _num(reorder.text)
                    ..landedCost = _num(cost.text)
                    ..salePrice = _num(price.text)
                    ..description = desc.text
                    ..barcode = barcode.text
                    ..model = model.text
                    ..grade = grade.text
                    ..warranty = warranty.text
                    ..expiry = DateTime.tryParse(expiry.text);
                  _record('UPDATE PRODUCT', item.id, 'Old: $old | Updated');
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool required = false, bool number = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'এই তথ্য প্রয়োজন' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _showItemDetails(_StockItem e) {
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
              Text(e.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              Text('${e.id} • ${e.sku} • ${e.category}'),
              const Divider(),
              _summaryRow('Available stock', '${_qty(e.available)} ${e.unit}'),
              _summaryRow('Reserved', '${_qty(e.reserved)} ${e.unit}'),
              _summaryRow('Damaged', '${_qty(e.damaged)} ${e.unit}'),
              _summaryRow('Landed unit cost', '৳${_money(e.landedCost)}'),
              _summaryRow('Expected sale price', '৳${_money(e.salePrice)}'),
              _summaryRow('Stock valuation',
                  '৳${_money(e.available * e.landedCost)}'),
              _summaryRow('Location', '${e.warehouse} / ${e.shelf}'),
              _summaryRow('Batch / Lot', e.batch),
              _summaryRow('Expiry', e.expiry == null ? 'N/A' : _date(e.expiry!)),
              _summaryRow('Barcode / QR', e.barcode.isEmpty ? 'N/A' : e.barcode),
              _summaryRow('Warranty', e.warranty.isEmpty ? 'N/A' : e.warranty),
              _summaryRow('Description', e.description),
              const SizedBox(height: 10),
              _primaryButton('সম্পাদনা', Icons.edit,
                  () {
                    Navigator.pop(ctx);
                    _showItemForm(item: e);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void _archiveItem(_StockItem item) {
    setState(() {
      item.archived = true;
      _record('ARCHIVE PRODUCT', item.id, 'পণ্য archive করা হয়েছে');
    });
    _snack('পণ্যটি archive করা হয়েছে; স্থায়ীভাবে মুছে ফেলা হয়নি');
  }

  void _showPurchaseForm({_StockItem? prefill}) =>
      _showTransactionForm(type: 'Purchase', prefill: prefill);

  void _showSaleForm() => _showTransactionForm(type: 'Sale');

  void _showTransactionForm({required String type, _StockItem? prefill}) {
    _StockItem? selected = prefill ??
        (_items.isEmpty ? null : _items.firstWhere((e) => !e.archived));
    final qty = TextEditingController(text: '1');
    final price = TextEditingController(
        text: '${type == 'Purchase' ? selected?.landedCost ?? 0 : selected?.salePrice ?? 0}');
    final party = TextEditingController();
    final phone = TextEditingController();
    final invoice = TextEditingController();
    final paid = TextEditingController(text: '0');
    final discount = TextEditingController(text: '0');
    final tax = TextEditingController(text: '0');
    final note = TextEditingController();
    final date = TextEditingController(text: _date(DateTime.now()));
    final location = TextEditingController(text: selected?.warehouse ?? 'Main Store');
    final freight = TextEditingController(text: '0');
    final labour = TextEditingController(text: '0');
    final packaging = TextEditingController(text: '0');
    final otherCost = TextEditingController(text: '0');
    final paymentMethod = ValueNotifier<String>('Cash');
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) {
          final quantity = _num(qty.text);
          final unitPrice = _num(price.text);
          final subtotal = quantity * unitPrice;
          final total = (subtotal - _num(discount.text) + _num(tax.text)).clamp(0, double.infinity).toDouble();
          final landedExtra = _num(freight.text) +
              _num(labour.text) +
              _num(packaging.text) +
              _num(otherCost.text);
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
                      DropdownButtonFormField<_StockItem>(
                        value: selected,
                        decoration: const InputDecoration(labelText: 'পণ্য'),
                        items: _items.where((e) => !e.archived).map((e) =>
                            DropdownMenuItem(value: e, child: Text('${e.name} (${e.sku})'))).toList(),
                        onChanged: (v) => refresh(() {
                          selected = v;
                          price.text = '${type == 'Purchase' ? v?.landedCost ?? 0 : v?.salePrice ?? 0}';
                          location.text = v?.warehouse ?? location.text;
                        }),
                      ),
                      const SizedBox(height: 8),
                      _field(party, type == 'Purchase' ? 'Supplier name *' : 'Customer name *', required: true),
                      _field(phone, 'Party phone / contact'),
                      _field(invoice, 'Invoice / reference number'),
                      _field(date, 'তারিখ (YYYY-MM-DD)'),
                      _field(qty, 'পরিমাণ *', required: true, number: true),
                      _field(price, 'প্রতি ইউনিট মূল্য (৳)', number: true),
                      _field(discount, 'Discount (৳)', number: true),
                      _field(tax, 'Tax (৳)', number: true),
                      _field(paid, 'Paid amount (৳)', number: true),
                      DropdownButtonFormField<String>(
                        value: paymentMethod.value,
                        decoration: const InputDecoration(labelText: 'Payment method'),
                        items: ['Cash', 'Bank', 'Mobile Banking', 'Credit', 'Other']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => paymentMethod.value = v ?? 'Cash',
                      ),
                      _field(location, 'Warehouse / Shop'),
                      if (type == 'Purchase') ...[
                        const Divider(),
                        const Align(alignment: Alignment.centerLeft, child: Text('Landed cost allocation', style: TextStyle(fontWeight: FontWeight.bold))),
                        _field(freight, 'Transport / freight (৳)', number: true),
                        _field(labour, 'Loading / labour (৳)', number: true),
                        _field(packaging, 'Packaging / handling (৳)', number: true),
                        _field(otherCost, 'Tax / commission / other (৳)', number: true),
                      ],
                      _field(note, 'নোট / return terms', maxLines: 2),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          _summaryRow('Subtotal', '৳${_money(subtotal)}'),
                          _summaryRow('Total', '৳${_money(total)}'),
                          if (type == 'Purchase') _summaryRow('Additional landed cost', '৳${_money(landedExtra)}'),
                          _summaryRow('Due', '৳${_money(due)}'),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate() || selected == null) return;
                  if (type == 'Sale' && quantity > selected!.available) {
                    _snack('পর্যাপ্ত available stock নেই');
                    return;
                  }
                  if (due < 0) {
                    _snack('Paid amount total-এর বেশি হতে পারবে না');
                    return;
                  }
                  setState(() {
                    final tx = _StockTransaction(
                      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
                      type: type,
                      itemName: selected!.name,
                      itemId: selected!.id,
                      party: party.text.trim(),
                      phone: phone.text.trim(),
                      invoice: invoice.text.trim(),
                      date: DateTime.tryParse(date.text) ?? DateTime.now(),
                      quantity: quantity,
                      unitPrice: unitPrice,
                      discount: _num(discount.text),
                      tax: _num(tax.text),
                      total: total,
                      paid: _num(paid.text),
                      due: due,
                      paymentMethod: paymentMethod.value,
                      paymentStatus: due <= 0 ? 'Paid' : (_num(paid.text) > 0 ? 'Partial' : 'Due'),
                      location: location.text.trim(),
                      note: note.text.trim(),
                      landedExtra: landedExtra,
                    );
                    _transactions.insert(0, tx);
                    if (type == 'Purchase') {
                      selected!.quantity += quantity;
                      selected!.landedCost = (selected!.landedCost * (selected!.quantity - quantity) +
                              (quantity * unitPrice) + landedExtra) /
                          selected!.quantity;
                      _record('PURCHASE', tx.id, '${selected!.name}, qty $quantity');
                    } else {
                      selected!.quantity -= quantity;
                      _record('SALE', tx.id, '${selected!.name}, qty $quantity');
                    }
                    _record('PAYMENT', tx.id, 'Paid ${tx.paid}; Due ${tx.due}');
                  });
                  Navigator.pop(ctx);
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
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        title: const Text('ব্যবসার খরচ যোগ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(title, 'খরচের বিবরণ *', required: true),
          _field(amount, 'পরিমাণ (৳) *', required: true, number: true),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
            items: ['পরিবহন','লোডিং/আনলোডিং','শ্রমিক','প্যাকেজিং','গুদাম ভাড়া','দোকান ভাড়া','হ্যান্ডলিং','ট্যাক্স/শুল্ক','কমিশন','অন্যান্য']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => refresh(() => category = v ?? category),
          ),
          _field(note, 'নোট'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () {
            if (title.text.trim().isEmpty || _num(amount.text) <= 0) return;
            setState(() {
              _expenses.insert(0, _StockExpense(title.text.trim(), category, _num(amount.text), DateTime.now(), note.text));
              _record('ADD EXPENSE', title.text.trim(), '৳${amount.text}');
            });
            Navigator.pop(ctx);
          }, child: const Text('সংরক্ষণ')),
        ],
      )),
    );
  }

  void _showTransferForm({_StockItem? item}) {
    _StockItem? selected = item ?? (_items.isEmpty ? null : _items.first);
    final qty = TextEditingController(text: '1');
    final destination = TextEditingController();
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        title: const Text('স্টক লোকেশন ট্রান্সফার'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<_StockItem>(
            value: selected,
            decoration: const InputDecoration(labelText: 'পণ্য'),
            items: _items.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
            onChanged: (v) => refresh(() => selected = v),
          ),
          _field(qty, 'পরিমাণ', number: true),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'নতুন লোকেশন'),
            items: _locations.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(),
            onChanged: (v) => destination.text = v ?? '',
          ),
          _field(reason, 'কারণ / reference'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () {
            if (selected == null || _num(qty.text) <= 0 || destination.text.isEmpty) return;
            setState(() {
              final from = selected!.warehouse;
              selected!.warehouse = destination.text;
              _record('STOCK TRANSFER', selected!.id, '$from → ${destination.text}; qty ${qty.text}; ${reason.text}');
            });
            Navigator.pop(ctx);
          }, child: const Text('Transfer')),
        ],
      )),
    );
  }

  void _showStockCount() {
    final controllers = <String, TextEditingController>{
      for (final e in _items) e.id: TextEditingController(text: '${e.quantity}')
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Physical stock count'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(children: _items.map((e) => Row(children: [
              Expanded(child: Text('${e.name}\nSystem: ${_qty(e.quantity)} ${e.unit}', style: const TextStyle(fontSize: 12))),
              SizedBox(width: 110, child: TextField(controller: controllers[e.id], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Counted'))),
            ])).toList()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () {
            setState(() {
              for (final e in _items) {
                final actual = _num(controllers[e.id]!.text);
                final variance = actual - e.quantity;
                if (variance != 0) {
                  e.quantity = actual;
                  _record('STOCK COUNT ADJUSTMENT', e.id, 'Variance: $variance');
                }
              }
            });
            Navigator.pop(ctx);
          }, child: const Text('Count & reconcile')),
        ],
      ),
    );
  }

  void _showAdjustmentForm() {
    _StockItem? selected = _items.isEmpty ? null : _items.first;
    final qty = TextEditingController(text: '1');
    final reason = TextEditingController();
    String type = 'Damaged';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        title: const Text('Stock adjustment / damage'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<_StockItem>(
            value: selected,
            decoration: const InputDecoration(labelText: 'পণ্য'),
            items: _items.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
            onChanged: (v) => refresh(() => selected = v),
          ),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'Adjustment type'),
            items: ['Damaged','Lost','Expired','Write-off','Returned','Correction']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => refresh(() => type = v ?? type),
          ),
          _field(qty, 'পরিমাণ', number: true),
          _field(reason, 'কারণ ও approval reference'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () {
            final amount = _num(qty.text);
            if (selected == null || amount <= 0 || amount > selected!.available) return;
            setState(() {
              selected!.quantity -= amount;
              if (type == 'Damaged') selected!.damaged += amount;
              _record('STOCK $type', selected!.id, 'Qty $amount; ${reason.text}');
            });
            Navigator.pop(ctx);
          }, child: const Text('সংরক্ষণ')),
        ],
      )),
    );
  }

  void _showPartyForm({required bool isSupplier}) {
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final note = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSupplier ? 'Supplier যোগ' : 'Customer যোগ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(name, 'নাম *', required: true),
          _field(phone, 'ফোন / যোগাযোগ'),
          _field(address, 'ঠিকানা'),
          _field(note, 'নোট'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () {
            if (name.text.trim().isEmpty) return;
            setState(() {
              final p = _StockParty(name.text.trim(), phone.text.trim(), address.text.trim(), note.text.trim());
              (isSupplier ? _suppliers : _customers).add(p);
              _record(isSupplier ? 'ADD SUPPLIER' : 'ADD CUSTOMER', p.name, p.phone);
            });
            Navigator.pop(ctx);
          }, child: const Text('সংরক্ষণ')),
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
              if (_audit.isEmpty) _empty('কোনো রেকর্ড নেই') else ..._audit.map(_auditTile),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockItem {
  _StockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unit,
    required this.brand,
    required this.batch,
    required this.warehouse,
    required this.shelf,
    required this.quantity,
    required this.reorder,
    required this.landedCost,
    required this.salePrice,
    this.reserved = 0,
    this.damaged = 0,
    this.description = '',
    this.barcode = '',
    this.model = '',
    this.grade = '',
    this.warranty = '',
    this.expiry,
    this.archived = false,
  });

  final String id;
  String name, sku, category, unit, brand, batch, warehouse, shelf;
  double quantity, reorder, landedCost, salePrice, reserved, damaged;
  String description, barcode, model, grade, warranty;
  DateTime? expiry;
  bool archived;

  double get available => (quantity - reserved - damaged).clamp(0, double.infinity).toDouble();

  Map<String, Object?> toMap() => {
        'id': id, 'name': name, 'sku': sku, 'category': category, 'unit': unit,
        'brand': brand, 'batch': batch, 'warehouse': warehouse, 'shelf': shelf,
        'quantity': quantity, 'reorder': reorder, 'landedCost': landedCost,
        'salePrice': salePrice, 'reserved': reserved, 'damaged': damaged,
        'description': description, 'barcode': barcode, 'model': model,
        'grade': grade, 'warranty': warranty, 'expiry': expiry?.toIso8601String(),
      };
}

class _StockTransaction {
  _StockTransaction({
    required this.id, required this.type, required this.itemName,
    required this.itemId, required this.party, required this.phone,
    required this.invoice, required this.date, required this.quantity,
    required this.unitPrice, required this.discount, required this.tax,
    required this.total, required this.paid, required this.due,
    required this.paymentMethod, required this.paymentStatus,
    required this.location, required this.note, required this.landedExtra,
  });
  final String id, type, itemName, itemId, party, phone, invoice;
  final DateTime date;
  final double quantity, unitPrice, discount, tax, total, paid, due, landedExtra;
  final String paymentMethod, paymentStatus, location, note;
}

class _StockExpense {
  _StockExpense(this.title, this.category, this.amount, this.date, this.note);
  final String title, category, note;
  final double amount;
  final DateTime date;
}

class _StockAudit {
  _StockAudit(this.action, this.ref, this.detail, this.time, this.actor);
  final String action, ref, detail, actor;
  final DateTime time;
}

class _StockLocation {
  _StockLocation(this.name, this.type, this.description);
  final String name, type, description;
}

class _StockParty {
  _StockParty(this.name, this.phone, this.address, this.note);
  final String name, phone, address, note;
}

double _num(String value) => double.tryParse(value.trim()) ?? 0;
String _money(num value) => value.toStringAsFixed(2);
String _qty(num value) => value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _dateTime(DateTime value) =>
    '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
