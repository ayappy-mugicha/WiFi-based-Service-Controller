# toggle_remote_desktop.ps1
# ----------------------------------------------------
# 設定値は同フォルダ内の .env ファイルから読み込みます
# ----------------------------------------------------

# 1. 変数の初期化
$TargetSSID = ""
$serviceName = "chromoting"
$LogPath = Join-Path $PSScriptRoot "wifi_monitor.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "[$timestamp] $Message"
}

# 2. .env ファイルから設定をロードする
$EnvFilePath = Join-Path $PSScriptRoot ".env"
if (Test-Path $EnvFilePath) {
    Get-Content $EnvFilePath | ForEach-Object {
        $line = $_.Trim()
        # 空行やコメント行 (#) を除外して処理
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line -split '=', 2
            if ($parts.Length -eq 2) {
                $key = $parts[0].Trim()
                $val = $parts[1].Trim()
                # 引用符 (シングル/ダブルクォート) を除去
                $val = $val -replace '^["'']|["'']$'
                if ($key -eq "TARGET_SSID") {
                    $TargetSSID = $val
                }
            }
        }
    }
}

if (-not $TargetSSID) {
    Write-Log "ERROR: .env ファイルが存在しないか、TARGET_SSID が指定されていません。"
    exit
}

# 3. 現在の接続SSIDを取得
$wifiInfo = netsh wlan show interfaces
$ssidLine = $wifiInfo | Select-String -Pattern "^\s+SSID\s+:\s+(.*)"

# 4. サービスの存在チェック
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Log "ERROR: $serviceName サービスが見つかりません。Chrome Remote Desktop が正しくインストールされ、リモートアクセスが有効になっているか確認してください。"
    exit
}

if ($ssidLine) {
    # Wi-Fi接続中
    $currentSSID = $ssidLine.Matches.Groups[1].Value.Trim()
    Write-Log "接続検知 - 現在のSSID: $currentSSID (対象SSID: $TargetSSID)"

    if ($currentSSID -eq $TargetSSID) {
        # 対象SSIDに接続されたので、サービスを開始する
        if ($service.Status -ne "Running") {
            Write-Log "対象のWi-Fiに接続されたため、サービス [$serviceName] を開始します。"
            Start-Service -Name $serviceName -ErrorAction SilentlyContinue
        } else {
            Write-Log "サービス [$serviceName] はすでに実行中です。"
        }
    } else {
        # 対象外のSSIDなので、サービスを停止する
        if ($service.Status -ne "Stopped") {
            Write-Log "対象外のWi-Fi ($currentSSID) に接続されたため、サービス [$serviceName] を停止します。"
            Stop-Service -Name $serviceName -ErrorAction SilentlyContinue
        } else {
            Write-Log "サービス [$serviceName] はすでに停止しています。"
        }
    }
} else {
    # Wi-Fi未接続なので、サービスを停止する
    Write-Log "接続検知 - Wi-Fiに接続されていません。サービス [$serviceName] を停止します。"
    if ($service.Status -ne "Stopped") {
        Stop-Service -Name $serviceName -ErrorAction SilentlyContinue
    }
}
