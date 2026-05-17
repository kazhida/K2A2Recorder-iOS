# K2A2Recorder-iOS

K2A2Recorder は、iOS のヘルスケアに保存された血圧データを確認し、最高血圧・最低血圧を追加できる SwiftUI アプリです。

## 主な機能

- ヘルスケアに保存されている血圧データの一覧表示
- 最高血圧・最低血圧の手入力
- このアプリで作成した血圧データの編集
- 編集時に値を空にして保存することによる、このアプリで作成した血圧データの削除
- 50 件単位の追加読み込み
- Pull to Refresh
- 日本語音声認識の入力ログ表示

## 必要環境

- Xcode 26 以降
- iOS 26.0 以降
- HealthKit を利用できる実機

HealthKit はシミュレータや一部の端末では利用できないため、動作確認は HealthKit 対応の実機で行ってください。

## セットアップ

1. リポジトリを取得します。

   ```sh
   git clone <repository-url>
   cd K2A2Recorder-iOS
   ```

2. Xcode でプロジェクトを開きます。

   ```sh
   open K2A2Recorder/K2A2Recorder.xcodeproj
   ```

3. `K2A2Recorder` スキームを選択し、HealthKit 対応の実機で実行します。

4. 初回起動時に表示される権限ダイアログで、ヘルスケアの血圧データの読み取り・書き込みを許可します。

## ビルド

コマンドラインからビルドする場合は、次のように実行できます。

```sh
xcodebuild \
  -project K2A2Recorder/K2A2Recorder.xcodeproj \
  -scheme K2A2Recorder \
  -destination 'generic/platform=iOS' \
  build
```

## 権限

このアプリは次の権限を使用します。

- HealthKit: 血圧データの読み取り・書き込み
- マイク: 音声入力
- 音声認識: 日本語音声の文字起こし

HealthKit entitlement は `K2A2Recorder/K2A2Recorder/K2A2Recorder.entitlements` で有効化されています。権限の利用目的文言は `K2A2Recorder/K2A2Recorder/Info.plist` に定義されています。

## プロジェクト構成

```text
K2A2Recorder/
├── K2A2Recorder.xcodeproj
├── K2A2Recorder/
│   ├── K2A2RecorderApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   └── Assets.xcassets/
├── BloodPressureRecord.swift
├── BloodPressureRepository.swift
├── BloodPressureInputPanel.swift
├── BloodPressureItem.swift
└── SpeechInputLogger.swift
```

## 開発メモ

- 血圧データは HealthKit の `HKCorrelationTypeIdentifier.bloodPressure` として扱います。
- HealthKit への保存時は、最高血圧と最低血圧の `HKQuantitySample` を作成し、それらを血圧 correlation として保存します。
- このアプリで作成したデータかどうかは、HealthKit の source bundle identifier を使って判定しています。
- 編集は HealthKit の既存 correlation を直接更新せず、新しい correlation を保存してから古い correlation を削除する形で行います。
