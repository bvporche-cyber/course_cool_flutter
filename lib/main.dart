import 'package:flutter/material.dart';

void main() {
  runApp(const CourseCoolApp());
}

class CourseCoolApp extends StatelessWidget {
  const CourseCoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Cool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ShoppingListPage(title: 'Course Cool'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key, required this.title});

  final String title;

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final List<ShoppingItem> _items = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  late FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTts();
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    await _speech.initialize(
      onError: (error) => print('Erreur reconnaissance vocale: $error'),
      onStatus: (status) => print('Status: $status'),
    );
  }

  Future<void> _initializeTts() async {
    _tts = FlutterTts();
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
            });
          },
          localeId: 'fr_FR',
        );
      }
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);

      if (_recognizedText.isNotEmpty) {
        _addItem(_recognizedText);
        _recognizedText = '';
      }
    }
  }

  void _addItem(String itemName) {
    setState(() {
      _items.add(ShoppingItem(name: itemName));
    });
    _speak('$itemName ajouté');
  }

  void _removeItem(int index) {
    final itemName = _items[index].name;
    setState(() {
      _items.removeAt(index);
    });
    _speak('$itemName supprimé');
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index].isPurchased = !_items[index].isPurchased;
    });

    if (_items[index].isPurchased) {
      _speak('${_items[index].name} acheté');
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _clearPurchased() {
    setState(() {
      _items.removeWhere((item) => item.isPurchased);
    });
    _speak('Articles achetés supprimés');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_items.any((item) => item.isPurchased))
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Effacer les articles achetés',
              onPressed: _clearPurchased,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _isListening ? Colors.red.shade50 : Colors.grey.shade100,
            child: Column(
              children: [
                Text(
                  _isListening ? 'Écoute en cours...' : 'Appuyez pour parler',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_recognizedText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _recognizedText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'Aucun article\nAppuyez sur le micro pour ajouter',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: Key(item.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeItem(index),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isPurchased,
                            onChanged: (_) => _toggleItem(index),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isPurchased
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isListening ? _stopListening : _startListening,
        tooltip: _isListening ? 'Arrêter' : 'Parler',
        backgroundColor: _isListening ? Colors.red : Colors.blue,
        child: Icon(_isListening ? Icons.stop : Icons.mic),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}

class ShoppingItem {
  final String id;
  final String name;
  bool isPurchased;

  ShoppingItem({required this.name, this.isPurchased = false})
    : id = DateTime.now().millisecondsSinceEpoch.toString();
}
