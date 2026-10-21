import 'package:flutter/material.dart';
import 'package:app_blocker/app_blocker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MullaStudyLockApp());
}

class MullaStudyLockApp extends StatelessWidget {
  const MullaStudyLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mulla Study Lock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final AppBlocker _blocker = AppBlocker.instance;
  bool _hasPermission = false;
  List<BlockSchedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _blocker.requestPermission();
    final status = await _blocker.hasPermission();
    final schedules = await _blocker.getSchedules();
    setState(() {
      _hasPermission = status;
      _schedules = schedules;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قفل الدراسة المجدول'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: !_hasPermission
          ? _buildPermissionView()
          : _buildSchedulesView(),
      floatingActionButton: _hasPermission
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddScheduleScreen()),
                );
                _loadData(); // تحديث القائمة بعد العودة
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة جدول'),
            )
          : null,
    );
  }

  Widget _buildPermissionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'الرجاء تفعيل صلاحية إمكانية الوصول\nلكي يعمل التطبيق بشكل صحيح',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('منح الصلاحية'),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesView() {
    if (_schedules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('لا توجد جداول مضافة بعد.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.lock_clock, color: Colors.teal),
            title: Text(schedule.name),
            subtitle: Text('${schedule.startTime.format(context)} - ${schedule.endTime.format(context)}'),
            trailing: Switch(
              value: true, // يمكنك ربطها بحالة التفعيل الفعلية لاحقاً
              onChanged: (val) async {
                if (val) {
                  await _blocker.enableSchedule(schedule.id);
                } else {
                  await _blocker.disableSchedule(schedule.id);
                }
                _loadData();
              },
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// شاشة إضافة جدول جديد
// ==========================================
class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _nameController = TextEditingController(text: 'ساعات المدرسة');
  
  // ترميز الأيام (ISO): الاثنين=1 ... الأحد=7
  final List<int> _selectedDays = [7, 1, 2, 3, 4]; // الأحد إلى الخميس افتراضياً
  
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);

  // تطبيقات تجريبية للحظر (لاحقاً سنقرأها من الهاتف)
  final List<String> _blockedApps = [
    'com.whatsapp',
    'com.instagram.android',
    'com.facebook.katana',
  ];

  final Map<int, String> _daysMap = {
    1: 'الإثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (time != null) {
      setState(() {
        if (isStart) _startTime = time;
        else _endTime = time;
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_nameController.text.isEmpty || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الجدول واختيار يوم واحد على الأقل')),
      );
      return;
    }

    final schedule = BlockSchedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      appIdentifiers: _blockedApps,
      weekdays: _selectedDays,
      startTime: _startTime,
      endTime: _endTime,
    );

    await AppBlocker.instance.addSchedule(schedule);
    await AppBlocker.instance.enableSchedule(schedule.id);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جدول جديد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم الجدول',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          
          const Text('أيام الحظر:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _daysMap.entries.map((entry) {
              final isSelected = _selectedDays.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(entry.key);
                    } else {
                      _selectedDays.remove(entry.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(true),
                  icon: const Icon(Icons.access_time),
                  label: Text('من: ${_startTime.format(context)}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(false),
                  icon: const Icon(Icons.access_time),
                  label: Text('إلى: ${_endTime.format(context)}'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saveSchedule,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('حفظ وتفعيل الجدول', style: TextStyle(fontSize: 18)),
          )
        ],
      ),
    );
  }
}
