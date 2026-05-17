//
//  BloodPressureItem.swift
//  K2A2Recorder
//
//  Created by Codex on 2026/05/17.
//

import SwiftUI

struct BloodPressureItem: View {
    let record: BloodPressureRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.measuredAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(record.systolic.rounded()))/\(Int(record.diastolic.rounded()))")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()

                Text(record.unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    BloodPressureItem(
        record: BloodPressureRecord(
            measuredAt: .now,
            systolic: 120,
            diastolic: 80
        )
    )
    .padding()
}
