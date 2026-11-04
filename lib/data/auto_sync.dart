import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dropbox_sync.dart';
import 'store.dart';

/// Watches the [Store] and Dropbox in the background:
///
/// - Debounced upload after any local data change (if `autoSync` is on).
/// - Periodic download check while foregrounded (60s interval).
/// - Download on launch and on resume.
/// - Full round trip on connect and on "Sync now".
///
/// Whole-file sync: the last writer wins. The app is designed for
/// one-device-at-a-time use; concurrent edits on two devices will lose
/// one side's changes. A proper per-entry merge would require schema
/// changes not currently in scope.
class AutoSyncService with WidgetsBindingObserver {
  final Store store;
  Timer? _uploadDebounce;
  Timer? _periodicCheck;
  DateTime? _lastSeenModified;
  bool _lastSeenAuto = false;
  bool _busy = false;
  bool _pendingPush = false;
  bool _pendingPull = false;

  static const _debounceDuration = Duration(seconds: 3);
  static const _retryDelay = Duration(seconds: 30);
  static const _pollInterval = Duration(seconds: 60);

  AutoSyncService(this.store) {
    _lastSeenModified = store.lastModified;
    _lastSeenAuto = store.autoSync;
    store.addListener(_onStoreChanged);
    WidgetsBinding.instance.addObserver(this);
    _startPeriodic();
    _pullIfRemoteChanged();
  }

  void dispose() {
    store.removeListener(_onStoreChanged);
    WidgetsBinding.instance.removeObserver(this);
    _uploadDebounce?.cancel();
    _periodicCheck?.cancel();
  }

  bool get _active => store.autoSync;

  // ---------- Lifecycle ----------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _pullIfRemoteChanged();
        _startPeriodic();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _periodicCheck?.cancel();
        _periodicCheck = null;
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  // ---------- Store listener ----------

  void _onStoreChanged() {
    final wasAuto = _lastSeenAuto;
    final isAuto = store.autoSync;
    _lastSeenAuto = isAuto;

    if (!wasAuto && isAuto) {
      _pullIfRemoteChanged();
      if (store.hasUnsyncedChanges) _scheduleUpload();
    } else if (wasAuto && !isAuto) {
      _uploadDebounce?.cancel();
      _uploadDebounce = null;
      _pendingPush = false;
      _pendingPull = false;
    }

    final lm = store.lastModified;
    if (lm != _lastSeenModified) {
      _lastSeenModified = lm;
      if (isAuto) _scheduleUpload();
    }
  }

  // ---------- Upload ----------

  void _scheduleUpload() {
    if (!_active) return;
    _uploadDebounce?.cancel();
    _uploadDebounce = Timer(_debounceDuration, _push);
  }

  Future<void> _push() async {
    if (!_active) return;
    if (_busy) {
      _pendingPush = true;
      return;
    }
    _busy = true;
    try {
      if (!await DropboxSync.isSignedIn()) return;
      if (!store.hasUnsyncedChanges) return;

      final newRev = await DropboxSync.upload(store.toSyncJson());
      if (newRev != null) {
        await store.setLastRemoteRev(newRev);
      }
      await store.markSynced(SyncDirection.upload);
    } catch (e) {
      debugPrint('[auto-sync] upload failed: $e');
      if (_active && store.hasUnsyncedChanges) {
        _uploadDebounce?.cancel();
        _uploadDebounce = Timer(_retryDelay, _push);
      }
    } finally {
      _busy = false;
      _drainPending();
    }
  }

  // ---------- Download ----------

  Future<void> _pullIfRemoteChanged() async {
    if (!_active) return;
    if (_busy) {
      _pendingPull = true;
      return;
    }
    _busy = true;
    try {
      if (!await DropboxSync.isSignedIn()) return;

      final meta = await DropboxSync.getMetadata();
      if (meta == null) {
        // No remote file yet — push if we have local data to seed it.
        if (store.hasUnsyncedChanges) _scheduleUpload();
        return;
      }
      if (meta.rev == store.lastRemoteRev) {
        // Remote unchanged. Make sure local edits (if any) get pushed.
        if (store.hasUnsyncedChanges) _scheduleUpload();
        return;
      }

      final json = await DropboxSync.download();
      if (json == null) return;

      final didMerge = await store.mergeFromSync(json);
      await store.setLastRemoteRev(meta.rev);

      if (didMerge) {
        await store.markSynced(SyncDirection.download);
      } else {
        // Local data was newer than the remote; push ours over it.
        _scheduleUpload();
      }
    } catch (e) {
      debugPrint('[auto-sync] download failed: $e');
    } finally {
      _busy = false;
      _drainPending();
    }
  }

  /// Runs any operation that was requested while [_busy] was true.
  /// Pull is prioritised over push so we check the remote before
  /// potentially overwriting it.
  void _drainPending() {
    if (_busy) return;
    if (_pendingPull) {
      _pendingPull = false;
      _pullIfRemoteChanged();
    } else if (_pendingPush) {
      _pendingPush = false;
      _push();
    }
  }

  // ---------- Public API used by Settings ----------

  Future<void> onDropboxConnected() async {
    if (!_active) return;
    await _pullIfRemoteChanged();
    if (store.hasUnsyncedChanges) {
      await _push();
    }
  }

  Future<void> syncNow() async {
    if (!_active) return;
    await onDropboxConnected();
  }

  // ---------- Periodic poll ----------

  void _startPeriodic() {
    _periodicCheck?.cancel();
    _periodicCheck = Timer.periodic(_pollInterval, (_) {
      _pullIfRemoteChanged();
    });
  }
}