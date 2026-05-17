//
//  SpeechInputLogger.swift
//  K2A2Recorder
//
//  Created by Codex on 2026/05/17.
//

import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechInputLogger {
    enum SpeechInputError: LocalizedError {
        case speechRecognizerUnavailable
        case speechRecognitionDenied
        case microphonePermissionDenied
        case audioInputUnavailable

        var errorDescription: String? {
            switch self {
            case .speechRecognizerUnavailable:
                "音声認識を利用できません。"
            case .speechRecognitionDenied:
                "音声認識の利用が許可されていません。"
            case .microphonePermissionDenied:
                "マイクの利用が許可されていません。"
            case .audioInputUnavailable:
                "音声入力を開始できませんでした。"
            }
        }
    }

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startLogging(onResult: @escaping @MainActor (String) -> Void) async throws {
        stopLogging()

        try await requestSpeechAuthorization()
        try await requestMicrophonePermission()

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechInputError.speechRecognizerUnavailable
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        self.recognitionRequest = recognitionRequest

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.channelCount > 0 else {
            throw SpeechInputError.audioInputUnavailable
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak recognitionRequest] buffer, _ in
            recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result, result.isFinal {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    onResult(text)
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self?.stopLogging()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopLogging() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    private func requestSpeechAuthorization() async throws {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard status == .authorized else {
            throw SpeechInputError.speechRecognitionDenied
        }
    }

    private func requestMicrophonePermission() async throws {
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            throw SpeechInputError.microphonePermissionDenied
        }
    }
}
