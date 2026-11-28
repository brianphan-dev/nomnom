import Foundation
import NomNomShared
import SQLite3

// MARK: - Errors & Outbox Record

public enum LocalDiaryStoreError: Error, Sendable, Equatable, LocalizedError {
    case openDatabaseFailed(String)
    case sqliteError(code: Int32, message: String)
    case serializationError(String)
    case invalidData(String)

    public var errorDescription: String? {
        switch self {
        case let .openDatabaseFailed(message):
            "Failed to open local SQLite diary database: \(message)"
        case let .sqliteError(code, message):
            "SQLite error (\(code)): \(message)"
        case let .serializationError(message):
            "Local storage JSON serialization error: \(message)"
        case let .invalidData(message):
            "Local storage encountered invalid data: \(message)"
        }
    }
}

/// Durable outbox entry written atomically alongside local diary mutations.
public struct OutboxMutationRecord: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var entityType: SyncEntityType
    public var entityId: UUID
    public var op: SyncMutationOp
    public var payloadJSON: String?
    public var idempotencyKey: String
    public var createdAt: Date

    public init(
        id: UUID,
        entityType: SyncEntityType,
        entityId: UUID,
        op: SyncMutationOp,
        payloadJSON: String?,
        idempotencyKey: String,
        createdAt: Date
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.op = op
        self.payloadJSON = payloadJSON
        self.idempotencyKey = idempotencyKey
        self.createdAt = createdAt
    }

    /// Converts the stored outbox row into a wire-ready `SyncMutation` for `POST /v1/sync/push`.
    public func toSyncMutation(decoder: JSONDecoder = NomNomJSON.makeDecoder()) throws -> SyncMutation {
        let payload: SyncPayload?
        if op == .upsert, let payloadJSON, let data = payloadJSON.data(using: .utf8) {
            switch entityType {
            case .meal:
                payload = .meal(try decoder.decode(Meal.self, from: data))
            case .foodItem:
                payload = .foodItem(try decoder.decode(FoodItem.self, from: data))
            case .photoAsset:
                payload = .photoAsset(try decoder.decode(PhotoAsset.self, from: data))
            }
        } else {
            payload = nil
        }

        return SyncMutation(
            mutationId: id,
            entityType: entityType,
            entityId: entityId,
            op: op,
            clientUpdatedAt: createdAt,
            payload: payload
        )
    }
}

// MARK: - Local SQLite Diary Store

