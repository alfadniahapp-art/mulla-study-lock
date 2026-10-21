import 'package:flutter/material.dart';
import 'package:app_blocker/app_blocker.dart';

void main() {
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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AppBlocker _blocker = AppBlocker.instance;
  
  bool _hasPermission = false;
  bool _isLoading = true;
  List<AppInfo> _installedApps = [];
  Set<String> _selectedPackages = {};

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // دالة التهيئة: طلب الصلاحيات وجلب التطبيقات
  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    
    // 1. طلب الصلاحيات
    await _blocker.requestPermission();
    _hasPermission = await _blocker.hasPermission();

    // 2. جلب التطبيقات إذا كانت الصلاحية ممنوحة
    if (_hasPermission) {
      final apps = await _blocker.getApps();
      // ترتيب التطبيقات أبجدياً
      apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      _installedApps = apps;
    }

    setState(() => _isLoading = false);
  }

  // دالة بدء الجدول التجريبي (يبدأ الآن ولمدة 5 دقائق)
  Future<void> _startTestSchedule() async {
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تطبيق واحد على الأقل')),
      );
      return;
    }

    final now = DateTime.now();
    final endTime = now.add(const Duration(minutes: 5));

    // إنشاء الجدول
    final schedule = BlockSchedule(
      id: 'test_schedule_${now.millisecondsSinceEpoch}',
      name: 'جدول تجريبي',
      appIdentifiers: _selectedPackages.toList(),
      weekdays: [now.weekday], // اليوم الحالي
      startTime: TimeOfDay(hour: now.hour, minute: now.minute),
      endTime: TimeOfDay(hour: endTime.hour, minute: endTime.minute),
    );

    await _blocker.addSchedule(schedule);
    await _blocker.enableSchedule(schedule.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تفعيل القفل لمدة 5 دقائق! جرب فتح التطبيقات التي اخترتها.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قفل التطبيقات المجدول'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeApp,
            tooltip: 'تحديث الصلاحيات والتطبيقات',
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'يجب تفعيل صلاحية إمكانية الوصول (Accessibility)\nلكي يعمل التطبيق.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeApp,
              child: const Text('طلب الصلاحية الآن'),
            ),
          ],
        ),
      );
    }

    // عرض قائمة التطبيقات
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.teal.withOpacity(0.1),
          child: const Text(
            'اختر التطبيقات التي تريد قفلها أثناء فترة الدراسة:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _installedApps.length,
            itemBuilder: (context, index) {
              final app = _installedApps[index];
              final isSelected = _selectedPackages.contains(app.packageName);

              return CheckboxListTile(
                title: Text(app.appName),
                subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12)),
                secondary: app.icon != null 
                    ? Image.memory(app.icon!, width: 40, height: 40) 
                    : const Icon(Icons.android, size: 40),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedPackages.add(app.packageName);
                    } else {
                      _selectedPackages.remove(app.packageName);
                    }
                  });
                },
              );
            },
          ),
        ),
        // زر بدء التجربة
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _startTestSchedule,
              icon: const Icon(Icons.lock_clock),
              label: const Text('تجربة القفل الآن (لمدة 5 دقائق)', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
