<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Build a SQL with strong-typed function.

## Features

- Support `select`, `insert`, `update` and `delete`
- Support type `string` and `int` on parameters binding

## Getting started

```
dart pub add sql_builder_dart
```

or

```
flutter pub add sql_builder_dart
```


## Usage

```dart
import 'sql_builder_dart/sql_builder_dart.dart';

void main() {
    final query = DatabaseCommandBuilder.select("aaa");
    query.selectColumn("aaa");
    print(query.build());
    print(query.getParams());
}
```
