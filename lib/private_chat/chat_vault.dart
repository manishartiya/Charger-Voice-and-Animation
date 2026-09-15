import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'chat_crypto.dart';

abstract class VaultStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class DeviceVaultStorage implements VaultStorage {
  final _storage = const FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: 'private_chat_$key');
  @override
  Future<void> write(String key, String value) => _storage.write(key: 'private_chat_$key', value: value);
}

Future<List<int>> derivePinKey(Map<String, dynamic> args) async {
  final key = await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 600000, bits: 256)
      .deriveKey(secretKey: SecretKey(utf8.encode(args['pin'] as String)),
        nonce: decodeBytes(args['salt'] as String));
  return key.extractBytes();
}

class VaultException implements Exception {
  const VaultException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ChatVault {
  ChatVault({VaultStorage? storage, DateTime Function()? now,
    Future<List<int>> Function(Map<String, dynamic>)? derive})
      : storage = storage ?? DeviceVaultStorage(), now = now ?? DateTime.now,
        derive = derive ?? ((args) => compute(derivePinKey, args));
  final VaultStorage storage;
  final DateTime Function() now;
  final Future<List<int>> Function(Map<String, dynamic>) derive;
  List<int>? _key;
  String? _salt;
  List<SavedChat> _chats = [];
  int _generation = 0;
  bool _busy = false;
  bool get unlocked => _key != null;
  List<SavedChat> get chats => List.unmodifiable(_chats);
  Future<bool> exists() async => await storage.read('vault') != null;

  void lock() {
    _generation++;
    _key = null;
    _salt = null;
    _chats = [];
  }

  Future<void> unlock(String pin, {bool create = false}) async {
    if (_busy) throw const VaultException('Please wait for the current attempt.');
    if (!RegExp(r'^\d{6,12}$').hasMatch(pin)) {
      throw const VaultException('Use a PIN with 6 to 12 digits.');
    }
    _busy = true;
    final generation = _generation;
    try {
      final attempts = jsonDecode(await storage.read('attempts') ?? '{}') as Map;
      final until = (attempts['until'] as num?)?.toInt() ?? 0;
      if (now().millisecondsSinceEpoch < until) {
        throw VaultException('Try again in ${((until - now().millisecondsSinceEpoch) / 1000).ceil()} seconds.');
      }
      final record = await storage.read('vault');
      if (create && record != null) throw const VaultException('A PIN already exists. Unlock with your current PIN.');
      if (!create && record == null) throw const VaultException('Set up your private PIN first.');
      final failures = ((attempts['failures'] as num?)?.toInt() ?? 0) + 1;
      // Persist before checking so closing the app cannot skip an attempt.
      final delay = failures >= 5 ? min(900, 30 * pow(2, min(failures - 5, 5)).toInt()) : 0;
      await storage.write('attempts', jsonEncode({'failures': failures,
        'until': now().millisecondsSinceEpoch + delay * 1000}));
      final data = record == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(record) as Map);
      final salt = data['salt'] as String? ?? encodeBytes(randomBytes(16));
      final key = await derive({'pin': pin, 'salt': salt});
      List<SavedChat> chats = [];
      if (record != null) {
        try {
          final clear = await ChatCrypto.decrypt(data, key, 'charge-voice-vault-v1');
          chats = (jsonDecode(clear) as List).map((v) => SavedChat.fromJson(Map<String, dynamic>.from(v as Map))).toList();
        } on SecretBoxAuthenticationError {
          throw const VaultException('Incorrect PIN.');
        }
      }
      if (generation != _generation) throw const VaultException('Locked. Enter your PIN again.');
      if (create) {
        final encrypted = await ChatCrypto.encrypt('[]', key, 'charge-voice-vault-v1');
        await storage.write('vault', jsonEncode({...encrypted, 'salt': salt, 'version': 1}));
      }
      await storage.write('attempts', '{}');
      if (generation != _generation) throw const VaultException('Locked. Enter your PIN again.');
      _key = key;
      _salt = salt;
      _chats = chats;
    } finally { _busy = false; }
  }

  Future<void> saveChat(SavedChat chat) async {
    final key = _key;
    final generation = _generation;
    if (key == null) throw const VaultException('Unlock your chat first.');
    final chats = [..._chats.where((c) => c.invite.roomId != chat.invite.roomId), chat];
    final encrypted = await ChatCrypto.encrypt(jsonEncode(chats.map((c) => c.toJson()).toList()), key, 'charge-voice-vault-v1');
    if (generation != _generation) throw const VaultException('Chat locked. Try again after unlocking.');
    await storage.write('vault', jsonEncode({...encrypted, 'salt': _salt, 'version': 1}));
    if (generation == _generation) _chats = chats;
  }
}
