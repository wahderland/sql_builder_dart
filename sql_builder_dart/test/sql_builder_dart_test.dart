import 'package:sql_builder_dart/sql_builder_dart.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {

    setUp(() {

    });

    test('select', () {
      final query = DatabaseCommandBuilder.select("aaa");
      query
          .selectColumn("aaa")
          .selectColumn("bbb")
          .selectColumn("ccc")
          .where()
          .equal("aaa", "ccc")
          .whereAnd()
          .notEqual("bbbb", "ddd")
          .whereOr()
          .notEqual("1", "3")
          .whereAndNest((scope) {
        scope.where().like("lv21", "2").whereAndNest((scope) {
          scope.where().inList("lv31", ["3", "6", "8"]);
          scope.whereAnd().inList("lv41", ["333", "666", "888"]);
          scope.whereAndNest((scope) {
            scope.where().equal("lv42", "hehe");
            scope.whereAnd().equal("lv43", "123");
          });
          scope.whereOr().equal("lv23", "4");
        });
      }).orderBy("bbb", SqlOrderBy.asc);
      print(query.build());
      print(query.getParams());
      expect(query.build(), 'SELECT aaa,bbb,ccc FROM aaa WHERE (aaa = ? AND (bbbb != ? OR (1 != ? AND (lv21 LIKE ? AND (lv31 IN (?,?,?) AND (lv41 IN (?,?,?)) AND (lv42 = ? AND (lv43 = ?)) OR (lv23 = ?)))))) ORDER BY bbb ASC');
      expect(query.getParams(), ["ccc", "ddd", "3", "2", "3", "6", "8", "333", "666", "888", "hehe", "123", "4"]);
    });

    test('update', () {
      final query = DatabaseCommandBuilder.update("BigTable");
      query
          .set("aaa", 123)
          .set("bbbb", "bbbbb")
          .set("aaa", 'max(a)')
          .where()
          .equal("aa", "1")
          .whereAnd()
          .like("bbb", "ssss%");
      print(query.build());
      print(query.getParams());
      expect(query.build(), 'UPDATE BigTable SET aaa = ?,bbbb = ?,aaa = ? WHERE (aa = ? AND (bbb LIKE ?))');
      expect(query.getParams(), [123, "bbbbb", "max(a)", "1", "ssss%"]);
    });

    test('insert', () {
      final query = DatabaseCommandBuilder.insert("BigTable");
      query
          .set("aaa", 123)
          .set("bbbb", "bbbbb")
          .set("ccc", 'max(a)')
          .watchConflict("ggg")
          .whenConflictDoUpdate()
          .where()
          .equal("aa", 1)
          .whereAnd()
          .equal("aa", "bbbb")
          .orderBy("bbb", SqlOrderBy.asc)
          .orderBy("ccc", SqlOrderBy.desc);
      print(query.build());
      print(query.getParams());
      expect(query.build(), 'INSERT INTO BigTable (aaa,bbbb,ccc) WHERE (aa = ? AND (aa = ?)) ON CONFLICT (ggg) DO UPDATE SET aaa = excluded.aaa,bbbb = excluded.bbbb,ccc = excluded.ccc ORDER BY bbb ASC,ccc DESC');
      expect(query.getParams(), [1, "bbbb"]);
    });

    test('delete', () {
      final query = DatabaseCommandBuilder.delete("BigTable");
      query.where().equal("aa", "1");
      print(query.build());
      print(query.getParams());
      expect(query.build(), 'DELETE FROM BigTable WHERE (aa = ?)');
      expect(query.getParams(), ["1"]);
    });
  });
}
