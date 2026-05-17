//
//  BloodPressureRepository.swift
//  K2A2Recorder
//
//  Created by Codex on 2026/05/17.
//

import Foundation
import HealthKit

final class BloodPressureRepository {
    struct BloodPressurePage {
        let records: [BloodPressureRecord]
        let nextPageCursor: Date?
        let hasNextPage: Bool
    }

    enum RepositoryError: LocalizedError {
        case healthDataUnavailable
        case missingHealthKitCorrelationID
        case correlationNotFound(UUID)
        case invalidBloodPressureCorrelation(UUID)

        var errorDescription: String? {
            switch self {
            case .healthDataUnavailable:
                "HealthKit is not available on this device."
            case .missingHealthKitCorrelationID:
                "The blood pressure record does not have a HealthKit correlation ID."
            case .correlationNotFound(let id):
                "Blood pressure correlation was not found: \(id.uuidString)"
            case .invalidBloodPressureCorrelation(let id):
                "Blood pressure correlation does not contain systolic and diastolic samples: \(id.uuidString)"
            }
        }
    }

    private let healthStore: HKHealthStore

    private static let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    private static let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    private static let bloodPressureType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!

    private static let shareTypes: Set<HKSampleType> = [
        systolicType,
        diastolicType,
        bloodPressureType
    ]

    private static let readTypes: Set<HKObjectType> = [
        systolicType,
        diastolicType,
        bloodPressureType
    ]

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func requestAuthorization() async throws {
        try ensureHealthDataAvailable()
        try await healthStore.requestAuthorization(
            toShare: Self.shareTypes,
            read: Self.readTypes
        )
    }

    @discardableResult
    func add(_ record: BloodPressureRecord) async throws -> UUID {
        try ensureHealthDataAvailable()

        let correlation = makeBloodPressureCorrelation(from: record)
        try await healthStore.save(correlation)
        return correlation.uuid
    }

    func delete(_ record: BloodPressureRecord) async throws {
        guard let correlationID = record.healthKitCorrelationID else {
            throw RepositoryError.missingHealthKitCorrelationID
        }

        try await delete(correlationID: correlationID)
    }

    func delete(correlationID: UUID) async throws {
        try ensureHealthDataAvailable()

        guard let correlation = try await findBloodPressureCorrelation(id: correlationID) else {
            throw RepositoryError.correlationNotFound(correlationID)
        }

        try await healthStore.delete(correlation)
    }

    func fetchPage(limit: Int = 50, before cursor: Date? = nil) async throws -> BloodPressurePage {
        try ensureHealthDataAvailable()

        let queryLimit = max(limit, 1) + 1
        let correlations = try await fetchBloodPressureCorrelations(limit: queryLimit, before: cursor)
        let pageCorrelations = Array(correlations.prefix(max(limit, 1)))
        let records = try pageCorrelations.map(makeBloodPressureRecord(from:))
        let hasNextPage = correlations.count > pageCorrelations.count

        return BloodPressurePage(
            records: records,
            nextPageCursor: hasNextPage ? records.last?.measuredAt : nil,
            hasNextPage: hasNextPage
        )
    }

    private func ensureHealthDataAvailable() throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw RepositoryError.healthDataUnavailable
        }
    }

    private func makeBloodPressureCorrelation(from record: BloodPressureRecord) -> HKCorrelation {
        let unit = HKUnit.millimeterOfMercury()
        let systolicMetadata = metadata(for: record, component: "systolic")
        let diastolicMetadata = metadata(for: record, component: "diastolic")

        let systolic = HKQuantitySample(
            type: Self.systolicType,
            quantity: HKQuantity(unit: unit, doubleValue: record.systolic),
            start: record.measuredAt,
            end: record.measuredAt,
            metadata: systolicMetadata
        )

        let diastolic = HKQuantitySample(
            type: Self.diastolicType,
            quantity: HKQuantity(unit: unit, doubleValue: record.diastolic),
            start: record.measuredAt,
            end: record.measuredAt,
            metadata: diastolicMetadata
        )

        return HKCorrelation(
            type: Self.bloodPressureType,
            start: record.measuredAt,
            end: record.measuredAt,
            objects: [systolic, diastolic],
            metadata: metadata(for: record, component: "correlation")
        )
    }

    private func metadata(for record: BloodPressureRecord, component: String) -> [String: Any] {
        let identifier = "BloodPressureRecord.\(record.localID.uuidString).\(component)"

        return [
            HKMetadataKeyExternalUUID: record.localID.uuidString,
            HKMetadataKeySyncIdentifier: identifier,
            HKMetadataKeySyncVersion: record.syncVersion,
            HKMetadataKeyWasUserEntered: true
        ]
    }

    private func fetchBloodPressureCorrelations(limit: Int, before cursor: Date?) async throws -> [HKCorrelation] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = cursor.map {
                HKQuery.predicateForSamples(
                    withStart: nil,
                    end: $0,
                    options: .strictStartDate
                )
            }

            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )

            let query = HKSampleQuery(
                sampleType: Self.bloodPressureType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let correlations = samples?.compactMap { $0 as? HKCorrelation } ?? []
                let filteredCorrelations = cursor.map { cursor in
                    correlations.filter { $0.startDate < cursor }
                } ?? correlations

                continuation.resume(returning: filteredCorrelations)
            }

            healthStore.execute(query)
        }
    }

    private func makeBloodPressureRecord(from correlation: HKCorrelation) throws -> BloodPressureRecord {
        guard
            let systolic = quantitySample(in: correlation, type: Self.systolicType),
            let diastolic = quantitySample(in: correlation, type: Self.diastolicType)
        else {
            throw RepositoryError.invalidBloodPressureCorrelation(correlation.uuid)
        }

        let localID = (correlation.metadata?[HKMetadataKeyExternalUUID] as? String)
            .flatMap(UUID.init(uuidString:)) ?? UUID()
        let syncVersion = correlation.metadata?[HKMetadataKeySyncVersion] as? Int
            ?? (correlation.metadata?[HKMetadataKeySyncVersion] as? NSNumber)?.intValue
            ?? 1
        let unit = HKUnit.millimeterOfMercury()

        return BloodPressureRecord(
            localID: localID,
            healthKitCorrelationID: correlation.uuid,
            measuredAt: correlation.startDate,
            systolic: systolic.quantity.doubleValue(for: unit),
            diastolic: diastolic.quantity.doubleValue(for: unit),
            unit: "mmHg",
            syncVersion: syncVersion
        )
    }

    private func quantitySample(in correlation: HKCorrelation, type: HKQuantityType) -> HKQuantitySample? {
        correlation.objects.first { $0.sampleType == type } as? HKQuantitySample
    }

    private func findBloodPressureCorrelation(id: UUID) async throws -> HKCorrelation? {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForObject(with: id)
            let query = HKSampleQuery(
                sampleType: Self.bloodPressureType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples?.first as? HKCorrelation)
            }

            healthStore.execute(query)
        }
    }
}

