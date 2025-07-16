import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_page.dart';
import '../api/api_keys.dart';
import '../widgets/language_selector.dart';

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
        Uri.parse(
          'https://translation.googleapis.com/language/translate/v2?key=$googleApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'q': text,
          'source': _selectedFromLanguage,
          'target': _selectedToLanguage,
          'format': 'text',
          //'key': googleApiKey, // Google Translate API key
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
              'Translation: $text (API Error - Status ${response.statusCode})';
        });
        await _saveToHistory(text, _translatedText);
      }
    } catch (e) {
      setState(() {
        _translatedText =
            'Translation: $text (Demo - Add API key or check internet)';
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
                  child: SingleChildScrollView(
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
                                child: LanguageSelector(
                                  labelText: 'From',
                                  selectedLanguageName:
                                      _languages[_selectedFromLanguage]!,
                                  allLanguages: _languages,
                                  onLanguageSelected: (newLangCode) {
                                    setState(() {
                                      _selectedFromLanguage = newLangCode;
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
                                child: LanguageSelector(
                                  labelText: 'To',
                                  selectedLanguageName:
                                      _languages[_selectedToLanguage]!,
                                  allLanguages: _languages,
                                  onLanguageSelected: (newLangCode) {
                                    setState(() {
                                      _selectedToLanguage = newLangCode;
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
