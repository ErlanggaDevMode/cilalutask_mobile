import 'package:flutter/foundation.dart';

import '../models/sop.dart';
import '../data/mock_data.dart';
import '../repositories/cilalu_repository.dart';

/// Dedicated controller for SOP (Standard Operating Procedure) management.
/// Handles SOP CRUD, reading confirmations, bookmarking, and company-scoped caching.
class SopController extends ChangeNotifier {
  final CilaluRepository _repository;

  List<SOPDocument> _sops = List.from(kInitialSops);
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  final void Function(SOPDocument sop)? onSopAdded;
  final void Function(SOPDocument sop)? onSopRead;

  SopController({
    CilaluRepository? repository,
    this.onSopAdded,
    this.onSopRead,
    List<SOPDocument>? initialSops,
  }) : _repository = repository ?? CilaluRepository() {
    if (initialSops != null) {
      _sops = List.from(initialSops);
    }
  }

  List<SOPDocument> get sops => List.unmodifiable(_sops);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Sets SOP list directly (e.g. for reset or mock initialization).
  void setSops(List<SOPDocument> sops) {
    _sops = List.from(sops);
    notifyListeners();
  }

  /// Clears SOP data (e.g. upon logout or company switch).
  void clear() {
    _sops = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads SOP documents for a given company code.
  Future<void> loadSops(String companyCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.getSops(companyCode);
      if (loaded.isNotEmpty || companyCode != 'CILALU-88') {
        _sops = loaded;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('SopController.loadSops error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new SOP document to memory and persists to repository.
  Future<void> addSop(String companyCode, SOPDocument newSop) async {
    _sops = [newSop, ..._sops];
    notifyListeners();

    onSopAdded?.call(newSop);

    try {
      await _repository.createSop(companyCode, newSop);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('SopController.addSop repository error: $e');
    }
  }

  /// Granularly deletes an SOP document from memory and repository.
  Future<void> deleteSop(String companyCode, String sopId) async {
    _sops = _sops.where((s) => s.id != sopId).toList();
    notifyListeners();

    try {
      await _repository.deleteSop(companyCode, sopId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('SopController.deleteSop repository error: $e');
    }
  }

  /// Confirms that current user has read the SOP.
  Future<void> confirmReadSop(String companyCode, String sopId) async {
    SOPDocument? target;
    _sops = _sops.map((s) {
      if (s.id == sopId) {
        target = s.copyWith(isReadByMe: true);
        return target!;
      }
      return s;
    }).toList();

    final sop = target ?? _sops.firstWhere((s) => s.id == sopId);
    notifyListeners();

    onSopRead?.call(sop);

    if (target != null) {
      try {
        await _repository.updateSop(companyCode, target!);
      } catch (e) {
        _errorMessage = e.toString();
        debugPrint('SopController.confirmReadSop repository error: $e');
      }
    }
  }

  /// Toggles bookmark on an SOP document.
  Future<void> toggleBookmarkSop(String companyCode, String sopId) async {
    SOPDocument? target;
    _sops = _sops.map((s) {
      if (s.id == sopId) {
        target = s.copyWith(isBookmarked: !s.isBookmarked);
        return target!;
      }
      return s;
    }).toList();

    notifyListeners();

    if (target != null) {
      try {
        await _repository.updateSop(companyCode, target!);
      } catch (e) {
        _errorMessage = e.toString();
        debugPrint('SopController.toggleBookmarkSop repository error: $e');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
