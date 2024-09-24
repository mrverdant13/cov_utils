# Coverde

[![pub package][pub_badge]][pub_link]
[![License: MIT][license_badge]][license_link]
[![Dart CI][dart_ci_badge]][dart_ci_link]
[![codecov][codecov_badge]][codecov_link]
[![CodeFactor][codefactor_badge]][codefactor_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![melos][melos_badge]][melos_link]

A CLI for basic coverage trace files manipulation.

---

# Index

- [Installing](#installing)
- [Features](#features)
- [Usage with `melos`](#usage-with-melos)
- [CI integration for coverage checks](#ci-integration-for-coverage-checks)

---

# Installing

You can make `coverde` globally available by executing the following command:

```sh
$ dart pub global activate coverde
```

**NOTE:** To run `coverde` directly from the terminal, add the system cache `bin` directory to your `PATH` environment variable.

---

# Features

- [**Check coverage value computed from a trace file**](#coverde-check)
- [**Filter the tested files included in a trace file**](#coverde-filter)
- [**Remove a set of files and folders**](#coverde-remove)
- [**Generate HTML coverage report**](#coverde-report)
- [**Compute and display the coverage value from a trace file**](#coverde-value)

## `coverde check`

**Check coverage value computed from a trace file.**

### Options

- `--input` | `-i`

  Trace file used for the coverage check.\
  Default value: `coverage/lcov.info`

### Flags

- `--verbose` | `-v`

  Whether to print the coverage value.\
  Use `--no-verbose` to disable this flag.\
  Default value: _Enabled_

### Parameters

- `<min_coverage>`

  An integer between 0 and 100 used as minimum acceptable coverage value.\
  This value is required.

### Examples

- `coverde check 90`
- `coverde check -i lcov.info 75`
- `coverde check 100 --no-verbose`

### Results

![Check example (pass)][_docs_coverde_check_example_1]

![Check example (fail)][_docs_coverde_check_example_2]

## `coverde filter`

**Filter the tested files included in a trace file.**

### Options

- `--input` | `-i`

  Coverage trace file to be filtered.\
  Default value: `coverage/lcov.info`

- `--output` | `-o`

  Filtered coverage trace file (automatically created if it is absent).\
  Default value: `coverage/filtered.lcov.info`

- `--paths-parent` | `-p`

  Prefix of the resulting filtered paths.\
  Default value: _Unset_

- `--filters` | `-f`

  Set of comma-separated patterns of the files to be opted out of coverage.\
  Default value: _Unset_

- `--mode` | `-m`

  The mode in which the filtered trace file content should be generated.\
  `a`: append content.\
  `w`: overwrite content.\
  Default value: `a` (append content)

### Examples

- `coverde filter`
- `coverde filter -f '\.g\.dart'`
- `coverde filter -f '\.freezed\.dart' -mode w`
- `coverde filter -f generated -mode a`
- `coverde filter -o coverage/trace-file.info`

## `coverde remove`

**Remove a set of files and folders.**

### Flags

- `--accept-absence`

  Set the command behavior according to a file/folder existence.\
  If enabled, the command continues and notifies the element absence.\
  If disabled, the command fails.\
  Use `--no-accept-absence` to disable this flag.\
  Default value: _Enabled_

## Parameters

- `<paths>`

  Set of paths to be removed.\
  Multiple paths can be specified by separating them with a space.\
  This value is required.

### Examples

- `coverde remove file.txt`
- `coverde remove path/to/folder/`
- `coverde remove path/to/another.file.txt path/to/another/folder/ local.folder/`

## `coverde report`

**Generate HTML & Markdown coverage report.**

> [!NOTE]
> Generated markdown report is a single file containing a short report of coverage for each file and summary of the entire coverage
> it can be useful when you want to comment a report of the code coverage inside pull requests. 

### Options

- `--input` | `-i`

  Coverage trace file to be used as source for report generation.\
  Default value: `coverage/lcov.info`

- `--output` | `-o`

  Destination folder where the generated html report files will be placed.\
  Default value: `coverage/html/`

- `--markdown` | `-m`

  Destination folder where the generated markdown report file will be placed.\
  Default value: `coverage/markdown/report.md`

- `--medium`

  Medium threshold for coverage value.\
  Default value: `75`

- `--high`

  High threshold for coverage value.\
  Default value: `90`

> [!NOTE]
> The report style is dynamically set according to individual, group and global coverage and the `--medium` and `--high` options.

### Flags

- `--launch` | `-l`

  Whether to launch the generated report in the default browser.\
  Use `--no-launch` to disable this flag.\
  Default value: _Disabled_

### Examples

- `coverde report`
- `coverde report -i coverage/trace-file.info --medium 50`
- `coverde report -o coverage/report --high 95 -l`

### Results

![Report example (directory)][_docs_coverde_report_example_1]

![Report example (file)][_docs_coverde_report_example_2]

![Markdown report example (file)][_docs_coverde_report_example_3]

## `coverde value`

**Compute and display the coverage value from a trace file.**

### Options

- `--input` | `-i`

  Coverage trace file to be used for coverage value computation.\
  Default value: `coverage/lcov.info`

### Flags

- `--verbose` | `-v`

  Whether to print the coverage value for each source file referenced in the trace file.\
  Use `--no-verbose` to disable this flag.\
  Default value: _Enabled_

### Examples

- `coverde value`
- `coverde value -i coverage/trace-file.info --no-verbose`

---

# Usage with [melos][melos_link]

If your project uses melos to manage its multi-package structure, it could be handy to collect test coverage data in a unified trace file.
This can be achieved by defining a melos script as follows:

```yaml
merge-trace-files:
  description: Merge all packages coverage trace files ignoring data related to generated files.
  run: >
    coverde rm MELOS_ROOT_PATH/coverage/filtered.lcov.info &&
    melos exec --file-exists=coverage/lcov.info -- "coverde filter --input ./coverage/lcov.info --output MELOS_ROOT_PATH/coverage/filtered.lcov.info --paths-parent MELOS_PACKAGE_PATH --filters '\.g\.dart'"
```

`merge-trace-files` is the melos script that merges the coverage trace file of all tested packages contained within the project

First, the script removes the `filtered.lcov.info` file, if it exists, from the `coverage` folder in the root folder of the project.

Then, the script executes the `coverde filter` command for each package that contains a `coverage/lcov.info` file, using its content as input and the `filtered.lcov.info` file in the project root as output.

The resulting merged trace file ignores data related to generated files, which are identified by the `.g.dart` extension.

Each referenced file path is prefixed with the package path, so that the resulting merged trace file contains a set of paths that represent the actual project structure, which is critical for the `coverde report` command to work properly, as it relies on the file system to generate the HTML report.

---

# CI integration for coverage checks

If your project uses GitHub Actions for CI, you might already know [very_good_coverage][very_good_coverage_link], which offers a simple but effective method for coverage validation.

However, adding coverage checks to CI workflows hosted by other alternatives is not always that straightforward.

To solve this, after enabling Dart or Flutter in your CI workflow, according to your project requirements, you can use `coverde` and its `check` tool by adding the following commands to your workflow steps:

- `dart pub global activate coverde`
- `coverde check <min_coverage>`

# Bugs or Requests

If you encounter any problems or you believe the CLI is missing a feature, feel free to [open an issue on GitHub][open_issue_link].

Pull request are also welcome. See [CONTRIBUTING.md][_docs_contributing_link].

[_docs_contributing_link]: https://github.com/mrverdant13/coverde/blob/main/CONTRIBUTING.md
[_docs_coverde_check_example_1]: https://github.com/mrverdant13/coverde/blob/main/packages/coverde_cli/doc/check_result_pass.png?raw=true
[_docs_coverde_check_example_2]: https://github.com/mrverdant13/coverde/blob/main/packages/coverde_cli/doc/check_result_fail.png?raw=true
[_docs_coverde_report_example_1]: https://github.com/mrverdant13/coverde/blob/main/packages/coverde_cli/doc/report_directory_example.png?raw=true
[_docs_coverde_report_example_2]: https://github.com/mrverdant13/coverde/blob/main/packages/coverde_cli/doc/report_file_example.png?raw=true
[_docs_coverde_report_example_3]: https://github.com/mrverdant13/coverde/blob/main/packages/coverde_cli/doc/markdown_report_file_example.png?raw=true
[codecov_badge]: https://codecov.io/gh/mrverdant13/coverde/branch/main/graph/badge.svg
[codecov_link]: https://codecov.io/gh/mrverdant13/coverde
[codefactor_badge]: https://www.codefactor.io/repository/github/mrverdant13/coverde/badge
[codefactor_link]: https://www.codefactor.io/repository/github/mrverdant13/coverde
[dart_ci_badge]: https://github.com/mrverdant13/coverde/workflows/Dart%20CI/badge.svg
[dart_ci_link]: https://github.com/mrverdant13/coverde/actions?query=workflow%3A%22Dart+CI%22
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[melos_badge]: https://img.shields.io/badge/maintained%20with-melos-f700ff.svg
[melos_link]: https://melos.invertase.dev/
[open_issue_link]: https://github.com/mrverdant13/coverde/issues/new
[pub_badge]: https://img.shields.io/pub/v/coverde.svg
[pub_link]: https://pub.dev/packages/coverde
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://github.com/VeryGoodOpenSource/very_good_analysis
[very_good_coverage_link]: https://github.com/VeryGoodOpenSource/very_good_coverage
