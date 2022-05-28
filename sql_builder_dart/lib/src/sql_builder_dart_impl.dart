import 'package:tuple/tuple.dart';

class DatabaseCommandBuilder {
  DatabaseCommandBuilder._();

  static DatabaseCommandBuilderSelect select(String tablename) {
    return DatabaseCommandBuilderSelect(tablename);
  }

  static DatabaseCommandBuilderInsert insert(String tablename) {
    return DatabaseCommandBuilderInsert(tablename);
  }

  static DatabaseCommandBuilderUpdate update(String tablename) {
    return DatabaseCommandBuilderUpdate(tablename);
  }

  static DatabaseCommandBuilderDelete delete(String tablename) {
    return DatabaseCommandBuilderDelete(tablename);
  }
}

abstract class DatabaseCommandBuilderRoot {
  String build();
  List<dynamic> getParams();
  DatabaseCommandBuilderWhereOperation where();
  DatabaseCommandBuilderOrderBy orderBy(String column, SqlOrderBy orderByType);
  void collectParams(List<String> context);
}

class DatabaseCommandBuilderSelect extends DatabaseCommandBuilderRoot {
  late final String tablename;
  final List<String> columnNames = [];
  final List<Tuple2<String, String>> selectedColumn = [];
  DatabaseCommandBuilderWhere? wo;
  DatabaseCommandBuilderOrderBy? ob;

  DatabaseCommandBuilderSelect(this.tablename);

  DatabaseCommandBuilderSelect selectColumn(String columnName,
      {String as = ""}) {
    selectedColumn.add(Tuple2<String, String>(columnName, as));
    return this;
  }

  @override
  DatabaseCommandBuilderWhereOperation where() {
    wo = DatabaseCommandBuilderWhere(this);
    return wo!.opt;
  }

  @override
  DatabaseCommandBuilderOrderBy orderBy(String column, SqlOrderBy orderByType) {
    ob = DatabaseCommandBuilderOrderBy.OrderBy(column, orderByType);
    return ob!;
  }

  @override
  String build() {
    final tmp = selectedColumn
        .map((e) => (e.item2.isEmpty) ? e.item1 : "${e.item1} AS ${e.item2}")
        .join(",");
    final tmp2 = tmp.isEmpty ? "*" : tmp;
    final query = StringBuffer();
    query.write("SELECT $tmp2 FROM $tablename");
    if (wo != null) {
      query.write(" WHERE (${wo!.build()})");
    }
    if (ob != null) {
      query.write(" ORDER BY ${ob!.build()}");
    }
    return query.toString();
  }

  @override
  String toString() {
    final tmp = selectedColumn
        .map((e) => (e.item2.isEmpty) ? e.item1 : "${e.item1} AS ${e.item2}")
        .join(",");
    final tmp2 = tmp.isEmpty ? "*" : tmp;
    final query = StringBuffer();
    query.write("SELECT $tmp2 FROM $tablename");
    if (wo != null) {
      query.write(" WHERE (${wo.toString()})");
    }
    return query.toString();
  }

  @override
  void collectParams(List<dynamic> context) {
    if (wo != null) {
      wo!.collectParams(context);
    }
  }

  @override
  List<dynamic> getParams() {
    final context = <dynamic>[];
    collectParams(context);
    return context;
  }
}

enum DatabaseCommandBuilderWhereType { and, or }

class DatabaseCommandBuilderWhereLogic {
  final DatabaseCommandBuilderWhere parent;
  late DatabaseCommandBuilderWhereType type;
  DatabaseCommandBuilderWhereLogic(this.parent);

  DatabaseCommandBuilderWhereOperation and() {
    type = DatabaseCommandBuilderWhereType.and;
    return parent.opt;
  }

  DatabaseCommandBuilderWhereOperation or() {
    type = DatabaseCommandBuilderWhereType.or;
    return parent.opt;
  }
}

class DatabaseCommandBuilderWhereScope {
  late final DatabaseCommandBuilderWhere whereObj;
  bool isInit = false;
  DatabaseCommandBuilderWhereScope(DatabaseCommandBuilderRoot root) {
    whereObj = DatabaseCommandBuilderWhere(root);
  }

  DatabaseCommandBuilderWhereOperation where() {
    isInit = true;
    return whereObj.opt;
  }

  DatabaseCommandBuilderWhereOperation whereAnd() {
    if (!isInit) {
      throw StateError("Please use where() first");
    }
    return whereObj.whereAnd();
  }

  DatabaseCommandBuilderWhere whereAndNest(
      Function(DatabaseCommandBuilderWhereScope) scope) {
    if (!isInit) {
      throw StateError("Please use where() first");
    }
    return whereObj.whereAndNest(scope);
  }

