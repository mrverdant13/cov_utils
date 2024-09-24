import 'package:collection/collection.dart';
import 'package:coverde/src/entities/cov_base.dart';
import 'package:coverde/src/entities/cov_dir.dart';
import 'package:coverde/src/entities/cov_file.dart';
import 'package:meta/meta.dart';

/// {@template trace_file}
/// # Trace File Data
///
/// A trace file (often named `lcov.info`) is made up of several human-readable
/// lines of text, divided into blocks of coverage data related to different
/// source files.
/// {@endtemplate}
@immutable
class TraceFile extends CovComputable {
  /// Create a trace file instance.
  ///
  /// {@macro trace_file}
  @visibleForTesting
  TraceFile({
    required Iterable<CovFile> sourceFilesCovData,
  }) : _sourceFilesCovData = Iterable.castFrom(sourceFilesCovData);

  /// Create a source file coverage data instance from the content string of a
  /// file coverage data block.
  ///
  /// {@macro trace_file}
  factory TraceFile.parse(String traceFileContent) {
    final filesCovDataStr = traceFileContent
        .split(CovFile.endOfRecordTag)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => '$s\n${CovFile.endOfRecordTag}');
    final sourceFilesCovData = filesCovDataStr
        .map(CovFile.parse)
        .where((fileCovData) => fileCovData.linesFound > 0);
    return TraceFile(
      sourceFilesCovData: sourceFilesCovData,
    );
  }

  final Iterable<CovFile> _sourceFilesCovData;

  /// Create a coverage tree.
  late final CovDir asTree = CovDir.tree(covFiles: sourceFilesCovData);

  /// Check if any name of the files included by this trace file match any of
  /// the provided [patterns].
  bool includeFileThatMatchPatterns(List<String> patterns) => patterns
      .map(RegExp.new)
      .any((p) => _sourceFilesCovData.any((f) => p.hasMatch(f.source.path)));

  /// The coverage data related to the referenced source files.
  UnmodifiableListView<CovFile> get sourceFilesCovData =>
      UnmodifiableListView<CovFile>(_sourceFilesCovData);

  @override
  int get linesHit => _sourceFilesCovData.map((e) => e.linesHit).sum;

  @override
  int get linesFound => _sourceFilesCovData.map((e) => e.linesFound).sum;

  static const _sourceFilesCovDataEquality = IterableEquality<CovFile>();

  /// generates a markdown report base on the given thresholds [medium], [high]
  String generateMarkdownReport({
    required double medium,
    required double high,
  }) {
    final buffer = StringBuffer()
      ..writeln('```')
      ..writeln('Minimum coverage : $medium')
      ..writeln('Code coverage threshold : [$medium - $high]')
      ..writeln('```')
      ..writeln()
      ..writeln('<details>')
      ..writeln()
      ..writeln('<summary> View Report </summary>')
      ..writeln()
      ..writeln('File | Lines Covered | Coverage | Health')
      ..writeln('-------- | --------- | -------- | --------');

    final sourceFilesCovDataSorted =
        sourceFilesCovData.sorted((a, b) => a.coverage.compareTo(b.coverage));

    for (final covFile in sourceFilesCovDataSorted) {
      buffer.write(
        '${covFile.source.path} | ${covFile.linesHit}/${covFile.linesFound} | ${covFile.coverageString} | ',
      );

      if (covFile.coverage >= high) {
        buffer.writeln('✅');
      } else if (covFile.coverage >= medium) {
        buffer.writeln('👍');
      } else {
        buffer.writeln('❌');
      }
    }

    buffer
      ..writeln('Summary | $coverageString ($linesHit/$linesFound)')
      ..writeln()
      ..writeln('</details>');

    return buffer.toString();
  }

  /// generates a github badge showing code coverage percentage based on
  /// the given thresholds [medium], [high]
  String generateBadge({
    required double medium,
    required double high,
  }) {
    var badgeColor = 'grey';

    if (coverage >= high) {
      badgeColor = 'success';
    } else if (coverage >= medium) {
      badgeColor = 'yellow';
    } else {
      badgeColor = 'red';
    }
    return '<img alt="Code coverage" src="https://img.shields.io/badge/Code%20Coverage-$coverageString%25-$badgeColor?style=flat-square">';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TraceFile &&
        _sourceFilesCovDataEquality.equals(
          other._sourceFilesCovData,
          _sourceFilesCovData,
        );
  }

  @override
  int get hashCode => _sourceFilesCovDataEquality.hash(_sourceFilesCovData);
}
