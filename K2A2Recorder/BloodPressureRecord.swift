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

    init(
        localID: UUID = UUID(),
        healthKitCorrelationID: UUID? = nil,
        measuredAt: Date,
        systolic: Double,
        diastolic: Double,
        unit: String = "mmHg",
        syncVersion: Int = 1
    ) {
        self.localID = localID
        self.healthKitCorrelationID = healthKitCorrelationID
        self.measuredAt = measuredAt
        self.systolic = systolic
        self.diastolic = diastolic
        self.unit = unit
        self.syncVersion = syncVersion
    }
}