  DatabaseCommandBuilderWhereOperation whereOr() {
    if (!isInit) {
      throw StateError("Please use where() first");
    }
    return whereObj.whereOr();
  }

  DatabaseCommandBuilderWhere whereOrNest(
      Function(DatabaseCommandBuilderWhereScope) scope) {
    if (!isInit) {
      throw StateError("Please use where() first");
    }
    return whereObj.whereAndNest(scope);
  }
}

class DatabaseCommandBuilderWhere {
  late DatabaseCommandBuilderWhereOperation opt;
  bool isScope;
  DatabaseCommandBuilderRoot root;

  List<Tuple2<DatabaseCommandBuilderWhereType, DatabaseCommandBuilderWhere>>
      whereList = [];

  DatabaseCommandBuilderWhere(this.root) : isScope = false {
    opt = DatabaseCommandBuilderWhereOperation(this);
  }

  DatabaseCommandBuilderWhere.Scope(this.root) : isScope = true {
    opt = DatabaseCommandBuilderWhereOperation(this);
  }

  DatabaseCommandBuilderWhere whereAndNest(
      Function(DatabaseCommandBuilderWhereScope) scope) {
    final scopeObj = DatabaseCommandBuilderWhereScope(root);
    scope(scopeObj);
    final whereObj = scopeObj.whereObj;
    whereList.add(
        Tuple2<DatabaseCommandBuilderWhereType, DatabaseCommandBuilderWhere>(
            DatabaseCommandBuilderWhereType.and, whereObj));
    return this;
  }

  DatabaseCommandBuilderWhereOperation whereAnd() {
    final whereObj = DatabaseCommandBuilderWhere(root);
    whereList.add(
        Tuple2<DatabaseCommandBuilderWhereType, DatabaseCommandBuilderWhere>(
            DatabaseCommandBuilderWhereType.and, whereObj));
    return whereObj.opt;
  }

  DatabaseCommandBuilderWhere whereOrNest(
      Function(DatabaseCommandBuilderWhereScope) scope) {
    final scopeObj = DatabaseCommandBuilderWhereScope(root);
    scope(scopeObj);
    final whereObj = scopeObj.whereObj;
    whereList.add(
        Tuple2<DatabaseCommandBuilderWhereType, DatabaseCommandBuilderWhere>(
            DatabaseCommandBuilderWhereType.or, whereObj));
    return this;
  }

  DatabaseCommandBuilderWhereOperation whereOr() {
    final whereObj = DatabaseCommandBuilderWhere(root);
    whereList.add(
        Tuple2<DatabaseCommandBuilderWhereType, DatabaseCommandBuilderWhere>(
            DatabaseCommandBuilderWhereType.or, whereObj));
    return whereObj.opt;
  }

  DatabaseCommandBuilderOrderBy orderBy(String column, SqlOrderBy orderByType) {
    return root.orderBy(column, orderByType);
  }

  void collectParams(List<dynamic> context) {
    opt.collectParams(context);
    for (var sibling in whereList) {
      sibling.item2.collectParams(context);
    }
  }

  List<dynamic> getParams() {
    return root.getParams();
  }

  String build() {
    if (!isScope && opt.build().isEmpty) {
      throw StateError("Invalid opeartor in query. get=[$opt]");
    }
    final whereStat = StringBuffer();
    if (!isScope) {
      whereStat.write(opt.build());
    }
    if (whereList.isNotEmpty) {
      var logic = "";
      if (whereList[0].item1 == DatabaseCommandBuilderWhereType.or) {
        logic = "OR";
      } else {
        logic = "AND";
      }
      if (!isScope) {
        whereStat.write(" $logic ");
      }
      whereStat.write("(${whereList[0].item2.build()})");
    }
    for (final sibling in whereList.skip(1)) {
      var logic = "";
      if (sibling.item1 == DatabaseCommandBuilderWhereType.or) {
        logic = "OR";
      } else {
        logic = "AND";
      }
      whereStat.write(" $logic (${sibling.item2.build()})");
    }
    return whereStat.toString();
  }

  @override
  String toString() {
    return build();
  }
}

class DatabaseCommandBuilderWhereOperation {
  DatabaseCommandBuilderWhere parent;
  DatabaseCommandBuilderWhereOperation(this.parent);
  String query = "";
  List<dynamic> variables = [];

  DatabaseCommandBuilderWhere equal(String column, dynamic value) {
    query = "$column = ?";
    variables.add(value);
    return parent;
  }

  DatabaseCommandBuilderWhere notEqual(String column, dynamic value) {
    query = "$column != ?";
    variables.add(value);
    return parent;
  }

  DatabaseCommandBuilderWhere like(String column, String pattern) {
    query = "$column LIKE ?";
    variables.add(pattern);
    return parent;
  }

