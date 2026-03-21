// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statement_dao.dart';

// ignore_for_file: type=lint
mixin _$StatementDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $StatementsTable get statements => attachedDatabase.statements;
  StatementDaoManager get managers => StatementDaoManager(this);
}

class StatementDaoManager {
  final _$StatementDaoMixin _db;
  StatementDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$StatementsTableTableManager get statements =>
      $$StatementsTableTableManager(_db.attachedDatabase, _db.statements);
}
