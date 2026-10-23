import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'smart_transition_controller.g.dart';

const _kPrefSmartTransitionKey = 'pref_smart_transition_enabled';

/// Controls whether intelligent Auto-DJ crossfade transition mode is enabled.
/// Persists the user preference locally via [SharedPreferencesAsync].
@Riverpod(keepAlive: true)
class SmartTransitionController extends _$SmartTransitionController {
  SharedPreferencesAsync? _prefs;

  SharedPreferencesAsync? get _safePrefs {
    try {
      _prefs ??= SharedPreferencesAsync();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  @override
  bool build() {
    // Read persisted setting asynchronously on startup
    _loadPreference();
    return true; // Default to true (Auto-DJ enabled)
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = _safePrefs;
      if (prefs != null) {
        final saved = await prefs.getBool(_kPrefSmartTransitionKey);
        if (saved != null) {
          state = saved;
        }
      }
    } catch (e) {
      debugPrint('[SmartTransitionController] Error reading preference: $e');
    }
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      final prefs = _safePrefs;
      if (prefs != null) {
        await prefs.setBool(_kPrefSmartTransitionKey, next);
        debugPrint('[SmartTransitionController] Smart transition set to: $next');
      }
    } catch (e) {
      debugPrint('[SmartTransitionController] Error saving preference: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    try {
      final prefs = _safePrefs;
      if (prefs != null) {
        await prefs.setBool(_kPrefSmartTransitionKey, enabled);
      }
    } catch (e) {
      debugPrint('[SmartTransitionController] Error saving preference: $e');
    }
  }
}
