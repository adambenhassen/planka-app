import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'widgets/confirm_dialog.dart';

/// Tracks the free-text editors on a card sheet and mediates every route exit.
class CardSheetDismissalGuard {
  CardSheetDismissalGuard([this._navigator]);

  NavigatorState? _navigator;
  BuildContext? _context;
  ModalRoute<dynamic>? _route;

  final hasUnsavedChanges = ValueNotifier<bool>(false);
  final _dirtyEditors = <String>{};
  final _focusNodes = <String, FocusNode>{};
  String? _lastFocusedEditor;
  bool _confirmationPending = false;
  bool _dismissalRequestPending = false;
  bool _allowNextPop = false;
  bool _suppressBlur = false;

  bool get shouldCommitOnBlur => !_confirmationPending && !_suppressBlur;
  bool get isDirty => hasUnsavedChanges.value;
  BuildContext get navigatorContext => _navigator!.context;

  void attach(BuildContext context) {
    _context = context;
    _navigator ??= Navigator.of(context);
    _route = ModalRoute.of(context);
  }

  void detach() {
    _context = null;
    _route = null;
  }

  void updateEditor(String id, bool dirty, FocusNode focus, bool focused) {
    _focusNodes[id] = focus;
    if (focused) _lastFocusedEditor = id;
    if (dirty) {
      _dirtyEditors.add(id);
    } else {
      _dirtyEditors.remove(id);
    }
    final next = _dirtyEditors.isNotEmpty;
    if (hasUnsavedChanges.value != next) hasUnsavedChanges.value = next;
  }

  void removeEditor(String id, FocusNode focus) {
    if (identical(_focusNodes[id], focus)) _focusNodes.remove(id);
    _dirtyEditors.remove(id);
    if (_lastFocusedEditor == id) _lastFocusedEditor = null;
    final next = _dirtyEditors.isNotEmpty;
    if (hasUnsavedChanges.value != next) hasUnsavedChanges.value = next;
  }

  /// Shows the shared discard prompt for an action that will close the sheet.
  /// Returns false when the user keeps editing.
  Future<bool> confirmBeforeAction() async {
    if (!isDirty) return true;
    if (_confirmationPending) return false;
    final context = _context;
    if (context == null || !context.mounted) return false;
    final l10n = AppLocalizations.of(context);
    _confirmationPending = true;
    final discard = await confirmDialog(
      context,
      title: l10n.cardUnsavedChangesTitle,
      message: l10n.cardUnsavedChangesMessage,
      cancelLabel: l10n.actionKeepEditing,
      confirmLabel: l10n.actionDiscard,
      destructive: true,
    );
    _confirmationPending = false;
    if (discard) {
      _suppressBlur = true;
      _dirtyEditors.clear();
      hasUnsavedChanges.value = false;
    } else {
      _suppressBlur = false;
      restoreLastFocus();
    }
    return discard;
  }

  /// Handles a route-level pop that bypassed [PopScope], such as a direct
  /// Navigator.pop from a parent or Flutter's modal-sheet drag callback.
  void requestDismiss([Object? result]) {
    if (_confirmationPending || _dismissalRequestPending) return;
    _dismissalRequestPending = true;
    unawaited(_confirmAndPop(result));
  }

  Future<void> _confirmAndPop(Object? result) async {
    // A direct Navigator.pop can call this while the navigator is flushing its
    // history. Defer the dialog push until that synchronous pop has completed.
    await Future<void>.delayed(Duration.zero);
    _dismissalRequestPending = false;
    if (_context == null) return;
    final allowed = await confirmBeforeAction();
    if (allowed) _pop(result);
  }

  void close([Object? result]) {
    _allowNextPop = true;
    _pop(result);
  }

  void _pop(Object? result) {
    final navigator = _navigator;
    if (navigator == null || !navigator.mounted) return;
    final route = _route;
    if (route != null && !route.isCurrent) return;
    navigator.pop(result);
  }

  bool consumeAllowedPop() {
    if (!_allowNextPop) return false;
    _allowNextPop = false;
    return true;
  }

  void temporarilySuppressBlur(bool suppress) => _suppressBlur = suppress;

  void restoreLastFocus() {
    final id = _lastFocusedEditor;
    final focus = id == null ? null : _focusNodes[id];
    if (focus == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (identical(_focusNodes[id], focus)) focus.requestFocus();
    });
  }

  void dispose() {
    hasUnsavedChanges.dispose();
    _dirtyEditors.clear();
    _focusNodes.clear();
  }
}
