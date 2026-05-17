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
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(record.measuredAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(record.systolic.rounded()))/\(Int(record.diastolic.rounded()))")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()

                Text(record.unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.trailing)

            Group {
                if record.isCreatedByThisApp {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                } else {
                    Color.clear
                }
            }
            .frame(width: 24, height: 24)
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