  DatabaseCommandBuilderWhere inList(String column, List<String> list) {
    final varListStr = list.map((e) => "?").join(",");
    query = "$column IN ($varListStr)";
    variables.addAll(list);
    return parent;
  }

  DatabaseCommandBuilderWhere notInList(String column, List<String> list) {
    final varListStr = list.map((e) => "?").join(",");
    query = "$column NOT IN ($varListStr)";
    variables.addAll(list);
    return parent;
  }

  DatabaseCommandBuilderWhere isNull(String column) {
    query = "$column IS NULL";
    return parent;
  }

  DatabaseCommandBuilderWhere isNotNull(String column) {
    query = "$column IS NOT NULL";
    return parent;
  }

  DatabaseCommandBuilderWhere greaterThanOrEqual(String column, dynamic value) {
    query = "$column >= ?";
    variables.add(value);
    return parent;
  }

  DatabaseCommandBuilderWhere greaterThab(String column, dynamic value) {
    query = "$column > ?";
    variables.add(value);
    return parent;
  }

  DatabaseCommandBuilderWhere lessThanOrEqual(String column, dynamic value) {
    query = "$column <= ?";
    variables.add(value);
    return parent;
  }

  DatabaseCommandBuilderWhere lessThan(String column, dynamic value) {
    query = "$column < ?";
    variables.add(value);
    return parent;
  }

  DatabaseCommandBuilderWhere between(
      String column, dynamic lowerValue, dynamic higherValue) {
    query = "$column BETWEEN ? AND ?";
    variables.add(lowerValue);
    variables.add(higherValue);
    return parent;
  }

  DatabaseCommandBuilderWhere notBetween(
      String column, dynamic lowerValue, dynamic higherValue) {
    query = "$column NOT BETWEEN ? AND ?";
    variables.add(lowerValue);
    variables.add(higherValue);
    return parent;
  }

  String build() {
    return query;
  }

  void collectParams(List<dynamic> context) {
    context.addAll(variables);
  }

  @override
  String toString() {
    return build();
  }
}

class _SetRecord {
  String column;
  dynamic value;
  _SetRecord(this.column, this.value);
}

class DatabaseCommandBuilderUpdate extends DatabaseCommandBuilderRoot {
  late final String tablename;
  final List<_SetRecord> data = [];
  DatabaseCommandBuilderWhere? wo;
  DatabaseCommandBuilderOrderBy? ob;

  DatabaseCommandBuilderUpdate(this.tablename);

  DatabaseCommandBuilderUpdate set(String column, dynamic value) {
    data.add(_SetRecord(column, value));
    print(value.runtimeType);
    return this;
  }

  @override
  DatabaseCommandBuilderWhereOperation where() {
    wo = DatabaseCommandBuilderWhere(this);
    return wo!.opt;
  }

  @override
  DatabaseCommandBuilderOrderBy orderBy(String column, SqlOrderBy orderByType) {
    ob = DatabaseCommandBuilderOrderBy.OrderBy(column, orderByType);
    return ob!;
  }

  @override
  String build() {
    final querySB = StringBuffer();
    querySB.write("UPDATE $tablename SET ");

    final setStatement = data.map((item) => "${item.column} = ?").join(",");
    querySB.write(setStatement);
    if (wo != null) {
      querySB.write(" WHERE (${wo!.build()})");
    }
    if (ob != null) {
      querySB.write(" ORDER BY ${ob!.build()}");
    }
    return querySB.toString();
  }

  @override
  String toString() {
    final querySB = StringBuffer();
    querySB.write("UPDATE $tablename SET ");

    final setStatement = data.map((item) {
      return "${item.column} = ${item.value}";
    }).join(",");
    querySB.write(setStatement);
    return querySB.toString();
  }

  @override
  void collectParams(List<dynamic> context) {
    for (var entry in data) {
      context.add(entry.value);
    }
    if (wo != null) {
      wo!.collectParams(context);
    }
  }

  @override
  List<dynamic> getParams() {
    final context = <dynamic>[];
    collectParams(context);
    return context;
  }
}

class DatabaseCommandBuilderInsert extends DatabaseCommandBuilderRoot {
  late final String tablename;
  DatabaseCommandBuilderWhere? wo;
  final conflictColumns = <String>[];
  var _needHandleConflict = false;
  var _strategy = DatabaseCommandBuilderConflictStrategy.unknown;
  final List<_SetRecord> data = [];
  DatabaseCommandBuilderOrderBy? ob;

  DatabaseCommandBuilderInsert(this.tablename);

  DatabaseCommandBuilderInsert set(String column, dynamic value) {
    data.add(_SetRecord(column, value));
    return this;
  }

  DatabaseCommandBuilderInsert watchConflict(String column) {
    _needHandleConflict = true;
    conflictColumns.add(column);
    return this;
  }

