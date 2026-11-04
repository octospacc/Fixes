import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DropboxSync {
  static const _appKey = String.fromEnvironment('DROPBOX_APP_KEY');
  static const _remotePath = '/fixes_backup.json';

  static const _kRefreshToken = 'dropbox_refresh_token';
  static const _kAccessToken = 'dropbox_access_token';
  static const _kAccessExpiry = 'dropbox_access_expiry';

  // ---------- Status ----------

  static Future<bool> isSignedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefreshToken) != null;
  }

  static Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRefreshToken);
    await p.remove(_kAccessToken);
    await p.remove(_kAccessExpiry);
  }

  // ---------- OAuth (PKCE, manual code paste) ----------

  static String buildAuthUrl(String verifier) {
    final challenge = _computeChallenge(verifier);
    final params = {
      'client_id': _appKey,
      'response_type': 'code',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'token_access_type': 'offline',
    };
    final uri = Uri.https('www.dropbox.com', '/oauth2/authorize', params);
    return uri.toString();
  }

  static Future<void> completeAuth(String code, String verifier) async {
    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
        'client_id': _appKey,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Token exchange failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final refresh = data['refresh_token'] as String?;
    final access = data['access_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt();

    if (refresh == null || access == null || expiresIn == null) {
      throw Exception('Missing token fields in Dropbox response');
    }

    final p = await SharedPreferences.getInstance();
    await p.setString(_kRefreshToken, refresh);
    await p.setString(_kAccessToken, access);
    await p.setString(
      _kAccessExpiry,
      DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
    );
  }

  // ---------- Upload / Download / Metadata ----------

  /// Uploads the JSON and returns the new file rev, or null on failure.
  static Future<String?> upload(String json) async {
    final token = await _getValidAccessToken();
    if (token == null) throw Exception('Not signed in to Dropbox');

    final response = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/upload'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': jsonEncode({
          'path': _remotePath,
          'mode': 'overwrite',
          'autorename': false,
          'mute': false,
          'strict_conflict': false,
        }),
      },
      body: utf8.encode(json),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['rev'] as String?;
  }

  /// Returns the backup contents, or null if no backup exists.
  static Future<String?> download() async {
    final token = await _getValidAccessToken();
    if (token == null) throw Exception('Not signed in to Dropbox');

    final response = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      headers: {
        'Authorization': 'Bearer $token',
        'Dropbox-API-Arg': jsonEncode({'path': _remotePath}),
      },
    );

    if (response.statusCode == 409) return null;
    if (response.statusCode != 200) {
      throw Exception(
        'Download failed (${response.statusCode}): ${response.body}',
      );
    }

    return utf8.decode(response.bodyBytes);
  }

  /// Returns the remote file metadata (server_modified + rev), or null if
  /// the file does not exist yet.
  static Future<({DateTime serverModified, String rev})?> getMetadata() async {
    final token = await _getValidAccessToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/get_metadata'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'path': _remotePath}),
    );

    if (response.statusCode == 409) return null;
    if (response.statusCode != 200) {
      debugPrint('[dropbox] getMetadata failed: ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final modifiedStr = data['server_modified'] as String?;
    final rev = data['rev'] as String?;
    if (modifiedStr == null || rev == null) return null;

    final modified = DateTime.tryParse(modifiedStr);
    if (modified == null) return null;

    return (serverModified: modified, rev: rev);
  }

  // ---------- Token management ----------

  static Future<String?> _getValidAccessToken() async {
    final p = await SharedPreferences.getInstance();
    final access = p.getString(_kAccessToken);
    final expiryStr = p.getString(_kAccessExpiry);

    if (access != null && expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null &&
          expiry.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        return access;
      }
    }

    return _refreshAccessToken();
  }

  static Future<String?> _refreshAccessToken() async {
    final p = await SharedPreferences.getInstance();
    final refresh = p.getString(_kRefreshToken);
    if (refresh == null) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refresh,
          'client_id': _appKey,
        },
      );

      if (response.statusCode != 200) {
        await signOut();
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final access = data['access_token'] as String;
      final expiresIn = (data['expires_in'] as num).toInt();

      await p.setString(_kAccessToken, access);
      await p.setString(
        _kAccessExpiry,
        DateTime.now()
            .add(Duration(seconds: expiresIn))
            .toIso8601String(),
      );

      return access;
    } catch (e) {
      debugPrint('[dropbox] refresh failed: $e');
      return null;
    }
  }

  // ---------- PKCE helpers ----------

  static String generateVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return _base64UrlNoPadding(bytes);
  }

  static String _computeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return _base64UrlNoPadding(digest.bytes);
  }

  static String _base64UrlNoPadding(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}