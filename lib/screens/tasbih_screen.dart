import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int counter = 0;
  int targetCount = 33;
  final TextEditingController _dhikrController = TextEditingController();
  String dhikrText = 'سبحان الله';
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  void _initializeAudio() async {
    await _audioPlayer.setSource(AssetSource('sounds/tasbih_sound.mp3'));
  }

  void _incrementCounter() async {
    if (counter < targetCount) {
      setState(() {
        counter++;
      });

      await _playTasbihSound();

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }
    }
  }

  // تشغيل صوت السبحة
  Future<void> _playTasbihSound() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('خطأ في تشغيل الصوت: $e');
    }
  }

  void _reset() {
    setState(() {
      counter = 0;
    });
  }

  void _showAddDhikrDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ذكر جديد'),
        content: TextField(
          controller: _dhikrController,
          decoration: const InputDecoration(
            hintText: 'اكتب الذكر هنا',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (_dhikrController.text.isNotEmpty) {
                setState(() {
                  dhikrText = _dhikrController.text;
                  counter = 0;
                });
                _dhikrController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 74, 108, 99),
      appBar: AppBar(
        title: const Text('السبحة الإلكترونية'),
        backgroundColor: const Color.fromARGB(255, 61, 91, 82),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      dhikrText,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 235, 235, 235),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showAddDhikrDialog,
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      label: const Text(
                        'تغيير الذكر',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: _incrementCounter,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(255, 187, 186, 186),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .3),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$counter',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(208, 35, 39, 40),
                          ),
                        ),
                        Text(
                          'من $targetCount',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTargetButton(33),
                  const SizedBox(width: 16),
                  _buildTargetButton(99),
                ],
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(235, 93, 145, 130),
                    foregroundColor: const Color.fromARGB(235, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'إعادة التعيين',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetButton(int count) {
    bool isSelected = targetCount == count;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          targetCount = count;
          counter = 0;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFFD9D9D9)
            : const Color(0xFFD9D9D9).withValues(alpha: .3), 
        foregroundColor: isSelected
            ? const Color(0xEB43635A)
            : const Color.fromARGB(134, 255, 255, 255),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _dhikrController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}