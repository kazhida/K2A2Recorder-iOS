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

    @State private var text: String

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
        _text = State(initialValue: value.map(String.init) ?? "")
    }

    private var isError: Bool {
        guard let parsedValue = Int(text), !text.isEmpty else { return false }
        return !valueRange.contains(parsedValue)
    }

    var body: some View {
        TextField(label, text: Binding(
            get: { text },
            set: updateText(_:)
        ))
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
        .font(.title2)
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .frame(minWidth: 96)
        .overlay {
            if isError {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.red, lineWidth: 1)
            }
        }
        .onChange(of: value) { _, nextValue in
            let nextText = nextValue.map(String.init) ?? ""
            if Int(text) != nextValue {
                text = nextText
            }
        }
    }

    private func updateText(_ nextText: String) {
        let maxLength = String(valueRange.upperBound).count
        let filteredText = String(nextText.filter(\.isNumber).prefix(maxLength))
        text = filteredText

        guard !filteredText.isEmpty else {
            onValueChange(nil)
            return
        }

        guard let nextValue = Int(filteredText), valueRange.contains(nextValue) else { return }
        onValueChange(nextValue)
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
