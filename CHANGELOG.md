# Change log


## Version 2.1.6
- 不正なJSONオブジェクトを送信するとクラッシュしてしまう問題の修正

## Version 2.1.5
- swiftをサポート

## Version 2.1.4
- CBBMultiplexDataBusが正しく解放されない問題の修正

## Version 2.1.3
- WebViewの解放時にクラッシュしてしまう問題の修正

## Version 2.1.2
- `#pragma clang diagnostic ignored "-Warc-retain-cycles"` で出力抑止していた警告を, 抑止しなくても警告が出ない形に修正

## Version 2.1.1
- `CBBWKWebViewDataBus#sendData` を複数スレッドから呼び出すとクラッシュする問題を修正

## Version 2.1.0
- マルチスレッドに対応
- `DataBus#handler` を DataBus実装から参照する方式を廃止 (破壊的変更)
  - DataBus実装はデータ到達時に `DataBus#onReceiveData` を呼ぶものとする
  - この変更は, 独自のDataBus実装開発者に影響する

## Version 2.0.0
初版
