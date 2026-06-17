import Foundation
import SwiftData

/// Vends the app's `ModelContainer`s over one shared `Schema`.
///
/// `live()` is an on-disk store with CloudKit **off for now** — the models are already
/// CloudKit-legal, so Slice 7 turns sync on by adding
/// `cloudKitDatabase: .private("iCloud.com.jmartinn.Cadence")` to the live config (plus the
/// iCloud/CloudKit + Push capabilities). `inMemory()` is hermetic and never touches iCloud.
enum CadenceStore {
    static let schema = Schema(versionedSchema: CadenceSchemaV2.self)

    /// On-disk persistence for the running app. CloudKit deferred to Slice 7.
    static func live() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, migrationPlan: CadenceMigrationPlan.self,
                                      configurations: config)
        } catch {
            fatalError("Failed to create live ModelContainer: \(error)")
        }
    }

    /// In-memory store for tests. `cloudKitDatabase: .none` keeps unsigned/CI runs quiet.
    /// NOTE: migrationPlan is intentionally omitted here — in-memory stores always start
    /// fresh (there is no on-disk V1 store to migrate), and passing a migration plan to an
    /// in-memory container causes SwiftData to interfere with in-session relationship
    /// tracking, breaking self-referential relationship inverse updates within the same
    /// ModelContext session.
    static func inMemory() -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }
}
