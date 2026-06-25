# WiFi-based Chrome Remote Desktop Controller (checkwifi)

特定のWi-Fi（自宅など）に接続しているときだけ Chrome Remote Desktop サービス（`chromoting`）を自動的に開始し、公共Wi-Fiや他のWi-Fiに接続しているとき、またはオフラインのときは自動的に停止するWindows向けのPowerShellスクリプトです。

安全性の低いネットワークに接続している際に、意図しないリモートアクセスを防ぐためのセキュリティ向上を目的としています。

## 特徴
- **自動切り替え**: Wi-Fiの接続イベント（接続・切断・切り替え）を検知し、指定されたSSIDの場合のみChrome Remote Desktopサービスを稼働させます。
- **タスクスケジューラ登録**: Windowsの起動時、およびWi-Fiの接続状態が変化したタイミングでバックグラウンド実行されるようにタスクを登録します。
- **ログ記録**: `wifi_monitor.log` に実行ログを出力し、動作状況を後から確認できます。

## 必要要件
- Windows OS
- Chrome Remote Desktop がインストールされ、リモートアクセスが有効化されていること
- 管理者権限（タスクスケジューラへのタスク登録に必要）

## ファイル構成
- [toggle_remote_desktop.ps1](./toggle_remote_desktop.ps1): Wi-Fiの接続状況を判定し、サービスを制御するスクリプト本体。
- [register_task.ps1](./register_task.ps1): `toggle_remote_desktop.ps1` をタスクスケジューラに自動実行タスクとして登録するスクリプト。
- [.env.example](./.env.example): 許可するSSIDを設定するためのテンプレートファイル。
- `wifi_monitor.log`: 動作ログが出力されるファイル。

## セットアップ手順

### 1. リポジトリのクローン/ダウンロード
本リポジトリをローカルの任意の場所にダウンロードします。

### 2. 設定ファイルの作成
`.env.example` をコピーして、同一ディレクトリに `.env` を作成します。
```powershell
Copy-Item .env.example .env
```
`.env` ファイルを開き、Chrome Remote Desktopの起動を許可するWi-FiのSSID（ネットワーク名）を設定します。
```env
TARGET_SSID=あなたのWiFiのSSID
```

### 3. タスクスケジューラへの登録
PowerShellを**管理者として実行**し、以下のコマンドを実行してタスクを登録します。

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\register_task.ps1
```

これで、以下のトリガーでスクリプトが自動実行されるようになります：
1. PCの起動時
2. Wi-Fiの接続成功時 (イベントID: 8001)
3. Wi-Fiの切断/切り替え時 (イベントID: 8003)

### 4. 動作確認
正しく動作しているかは、同一フォルダに出力される `wifi_monitor.log` を確認してください。
設定したSSIDに接続されているときはサービスが開始し、それ以外のWi-Fiや未接続状態のときはサービスが停止します。

## アンインストール
登録したタスクを削除したい場合は、PowerShell（管理者権限）で以下のコマンドを実行してください。
```powershell
Unregister-ScheduledTask -TaskName "WiFi_ChromeRemoteDesktop_Control" -Confirm:$false
```
