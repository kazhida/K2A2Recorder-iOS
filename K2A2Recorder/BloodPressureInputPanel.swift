//
//  BloodPressureInputPanel.swift
//  K2A2Recorder
//
//  Created by Codex on 2026/05/17.
//

import SwiftUI

enum BloodPressureInputMode {
    case normal
    case add
    case edit
}

struct BloodPressureInputPanel: View {
    let systolic: Int?
    let diastolic: Int?
    let inputMode: BloodPressureInputMode
    var systolicRange: ClosedRange<Int> = 70...250
    var diastolicRange: ClosedRange<Int> = 40...150
    var onSystolicChange: (Int?) -> Void = { _ in }
    var onDiastolicChange: (Int?) -> Void = { _ in }
    var onMicClick: () -> Void = {}
    var onCancelClick: () -> Void = {}
    var onSaveClick: () -> Void = {}

    private var saveButtonText: String {
        switch inputMode {
        case .edit:
            "更新"
        case .add, .normal:
            "保存"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            cancelArea(
                colors: [
                    Color.white.opacity(0.4),
                    Color.white.opacity(0.67),
                    Color.white.opacity(0.87),
                    Color.white
                ]
            )

            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    BloodPressureTextField(
                        label: "最高血圧",
                        value: systolic,
                        valueRange: systolicRange,
                        onValueChange: onSystolicChange
                    )

                    Text("/")
                        .foregroundStyle(.secondary)

                    BloodPressureTextField(
                        label: "最低血圧",
                        value: diastolic,
                        valueRange: diastolicRange,
                        onValueChange: onDiastolicChange
                    )

                    Text("mmHg")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Button(action: onMicClick) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 34))
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("音声入力")

                    Spacer()

                    Button("キャンセル", action: onCancelClick)
                        .buttonStyle(.borderless)

                    Button(saveButtonText, action: onSaveClick)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
            .background(Color.white)

            cancelArea(
                colors: [
                    Color.white,
                    Color.white.opacity(0.87),
                    Color.white.opacity(0.67),
                    Color.white.opacity(0.4)
                ]
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func cancelArea(colors: [Color]) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: onCancelClick)
    }
}

private struct BloodPressureTextField: View {
    let label: String
    let value: Int?
    let valueRange: ClosedRange<Int>
    var onValueChange: (Int?) -> Void = { _ in }

    @State private var selectedValue: Int?

    init(
        label: String,
        value: Int?,
        valueRange: ClosedRange<Int>,
        onValueChange: @escaping (Int?) -> Void = { _ in }
    ) {
        self.label = label
        self.value = value
        self.valueRange = valueRange
        self.onValueChange = onValueChange
        _selectedValue = State(initialValue: value)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(label, selection: Binding(
                get: { selectedValue },
                set: { selectedValue = $0 }
            )) {
                Text("--")
                    .tag(Optional<Int>.none)

                ForEach(Array(valueRange), id: \.self) { value in
                    Text("\(value)")
                        .monospacedDigit()
                        .tag(Optional.some(value))
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(width: 96, height: 120)
            .clipped()
        }
        .onChange(of: selectedValue) { _, nextValue in
            onValueChange(nextValue)
        }
        .onChange(of: value) { _, nextValue in
            if selectedValue != nextValue {
                selectedValue = nextValue
            }
        }
    }
}

#Preview {
    BloodPressureInputPanel(
        systolic: 128,
        diastolic: 82,
        inputMode: .add
    )
    .frame(height: 360)
    .background(Color.gray.opacity(0.15))
}