/// Native `SQLite3` offline-first persistence actor with FTS5 food search,
/// atomic `sync_outbox` transactions, sync cursor state, and deterministic import deduplication.
public actor LocalDiaryStore {
    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    private static let syncSeqStateKey = "last_sync_seq"
    private static let lastSyncedAtStateKey = "last_synced_at"

    private nonisolated(unsafe) var db: OpaquePointer?
    private let path: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(path: String = ":memory:") throws {
        self.path = path
        self.encoder = NomNomJSON.makeEncoder()
        self.decoder = NomNomJSON.makeDecoder()

        if path != ":memory:" {
            let parentDir = URL(fileURLWithPath: path).deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let openResult = sqlite3_open_v2(path, &handle, flags, nil)
        guard openResult == SQLITE_OK, let openedHandle = handle else {
            let message = handle.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
            if let handle {
                sqlite3_close(handle)
            }
            throw LocalDiaryStoreError.openDatabaseFailed(message)
        }

        self.db = openedHandle

        do {
            try Self.configureAndMigrate(handle: openedHandle, isInMemory: path == ":memory:")
        } catch {
            sqlite3_close(openedHandle)
            self.db = nil
            throw error
        }
    }

    public init(url: URL) throws {
        try self.init(path: url.path)
    }

    public static func inMemory() throws -> LocalDiaryStore {
        try LocalDiaryStore(path: ":memory:")
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    // MARK: - Schema & Migrations

    private static func configureAndMigrate(handle: OpaquePointer, isInMemory: Bool) throws {
        if !isInMemory {
            try executeStaticSQL(handle, sql: "PRAGMA journal_mode = WAL;")
        }
        try executeStaticSQL(handle, sql: "PRAGMA foreign_keys = ON;")
        try executeStaticSQL(handle, sql: "PRAGMA busy_timeout = 5000;")

        let schemaSQL = """
        CREATE TABLE IF NOT EXISTS meals (
            id TEXT PRIMARY KEY NOT NULL,
            local_date TEXT NOT NULL,
            eaten_at REAL NOT NULL,
            meal_type TEXT NOT NULL,
            title TEXT NOT NULL,
            dedupe_fingerprint TEXT,
            sync_seq INTEGER,
            updated_at REAL NOT NULL,
            deleted_at REAL,
            payload_json TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_meals_local_date
            ON meals(local_date, deleted_at, eaten_at);
        CREATE INDEX IF NOT EXISTS idx_meals_sync_seq
            ON meals(sync_seq);
        CREATE INDEX IF NOT EXISTS idx_meals_dedupe_fingerprint
            ON meals(dedupe_fingerprint);

        CREATE TABLE IF NOT EXISTS food_items (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            brand TEXT,
            barcode TEXT,
            source TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            last_used_at REAL,
            sync_seq INTEGER,
            updated_at REAL NOT NULL,
            deleted_at REAL,
            payload_json TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_food_items_barcode
            ON food_items(barcode);
        CREATE INDEX IF NOT EXISTS idx_food_items_recent
            ON food_items(deleted_at, is_favorite, last_used_at);

        CREATE VIRTUAL TABLE IF NOT EXISTS food_items_fts USING fts5(
            food_id UNINDEXED,
            name,
            brand,
            barcode,
            tokenize='unicode61 remove_diacritics 2'
        );

        CREATE TABLE IF NOT EXISTS photo_assets (
            id TEXT PRIMARY KEY NOT NULL,
            meal_id TEXT NOT NULL,
            local_filename TEXT NOT NULL,
            sha256_hash TEXT NOT NULL,
            r2_object_key TEXT,
            upload_state TEXT NOT NULL,
            sync_seq INTEGER,
            updated_at REAL NOT NULL,
            deleted_at REAL,
            payload_json TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_photo_assets_meal_id
            ON photo_assets(meal_id);

        CREATE TABLE IF NOT EXISTS sync_outbox (
            id TEXT PRIMARY KEY NOT NULL,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            op TEXT NOT NULL,
            payload_json TEXT,
            idempotency_key TEXT NOT NULL UNIQUE,
            created_at REAL NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_sync_outbox_created_at
            ON sync_outbox(created_at);

        CREATE TABLE IF NOT EXISTS sync_state (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS import_fingerprints (
            fingerprint TEXT PRIMARY KEY NOT NULL,
            source TEXT NOT NULL,
            meal_id TEXT NOT NULL,
            imported_at REAL NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_import_fingerprints_source
            ON import_fingerprints(source);
        """

        try executeStaticSQL(handle, sql: schemaSQL)
    }

    // MARK: - Meal Mutations & Queries

    /// Atomically persists a `Meal` and enqueues its `sync_outbox` mutation in a single transaction.
    public func saveMeal(_ meal: Meal, enqueueSync: Bool = true) throws {
        try withImmediateTransaction {
            let payloadJSON = try encodeJSONString(meal)
            try upsertMealRow(meal, payloadJSON: payloadJSON)

            if let fingerprint = meal.dedupeFingerprint, !fingerprint.isEmpty, !meal.isDeleted {
                try insertImportFingerprintRow(
                    fingerprint: fingerprint,
                    source: meal.captureMethod.rawValue,
                    mealId: meal.id,
                    importedAt: meal.createdAt
                )
            }

            if enqueueSync {
                let op: SyncMutationOp = meal.isDeleted ? .delete : .upsert
                try insertOutboxRow(
                    entityType: .meal,
                    entityId: meal.id,
                    op: op,
                    payloadJSON: op == .upsert ? payloadJSON : nil,
                    createdAt: meal.updatedAt
                )
            }
        }
    }

    /// Atomically soft-deletes a `Meal` and enqueues a `.delete` mutation into `sync_outbox`.
    public func softDeleteMeal(id: UUID, at deletedAt: Date = Date(), enqueueSync: Bool = true) throws {
        try withImmediateTransaction {
            if var existing = try fetchMealRow(id: id) {
                existing.deletedAt = deletedAt
                existing.updatedAt = deletedAt
                let payloadJSON = try encodeJSONString(existing)
                try upsertMealRow(existing, payloadJSON: payloadJSON)
            } else {
                let sql = "UPDATE meals SET deleted_at = ?, updated_at = ? WHERE id = ?;"
                let stmt = try prepare(sql)
                defer { sqlite3_finalize(stmt) }
                sqlite3_bind_double(stmt, 1, deletedAt.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 2, deletedAt.timeIntervalSince1970)
                bindText(stmt, index: 3, value: id.uuidString)
                try stepDone(stmt)
            }

            if enqueueSync {
                try insertOutboxRow(
                    entityType: .meal,
                    entityId: id,
                    op: .delete,
                    payloadJSON: nil,
                    createdAt: deletedAt
                )
            }
        }
    }

    /// Applies an external import batch (such as MyFitnessPal or HealthKit) in one atomic transaction.
    public func applyImport(
        mealsToInsert: [Meal],
        mealIdsToDelete: [UUID] = [],
        source: String,
        deletedAt: Date = Date(),
        enqueueSync: Bool = true
    ) throws {
        try withImmediateTransaction {
            for mealId in mealIdsToDelete {
                if var existing = try fetchMealRow(id: mealId) {
                    existing.deletedAt = deletedAt
                    existing.updatedAt = deletedAt
                    let payloadJSON = try encodeJSONString(existing)
                    try upsertMealRow(existing, payloadJSON: payloadJSON)
                }
                if enqueueSync {
                    try insertOutboxRow(
                        entityType: .meal,
                        entityId: mealId,
                        op: .delete,
                        payloadJSON: nil,
                        createdAt: deletedAt
                    )
                }
            }

            for meal in mealsToInsert {
                let payloadJSON = try encodeJSONString(meal)
                try upsertMealRow(meal, payloadJSON: payloadJSON)
                if let fingerprint = meal.dedupeFingerprint, !fingerprint.isEmpty {
                    try insertImportFingerprintRow(
                        fingerprint: fingerprint,
                        source: source,
                        mealId: meal.id,
                        importedAt: meal.createdAt
                    )
                }
                if enqueueSync {
                    try insertOutboxRow(
                        entityType: .meal,
                        entityId: meal.id,
                        op: .upsert,
                        payloadJSON: payloadJSON,
                        createdAt: meal.updatedAt
                    )
                }
            }
        }
    }

    /// Upserts a meal received from remote sync (including tombstones) without re-enqueuing an outbox mutation.
    public func upsertRemoteMeal(_ meal: Meal) throws {
        try withImmediateTransaction {
            let payloadJSON = try encodeJSONString(meal)
            try upsertMealRow(meal, payloadJSON: payloadJSON)
            if let fingerprint = meal.dedupeFingerprint, !fingerprint.isEmpty, !meal.isDeleted {
                try insertImportFingerprintRow(
                    fingerprint: fingerprint,
                    source: meal.captureMethod.rawValue,
                    mealId: meal.id,
                    importedAt: meal.createdAt
                )
            }
        }
    }

    public func meal(id: UUID) throws -> Meal? {
        try fetchMealRow(id: id)
    }

    public func allMeals(includeDeleted: Bool = false) throws -> [Meal] {
        let sql = includeDeleted
            ? "SELECT payload_json FROM meals ORDER BY local_date ASC, eaten_at ASC, id ASC;"
            : "SELECT payload_json FROM meals WHERE deleted_at IS NULL ORDER BY local_date ASC, eaten_at ASC, id ASC;"
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        return try readDecodedRows(stmt, as: Meal.self)
    }

    /// Returns all active (non-deleted) meals for a calendar date (`YYYY-MM-DD`), ordered chronologically.
    public func meals(forLocalDate localDate: String) throws -> [Meal] {
        let sql = """
        SELECT payload_json
        FROM meals
        WHERE local_date = ? AND deleted_at IS NULL
        ORDER BY eaten_at ASC, id ASC;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: localDate)
        return try readDecodedRows(stmt, as: Meal.self)
    }

    /// Returns all active (non-deleted) meals within an inclusive `[from, to]` `YYYY-MM-DD` date range.
    public func mealsInDateRange(from startLocalDate: String, to endLocalDate: String) throws -> [Meal] {
        let sql = """
        SELECT payload_json
        FROM meals
        WHERE local_date >= ? AND local_date <= ? AND deleted_at IS NULL
        ORDER BY local_date ASC, eaten_at ASC, id ASC;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: startLocalDate)
        bindText(stmt, index: 2, value: endLocalDate)
        return try readDecodedRows(stmt, as: Meal.self)
    }

    // MARK: - Food Catalog & FTS5 Search

    public func saveFoodItem(_ item: FoodItem, enqueueSync: Bool = false) throws {
        try withImmediateTransaction {
            let payloadJSON = try encodeJSONString(item)
            try upsertFoodItemRow(item, payloadJSON: payloadJSON)
            if enqueueSync {
                let op: SyncMutationOp = item.deletedAt != nil ? .delete : .upsert
                try insertOutboxRow(
                    entityType: .foodItem,
                    entityId: item.id,
                    op: op,
                    payloadJSON: op == .upsert ? payloadJSON : nil,
                    createdAt: item.updatedAt
                )
            }
        }
    }

    public func upsertRemoteFoodItem(_ item: FoodItem) throws {
        try withImmediateTransaction {
            let payloadJSON = try encodeJSONString(item)
            try upsertFoodItemRow(item, payloadJSON: payloadJSON)
        }
    }

    /// Seeds initial offline catalog staples only when `food_items` is completely empty.
    @discardableResult
    public func seedFoodItemsIfEmpty(_ items: [FoodItem]) throws -> Int {
        guard !items.isEmpty else { return 0 }
        return try withImmediateTransaction {
            let countStmt = try prepare("SELECT COUNT(*) FROM food_items;")
            defer { sqlite3_finalize(countStmt) }
            guard sqlite3_step(countStmt) == SQLITE_ROW else {
                throw lastSQLiteError()
            }
            let existingCount = sqlite3_column_int64(countStmt, 0)
            guard existingCount == 0 else { return 0 }

            for item in items {
                let payloadJSON = try encodeJSONString(item)
                try upsertFoodItemRow(item, payloadJSON: payloadJSON)
            }
            return items.count
        }
    }

    public func foodItem(byBarcode barcode: String) throws -> FoodItem? {
        let cleaned = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        let sql = """
        SELECT payload_json
        FROM food_items
        WHERE barcode = ? AND deleted_at IS NULL
        LIMIT 1;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: cleaned)
        return try readDecodedRows(stmt, as: FoodItem.self).first
    }

    public func allFoodItems(includeDeleted: Bool = false) throws -> [FoodItem] {
        let sql = includeDeleted
            ? "SELECT payload_json FROM food_items ORDER BY name ASC;"
            : "SELECT payload_json FROM food_items WHERE deleted_at IS NULL ORDER BY name ASC;"
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        return try readDecodedRows(stmt, as: FoodItem.self)
    }

    public func recentFoods(limit: Int = 20) throws -> [FoodItem] {
        let safeLimit = max(1, limit)
        let sql = """
        SELECT payload_json
        FROM food_items
        WHERE deleted_at IS NULL
        ORDER BY is_favorite DESC, COALESCE(last_used_at, 0) DESC, name ASC
        LIMIT ?;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(safeLimit))
        return try readDecodedRows(stmt, as: FoodItem.self)
    }

    /// Instant offline full-text prefix search backed by SQLite FTS5.
    public func searchLocalFoods(query: String, limit: Int = 25) throws -> [FoodItem] {
        let safeLimit = max(1, limit)
        let ftsMatchExpression = Self.buildFTS5Query(from: query)
        guard !ftsMatchExpression.isEmpty else {
            return try recentFoods(limit: safeLimit)
        }

        let sql = """
        SELECT f.payload_json
        FROM food_items_fts
        INNER JOIN food_items AS f ON f.id = food_items_fts.food_id
        WHERE food_items_fts MATCH ? AND f.deleted_at IS NULL
        ORDER BY bm25(food_items_fts), f.is_favorite DESC, COALESCE(f.last_used_at, 0) DESC, f.name ASC
        LIMIT ?;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: ftsMatchExpression)
        sqlite3_bind_int(stmt, 2, Int32(safeLimit))
        return try readDecodedRows(stmt, as: FoodItem.self)
    }

    // MARK: - Photo Assets

    public func savePhotoAsset(_ asset: PhotoAsset, enqueueSync: Bool = true) throws {
        try withImmediateTransaction {
            let payloadJSON = try encodeJSONString(asset)
            try upsertPhotoAssetRow(asset, payloadJSON: payloadJSON)
            if enqueueSync {
                let op: SyncMutationOp = asset.deletedAt != nil ? .delete : .upsert
                try insertOutboxRow(
                    entityType: .photoAsset,
                    entityId: asset.id,
                    op: op,
                    payloadJSON: op == .upsert ? payloadJSON : nil,
                    createdAt: asset.updatedAt
                )
            }
        }
    }

    public func upsertRemotePhotoAsset(_ asset: PhotoAsset) throws {
        try withImmediateTransaction {
            let payloadJSON = try encodeJSONString(asset)
            try upsertPhotoAssetRow(asset, payloadJSON: payloadJSON)
        }
    }

    public func photoAssets(forMealId mealId: UUID) throws -> [PhotoAsset] {
        let sql = """
        SELECT payload_json
        FROM photo_assets
        WHERE meal_id = ? AND deleted_at IS NULL
        ORDER BY updated_at ASC, id ASC;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: mealId.uuidString)
        return try readDecodedRows(stmt, as: PhotoAsset.self)
    }

    public func allPhotoAssets(includeDeleted: Bool = false) throws -> [PhotoAsset] {
        let sql = includeDeleted
            ? "SELECT payload_json FROM photo_assets ORDER BY updated_at ASC, id ASC;"
            : "SELECT payload_json FROM photo_assets WHERE deleted_at IS NULL ORDER BY updated_at ASC, id ASC;"
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        return try readDecodedRows(stmt, as: PhotoAsset.self)
    }

    // MARK: - Sync Outbox & Cursor State

    public func pendingOutboxMutations(limit: Int = 100) throws -> [OutboxMutationRecord] {
        let safeLimit = max(1, limit)
        let sql = """
        SELECT id, entity_type, entity_id, op, payload_json, idempotency_key, created_at
        FROM sync_outbox
        ORDER BY created_at ASC, rowid ASC
        LIMIT ?;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(safeLimit))

        var records: [OutboxMutationRecord] = []
        while true {
            let step = sqlite3_step(stmt)
            if step == SQLITE_ROW {
                guard let idString = readText(stmt, column: 0),
                      let id = UUID(uuidString: idString),
                      let entityTypeRaw = readText(stmt, column: 1),
                      let entityType = SyncEntityType(rawValue: entityTypeRaw),
                      let entityIdString = readText(stmt, column: 2),
                      let entityId = UUID(uuidString: entityIdString),
                      let opRaw = readText(stmt, column: 3),
                      let op = SyncMutationOp(rawValue: opRaw),
                      let idempotencyKey = readText(stmt, column: 5)
                else {
                    throw LocalDiaryStoreError.invalidData("Corrupted row in sync_outbox.")
                }

                let payloadJSON = readText(stmt, column: 4)
                let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 6))
                records.append(
                    OutboxMutationRecord(
                        id: id,
                        entityType: entityType,
                        entityId: entityId,
                        op: op,
                        payloadJSON: payloadJSON,
                        idempotencyKey: idempotencyKey,
                        createdAt: createdAt
                    )
                )
            } else if step == SQLITE_DONE {
                break
            } else {
                throw lastSQLiteError()
            }
        }
        return records
    }

    public func pendingOutboxCount() throws -> Int {
        let stmt = try prepare("SELECT COUNT(*) FROM sync_outbox;")
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw lastSQLiteError()
        }
        return Int(sqlite3_column_int64(stmt, 0))
    }

    public func markOutboxCompleted(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        try withImmediateTransaction {
            let stmt = try prepare("DELETE FROM sync_outbox WHERE id = ?;")
            defer { sqlite3_finalize(stmt) }
            for id in ids {
                sqlite3_reset(stmt)
                sqlite3_clear_bindings(stmt)
                bindText(stmt, index: 1, value: id.uuidString)
                try stepDone(stmt)
            }
        }
    }

    public func lastSyncSeq() throws -> Int64 {
        guard let raw = try syncStateValue(forKey: Self.syncSeqStateKey),
              let parsed = Int64(raw)
        else {
            return 0
        }
        return parsed
    }

    public func setLastSyncSeq(_ seq: Int64) throws {
        try withImmediateTransaction {
            try upsertSyncState(key: Self.syncSeqStateKey, value: String(seq))
        }
    }

    public func lastSyncedAt() throws -> Date? {
        guard let raw = try syncStateValue(forKey: Self.lastSyncedAtStateKey) else {
            return nil
        }
        return NomNomJSON.parseISO8601(raw)
    }

    public func setLastSyncedAt(_ date: Date) throws {
        try withImmediateTransaction {
            try upsertSyncState(key: Self.lastSyncedAtStateKey, value: NomNomJSON.formatISO8601(date))
        }
    }

    /// Atomically applies a batch of remote sync changes (upserts + tombstones) and advances the sync cursor.
    public func applyRemoteChanges(_ response: SyncChangesResponse) throws {
        try withImmediateTransaction {
            for meal in response.meals {
                let payloadJSON = try encodeJSONString(meal)
                try upsertMealRow(meal, payloadJSON: payloadJSON)
                if let fingerprint = meal.dedupeFingerprint, !fingerprint.isEmpty, !meal.isDeleted {
                    try insertImportFingerprintRow(
                        fingerprint: fingerprint,
                        source: meal.captureMethod.rawValue,
                        mealId: meal.id,
                        importedAt: meal.createdAt
                    )
                }
            }

            for foodItem in response.foodItems {
                let payloadJSON = try encodeJSONString(foodItem)
                try upsertFoodItemRow(foodItem, payloadJSON: payloadJSON)
            }

            for photoAsset in response.photoAssets {
                let payloadJSON = try encodeJSONString(photoAsset)
                try upsertPhotoAssetRow(photoAsset, payloadJSON: payloadJSON)
            }

            let currentSeq = (try syncStateValue(forKey: Self.syncSeqStateKey)).flatMap(Int64.init) ?? 0
            let nextSeq = max(currentSeq, response.nextSeq)
            try upsertSyncState(key: Self.syncSeqStateKey, value: String(nextSeq))
            try upsertSyncState(
                key: Self.lastSyncedAtStateKey,
                value: NomNomJSON.formatISO8601(response.serverTime)
            )
        }
    }

    // MARK: - Import Fingerprint Deduplication

    public func hasImportFingerprint(_ fingerprint: String) throws -> Bool {
        let sql = "SELECT 1 FROM import_fingerprints WHERE fingerprint = ? LIMIT 1;"
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: fingerprint)
        let step = sqlite3_step(stmt)
        if step == SQLITE_ROW {
            return true
        }
        if step == SQLITE_DONE {
            return false
        }
        throw lastSQLiteError()
    }

    public func existingImportFingerprints(source: String? = nil) throws -> Set<String> {
        let sql: String
        if source != nil {
            sql = "SELECT fingerprint FROM import_fingerprints WHERE source = ?;"
        } else {
            sql = "SELECT fingerprint FROM import_fingerprints;"
        }
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        if let source {
            bindText(stmt, index: 1, value: source)
        }

        var result = Set<String>()
        while true {
            let step = sqlite3_step(stmt)
            if step == SQLITE_ROW {
                if let fp = readText(stmt, column: 0) {
                    result.insert(fp)
                }
            } else if step == SQLITE_DONE {
                break
            } else {
                throw lastSQLiteError()
            }
        }
        return result
    }

    public func recordImportFingerprint(
        _ fingerprint: String,
        source: String,
        mealId: UUID,
        importedAt: Date = Date()
    ) throws {
        try withImmediateTransaction {
            try insertImportFingerprintRow(
                fingerprint: fingerprint,
                source: source,
                mealId: mealId,
                importedAt: importedAt
            )
        }
    }

    /// Wipes all user diary data (used after permanent account deletion or full local reset).
    public func clearAllData() throws {
        try withImmediateTransaction {
            try executeSQL("DELETE FROM meals;")
            try executeSQL("DELETE FROM food_items;")
            try executeSQL("DELETE FROM food_items_fts;")
            try executeSQL("DELETE FROM photo_assets;")
            try executeSQL("DELETE FROM sync_outbox;")
            try executeSQL("DELETE FROM sync_state;")
            try executeSQL("DELETE FROM import_fingerprints;")
        }
    }

    // MARK: - Low-Level SQLite Helpers

    private func requireHandle() throws -> OpaquePointer {
        guard let db else {
            throw LocalDiaryStoreError.openDatabaseFailed("Database handle is closed.")
        }
        return db
    }

    private func withImmediateTransaction<T>(_ body: () throws -> T) throws -> T {
        try executeSQL("BEGIN IMMEDIATE;")
        do {
            let value = try body()
            try executeSQL("COMMIT;")
            return value
        } catch {
            _ = try? executeSQL("ROLLBACK;")
            throw error
        }
    }

    private func executeSQL(_ sql: String) throws {
        let handle = try requireHandle()
        try Self.executeStaticSQL(handle, sql: sql)
    }

    private static func executeStaticSQL(_ handle: OpaquePointer, sql: String) throws {
        var errorPointer: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &errorPointer)
        if result != SQLITE_OK {
            let message = errorPointer.map { String(cString: $0) }
                ?? String(cString: sqlite3_errmsg(handle))
            sqlite3_free(errorPointer)
            throw LocalDiaryStoreError.sqliteError(code: result, message: message)
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        let handle = try requireHandle()
        var stmt: OpaquePointer?
        let result = sqlite3_prepare_v2(handle, sql, -1, &stmt, nil)
        guard result == SQLITE_OK, let prepared = stmt else {
            throw lastSQLiteError()
        }
        return prepared
    }

    private func stepDone(_ stmt: OpaquePointer) throws {
        let result = sqlite3_step(stmt)
        guard result == SQLITE_DONE else {
            throw lastSQLiteError()
        }
    }

    private func lastSQLiteError() -> LocalDiaryStoreError {
        guard let db else {
            return .openDatabaseFailed("Database handle is closed.")
        }
        let code = sqlite3_errcode(db)
        let message = String(cString: sqlite3_errmsg(db))
        return .sqliteError(code: code, message: message)
    }

    private func bindText(_ stmt: OpaquePointer, index: Int32, value: String?) {
        if let value {
            sqlite3_bind_text(stmt, index, value, -1, Self.sqliteTransient)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func bindOptionalInt64(_ stmt: OpaquePointer, index: Int32, value: Int64?) {
        if let value {
            sqlite3_bind_int64(stmt, index, value)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func bindOptionalDouble(_ stmt: OpaquePointer, index: Int32, value: Double?) {
        if let value {
            sqlite3_bind_double(stmt, index, value)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func readText(_ stmt: OpaquePointer, column: Int32) -> String? {
        guard sqlite3_column_type(stmt, column) != SQLITE_NULL,
              let raw = sqlite3_column_text(stmt, column)
        else {
            return nil
        }
        return String(cString: raw)
    }

    private func encodeJSONString<T: Encodable>(_ value: T) throws -> String {
        do {
            let data = try encoder.encode(value)
            guard let string = String(data: data, encoding: .utf8) else {
                throw LocalDiaryStoreError.serializationError("Encoded JSON was not valid UTF-8.")
            }
            return string
        } catch let storeError as LocalDiaryStoreError {
            throw storeError
        } catch {
            throw LocalDiaryStoreError.serializationError(String(describing: error))
        }
    }

    private func readDecodedRows<T: Decodable>(_ stmt: OpaquePointer, as type: T.Type) throws -> [T] {
        var results: [T] = []
        while true {
            let step = sqlite3_step(stmt)
            if step == SQLITE_ROW {
                guard let json = readText(stmt, column: 0),
                      let data = json.data(using: .utf8)
                else {
                    throw LocalDiaryStoreError.invalidData("Missing payload_json column.")
                }
                do {
                    results.append(try decoder.decode(T.self, from: data))
                } catch {
                    throw LocalDiaryStoreError.serializationError(String(describing: error))
                }
            } else if step == SQLITE_DONE {
                break
            } else {
                throw lastSQLiteError()
            }
        }
        return results
    }

    private func fetchMealRow(id: UUID) throws -> Meal? {
        let sql = "SELECT payload_json FROM meals WHERE id = ? LIMIT 1;"
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: id.uuidString)
        return try readDecodedRows(stmt, as: Meal.self).first
    }

    private func upsertMealRow(_ meal: Meal, payloadJSON: String) throws {
        let sql = """
        INSERT INTO meals (
            id, local_date, eaten_at, meal_type, title, dedupe_fingerprint,
            sync_seq, updated_at, deleted_at, payload_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            local_date = excluded.local_date,
            eaten_at = excluded.eaten_at,
            meal_type = excluded.meal_type,
            title = excluded.title,
            dedupe_fingerprint = excluded.dedupe_fingerprint,
            sync_seq = excluded.sync_seq,
            updated_at = excluded.updated_at,
            deleted_at = excluded.deleted_at,
            payload_json = excluded.payload_json;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        bindText(stmt, index: 1, value: meal.id.uuidString)
        bindText(stmt, index: 2, value: meal.localDate)
        sqlite3_bind_double(stmt, 3, meal.eatenAt.timeIntervalSince1970)
        bindText(stmt, index: 4, value: meal.mealType.rawValue)
        bindText(stmt, index: 5, value: meal.title)
        bindText(stmt, index: 6, value: meal.dedupeFingerprint)
        bindOptionalInt64(stmt, index: 7, value: meal.syncSeq)
        sqlite3_bind_double(stmt, 8, meal.updatedAt.timeIntervalSince1970)
        bindOptionalDouble(stmt, index: 9, value: meal.deletedAt?.timeIntervalSince1970)
        bindText(stmt, index: 10, value: payloadJSON)
        try stepDone(stmt)
    }

    private func upsertFoodItemRow(_ item: FoodItem, payloadJSON: String) throws {
        let sql = """
        INSERT INTO food_items (
            id, name, brand, barcode, source, is_favorite,
            last_used_at, sync_seq, updated_at, deleted_at, payload_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            name = excluded.name,
            brand = excluded.brand,
            barcode = excluded.barcode,
            source = excluded.source,
            is_favorite = excluded.is_favorite,
            last_used_at = excluded.last_used_at,
            sync_seq = excluded.sync_seq,
            updated_at = excluded.updated_at,
            deleted_at = excluded.deleted_at,
            payload_json = excluded.payload_json;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        bindText(stmt, index: 1, value: item.id.uuidString)
        bindText(stmt, index: 2, value: item.name)
        bindText(stmt, index: 3, value: item.brand)
        bindText(stmt, index: 4, value: item.barcode)
        bindText(stmt, index: 5, value: item.source.rawValue)
        sqlite3_bind_int(stmt, 6, item.isFavorite ? 1 : 0)
        bindOptionalDouble(stmt, index: 7, value: item.lastUsedAt?.timeIntervalSince1970)
        bindOptionalInt64(stmt, index: 8, value: item.syncSeq)
        sqlite3_bind_double(stmt, 9, item.updatedAt.timeIntervalSince1970)
        bindOptionalDouble(stmt, index: 10, value: item.deletedAt?.timeIntervalSince1970)
        bindText(stmt, index: 11, value: payloadJSON)
        try stepDone(stmt)

        // Keep FTS5 virtual table strictly synchronized with active food_items rows.
        let deleteFTS = try prepare("DELETE FROM food_items_fts WHERE food_id = ?;")
        defer { sqlite3_finalize(deleteFTS) }
        bindText(deleteFTS, index: 1, value: item.id.uuidString)
        try stepDone(deleteFTS)

        if item.deletedAt == nil {
            let insertFTS = try prepare(
                "INSERT INTO food_items_fts (food_id, name, brand, barcode) VALUES (?, ?, ?, ?);"
            )
            defer { sqlite3_finalize(insertFTS) }
            bindText(insertFTS, index: 1, value: item.id.uuidString)
            bindText(insertFTS, index: 2, value: item.name)
            bindText(insertFTS, index: 3, value: item.brand ?? "")
            bindText(insertFTS, index: 4, value: item.barcode ?? "")
            try stepDone(insertFTS)
        }
    }

    private func upsertPhotoAssetRow(_ asset: PhotoAsset, payloadJSON: String) throws {
        let sql = """
        INSERT INTO photo_assets (
            id, meal_id, local_filename, sha256_hash, r2_object_key,
            upload_state, sync_seq, updated_at, deleted_at, payload_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            meal_id = excluded.meal_id,
            local_filename = excluded.local_filename,
            sha256_hash = excluded.sha256_hash,
            r2_object_key = excluded.r2_object_key,
            upload_state = excluded.upload_state,
            sync_seq = excluded.sync_seq,
            updated_at = excluded.updated_at,
            deleted_at = excluded.deleted_at,
            payload_json = excluded.payload_json;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        bindText(stmt, index: 1, value: asset.id.uuidString)
        bindText(stmt, index: 2, value: asset.mealId.uuidString)
        bindText(stmt, index: 3, value: asset.localFilename)
        bindText(stmt, index: 4, value: asset.sha256Hash)
        bindText(stmt, index: 5, value: asset.r2ObjectKey)
        bindText(stmt, index: 6, value: asset.uploadState.rawValue)
        bindOptionalInt64(stmt, index: 7, value: asset.syncSeq)
        sqlite3_bind_double(stmt, 8, asset.updatedAt.timeIntervalSince1970)
        bindOptionalDouble(stmt, index: 9, value: asset.deletedAt?.timeIntervalSince1970)
        bindText(stmt, index: 10, value: payloadJSON)
        try stepDone(stmt)
    }

    private func insertOutboxRow(
        entityType: SyncEntityType,
        entityId: UUID,
        op: SyncMutationOp,
        payloadJSON: String?,
        createdAt: Date
    ) throws {
        let mutationId = UUID()
        let sql = """
        INSERT INTO sync_outbox (
            id, entity_type, entity_id, op, payload_json, idempotency_key, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        bindText(stmt, index: 1, value: mutationId.uuidString)
        bindText(stmt, index: 2, value: entityType.rawValue)
        bindText(stmt, index: 3, value: entityId.uuidString)
        bindText(stmt, index: 4, value: op.rawValue)
        bindText(stmt, index: 5, value: payloadJSON)
        bindText(stmt, index: 6, value: mutationId.uuidString.lowercased())
        sqlite3_bind_double(stmt, 7, createdAt.timeIntervalSince1970)
        try stepDone(stmt)
    }

    private func insertImportFingerprintRow(
        fingerprint: String,
        source: String,
        mealId: UUID,
        importedAt: Date
    ) throws {
        let sql = """
        INSERT OR IGNORE INTO import_fingerprints (fingerprint, source, meal_id, imported_at)
        VALUES (?, ?, ?, ?);
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: fingerprint)
        bindText(stmt, index: 2, value: source)
        bindText(stmt, index: 3, value: mealId.uuidString)
        sqlite3_bind_double(stmt, 4, importedAt.timeIntervalSince1970)
        try stepDone(stmt)
    }

    private func syncStateValue(forKey key: String) throws -> String? {
        let stmt = try prepare("SELECT value FROM sync_state WHERE key = ? LIMIT 1;")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: key)
        let step = sqlite3_step(stmt)
        if step == SQLITE_ROW {
            return readText(stmt, column: 0)
        }
        if step == SQLITE_DONE {
            return nil
        }
        throw lastSQLiteError()
    }

    private func upsertSyncState(key: String, value: String) throws {
        let sql = """
        INSERT INTO sync_state (key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value;
        """
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, index: 1, value: key)
        bindText(stmt, index: 2, value: value)
        try stepDone(stmt)
    }

    private static func buildFTS5Query(from rawQuery: String) -> String {
        let tokens = rawQuery
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.replacingOccurrences(of: "\"", with: "") }
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return "" }
        return tokens.map { "\"\($0)\"*" }.joined(separator: " ")
    }
}