  DatabaseCommandBuilderInsert whenConflictDoNothing() {
    _needHandleConflict = true;
    _strategy = DatabaseCommandBuilderConflictStrategy.doNothing;
    return this;
  }

  DatabaseCommandBuilderInsert whenConflictDoUpdate() {
    _needHandleConflict = true;
    _strategy = DatabaseCommandBuilderConflictStrategy.update;
    return this;
  }

  @override
  DatabaseCommandBuilderWhereOperation where() {
    wo = DatabaseCommandBuilderWhere(this);
    return wo!.opt;
  }

  @override
  DatabaseCommandBuilderOrderBy orderBy(String column, SqlOrderBy orderByType) {
    ob = DatabaseCommandBuilderOrderBy.OrderBy(column, orderByType);
    return ob!;
  }

  @override
  String build() {
    final querySB = StringBuffer();
    querySB.write("INSERT INTO $tablename ");
    final colStatement = data.map((item) => item.column).join(",");
    if (colStatement.isNotEmpty) {
      querySB.write("($colStatement)");
    }
    if (wo != null) {
      querySB.write(" WHERE (${wo!.build()})");
    }
    if (_needHandleConflict) {
      if (conflictColumns.isEmpty) {
        throw StateError("Not setting conflict constraints");
      }
      querySB.write(" ON CONFLICT (${conflictColumns.join(',')})");
      if (_strategy == DatabaseCommandBuilderConflictStrategy.update) {
        final collection = [];
        for (final item in data) {
          if (conflictColumns.contains(item.column)) {
            continue;
          }
          collection.add("${item.column} = excluded.${item.column}");
        }
        querySB.write(" DO UPDATE SET ${collection.join(",")}");
      } else if (_strategy ==
          DatabaseCommandBuilderConflictStrategy.doNothing) {
        querySB.write("DO NOTHING");
      } else {
        throw StateError("Missing the conflict strategy.");
      }
    }
    if (ob != null) {
      querySB.write(" ORDER BY ${ob!.build()}");
    }
    return querySB.toString();
  }

  @override
  void collectParams(List<dynamic> context) {
    if (wo != null) {
      wo!.collectParams(context);
    }
  }

  @override
  List<dynamic> getParams() {
    final context = <dynamic>[];
    collectParams(context);
    return context;
  }
}

enum DatabaseCommandBuilderConflictStrategy { unknown, doNothing, update }

class DatabaseCommandBuilderDelete extends DatabaseCommandBuilderRoot {
  late final String tablename;
  DatabaseCommandBuilderWhere? wo;
  DatabaseCommandBuilderOrderBy? ob;

  DatabaseCommandBuilderDelete(this.tablename);

  @override
  DatabaseCommandBuilderWhereOperation where() {
    wo = DatabaseCommandBuilderWhere(this);
    return wo!.opt;
  }

  @override
  DatabaseCommandBuilderOrderBy orderBy(String column, SqlOrderBy orderByType) {
    ob = DatabaseCommandBuilderOrderBy.OrderBy(column, orderByType);
    return ob!;
  }

  @override
  String build() {
    final querySB = StringBuffer();
    querySB.write("DELETE FROM $tablename");
    if (wo != null) {
      querySB.write(" WHERE (${wo!.build()})");
    }
    if (ob != null) {
      querySB.write(" ORDER BY ${ob!.build()}");
    }
    return querySB.toString();
  }

  @override
  void collectParams(List<dynamic> context) {
    if (wo != null) {
      wo!.collectParams(context);
    }
  }

  @override
  List<dynamic> getParams() {
    final context = <dynamic>[];
    collectParams(context);
    return context;
  }
}

enum SqlOrderBy {
  asc,
  desc,
}

class DatabaseCommandBuilderOrderBy {
  final orderByList = <Tuple2<String, SqlOrderBy>>[];
  DatabaseCommandBuilderOrderBy._();
  DatabaseCommandBuilderOrderBy.OrderBy(String col, SqlOrderBy orderByType) {
    orderByList.add(Tuple2<String, SqlOrderBy>(col, orderByType));
  }

  DatabaseCommandBuilderOrderBy orderBy(String col, SqlOrderBy orderByType) {
    orderByList.add(Tuple2<String, SqlOrderBy>(col, orderByType));
    return this;
  }

  String build() {
    final List<String> orderByStrList = <String>[];
    for (var orderByEntry in orderByList) {
      var typeStr = (orderByEntry.item2 == SqlOrderBy.asc) ? "ASC" : "DESC";
      orderByStrList.add("${orderByEntry.item1} ${typeStr}");
    }
    if (orderByStrList.isEmpty) {
      return "";
    } else {
      return orderByStrList.join(',');
    }
  }
}
