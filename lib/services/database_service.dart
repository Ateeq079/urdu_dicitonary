import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word_result.dart';

class DatabaseService {
  static const String _dbName = 'lughat.db';
  static const int _dbVersion = 1;

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Create table
        await db.execute('''
          CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            urdu TEXT NOT NULL,
            roman TEXT NOT NULL,
            english TEXT NOT NULL
          )
        ''');

        // Create indexes for fast lookup
        await db.execute('CREATE INDEX idx_urdu ON words (urdu)');
        await db.execute('CREATE INDEX idx_roman ON words (roman)');
        await db.execute('CREATE INDEX idx_english ON words (english)');

        // Populate table from assets
        await _seedDatabase(db);
      },
    );
  }

  static Future<void> _seedDatabase(Database db) async {
    try {
      final jsonString = await rootBundle.loadString('assets/dictionary.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      // Batch insert for performance
      final batch = db.batch();
      for (final item in jsonList) {
        batch.insert('words', {
          'urdu': item['urdu'],
          'roman': item['roman'],
          'english': item['english'],
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print('Error seeding database: $e');
    }
  }

  /// Looks up an Urdu word (either exactly or via Roman transliteration).
  /// Returns a WordResult containing a single DictEntry.
  static Future<WordResult?> lookupUrdu(String query) async {
    final db = await database;
    final cleanQuery = query.trim().toLowerCase();
    
    // First try exact Urdu match
    var results = await db.query(
      'words',
      where: 'urdu = ?',
      whereArgs: [cleanQuery],
      limit: 1,
    );

    // If no exact match, try Roman Urdu
    if (results.isEmpty) {
      results = await db.query(
        'words',
        where: 'roman = ?',
        whereArgs: [cleanQuery],
        limit: 1,
      );
    }

    if (results.isNotEmpty) {
      final row = results.first;
      return _buildResult(
        row['urdu'] as String,
        row['english'] as String,
        row['roman'] as String,
      );
    }

    return null;
  }

  /// Converts a DB row into our standard WordResult/DictEntry format.
  static WordResult _buildResult(String urdu, String english, String roman) {
    final sense = Sense(
      definition: english,
      examples: const [],
      synonyms: const [],
      antonyms: const [],
      translations: const [],
    );

    final entry = DictEntry(
      langCode: 'ur',
      langName: 'Urdu',
      partOfSpeech: 'word', // default
      pronunciation: roman, // use Roman Urdu as pronunciation
      forms: const [],
      senses: [sense],
      synonyms: const [],
      antonyms: const [],
    );

    return WordResult(word: urdu, entries: [entry]);
  }
}
