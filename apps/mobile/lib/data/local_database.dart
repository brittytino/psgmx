import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

@DataClassName('DailyFiveCacheEntry')
class DailyFiveCache extends Table {
  TextColumn get id => text()();
  TextColumn get questionText => text()();
  TextColumn get optionsJson => text()(); 
  IntColumn get correctOption => integer()();
  TextColumn get topic => text()();
  TextColumn get difficulty => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class OfflineStreaks extends Table {
  TextColumn get userId => text()();
  IntColumn get currentStreak => integer()();
  IntColumn get longestStreak => integer()();
  IntColumn get freezesRemaining => integer()();
  TextColumn get freezesResetMonth => text()();
  TextColumn get lastCompletedDate => text().nullable()();
  RealColumn get lastAccuracyRate => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()(); 
  TextColumn get payloadJson => text()(); 
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [DailyFiveCache, OfflineStreaks, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'psgmx_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final AppDatabase localDb = AppDatabase();
