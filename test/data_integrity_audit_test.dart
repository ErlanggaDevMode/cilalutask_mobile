import 'package:flutter_test/flutter_test.dart';
import 'package:cilalutask_mobile/core/utils/task_metrics_calculator.dart';
import 'package:cilalutask_mobile/data/mock_data.dart';
import 'package:cilalutask_mobile/models/task.dart';
import 'package:cilalutask_mobile/models/company.dart';

void main() {
  group('DATA MASTER INTEGRITY & RECONCILIATION AUDIT', () {
    test('1. SOP readTeamCount does not contain hardcoded 34 Tim', () {
      for (final sop in kInitialSops) {
        if (sop.readTeamCount != null && sop.readTeamCount != 'Lengkap') {
          expect(
            sop.readTeamCount!.contains('34 Tim'),
            isFalse,
            reason: 'SOP ${sop.code} contains legacy static denominator 34 Tim',
          );
        }
      }
    });

    test('2. No references to legacy division IT & Development', () {
      for (final emp in kEmployees) {
        expect(emp.division, isNot('IT & Development'));
      }
      for (final task in kInitialTasks) {
        expect(task.division, isNot('IT & Development'));
      }
    });

    test('3. Dynamic TaskMetricsCalculator handles empty dataset safely', () {
      final metrics = TaskMetricsCalculator.computeMetrics([]);
      expect(metrics.total, 0);
      expect(metrics.completed, 0);
      expect(metrics.completionRate, 0.0);
      expect(metrics.averageProgress, 0.0);
      expect(metrics.completionRate.isNaN, isFalse);
    });

    test('4. Task completion count matches actual completed tasks', () {
      final completed = kInitialTasks
          .where((t) => t.status == TaskStatus.completed)
          .length;
      final metrics = TaskMetricsCalculator.computeMetrics(kInitialTasks);
      expect(metrics.completed, completed);
      expect(metrics.completed, 2); // 2 tasks completed out of 8
    });

    test('5. TaskMetricsCalculator completionRate is 25.0% and home efficiency rounds to 25%', () {
      final metrics = TaskMetricsCalculator.computeMetrics(kInitialTasks);
      expect(metrics.completionRate, 25.0);
      final roundedEfficiency = metrics.total > 0
          ? metrics.completionRate.round()
          : 100;
      expect(roundedEfficiency, 25);
      expect(roundedEfficiency, isNot(2500));
    });

    test('6. Division productivity calculation uses IT & Tech and excludes legacy division names', () {
      final divMetrics = TaskMetricsCalculator.computeDivisionProductivity(
        kInitialTasks,
      );
      final divisionNames = divMetrics.map((d) => d.name).toList();
      expect(divisionNames.contains('IT & Development'), isFalse);
      expect(divisionNames.contains('IT & Tech'), isTrue);
    });

    test('7. Multi-tenant company model consistency', () {
      final company = Company(
        id: 'comp-1',
        code: 'CILALU-88',
        name: 'PT Cilalu Sentosa',
        adminName: 'Sarah Pratama',
        adminEmail: 'sarah.pratama@cilalutask.id',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(company.code, 'CILALU-88');
      expect(company.name, 'PT Cilalu Sentosa');
      expect(company.adminEmail, 'sarah.pratama@cilalutask.id');
      expect(company.adminName, 'Sarah Pratama');
    });
  });
}
