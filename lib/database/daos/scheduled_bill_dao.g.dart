// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_bill_dao.dart';

// ignore_for_file: type=lint
mixin _$ScheduledBillDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ScheduledBillsTable get scheduledBills => attachedDatabase.scheduledBills;
  ScheduledBillDaoManager get managers => ScheduledBillDaoManager(this);
}

class ScheduledBillDaoManager {
  final _$ScheduledBillDaoMixin _db;
  ScheduledBillDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ScheduledBillsTableTableManager get scheduledBills =>
      $$ScheduledBillsTableTableManager(
        _db.attachedDatabase,
        _db.scheduledBills,
      );
}
