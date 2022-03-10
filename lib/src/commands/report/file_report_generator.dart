import 'package:collection/collection.dart';
import 'package:coverde/src/commands/report/report_generator_base.dart';
import 'package:coverde/src/entities/cov_file.dart';
import 'package:coverde/src/entities/cov_line.dart';
import 'package:coverde/src/utils/path.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:universal_io/io.dart';

/// Report generator for [CovFile]s.
mixin FileReportGenerator on ReportGeneratorBase {
  static const _lineReportSegmentTemplateSource = '''
<a name="{{lineNumber}}"><span class="lineNum">{{paddedLineNumber}}</span><span class="sourceLine{{lineHtmlClass}}">{{maybePaddedLineHits}} : {{{lineSource}}}</span></a>''';

  static final _lineReportSegmentTemplate = Template(
    _lineReportSegmentTemplateSource,
  );

  static const _fileReportTemplateSource = '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" type="text/css" href="{{{cssPath}}}" />
    <title class="headTitle">Coverage Report - {{tracefileName}}</title>
  </head>

  <body>
    <table width="100%" border="0" cellspacing="0" cellpadding="0">
      <tbody>
        <tr>
          <td class="title">Code Coverage Report</td>
        </tr>
        <tr>
          <td class="ruler" height="3px"></td>
        </tr>

        <tr>
          <td width="100%">
            <table cellpadding="1" border="0" width="100%">
              <tbody>
                <tr>
                  <td width="10%" class="headerItem">Current view:</td>
                  <td width="35%" class="headerValue currentFileName">
                    <a class="topLevelAnchor" href="{{{reportRoot}}}">top level</a> - <a class="currentDirPath" href="index.html">{{{dirPath}}}</a> - {{fileName}}
                  </td>
                  <td width="5%"></td>
                  <td width="15%"></td>
                  <td width="10%" class="headerCovTableHead">Hit</td>
                  <td width="10%" class="headerCovTableHead">Total</td>
                  <td width="15%" class="headerCovTableHead">Coverage</td>
                </tr>
                <tr>
                  <td class="headerItem">Test:</td>
                  <td class="headerValue tracefileName">{{tracefileName}}</td>
                  <td></td>
                  <td class="headerItem">Lines:</td>
                  <td class="headerCovTableEntry linesHit">{{hitLines}}</td>
                  <td class="headerCovTableEntry linesFound">{{foundLines}}</td>
                  <td class="covValue headerCovTableEntry{{covSuffix}}">{{coverage}} %</td>
                </tr>
                <tr>
                  <td class="headerItem">Date:</td>
                  <td class="headerValue lastTracefileModificationDate">
                    {{date}}
                  </td>
                  <td></td>
                  <td></td>
                  <td></td>
                  <td></td>
                  <td></td>
                </tr>
                <tr>
                  <td height="3px"></td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>

        <tr>
          <td class="ruler" height="3px"></td>
        </tr>
      </tbody>
    </table>

    <table cellpadding="0" cellspacing="0" border="0">
      <tbody>
        <tr>
          <td><br /></td>
        </tr>
        <tr>
          <td>
            <pre class="sourceHeading">          Line data    Source code</pre>
            <pre class="source">
{{{linesReports}}}
            </pre>
          </td>
        </tr>
      </tbody>
    </table>
    <br />

    <table width="100%" border="0" cellspacing="0" cellpadding="0">
      <tbody>
        <tr>
          <td class="ruler" height="3px"></td>
        </tr>
        <tr>
          <td class="versionInfo">
            Generated by:
            <a href="https://github.com/mrverdant13/coverde" target="_parent">
              coverde
            </a>
          </td>
        </tr>
      </tbody>
    </table>
    <br />
  </body>
</html>
''';

  static final _fileReportTemplate = Template(_fileReportTemplateSource);

  String _generateLineReportSegmentContent({
    required Map<String, dynamic> vars,
  }) =>
      _lineReportSegmentTemplate.renderString(vars);

  String _generateFileReportContent({
    required Map<String, dynamic> vars,
  }) =>
      _fileReportTemplate.renderString(vars);

  String _generateLineReportSegment({
    required int lineNumber,
    required CovLine? covLine,
    required String source,
  }) {
    final paddedLineNumber = '$lineNumber '.padLeft(9);
    final maybePaddedLineHits = () {
      final maybeLineHits = '${covLine?.hitsNumber ?? ''}';
      return maybeLineHits.padLeft(11);
    }();
    final lineHtmlClass = () {
      if (covLine == null) return null;
      return covLine.hasBeenHit ? ' lineCov' : ' lineNoCov';
    }();

    final vars = <String, dynamic>{
      'lineNumber': lineNumber,
      'paddedLineNumber': paddedLineNumber,
      'maybePaddedLineHits': maybePaddedLineHits,
      'lineHtmlClass': lineHtmlClass,
      'lineSource': source,
    };

    final segment = _generateLineReportSegmentContent(vars: vars);
    return segment;
  }

  /// Generate the coverage report for the given [covFile].
  void generateFileReport({
    required Directory rootReportDir,
    required CovFile covFile,
    required CovClassSuffixBuilder covClassSuffix,
  }) {
    final relativePath = path.canonicalize(
      path.relative(
        covFile.source.path,
        from: projectRootDir.path,
      ),
    );
    final relativeDirPathSegments = path
        .split(
          path.dirname(relativePath),
        )
        .where(
          (s) => s != '.',
        );
    final rootRelativePath = path.joinAll(
      List.filled(relativeDirPathSegments.length, '..'),
    );
    final cssRelativePath = path.join(rootRelativePath, 'report_style.css');
    final rootReportRelativePath = path.join(rootRelativePath, 'index.html');
    final dirPath = covFile.source.parent.path;
    final fileName = path.basename(relativePath);

    final sourceLines = covFile.source.readAsLinesSync();
    final lineReportSegmentsBuf = StringBuffer();
    for (var i = 0; i < sourceLines.length; i++) {
      final lineNumber = i + 1;
      final covLine = covFile.covLines.singleWhereOrNull(
        (l) => l.lineNumber == lineNumber,
      );
      final source = sourceLines[i];
      final lineReportSegment = _generateLineReportSegment(
        lineNumber: lineNumber,
        covLine: covLine,
        source: source,
      );
      lineReportSegmentsBuf.writeln(lineReportSegment);
    }

    final vars = <String, dynamic>{
      'cssPath': cssRelativePath,
      'tracefileName': tracefileName,
      'reportRoot': rootReportRelativePath,
      'dirPath': dirPath,
      'fileName': fileName,
      'hitLines': covFile.linesHit,
      'foundLines': covFile.linesFound,
      'coverage': covFile.coverage,
      'covSuffix': covClassSuffix(covFile.coverage),
      'date': tracefileModificationDateTime.toString(),
      'linesReports': lineReportSegmentsBuf.toString().trim(),
    };

    final reportPath = path.join(rootReportDir.path, '$relativePath.html');
    final reportFile = File(reportPath);
    if (!reportFile.existsSync()) reportFile.createSync(recursive: true);

    final report = _generateFileReportContent(vars: vars);
    reportFile.writeAsStringSync(report);
  }
}