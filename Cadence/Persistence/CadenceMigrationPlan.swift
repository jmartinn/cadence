import Foundation
import SwiftData

/// Ordered migration plan for Cadence's store. V1→V2 adds the optional, defaulted add-on
/// relationship — a purely additive change, so the stage is `.lightweight` (existing rows
/// migrate untouched, with `parent == nil` and `addOns == []`).
enum CadenceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CadenceSchemaV1.self, CadenceSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: CadenceSchemaV1.self,
        toVersion: CadenceSchemaV2.self
    )
}
