//
//  ContentView.swift
//  K2A2Recorder
//
//  Created by 樋田一幸 on 2026/05/17.
//

import SwiftUI

struct ContentView: View {
    private let pageLimit = 50
    private let repository = BloodPressureRepository()
    private let speechInputLogger = SpeechInputLogger()

    @State private var records: [BloodPressureRecord] = []
    @State private var nextPageCursor: Date?
    @State private var hasNextPage = false
    @State private var isLoading = false
    @State private var didLoadInitialPage = false
    @State private var errorMessage: String?
    @State private var alertMessage: String?
    @State private var inputMode: BloodPressureInputMode = .normal
    @State private var inputSystolic: Int?
    @State private var inputDiastolic: Int?
    @State private var editingRecord: BloodPressureRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if records.isEmpty && isLoading {
                        ProgressView("読み込み中")
                    } else if records.isEmpty, let errorMessage {
                        ContentUnavailableView(
                            "血圧データを読み込めませんでした",
                            systemImage: "heart.text.square",
                            description: Text(errorMessage)
                        )
                    } else if records.isEmpty {
                        ContentUnavailableView(
                            "血圧データがありません",
                            systemImage: "heart.text.square",
                            description: Text("ヘルスケアに保存されている血圧データが見つかりません。")
                        )
                    } else {
                        List {
                            ForEach(records, id: \.localID) { record in
                                BloodPressureItem(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if record.isCreatedByThisApp {
                                            editBloodPressure(record)
                                        }
                                    }
                                    .onAppear {
                                        loadNextPageIfNeeded(currentRecord: record)
                                    }
                            }

                            if isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }

                if inputMode != .normal {
                    BloodPressureInputPanel(
                        systolic: inputSystolic,
                        diastolic: inputDiastolic,
                        inputMode: inputMode,
                        onSystolicChange: { inputSystolic = $0 },
                        onDiastolicChange: { inputDiastolic = $0 },
                        onMicClick: startSpeechInputLogging,
                        onCancelClick: cancelBloodPressureInput,
                        onSaveClick: saveBloodPressureInput
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.red, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("K2A2")
                        .font(.system(size: 25.5, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addBloodPressure) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("血圧を追加")
                }
            }
            .task {
                await loadInitialPageIfNeeded()
            }
            .refreshable {
                await reload()
            }
            .alert(
                "エラー",
                isPresented: Binding(
                    get: { !(alertMessage?.isEmpty ?? true) },
                    set: { isPresented in
                        if !isPresented {
                            alertMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func addBloodPressure() {
        editingRecord = nil
        inputSystolic = nil
        inputDiastolic = nil
        withAnimation {
            inputMode = .add
        }
    }

    private func editBloodPressure(_ record: BloodPressureRecord) {
        editingRecord = record
        inputSystolic = Int(record.systolic.rounded())
        inputDiastolic = Int(record.diastolic.rounded())
        withAnimation {
            inputMode = .edit
        }
    }

    private func cancelBloodPressureInput() {
        speechInputLogger.stopLogging()
        editingRecord = nil
        withAnimation {
            inputMode = .normal
        }
    }

    private func startSpeechInputLogging() {
        Task {
            do {
                try await speechInputLogger.startLogging { recognizedText in
                    let pressures = recognizedText.split(separator: /\D+/).compactMap { Int($0) }
                    if pressures.count >= 2 {
                        inputSystolic = pressures[0]
                        inputDiastolic = pressures[1]
                    }
                    alertMessage = nil
                }
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    private func saveBloodPressureInput() {
        let currentMode = inputMode
        let originalRecord = editingRecord

        if currentMode == .edit,
           let originalRecord,
           inputSystolic == nil,
           inputDiastolic == nil {
            Task {
                defer { cancelBloodPressureInput() }

                do {
                    try await repository.requestAuthorization()
                    try await repository.delete(originalRecord)
                    records.removeAll { $0.localID == originalRecord.localID }
                } catch {
                    alertMessage = error.localizedDescription
                    errorMessage = error.localizedDescription
                }
            }
            return
        }

        guard let systolic = inputSystolic, let diastolic = inputDiastolic else {
            alertMessage = "最高血圧と最低血圧を両方入力してください。"
            return
        }

        let record: BloodPressureRecord

        if currentMode == .edit, let originalRecord {
            record = originalRecord.copyReplacingBloodPressure(
                systolic: Double(systolic),
                diastolic: Double(diastolic)
            )
        } else {
            record = BloodPressureRecord(
                measuredAt: .now,
                systolic: Double(systolic),
                diastolic: Double(diastolic)
            )
        }

        Task {
            defer { cancelBloodPressureInput() }

            do {
                try await repository.requestAuthorization()

                let healthKitID = try await repository.add(record)
                record.healthKitCorrelationID = healthKitID

                if currentMode == .edit, let originalRecord {
                    do {
                        try await repository.delete(originalRecord)
                    } catch {
                        alertMessage = "古い血圧データの削除に失敗しました。\n\(error.localizedDescription)"
                    }
                }

                if currentMode == .edit,
                   let originalRecord,
                   let index = records.firstIndex(where: { $0.localID == originalRecord.localID }) {
                    records[index] = record
                } else {
                    records.insert(record, at: 0)
                }
            } catch {
                alertMessage = error.localizedDescription
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadInitialPageIfNeeded() async {
        guard !didLoadInitialPage else { return }
        didLoadInitialPage = true
        await reload()
    }

    private func reload() async {
        guard !isLoading else { return }

        records = []
        nextPageCursor = nil
        hasNextPage = false
        errorMessage = nil

        await loadPage(before: nil)
    }

    private func loadNextPageIfNeeded(currentRecord: BloodPressureRecord) {
        guard currentRecord.localID == records.last?.localID else { return }
        guard hasNextPage, !isLoading else { return }

        Task {
            await loadPage(before: nextPageCursor)
        }
    }

    private func loadPage(before cursor: Date?) async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if cursor == nil {
                try await repository.requestAuthorization()
            }

            let page = try await repository.fetchPage(limit: pageLimit, before: cursor)
            records.append(contentsOf: page.records)
            nextPageCursor = page.nextPageCursor
            hasNextPage = page.hasNextPage
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
