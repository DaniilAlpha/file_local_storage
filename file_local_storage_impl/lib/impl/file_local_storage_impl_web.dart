import "dart:async";
import "dart:html";
import "dart:indexed_db";
import "dart:js_interop";
import "dart:typed_data";

import "package:file_local_storage_impl/file_local_storage_impl.dart";

final class FileLocalStorageImpl extends FileLocalStorageInterface {
  FileLocalStorageImpl({super.storagePath, required super.storageName}) {
    if (!IdbFactory.supported) {
      throw FileLocalStorageException("IndexedDB is not supported.");
    }
  }

  late final connection = window.indexedDB!.open(
    "file_local_storage_db",
    version: 1,
    onUpgradeNeeded: _onUpgradeNeeded,
  );

  @override
  Future<ByteBuffer> load(String name) async {
    final db = await connection;
    final store =
        db.transactionStore(storageName, "readonly").objectStore(storageName);

    try {
      final result = await store.getObject(KeyRange.only(name));
      if (result! is! ByteBuffer)
        throw FileLocalStorageException("Invalid saved data.");
      return result;
    } on Exception catch (e) {
      String msg;
      try {
        final dynamic dynE = e;
        // ignore: avoid_dynamic_calls
        msg = dynE.message;
        // ignore: avoid_catching_errors
      } on NoSuchMethodError {
        msg = "IndexedDB getObject exception.";
      }
      throw FileLocalStorageException(msg);
    }
  }

  @override
  Future<void> save(String name, ByteBuffer data) async {
    final db = await connection;
    final store =
        db.transactionStore(storageName, "readwrite").objectStore(storageName);

    try {
      await store.put(data.toJS, name);
    } on Exception catch (e) {
      String msg;
      try {
        final dynamic dynE = e;
        // ignore: avoid_dynamic_calls
        msg = dynE.message;
        // ignore: avoid_catching_errors
      } on NoSuchMethodError {
        msg = "IndexedDB put exception.";
      }
      throw FileLocalStorageException(msg);
    }
  }

  void _onUpgradeNeeded(VersionChangeEvent event) {
    final Database db = event.target.result;
    if (db.objectStoreNames?.contains(storageName) != true) {
      db.createObjectStore(storageName);
    }
  }
}