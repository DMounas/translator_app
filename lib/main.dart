import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Language Translator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: TranslatorHome(),
    );
  }
}

class TranslatorHome extends StatefulWidget {
  @override
  _TranslatorHomeState createState() => _TranslatorHomeState();
}

class _TranslatorHomeState extends State<TranslatorHome> {
  final TextEditingController _inputController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  String _translatedText = '';
  bool _isListening = false;
  bool _isLoading = false;
  String _selectedFromLanguage = 'en';
  String _selectedToLanguage = 'es';

  final Map<String, String> _languages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'hi': 'Hindi',
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  void _initSpeech() async {
    await _speech.initialize();
    setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage(_selectedToLanguage);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _translateText(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://translation.googleapis.com/language/translate/v2'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'q': text,
          'source': _selectedFromLanguage,
          'target': _selectedToLanguage,
          'format': 'text',
          'key': 'API_KEY', // Google Translate API key
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText =
            data['data']['translations'][0]['translatedText'];

        setState(() {
          _translatedText = translatedText;
        });

        await _saveToHistory(text, translatedText);
      } else {
        setState(() {
          _translatedText =
              'Translation: $text (Demo - Add API key for real translation)';
        });
        await _saveToHistory(text, _translatedText);
      }
    } catch (e) {
      setState(() {
        _translatedText =
            'Translation: $text (Demo - Add API key for real translation)';
      });
      await _saveToHistory(text, _translatedText);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveToHistory(String original, String translated) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('translation_history') ?? [];

    final entry = json.encode({
      'original': original,
      'translated': translated,
      'fromLang': _selectedFromLanguage,
      'toLang': _selectedToLanguage,
      'timestamp': DateTime.now().toIso8601String(),
    });

    history.insert(0, entry);
    if (history.length > 100) history.removeLast();

    await prefs.setStringList('translation_history', history);
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _inputController.text = result.recognizedWords;
            });
          },
          localeId: _selectedFromLanguage,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _speakTranslation() async {
    if (_translatedText.isNotEmpty) {
      await _flutterTts.setLanguage(_selectedToLanguage);
      await _flutterTts.speak(_translatedText);
    }
  }

  void _swapLanguages() {
    setState(() {
      String temp = _selectedFromLanguage;
      _selectedFromLanguage = _selectedToLanguage;
      _selectedToLanguage = temp;

      // Swap texts
      String tempText = _inputController.text;
      _inputController.text = _translatedText;
      _translatedText = tempText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade600, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Translator',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.history, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Language Selection
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedFromLanguage,
                                decoration: InputDecoration(
                                  labelText: 'From',
                                  border: OutlineInputBorder(),
                                ),
                                items: _languages.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFromLanguage = value!;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            GestureDetector(
                              onTap: _swapLanguages,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedToLanguage,
                                decoration: InputDecoration(
                                  labelText: 'To',
                                  border: OutlineInputBorder(),
                                ),
                                items: _languages.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedToLanguage = value!;
                                  });
                                  _initTts();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Input Section
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _inputController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Enter text to translate...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _startListening,
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                  ),
                                  label: Text(
                                    _isListening
                                        ? 'Listening...'
                                        : 'Voice Input',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isListening
                                        ? Colors.red
                                        : Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _translateText(
                                          _inputController.text,
                                        ),
                                  icon: _isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Icon(Icons.translate),
                                  label: Text('Translate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Output Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Translation:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_translatedText.isNotEmpty)
                                  IconButton(
                                    onPressed: _speakTranslation,
                                    icon: Icon(Icons.volume_up),
                                    color: Colors.blue,
                                  ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,

                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                _translatedText.isEmpty
                                    ? 'Translation will appear here...'
                                    : _translatedText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _translatedText.isEmpty
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('translation_history') ?? [];

    setState(() {
      _history = history
          .map((item) => json.decode(item) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('translation_history');
    setState(() {
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Translation History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear History'),
                    content: Text(
                      'Are you sure you want to clear all translation history?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearHistory();
                          Navigator.pop(context);
                        },
                        child: Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No translation history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                final timestamp = DateTime.parse(item['timestamp']);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['fromLang'].toString().toUpperCase()} → ${item['toLang'].toString().toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(item['original'], style: TextStyle(fontSize: 16)),
                        Divider(),
                        Text(
                          item['translated'],
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
