//
//  BloodPressureRecord.swift
//  K2A2Recorder
//
//  Created by Codex on 2026/05/17.
//

import Foundation
import SwiftData

@Model
final class BloodPressureRecord {
    @Attribute(.unique) var localID: UUID
    var healthKitCorrelationID: UUID?
    var measuredAt: Date
    var systolic: Double
    var diastolic: Double
    var unit: String
    var syncVersion: Int
    var sourceBundleIdentifier: String?

    var isCreatedByThisApp: Bool {
        sourceBundleIdentifier == Bundle.main.bundleIdentifier
    }

    init(
        localID: UUID = UUID(),
        healthKitCorrelationID: UUID? = nil,
        measuredAt: Date,
        systolic: Double,
        diastolic: Double,
        unit: String = "mmHg",
        syncVersion: Int = 1,
        sourceBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) {
        self.localID = localID
        self.healthKitCorrelationID = healthKitCorrelationID
        self.measuredAt = measuredAt
        self.systolic = systolic
        self.diastolic = diastolic
        self.unit = unit
        self.syncVersion = syncVersion
        self.sourceBundleIdentifier = sourceBundleIdentifier
    }

    func copyReplacingBloodPressure(systolic: Double, diastolic: Double) -> BloodPressureRecord {
        BloodPressureRecord(
            localID: localID,
            healthKitCorrelationID: nil,
            measuredAt: measuredAt,
            systolic: systolic,
            diastolic: diastolic,
            unit: unit,
            syncVersion: syncVersion + 1,
            sourceBundleIdentifier: Bundle.main.bundleIdentifier
        )
    }
}

