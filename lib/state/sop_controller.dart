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
      } else if (_sops.isEmpty) {
        _sops = List.from(kInitialSops);
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
    final existingIdx = _sops.indexWhere((s) => s.id == newSop.id);
    if (existingIdx >= 0) {
      final copy = List<SOPDocument>.from(_sops);
      copy[existingIdx] = newSop;
      _sops = copy;
    } else {
      _sops = [newSop, ..._sops];
    }
    notifyListeners();

    onSopAdded?.call(newSop);

    try {
      await _repository.createSop(companyCode, newSop, currentList: _sops);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('SopController.addSop repository error: $e');
    }
  }

  /// Updates an existing SOP document (e.g. revision upload) in memory and repository.
  Future<void> updateSop(String companyCode, SOPDocument updatedSop) async {
    _sops = _sops.map((s) => s.id == updatedSop.id ? updatedSop : s).toList();
    notifyListeners();

    try {
      await _repository.updateSop(companyCode, updatedSop, currentList: _sops);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('SopController.updateSop repository error: $e');
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

  /// Confirms that current user has read the SOP and updates team verification metrics.
  Future<void> confirmReadSop(
    String companyCode,
    String sopId, {
    int totalEmployees = 6,
  }) async {
    SOPDocument? target;
    _sops = _sops.map((s) {
      if (s.id == sopId) {
        final alreadyRead = s.isReadByMe;
        int currentRead = 0;
        int totalTeam = totalEmployees > 0 ? totalEmployees : 6;

        if (s.readTeamCount != null && s.readTeamCount!.contains('/')) {
          final parts = s.readTeamCount!.split('/');
          currentRead = int.tryParse(parts[0].trim()) ?? 0;
          final denomPart = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
          final parsedDenom = int.tryParse(denomPart);
          if (parsedDenom != null && parsedDenom > 0) {
            totalTeam = parsedDenom;
          }
        }

        if (!alreadyRead || currentRead == 0) {
          currentRead = (currentRead + 1).clamp(1, totalTeam);
        }

        final newPercent = ((currentRead / totalTeam) * 100).round().clamp(
          0,
          100,
        );

        target = s.copyWith(
          isReadByMe: true,
          isUrgentMandatory: false,
          readProgressPercent: newPercent,
          readTeamCount: '$currentRead/$totalTeam Tim',
          complianceRatioText: '$newPercent% Karyawan terverifikasi',
        );
        return target!;
      }
      return s;
    }).toList();

    final sop = target ?? _sops.firstWhere((s) => s.id == sopId);
    notifyListeners();

    onSopRead?.call(sop);

    if (target != null) {
      try {
        await _repository.updateSop(companyCode, target!, currentList: _sops);
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
        await _repository.updateSop(companyCode, target!, currentList: _sops);
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
