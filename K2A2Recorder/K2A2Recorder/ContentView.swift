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

    @State private var records: [BloodPressureRecord] = []
    @State private var nextPageCursor: Date?
    @State private var hasNextPage = false
    @State private var isLoading = false
    @State private var didLoadInitialPage = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
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
            .navigationTitle("血圧")
            .task {
                await loadInitialPageIfNeeded()
            }
            .refreshable {
                await reload()
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
