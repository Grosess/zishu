import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Simple error handling
  FlutterError.onError = (details) {
    print('Flutter error: ${details.exception}');
  };
  
  runApp(DebugApp());
}

class DebugApp extends StatefulWidget {
  @override
  _DebugAppState createState() => _DebugAppState();
}

class _DebugAppState extends State<DebugApp> {
  String status = 'Starting...';
  List<String> logs = [];
  
  @override
  void initState() {
    super.initState();
    _runInitialization();
  }
  
  void _log(String message) {
    setState(() {
      logs.add(message);
      status = message;
    });
    print(message);
  }
  
  Future<void> _runInitialization() async {
    try {
      _log('1. Widget binding initialized');
      
      // Test orientation lock
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        _log('2. Orientation locked successfully');
      } catch (e) {
        _log('2. ERROR setting orientation: $e');
      }
      
      // Test shared preferences
      try {
        await Future.delayed(Duration(milliseconds: 100));
        _log('3. Basic initialization complete');
      } catch (e) {
        _log('3. ERROR in initialization: $e');
      }
      
      _log('✓ All initialization complete!');
      
    } catch (e) {
      _log('FATAL ERROR: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Zishu Debug'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: $status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: status.contains('ERROR') ? Colors.red : Colors.green,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Initialization Log:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        log,
                        style: TextStyle(
                          color: log.contains('ERROR') ? Colors.red : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}