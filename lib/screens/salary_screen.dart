
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen>
    with SingleTickerProviderStateMixin {
  static const Color navy = Color(0xFF073B70);
  static const Color blue = Color(0xFF1264E8);
  static const Color bg = Color(0xFFF3F7FD);
  static const Color green = Color(0xFF16A765);
  static const Color orange = Color(0xFFF39A24);
  static const Color red = Color(0xFFE34D59);
  static const Color purple = Color(0xFF8156D9);

  late final TabController _tabs;
  final TextEditingController _search = TextEditingController();

  final List<Map<String, dynamic>> employees = [];
  final List<Map<String, dynamic>> attendance = [];
  final List<Map<String, dynamic>> payroll = [];
  final List<Map<String, dynamic>> leaves = [];
  final List<Map<String, dynamic>> advances = [];
  final List<Map<String, dynamic>> reviews = [];
  final List<Map<String, dynamic>> activity = [];
  final List<Map<String, dynamic>> holidays = [];
  final List<Map<String, dynamic>> shifts = [];
  final List<Map<String, dynamic>> departments = [];

  String searchText = '';
  String employeeFilter = 'সব';
  String payrollFilter = 'সব';
  String leaveFilter = 'সব';
  String reportPeriod = 'এই মাস';

  final List<String> tabNames = [
    'ড্যাশবোর্ড',
    'কর্মী',
    'হাজিরা',
    'বেতন',
    'ছুটি',
    'পারফরম্যান্স',
    'রিপোর্ট',
    'সেটিংস',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: tabNames.length, vsync: this);
    departments.addAll([
      {'name': 'প্রশাসন'},
      {'name': 'হিসাব বিভাগ'},
      {'name': 'বিক্রয়'},
      {'name': 'অপারেশন'},
      {'name': 'আইটি'},
      {'name': 'অন্যান্য'},
    ]);
    shifts.addAll([
      {'name': 'সকাল শিফট', 'start': '09:00 AM', 'end': '05:00 PM'},
      {'name': 'বিকাল শিফট', 'start': '02:00 PM', 'end': '10:00 PM'},
    ]);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  String money(dynamic value) {
    final n = double.tryParse('$value') ?? 0;
    return '৳${NumberFormat('#,##,##0.##').format(n)}';
  }

  String today() => DateFormat('dd MMM yyyy').format(DateTime.now());

  void logActivity(String action, String details) {
    activity.insert(0, {
      'action': action,
      'details': details,
      'date': DateTime.now(),
    });
  }

  void toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int get activeEmployees =>
      employees.where((e) => e['status'] == 'সক্রিয়').length;

  int get onLeave =>
      employees.where((e) => e['status'] == 'ছুটিতে').length;

  int get presentToday => attendance.where((a) =>
      a['date'] == DateFormat('yyyy-MM-dd').format(DateTime.now()) &&
      a['status'] == 'উপস্থিত').length;

  double get monthlyPayroll => payroll
      .where((p) => p['month'] == DateFormat('yyyy-MM').format(DateTime.now()))
      .fold(0.0, (sum, p) => sum + (double.tryParse('${p['net']}') ?? 0));

  double get totalSalary => employees.fold(
      0.0, (sum, e) => sum + (double.tryParse('${e['basic']}') ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Employee HR & Salary'),
        actions: [
          IconButton(
            tooltip: 'নোটিফিকেশন',
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            tooltip: 'নতুন কর্মী',
            onPressed: _addEmployee,
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: tabNames.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _dashboard(),
          _employeePage(),
          _attendancePage(),
          _payrollPage(),
          _leavePage(),
          _performancePage(),
          _reportsPage(),
          _settingsPage(),
        ],
      ),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              onPressed: _addEmployee,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Widget _page(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: child,
      );

  Widget _section(String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE3EAF4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: child,
      );

  Widget _statCard(String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return _card(
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _dashboard() {
    return _page(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Employee & HR Management',
                  style: TextStyle(
                      color: navy, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('আজ: ${today()}',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _addEmployee,
                      icon: const Icon(Icons.person_add),
                      label: const Text('কর্মী যোগ'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addAttendance,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('হাজিরা'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        _section('কর্মী ও হাজিরার সারাংশ'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _statCard('মোট কর্মী', '${employees.length}',
                Icons.groups_outlined, blue),
            _statCard('সক্রিয় কর্মী', '$activeEmployees',
                Icons.verified_user_outlined, green),
            _statCard('আজ উপস্থিত', '$presentToday',
                Icons.fact_check_outlined, green),
            _statCard('ছুটিতে', '$onLeave',
                Icons.flight_takeoff, orange),
          ],
        ),
        _section('বেতন ও আর্থিক সারাংশ'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _statCard('মাসিক বেসিক বেতন', money(totalSalary),
                Icons.account_balance_wallet_outlined, blue),
            _statCard('এই মাসের পে-রোল', money(monthlyPayroll),
                Icons.payments_outlined, green),
            _statCard(
                'বেতন বকেয়া',
                '${payroll.where((p) => p['status'] != 'পরিশোধিত').length}',
                Icons.pending_actions,
                red),
            _statCard('অগ্রিম/লোন', money(advances.fold<double>(
                0, (s, a) => s + (double.tryParse('${a['balance']}') ?? 0))),
                Icons.money_outlined, orange),
          ],
        ),
        _section('দ্রুত কাজ'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          children: [
            _quickAction('কর্মী', Icons.people, blue, () => _tabs.animateTo(1)),
            _quickAction(
                'হাজিরা', Icons.calendar_month, green, _addAttendance),
            _quickAction(
                'বেতন', Icons.payments, orange, () => _tabs.animateTo(3)),
            _quickAction(
                'ছুটি', Icons.beach_access, purple, () => _tabs.animateTo(4)),
            _quickAction('রিভিউ', Icons.trending_up, blue,
                () => _tabs.animateTo(5)),
            _quickAction('রিপোর্ট', Icons.analytics, green,
                () => _tabs.animateTo(6)),
          ],
        ),
        _section('সাম্প্রতিক কার্যক্রম'),
        _activityList(limit: 5),
      ],
    ));
  }

  Widget _quickAction(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: _card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 7),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))
          ],
        ),
      ),
    );
  }

  Widget _employeePage() {
    final filtered = employees.where((e) {
      final q = searchText.toLowerCase();
      final matches = '${e['name']} ${e['id']} ${e['department']}'
          .toLowerCase()
          .contains(q);
      final status = employeeFilter == 'সব' || e['status'] == employeeFilter;
      return matches && status;
    }).toList();

    return _page(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('কর্মী তালিকা',
            trailing: FilledButton.icon(
              onPressed: _addEmployee,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('নতুন'),
            )),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => searchText = v),
          decoration: InputDecoration(
            hintText: 'নাম, আইডি বা বিভাগ দিয়ে খুঁজুন',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: () {
                _search.clear();
                setState(() => searchText = '');
              },
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _chips(['সব', 'সক্রিয়', 'ছুটিতে', 'নিষ্ক্রিয়'], employeeFilter,
            (v) => setState(() => employeeFilter = v)),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          _empty('কোনো কর্মী পাওয়া যায়নি', Icons.people_outline)
        else
          ...filtered.map(_employeeTile),
      ],
    ));
  }

  Widget _employeeTile(Map<String, dynamic> e) {
    final status = e['status'] ?? 'সক্রিয়';
    final color = status == 'সক্রিয়'
        ? green
        : status == 'ছুটিতে'
            ? orange
            : red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: () => _employeeDetails(e),
        child: _card(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: blue.withOpacity(.12),
                child: Text(
                  (e['name'] ?? 'ক').toString().isNotEmpty
                      ? (e['name'] as String).substring(0, 1)
                      : 'ক',
                  style: const TextStyle(
                      color: blue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${e['id']} • ${e['department']}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('${e['designation']}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusBadge(status, color),
                  const SizedBox(height: 5),
                  Text(money(e['basic']),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _employeeDetails(Map<String, dynamic> e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 30,
                    backgroundColor: blue.withOpacity(.12),
                    child: const Icon(Icons.person, color: blue, size: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e['name']}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${e['id']} • ${e['designation']}'),
                      Text('${e['department']}'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _editEmployee(e);
                  },
                  icon: const Icon(Icons.edit),
                )
              ],
            ),
            const SizedBox(height: 12),
            _section('ব্যক্তিগত তথ্য'),
            _detail('ফোন', e['phone']),
            _detail('ইমেইল', e['email']),
            _detail('ঠিকানা', e['address']),
            _detail('জরুরি যোগাযোগ', e['emergency']),
            _detail('রক্তের গ্রুপ', e['blood']),
            _detail('জাতীয় পরিচয়পত্র', e['nid']),
            _section('চাকরি ও ডিউটি'),
            _detail('যোগদানের তারিখ', e['joining']),
            _detail('চাকরির ধরন', e['employmentType']),
            _detail('ডিউটি শিফট', e['shift']),
            _detail('কর্মদিবস', e['workingDays']),
            _detail('দায়িত্ব', e['responsibilities']),
            _section('বেতন'),
            _detail('মূল বেতন', money(e['basic'])),
            _detail('ভাতা', money(e['allowance'])),
            _detail('ওভারটাইম রেট', money(e['otRate'])),
            _detail('স্ট্যাটাস', e['status']),
            _section('নথি ও যোগ্যতা'),
            _detail('শিক্ষাগত যোগ্যতা', e['education']),
            _detail('ডকুমেন্ট রেফারেন্স', e['documents']),
            _detail('নোট', e['notes']),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _editEmployee(e);
              },
              icon: const Icon(Icons.edit),
              label: const Text('প্রোফাইল পরিবর্তন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 125,
                child: Text(label,
                    style: const TextStyle(color: Colors.black54))),
            Expanded(
                child: Text((value ?? '-').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  void _addEmployee() => _employeeForm();

  void _editEmployee(Map<String, dynamic> employee) =>
      _employeeForm(existing: employee);

  Future<void> _employeeForm({Map<String, dynamic>? existing}) async {
    final e = existing ?? <String, dynamic>{};
    final controllers = <String, TextEditingController>{};
    final fields = <String, String>{
      'name': 'পূর্ণ নাম *',
      'id': 'Employee ID *',
      'designation': 'পদবি',
      'department': 'বিভাগ',
      'phone': 'মোবাইল নম্বর',
      'email': 'ইমেইল',
      'address': 'ঠিকানা',
      'emergency': 'জরুরি যোগাযোগ',
      'blood': 'রক্তের গ্রুপ',
      'nid': 'জাতীয় পরিচয়পত্র নম্বর',
      'joining': 'যোগদানের তারিখ',
      'employmentType': 'চাকরির ধরন',
      'shift': 'ডিউটি শিফট',
      'workingDays': 'কর্মদিবস',
      'responsibilities': 'দায়িত্ব ও কাজের বিবরণ',
      'basic': 'মূল বেতন',
      'allowance': 'মাসিক ভাতা',
      'otRate': 'ওভারটাইম ঘণ্টাপ্রতি রেট',
      'education': 'শিক্ষাগত যোগ্যতা',
      'documents': 'ডকুমেন্ট/ফাইল রেফারেন্স',
      'notes': 'অতিরিক্ত নোট',
    };
    for (final key in fields.keys) {
      controllers[key] =
          TextEditingController(text: '${e[key] ?? ''}');
    }
    String status = '${e['status'] ?? 'সক্রিয়'}';
    String type = '${e['employmentType'] ?? 'স্থায়ী'}';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'নতুন কর্মী যোগ' : 'কর্মী তথ্য পরিবর্তন'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...fields.entries.map((entry) {
                    final key = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: TextField(
                        controller: controllers[key],
                        maxLines: [
                          'address',
                          'responsibilities',
                          'education',
                          'documents',
                          'notes'
                        ].contains(key)
                            ? 2
                            : 1,
                        keyboardType: [
                          'basic',
                          'allowance',
                          'otRate'
                        ].contains(key)
                            ? TextInputType.number
                            : TextInputType.text,
                        decoration: InputDecoration(labelText: entry.value),
                      ),
                    );
                  }),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration:
                        const InputDecoration(labelText: 'চাকরির ধরন'),
                    items: ['স্থায়ী', 'চুক্তিভিত্তিক', 'খণ্ডকালীন', 'অস্থায়ী']
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setDialog(() => type = v ?? type),
                  ),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'স্ট্যাটাস'),
                    items: ['সক্রিয়', 'ছুটিতে', 'নিষ্ক্রিয়']
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setDialog(() => status = v ?? status),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                if (controllers['name']!.text.trim().isEmpty ||
                    controllers['id']!.text.trim().isEmpty) {
                  toast('নাম ও Employee ID আবশ্যক।');
                  return;
                }
                final data = <String, dynamic>{
                  for (final key in fields.keys)
                    key: controllers[key]!.text.trim(),
                  'employmentType': type,
                  'status': status,
                };
                if (existing == null) {
                  if (employees.any((x) => x['id'] == data['id'])) {
                    toast('এই Employee ID আগে থেকেই আছে।');
                    return;
                  }
                  employees.add(data);
                  logActivity('কর্মী যোগ', data['name']);
                } else {
                  existing.addAll(data);
                  logActivity('কর্মী পরিবর্তন', data['name']);
                }
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  Widget _attendancePage() {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRows = attendance.where((a) => a['date'] == dateKey).toList();
    return _page(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('হাজিরা ব্যবস্থাপনা',
            trailing: FilledButton.icon(
                onPressed: _addAttendance,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('হাজিরা যোগ'))),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.9,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          children: [
            _statCard('উপস্থিত', '${todayRows.where((a) => a['status'] == 'উপস্থিত').length}', Icons.check_circle, green),
            _statCard('অনুপস্থিত', '${todayRows.where((a) => a['status'] == 'অনুপস্থিত').length}', Icons.cancel, red),
            _statCard('দেরি', '${todayRows.where((a) => a['status'] == 'দেরি').length}', Icons.watch_later, orange),
            _statCard('ছুটি', '${todayRows.where((a) => a['status'] == 'ছুটি').length}', Icons.beach_access, purple),
          ],
        ),
        _section('আজকের হাজিরা'),
        if (todayRows.isEmpty)
          _empty('আজকের হাজিরা যোগ করা হয়নি', Icons.calendar_month)
        else
          ...todayRows.map((a) => _attendanceTile(a)),
        _section('হাজিরার ইতিহাস'),
        ...attendance.reversed.map(_attendanceTile),
        _section('শিফট ও ডিউটি'),
        ...shifts.map((s) => _card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: blue),
                title: Text('${s['name']}'),
                subtitle: Text('${s['start']} — ${s['end']}'),
                trailing: IconButton(
                    onPressed: () => _editShift(s),
                    icon: const Icon(Icons.edit)),
              ),
            )),
        OutlinedButton.icon(
          onPressed: _addShift,
          icon: const Icon(Icons.add),
          label: const Text('নতুন শিফট যোগ'),
        ),
        _section('ছুটি ও Holiday Calendar'),
        ...holidays.map((h) => _card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event, color: purple),
                title: Text('${h['name']}'),
                subtitle: Text('${h['date']} • ${h['type']}'),
              ),
            )),
        OutlinedButton.icon(
            onPressed: _addHoliday,
            icon: const Icon(Icons.add),
            label: const Text('ছুটি/হলিডে যোগ')),
      ],
    ));
  }

  Widget _attendanceTile(Map<String, dynamic> a) {
    final color = a['status'] == 'উপস্থিত'
        ? green
        : a['status'] == 'দেরি'
            ? orange
            : red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _card(
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: blue),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${a['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${a['date']} • ${a['in']} – ${a['out']}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('OT: ${a['overtime']} ঘণ্টা • ${a['note']}',
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            _statusBadge('${a['status']}', color),
          ],
        ),
      ),
    );
  }

  Future<void> _addAttendance() async {
    if (employees.isEmpty) {
      toast('আগে কর্মী যোগ করুন।');
      return;
    }
    String employeeId = '${employees.first['id']}';
    String status = 'উপস্থিত';
    final inTime = TextEditingController(text: '09:00 AM');
    final outTime = TextEditingController(text: '05:00 PM');
    final overtime = TextEditingController(text: '0');
    final note = TextEditingController();
    DateTime date = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('হাজিরা রেকর্ড'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: employeeId,
                  decoration: const InputDecoration(labelText: 'কর্মী'),
                  items: employees
                      .map((e) => DropdownMenuItem<String>(
                          value: '${e['id']}',
                          child: Text('${e['name']} (${e['id']})')))
                      .toList(),
                  onChanged: (v) => setDialog(() => employeeId = v!),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(DateFormat('dd MMM yyyy').format(date)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: date,
                    );
                    if (picked != null) setDialog(() => date = picked);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'অবস্থা'),
                  items: ['উপস্থিত', 'অনুপস্থিত', 'দেরি', 'ছুটি', 'আর্লি এক্সিট']
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setDialog(() => status = v!),
                ),
                TextField(
                    controller: inTime,
                    decoration: const InputDecoration(labelText: 'প্রবেশ সময়')),
                TextField(
                    controller: outTime,
                    decoration: const InputDecoration(labelText: 'বাহির সময়')),
                TextField(
                    controller: overtime,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'ওভারটাইম ঘণ্টা')),
                TextField(
                    controller: note,
                    decoration: const InputDecoration(labelText: 'নোট')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final emp = employees.firstWhere((e) => e['id'] == employeeId);
                final key = DateFormat('yyyy-MM-dd').format(date);
                final existing = attendance.indexWhere(
                    (a) => a['employeeId'] == employeeId && a['date'] == key);
                final data = {
                  'employeeId': employeeId,
                  'name': emp['name'],
                  'date': key,
                  'status': status,
                  'in': inTime.text,
                  'out': outTime.text,
                  'overtime': overtime.text,
                  'note': note.text,
                };
                if (existing >= 0) {
                  attendance[existing] = data;
                } else {
                  attendance.add(data);
                }
                logActivity('হাজিরা রেকর্ড', '${emp['name']} • $status');
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('সংরক্ষণ'),
            )
          ],
        ),
      ),
    );
    inTime.dispose();
    outTime.dispose();
    overtime.dispose();
    note.dispose();
  }

  void _addShift() => _shiftForm();

  void _editShift(Map<String, dynamic> shift) => _shiftForm(existing: shift);

  Future<void> _shiftForm({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final start = TextEditingController(text: '${existing?['start'] ?? ''}');
    final end = TextEditingController(text: '${existing?['end'] ?? ''}');
    await _simpleForm(
      title: existing == null ? 'নতুন শিফট' : 'শিফট পরিবর্তন',
      fields: [
        _FormField('শিফটের নাম', name),
        _FormField('শুরুর সময়', start),
        _FormField('শেষ সময়', end),
      ],
      onSave: () {
        final data = {'name': name.text, 'start': start.text, 'end': end.text};
        if (existing == null) {
          shifts.add(data);
        } else {
          existing.addAll(data);
        }
        logActivity('শিফট পরিবর্তন', name.text);
      },
    );
    name.dispose();
    start.dispose();
    end.dispose();
  }

  Future<void> _addHoliday() async {
    final name = TextEditingController();
    final date = TextEditingController(text: today());
    final type = TextEditingController(text: 'সরকারি ছুটি');
    await _simpleForm(
      title: 'ছুটি/হলিডে যোগ',
      fields: [
        _FormField('ছুটির নাম', name),
        _FormField('তারিখ', date),
        _FormField('ধরন', type),
      ],
      onSave: () {
        holidays.add({
          'name': name.text,
          'date': date.text,
          'type': type.text,
        });
        logActivity('হলিডে যোগ', name.text);
      },
    );
    name.dispose();
    date.dispose();
    type.dispose();
  }

  Widget _payrollPage() {
    final rows = payroll.where((p) {
      return payrollFilter == 'সব' || p['status'] == payrollFilter;
    }).toList();
    return _page(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Salary & Payroll',
            trailing: FilledButton.icon(
              onPressed: _generatePayroll,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('পে-রোল'),
            )),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('এই মাসের মোট বেতন',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 5),
              Text(money(monthlyPayroll),
                  style: const TextStyle(
                      fontSize: 25, color: navy, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('মোট কর্মী: ${employees.length}'),
            ],
          ),
        ),
        _section('পে-রোল স্ট্যাটাস'),
        _chips(['সব', 'পরিশোধিত', 'অপেক্ষমাণ'], payrollFilter,
            (v) => setState(() => payrollFilter = v)),
        if (rows.isEmpty)
          _empty('এখনো কোনো বেতন রেকর্ড নেই', Icons.payments_outlined)
        else
          ...rows.reversed.map(_payrollTile),
        _section('অগ্রিম বেতন ও ঋণ'),
        FilledButton.icon(
            onPressed: _addAdvance,
            icon: const Icon(Icons.add),
            label: const Text('অগ্রিম বেতন যোগ')),
        if (advances.isEmpty)
          _empty('অগ্রিম বেতনের রেকর্ড নেই', Icons.money)
        else
          ...advances.reversed.map((a) => _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    _detail('তারিখ', a['date']),
                    _detail('মূল টাকা', money(a['amount'])),
                    _detail('পরিশোধ', money(a['recovered'])),
                    _detail('বাকি', money(a['balance'])),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _recoverAdvance(a),
                        child: const Text('কিস্তি/রিকভারি যোগ'),
                      ),
                    )
                  ],
                ),
              )),
      ],
    ));
  }

  Widget _payrollTile(Map<String, dynamic> p) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _card(
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: blue),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${p['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${p['month']} • ${p['employeeId']}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  _statusBadge(
                      '${p['status']}',
                      p['status'] == 'পরিশোধিত' ? green : orange),
                ],
              ),
              const Divider(),
              _detail('মূল বেতন', money(p['basic'])),
              _detail('ভাতা', money(p['allowance'])),
              _detail('বোনাস/ইনসেনটিভ', money(p['bonus'])),
              _detail('ওভারটাইম', money(p['overtimePay'])),
              _detail('কর্তন', money(p['deduction'])),
              _detail('অগ্রিম কর্তন', money(p['advanceDeduction'])),
              const Divider(),
              _detail('নেট বেতন', money(p['net'])),
              _detail('পেমেন্ট তারিখ', p['paymentDate']),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _payslip(p),
                    icon: const Icon(Icons.receipt),
                    label: const Text('পে-স্লিপ'),
                  ),
                  if (p['status'] != 'পরিশোধিত')
                    TextButton.icon(
                      onPressed: () => _markPaid(p),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('পরিশোধ করুন'),
                    ),
                ],
              )
            ],
          ),
        ),
      );

  Future<void> _generatePayroll() async {
    if (employees.isEmpty) {
      toast('আগে কর্মী যোগ করুন।');
      return;
    }
    String employeeId = '${employees.first['id']}';
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final bonus = TextEditingController(text: '0');
    final deduction = TextEditingController(text: '0');
    final advanceDeduction = TextEditingController(text: '0');
    final overtimeHours = TextEditingController(text: '0');
    final note = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('মাসিক পে-রোল তৈরি'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: employeeId,
                  decoration: const InputDecoration(labelText: 'কর্মী'),
                  items: employees
                      .map((e) => DropdownMenuItem<String>(
                          value: '${e['id']}',
                          child: Text('${e['name']}')))
                      .toList(),
                  onChanged: (v) => setDialog(() => employeeId = v!),
                ),
                _readOnly('বেতন মাস', month),
                _readOnly('মূল বেতন', money(employees.firstWhere(
                    (e) => e['id'] == employeeId)['basic'])),
                _input(bonus, 'বোনাস/ইনসেনটিভ'),
                _input(deduction, 'অন্যান্য কর্তন'),
                _input(advanceDeduction, 'অগ্রিম বেতন কর্তন'),
                _input(overtimeHours, 'ওভারটাইম ঘণ্টা'),
                _input(note, 'নোট'),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final e = employees.firstWhere((x) => x['id'] == employeeId);
                if (payroll.any((p) =>
                    p['employeeId'] == employeeId && p['month'] == month)) {
                  toast('এই মাসের পে-রোল আগে তৈরি করা হয়েছে।');
                  return;
                }
                final basic = double.tryParse('${e['basic']}') ?? 0;
                final allowance = double.tryParse('${e['allowance']}') ?? 0;
                final b = double.tryParse(bonus.text) ?? 0;
                final d = double.tryParse(deduction.text) ?? 0;
                final ad = double.tryParse(advanceDeduction.text) ?? 0;
                final hours = double.tryParse(overtimeHours.text) ?? 0;
                final otRate = double.tryParse('${e['otRate']}') ?? 0;
                final otPay = hours * otRate;
                final net = basic + allowance + b + otPay - d - ad;
                payroll.add({
                  'employeeId': employeeId,
                  'name': e['name'],
                  'month': month,
                  'basic': basic,
                  'allowance': allowance,
                  'bonus': b,
                  'deduction': d,
                  'advanceDeduction': ad,
                  'overtimeHours': hours,
                  'overtimePay': otPay,
                  'net': net,
                  'note': note.text,
                  'status': 'অপেক্ষমাণ',
                  'paymentDate': '-',
                });
                logActivity('পে-রোল তৈরি', '${e['name']} • $month');
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('পে-রোল তৈরি'),
            )
          ],
        ),
      ),
    );
    bonus.dispose();
    deduction.dispose();
    advanceDeduction.dispose();
    overtimeHours.dispose();
    note.dispose();
  }

  void _markPaid(Map<String, dynamic> p) {
    setState(() {
      p['status'] = 'পরিশোধিত';
      p['paymentDate'] = today();
    });
    logActivity('বেতন পরিশোধ', '${p['name']} • ${p['month']}');
  }

  void _payslip(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salary Payslip'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Employee HR & Payroll',
                  style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
              const Divider(),
              _detail('কর্মীর নাম', p['name']),
              _detail('Employee ID', p['employeeId']),
              _detail('বেতন মাস', p['month']),
              const Divider(),
              _detail('মূল বেতন', money(p['basic'])),
              _detail('ভাতা', money(p['allowance'])),
              _detail('বোনাস', money(p['bonus'])),
              _detail('ওভারটাইম', money(p['overtimePay'])),
              _detail('কর্তন', money(p['deduction'])),
              _detail('অগ্রিম কর্তন', money(p['advanceDeduction'])),
              const Divider(),
              _detail('নেট বেতন', money(p['net'])),
              _detail('স্ট্যাটাস', p['status']),
              _detail('পরিশোধের তারিখ', p['paymentDate']),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বন্ধ')),
        ],
      ),
    );
  }

  Future<void> _addAdvance() async {
    if (employees.isEmpty) {
      toast('আগে কর্মী যোগ করুন।');
      return;
    }
    String employeeId = '${employees.first['id']}';
    final amount = TextEditingController();
    final recovered = TextEditingController(text: '0');
    final date = TextEditingController(text: today());
    final reason = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('অগ্রিম বেতন/ঋণ যোগ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: employeeId,
                decoration: const InputDecoration(labelText: 'কর্মী'),
                items: employees
                    .map((e) => DropdownMenuItem<String>(
                        value: '${e['id']}', child: Text('${e['name']}')))
                    .toList(),
                onChanged: (v) => setDialog(() => employeeId = v!),
              ),
              _input(amount, 'অগ্রিম টাকার পরিমাণ'),
              _input(recovered, 'ইতোমধ্যে পরিশোধ'),
              _input(date, 'তারিখ'),
              _input(reason, 'কারণ/নোট'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final e = employees.firstWhere((x) => x['id'] == employeeId);
                final a = double.tryParse(amount.text) ?? 0;
                final r = double.tryParse(recovered.text) ?? 0;
                if (a <= 0 || r > a) {
                  toast('সঠিক টাকার পরিমাণ দিন।');
                  return;
                }
                advances.add({
                  'employeeId': employeeId,
                  'name': e['name'],
                  'amount': a,
                  'recovered': r,
                  'balance': a - r,
                  'date': date.text,
                  'reason': reason.text,
                });
                logActivity('অগ্রিম বেতন যোগ', e['name']);
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('সংরক্ষণ'),
            )
          ],
        ),
      ),
    );
    amount.dispose();
    recovered.dispose();
    date.dispose();
    reason.dispose();
  }

  Future<void> _recoverAdvance(Map<String, dynamic> a) async {
    final amount = TextEditingController();
    await _simpleForm(
      title: 'অগ্রিম টাকা রিকভারি',
      fields: [_FormField('রিকভারি টাকার পরিমাণ', amount)],
      onSave: () {
        final value = double.tryParse(amount.text) ?? 0;
        final balance = double.tryParse('${a['balance']}') ?? 0;
        if (value <= 0 || value > balance) {
          toast('বাকি টাকার মধ্যে সঠিক পরিমাণ দিন।');
          return;
        }
        a['recovered'] = (double.tryParse('${a['recovered']}') ?? 0) + value;
        a['balance'] = balance - value;
        logActivity('অগ্রিম রিকভারি', '${a['name']} • ${money(value)}');
      },
    );
    amount.dispose();
  }

  Widget _leavePage() {
    final rows = leaves.where((l) {
      return leaveFilter == 'সব' || l['status'] == leaveFilter;
    }).toList();
    final totalEntitlement = 24;
    final used = leaves
        .where((l) => l['status'] == 'অনুমোদিত')
        .fold<int>(0, (s, l) => s + (int.tryParse('${l['days']}') ?? 0));
    return _page(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Leave Management',
            trailing: FilledButton.icon(
                onPressed: _applyLeave,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ছুটির আবেদন'))),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _statCard('মোট', '$totalEntitlement', Icons.beach_access, blue),
            _statCard('ব্যবহৃত', '$used', Icons.check_circle, green),
            _statCard('অবশিষ্ট', '${(totalEntitlement - used).clamp(0, totalEntitlement)}', Icons.hourglass_bottom, orange),
          ],
        ),
        _section('ছুটির আবেদন'),
        _chips(['সব', 'অপেক্ষমাণ', 'অনুমোদিত', 'প্রত্যাখ্যাত'], leaveFilter,
            (v) => setState(() => leaveFilter = v)),
        if (rows.isEmpty)
          _empty('কোনো ছুটির আবেদন নেই', Icons.beach_access)
        else
          ...rows.reversed.map(_leaveTile),
        _section('ছুটির ধরন'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            'নৈমিত্তিক',
            'অসুস্থতা',
            'বার্ষিক',
            'উৎসব',
            'বিনা বেতনে',
            'বিশেষ',
          ].map((e) => Chip(label: Text(e))).toList(),
        ),
      ],
    ));
  }

  Widget _leaveTile(Map<String, dynamic> l) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${l['name']} • ${l['type']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  _statusBadge(
                      '${l['status']}',
                      l['status'] == 'অনুমোদিত'
                          ? green
                          : l['status'] == 'প্রত্যাখ্যাত'
                              ? red
                              : orange),
                ],
              ),
              _detail('তারিখ', '${l['from']} — ${l['to']}'),
              _detail('দিন', l['days']),
              _detail('কারণ', l['reason']),
              if (l['status'] == 'অপেক্ষমাণ')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _updateLeave(l, 'প্রত্যাখ্যাত'),
                      child: const Text('প্রত্যাখ্যান'),
                    ),
                    FilledButton(
                      onPressed: () => _updateLeave(l, 'অনুমোদিত'),
                      child: const Text('অনুমোদন'),
                    )
                  ],
                ),
            ],
          ),
        ),
      );

  Future<void> _applyLeave() async {
    if (employees.isEmpty) {
      toast('আগে কর্মী যোগ করুন।');
      return;
    }
    String employeeId = '${employees.first['id']}';
    String type = 'নৈমিত্তিক';
    final from = TextEditingController(text: today());
    final to = TextEditingController(text: today());
    final days = TextEditingController(text: '1');
    final reason = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('ছুটির আবেদন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: employeeId,
                  decoration: const InputDecoration(labelText: 'কর্মী'),
                  items: employees
                      .map((e) => DropdownMenuItem<String>(
                          value: '${e['id']}', child: Text('${e['name']}')))
                      .toList(),
                  onChanged: (v) => setDialog(() => employeeId = v!),
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'ছুটির ধরন'),
                  items: [
                    'নৈমিত্তিক',
                    'অসুস্থতা',
                    'বার্ষিক',
                    'উৎসব',
                    'বিনা বেতনে',
                    'বিশেষ'
                  ]
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setDialog(() => type = v!),
                ),
                _input(from, 'শুরুর তারিখ'),
                _input(to, 'শেষ তারিখ'),
                _input(days, 'মোট দিন'),
                _input(reason, 'আবেদনের কারণ'),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final e = employees.firstWhere((x) => x['id'] == employeeId);
                leaves.add({
                  'employeeId': employeeId,
                  'name': e['name'],
                  'type': type,
                  'from': from.text,
                  'to': to.text,
                  'days': int.tryParse(days.text) ?? 1,
                  'reason': reason.text,
                  'status': 'অপেক্ষমাণ',
                });
                logActivity('ছুটির আবেদন', e['name']);
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('আবেদন জমা'),
            )
          ],
        ),
      ),
    );
    from.dispose();
    to.dispose();
    days.dispose();
    reason.dispose();
  }

  void _updateLeave(Map<String, dynamic> l, String status) {
    setState(() => l['status'] = status);
    logActivity('ছুটি $status', l['name']);
  }

  Widget _performancePage() {
    return _page(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Performance & History',
            trailing: FilledButton.icon(
                onPressed: _addReview,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('রিভিউ যোগ'))),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('পারফরম্যান্স রিভিউ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                  'কর্মীর কাজের মান, লক্ষ্য পূরণ, দক্ষতা, সময়ানুবর্তিতা ও আচরণ মূল্যায়ন করুন।',
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        if (reviews.isEmpty)
          _empty('কোনো রিভিউ যোগ করা হয়নি', Icons.trending_up)
        else
          ...reviews.reversed.map((r) => _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    _detail('তারিখ', r['date']),
                    _detail('স্কোর', '${r['rating']}/5'),
                    _detail('লক্ষ্য/ফলাফল', r['goals']),
                    _detail('মন্তব্য', r['comment']),
                    _detail('অর্জন', r['achievement']),
                  ],
                ),
              )),
        _section('চাকরির ইতিহাস'),
        ...employees.map((e) => _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  _detail('পদবি', e['designation']),
                  _detail('বিভাগ', e['department']),
                  _detail('যোগদান', e['joining']),
                  _detail('স্ট্যাটাস', e['status']),
                ],
              ),
            )),
        _section('Promotion / Warning / Resignation'),
        OutlinedButton.icon(
          onPressed: _addEmploymentEvent,
          icon: const Icon(Icons.history),
          label: const Text('চাকরির ইতিহাস/পরিবর্তন যোগ'),
        ),
        _activityList(),
      ],
    ));
  }

  Future<void> _addReview() async {
    if (employees.isEmpty) {
      toast('আগে কর্মী যোগ করুন।');
      return;
    }
    String employeeId = '${employees.first['id']}';
    String rating = '5';
    final goals = TextEditingController();
    final comment = TextEditingController();
    final achievement = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Performance Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: employeeId,
                decoration: const InputDecoration(labelText: 'কর্মী'),
                items: employees
                    .map((e) => DropdownMenuItem<String>(
                        value: '${e['id']}', child: Text('${e['name']}')))
                    .toList(),
                onChanged: (v) => setDialog(() => employeeId = v!),
              ),
              DropdownButtonFormField<String>(
                value: rating,
                decoration: const InputDecoration(labelText: 'রেটিং'),
                items: ['1', '2', '3', '4', '5']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setDialog(() => rating = v!),
              ),
              _input(goals, 'লক্ষ্য ও ফলাফল'),
              _input(comment, 'রিভিউ মন্তব্য'),
              _input(achievement, 'অর্জন/পুরস্কার'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final e = employees.firstWhere((x) => x['id'] == employeeId);
                reviews.add({
                  'employeeId': employeeId,
                  'name': e['name'],
                  'date': today(),
                  'rating': rating,
                  'goals': goals.text,
                  'comment': comment.text,
                  'achievement': achievement.text,
                });
                logActivity('পারফরম্যান্স রিভিউ', e['name']);
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('সংরক্ষণ'),
            )
          ],
        ),
      ),
    );
    goals.dispose();
    comment.dispose();
    achievement.dispose();
  }

  Future<void> _addEmploymentEvent() async {
    if (employees.isEmpty) {
      toast('আগে কর্মী যোগ করুন।');
      return;
    }
    String employeeId = '${employees.first['id']}';
    String type = 'পদোন্নতি';
    final details = TextEditingController();
    final reason = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('চাকরির ইতিহাস যোগ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: employeeId,
                items: employees
                    .map((e) => DropdownMenuItem<String>(
                        value: '${e['id']}', child: Text('${e['name']}')))
                    .toList(),
                onChanged: (v) => setDialog(() => employeeId = v!),
                decoration: const InputDecoration(labelText: 'কর্মী'),
              ),
              DropdownButtonFormField<String>(
                value: type,
                items: [
                  'পদোন্নতি',
                  'বিভাগ পরিবর্তন',
                  'পদবি পরিবর্তন',
                  'বেতন পরিবর্তন',
                  'সতর্কবার্তা',
                  'অর্জন',
                  'পদত্যাগ',
                  'চাকরিচ্যুতি'
                ]
                    .map((v) =>
                        DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setDialog(() => type = v!),
                decoration: const InputDecoration(labelText: 'ইভেন্ট'),
              ),
              _input(details, 'বিস্তারিত'),
              _input(reason, 'কারণ/নোট'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final e = employees.firstWhere((x) => x['id'] == employeeId);
                logActivity(type, '${e['name']}: ${details.text} ${reason.text}');
                Navigator.pop(ctx);
                toast('ইতিহাস কার্যক্রম লগে যুক্ত হয়েছে।');
              },
              child: const Text('সংরক্ষণ'),
            )
          ],
        ),
      ),
    );
    details.dispose();
    reason.dispose();
  }

  Widget _reportsPage() {
    final paid = payroll.where((p) => p['status'] == 'পরিশোধিত').length;
    final pending = payroll.length - paid;
    final totalPaid = payroll
        .where((p) => p['status'] == 'পরিশোধিত')
        .fold<double>(0, (s, p) => s + (double.tryParse('${p['net']}') ?? 0));
    return _page(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Reports & Analytics'),
        DropdownButtonFormField<String>(
          value: reportPeriod,
          decoration: const InputDecoration(labelText: 'রিপোর্ট সময়সীমা'),
          items: ['এই মাস', 'গত মাস', 'এই বছর', 'সকল সময়']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => reportPeriod = v!),
        ),
        _section('রিপোর্ট সারাংশ'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          children: [
            _statCard('মোট পে-রোল', '${payroll.length}', Icons.receipt, blue),
            _statCard('পরিশোধিত', '$paid', Icons.check_circle, green),
            _statCard('অপেক্ষমাণ', '$pending', Icons.pending, orange),
            _statCard('পরিশোধের পরিমাণ', money(totalPaid), Icons.payments, green),
          ],
        ),
        _section('রিপোর্ট ক্যাটাগরি'),
        _reportTile('Attendance Report', Icons.calendar_month,
            'উপস্থিতি, অনুপস্থিতি, দেরি ও ওভারটাইম', () => _showReport('হাজিরা')),
        _reportTile('Salary Report', Icons.payments,
            'বেতন, বোনাস, কর্তন, পে-রোল ও পেমেন্ট', () => _showReport('বেতন')),
        _reportTile('Leave Report', Icons.beach_access,
            'ছুটির আবেদন, ব্যবহার ও অবশিষ্ট', () => _showReport('ছুটি')),
        _reportTile('Performance Report', Icons.trending_up,
            'রিভিউ, রেটিং ও অর্জন', () => _showReport('পারফরম্যান্স')),
        _reportTile('Employee Report', Icons.people,
            'কর্মী, বিভাগ ও চাকরির অবস্থা', () => _showReport('কর্মী')),
        _section('Export Data'),
        _card(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('রিপোর্ট Export',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(
                'PDF, Excel/Spreadsheet ও Print সুবিধা পরবর্তী Export service-এর সঙ্গে যুক্ত হবে।',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _reportTile(
      String title, IconData icon, String subtitle, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: blue),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        ),
      );

  void _showReport(String type) {
    String content;
    if (type == 'কর্মী') {
      content = employees
          .map((e) =>
              '${e['id']} | ${e['name']} | ${e['department']} | ${e['status']}')
          .join('\n');
    } else if (type == 'বেতন') {
      content = payroll
          .map((p) =>
              '${p['name']} | ${p['month']} | ${money(p['net'])} | ${p['status']}')
          .join('\n');
    } else if (type == 'ছুটি') {
      content = leaves
          .map((l) =>
              '${l['name']} | ${l['type']} | ${l['from']} - ${l['to']} | ${l['status']}')
          .join('\n');
    } else if (type == 'হাজিরা') {
      content = attendance
          .map((a) =>
              '${a['name']} | ${a['date']} | ${a['status']} | OT ${a['overtime']}')
          .join('\n');
    } else {
      content = reviews
          .map((r) =>
              '${r['name']} | ${r['date']} | ${r['rating']}/5 | ${r['achievement']}')
          .join('\n');
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$type রিপোর্ট'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: SelectableText(content.isEmpty ? 'কোনো তথ্য নেই।' : content),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বন্ধ')),
        ],
      ),
    );
  }

  Widget _settingsPage() {
    return _page(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('HR Settings'),
        _settingsTile(Icons.business, 'Department Management',
            'বিভাগ যোগ ও ব্যবস্থাপনা', _manageDepartments),
        _settingsTile(Icons.schedule, 'Shift Management',
            'ডিউটি শিফট ও সময়', () => _tabs.animateTo(2)),
        _settingsTile(Icons.event, 'Holiday & Calendar',
            'সরকারি, উৎসব ও কাস্টম ছুটি', _addHoliday),
        _settingsTile(Icons.notifications, 'Notifications',
            'বেতন, হাজিরা ও ছুটির নোটিফিকেশন', _showNotifications),
        _settingsTile(Icons.security, 'Privacy & Permissions',
            'Admin/Employee access control', _showPermissions),
        _settingsTile(Icons.history, 'Activity / Audit History',
            'পরিবর্তন, অনুমোদন ও কার্যক্রম লগ', () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Activity History'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(child: _activityList()),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('বন্ধ'))
              ],
            ),
          );
        }),
        _section('ডেটা ও নিরাপত্তা'),
        _card(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('গুরুত্বপূর্ণ নিরাপত্তা নোট',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(
                'NID, বেতন, ফোন, ঠিকানা ও কর্মীর ডকুমেন্ট সীমিত অনুমতিতে দেখাতে হবে। Admin সব ব্যবস্থাপনা করতে পারবেন; কর্মী কেবল অনুমোদিত নিজের তথ্য দেখতে পারবেন। এই অনুমতি সার্ভার/API-তেও যাচাই করতে হবে।',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _settingsTile(
          IconData icon, String title, String subtitle, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: blue),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        ),
      );

  void _manageDepartments() {
    final name = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Department Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ...departments.map((d) => ListTile(
                  title: Text('${d['name']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: red),
                    onPressed: () {
                      setState(() => departments.remove(d));
                      Navigator.pop(ctx);
                    },
                  ),
                )),
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'নতুন বিভাগ')),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                setState(() => departments.add({'name': name.text.trim()}));
                logActivity('বিভাগ যোগ', name.text);
                Navigator.pop(ctx);
              },
              child: const Text('বিভাগ যোগ'),
            )
          ],
        ),
      ),
    ).whenComplete(name.dispose);
  }

  void _showNotifications() {
    final pendingLeaves =
        leaves.where((l) => l['status'] == 'অপেক্ষমাণ').length;
    final pendingPayroll =
        payroll.where((p) => p['status'] != 'পরিশোধিত').length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detail('অপেক্ষমাণ ছুটি', pendingLeaves),
            _detail('অপেক্ষমাণ বেতন', pendingPayroll),
            _detail('মোট কর্মী', employees.length),
            _detail('আজকের তারিখ', today()),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বন্ধ')),
        ],
      ),
    );
  }

  void _showPermissions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Permissions'),
        content: const Text(
          'Admin: কর্মী, বেতন, হাজিরা, ছুটি, রিপোর্ট ও সেটিংস পরিচালনা।\n\nEmployee: নিজের প্রোফাইল, হাজিরা, বেতন স্লিপ ও ছুটির তথ্য দেখা এবং অনুমোদিত আবেদন।\n\nএই নিয়মগুলো Google Apps Script API-তে যাচাই না করা পর্যন্ত এগুলো কেবল UI নির্দেশনা।',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বন্ধ')),
        ],
      ),
    );
  }

  Widget _activityList({int? limit}) {
    final rows = limit == null ? activity : activity.take(limit).toList();
    if (rows.isEmpty) {
      return _empty('এখনো কোনো কার্যক্রম নেই', Icons.history);
    }
    return Column(
      children: rows.map((a) {
        final date = a['date'] as DateTime;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF1FF),
              child: Icon(Icons.history, color: blue)),
          title: Text('${a['action']}'),
          subtitle: Text('${a['details']}'),
          trailing: Text(DateFormat('dd/MM HH:mm').format(date),
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        );
      }).toList(),
    );
  }

  Widget _chips(
      List<String> values, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 7,
      children: values
          .map((v) => ChoiceChip(
                label: Text(v),
                selected: selected == v,
                onSelected: (_) => onSelect(v),
                selectedColor: blue.withOpacity(.15),
                labelStyle: TextStyle(
                    color: selected == v ? blue : Colors.black87,
                    fontWeight:
                        selected == v ? FontWeight.bold : FontWeight.normal),
              ))
          .toList(),
    );
  }

  Widget _statusBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _empty(String message, IconData icon) => _card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Icon(icon, color: Colors.black26, size: 34),
                const SizedBox(height: 8),
                Text(message,
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
      );

  Widget _input(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: TextField(
          controller: c,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _readOnly(String label, String value) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(value),
      );

  Future<void> _simpleForm({
    required String title,
    required List<_FormField> fields,
    required VoidCallback onSave,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields.map((f) => _input(f.controller, f.label)).toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল')),
          FilledButton(
            onPressed: () {
              onSave();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }
}

class _FormField {
  final String label;
  final TextEditingController controller;

  _FormField(this.label, this.controller);
}
