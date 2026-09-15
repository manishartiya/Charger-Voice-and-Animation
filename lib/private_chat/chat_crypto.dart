import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

List<int> randomBytes(int length) {
  final random = Random.secure();
  return List.generate(length, (_) => random.nextInt(256));
}

String encodeBytes(List<int> value) => base64UrlEncode(value).replaceAll('=', '');
List<int> decodeBytes(String value) => base64Url.decode(base64Url.normalize(value));

class ChatInvite {
  ChatInvite(this.roomId, this.key);
  factory ChatInvite.create() => ChatInvite(
    randomBytes(24).map((v) => v.toRadixString(16).padLeft(2, '0')).join(),
    randomBytes(32),
  );
  factory ChatInvite.parse(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 3 || parts[0] != 'CV1' ||
        !RegExp(r'^[a-f0-9]{48}$').hasMatch(parts[1]) ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(parts[2])) {
      throw const FormatException('This invitation code is not valid.');
    }
    final key = decodeBytes(parts[2]);
    if (key.length != 32) throw const FormatException('Invalid invitation key.');
    return ChatInvite(parts[1], key);
  }
  final String roomId;
  final List<int> key;
  String get code => 'CV1.$roomId.${encodeBytes(key)}';
}

class ChatCrypto {
  static final cipher = AesGcm.with256bits();
  static Future<Map<String, dynamic>> encrypt(
    String text, List<int> key, String context,
  ) async {
    final box = await cipher.encrypt(utf8.encode(text), secretKey: SecretKey(key),
      nonce: cipher.newNonce(), aad: utf8.encode(context));
    return {'cipher': encodeBytes(box.cipherText), 'nonce': encodeBytes(box.nonce),
      'mac': encodeBytes(box.mac.bytes)};
  }
  static Future<String> decrypt(Map<String, dynamic> data, List<int> key, String context) async {
    final box = SecretBox(decodeBytes(data['cipher'] as String),
      nonce: decodeBytes(data['nonce'] as String), mac: Mac(decodeBytes(data['mac'] as String)));
    return utf8.decode(await cipher.decrypt(box, secretKey: SecretKey(key), aad: utf8.encode(context)));
  }
}

class SavedChat {
  SavedChat({required this.invite, required this.name});
  factory SavedChat.fromJson(Map<String, dynamic> data) => SavedChat(
    invite: ChatInvite.parse(data['invite'] as String), name: data['name'] as String);
  final ChatInvite invite;
  final String name;
  Map<String, dynamic> toJson() => {'invite': invite.code, 'name': name};
}
