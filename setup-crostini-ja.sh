#!/bin/bash

# =============================================================================
#   Setup Crositini for Japanese Environment (Version 0.1.0)
# =============================================================================
#
# 概要:
#   Crostini（Chromebook に搭載されている Linux 環境）の初期設定を行うためのスクリプトです。
#   日本語環境の設定や VSCodeのインストールを行い、追加の処理として各種開発環境の構築を行います。
#
# 使い方:
#   1. このスクリプトを Linux ファイル側にダウンロードまたはコピーします（ファイル名：`setup-crostini-ja.sh`）
#   2. スクリプトを開き、必要に応じて下にある「設定項目」の欄を編集します。
#   3. 実行権限を付与します: `chmod +x setup-crostini-ja.sh`
#   4. スクリプトを実行します: `sudo bash setup-crostini-ja.sh`
#   5. 処理は自動的に行われ、処理内容は拡張子 `.log` のログファイルに記録されます。
#
# 注意:
#   - スクリプト実行には、sudo が必要です。元のユーザー権限で実行したいコマンドがあるため、$SUDO_USER 変数を利用します。
#   - スクリプトは、Crostini 環境を想定しています。
#   - 日本語入力の設定はスクリプトでは行っていません（※1）
#   - Chromium, InkScape, GIMP は使用する容量が大きいので、インストールする場合は十分なストレージを確保してください（※2）
#     ※1: 必要な場合は、例えば `chrome://flags/#crostini-qt-ime-support` を有効化する方法があります
#     ※2: 構築時のデフォルト設定（10GB）か、それ以上を推奨します
#
# 処理について:
#   スクリプト内で行われる処理は、必須処理とオプション処理に分かれます。
#   1. 必須処理:
#     - apt パッケージリストの更新とアップグレード
#     - 日本語フォントのインストール、フォントキャッシュの更新
#     - locale 設定を日本（ja_JP.UTF-8）に変更
#     - Visual Studio Code（VSCode）のインストール
#     - VSCode 日本語拡張機能（MS-CEINTL.vscode-language-pack-ja）のインストール
#   2. オプション処理:
#     - git の設定（user.name, user.email）
#     - nano のインストール
#     - マニュアル（manpages-ja, manpages-ja-dev）のインストール
#     - Node.js（volta経由）のインストール
#     - Keyring（gnome-keyring）を導入し、VSCode と連携
#     - C/C++開発環境のインストール
#     - Java（OpenJDK）のインストール
#     - Docker のインストール
#     - Python（python3, python3-pip, python3-venv）のインストール
#     - Chromium ブラウザのインストール
#     - InkScape（ベクタードローソフト）のインストール
#     - GIMP（画像編集ソフト）のインストール
#
# リポジトリURL: https://github.com/nonaka101/setup-crostini-ja
# 作成: nonaka101（https://github.com/nonaka101）
# ライセンス: MIT License（https://opensource.org/license/mit/）







# =============================================================================
#   設定項目
# =============================================================================

# 各オプション処理を実行するかどうかを設定します。


# --- Git の設定（user.name, user.email） ---
# ※ 両者が設定されている場合のみ、`git config --global` にて処理します
OPTION_GIT_CONFIG_USER_NAME=""  # 例: "Your Name"
OPTION_GIT_CONFIG_USER_EMAIL="" # 例: "sample@example.com"


# --- nano の設定 ---
# 0 = インストールしない
# 1 = インストールする
# 2 = インストールしてデフォルトエディタに設定
OPTION_NANO_INSTALLATION=0


# --- 各種開発環境のインストール ---
# 0 = インストールしない
# 1 = インストールする
# 2 = インストールする（VSCode拡張機能含む）

# C/C++
OPTION_CPP_DEV_INSTALL=0

# Java（default-jdk： apt 経由での相対的に古い OpenJDK です）
# ※ 最新版を使いたい場合は、ここではなく、別途手動でインストールしてください
OPTION_JAVA_INSTALL=0

# Docker
OPTION_DOCKER_INSTALL=0

# Python（python3, python3-pip, python3-venv)
OPTION_PYTHON_INSTALL=0


# --- その他 開発環境のインストール ---
# 0 = インストールしない
# 1 = インストールする

# マニュアル（manpages-ja, manpages-ja-dev）
OPTION_MANPAGES_INSTALL=0

# Node.js（volta を使って、node, npm, yarn をインストールします)
OPTION_NODEJS_INSTALL=0

# Keyring（gnome-keyring、これを使って VSCode と連携させます）
OPTION_KEYRING_INSTALL=0


# --- アプリケーションのインストール ---
# 0 = インストールしない
# 1 = インストールする
#
# ※ 使用する容量が大きいので、インストールする場合は十分なストレージを確保してください

# Chromium ブラウザ：0 = インストールしない, 1 = インストールする
OPTION_CHROMIUM_INSTALL=0

# InkScape（ベクタードローソフト)：0 = インストールしない, 1 = インストールする
OPTION_INKSCAPE_INSTALL=0

# GIMP（画像編集ソフト)：0 = インストールしない, 1 = インストールする
OPTION_GIMP_INSTALL=0





# =============================================================================
#   処理部
# =============================================================================


# --- グローバル変数 ---
LOG_FILE="$(basename "$0" .sh).log"	# 自身のファイル名.log
SCRIPT_VERSION="0.1.0"



# --- ログ関数 ---
# `タイムスタンプ [ログレベル] ログメッセージ` の形式で、ターミナルとログファイルに出力
# $1: ログメッセージ
# $2: ログレベル（INFO, WARN, ERROR, CMD_SUCCESS, CMD_FAIL など、デフォルトは INFO）
function log_message() {
  local level="INFO"
  if [[ -n "$2" ]]; then
    level="$2"
  fi
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $1" | tee -a "$LOG_FILE"
}





# --- Crostini 環境の確認 ---
# Crostini の hostname が penguin であることを利用して環境を判定、処理を継続するかを確認する
function check_crostini() {
	if [[ "$(hostname)" != "penguin" ]]; then
		log_message "実行環境が Crostini でない可能性があります" "WARN"
		log_message "このスクリプトは Crostini（Chromebook に搭載されている Linux 環境）を想定しています。" "INFO"
		log_message "Crostini 以外で実行する場合、想定外の挙動をする可能性があります。" "INFO"
		echo ""
		echo "-----------------------------------------------------"
		read -rp "処理を続行しますか？（y/N): " start_confirm

		if [[ ! "$start_confirm" =~ ^[Yy]$ ]]; then
			log_message "ユーザー選択により、処理がキャンセルされました。" "INFO"
			echo "処理をキャンセルしました。"
			exit 0
		fi
		log_message "ユーザー選択により、処理を続行します" "INFO"
	else
		log_message "Crostini 環境が確認されました。" "INFO"
	fi
}





# --- sudo権限の事前確認とキャッシュ保持 ---
function check_sudo_and_keep_alive() {
  log_message "このスクリプトは多くの処理で管理者権限（sudo）を必要とします。"
  if [[ "$(id -u)" -ne 0 ]]; then
    log_message "スクリプトがroot権限で実行されていません。sudoで実行してください（例: sudo bash $0)" "ERROR"
    exit 1
  fi
  if [[ -z "$SUDO_USER" ]] || [[ "$SUDO_USER" == "root" ]]; then
    # SUDO_USER がおかしいため、ユーザーに処理の確認をするか判断してもらう
    log_message "SUDO_USERが正しく設定されていません。'sudo bash $0' のように実行してください。" "WARN"
    log_message "いくつかのユーザー固有設定が正しく行えない可能性があります。" "WARN"
    read -rp "処理を続行しますか？（y/N): " sudo_user_confirmation
    if [[ ! "$sudo_user_confirmation" =~ ^[Yy]$ ]]; then
      log_message "ユーザーによって処理がキャンセルされました。" "INFO"
      exit 0
    fi
  fi
  log_message "sudo権限の有効性を確認し、キャッシュを試みます..."
  if sudo -v; then
    log_message "sudo権限を確認しました。"
  else
    log_message "sudo権限の確認に失敗しました。パスワードが正しくないか、sudoが利用できません。" "ERROR"
    log_message "スクリプトを終了します。" "ERROR"
    exit 1
  fi
}





# ---ログファイルのヘッダー（実行日時やユーザーなど）を出力 ---
function generate_log_header() {
	# `>` により、ログファイルの初期化
	echo "Crostini（Chromebook Linux 環境）初期設定スクリプト（バージョン $SCRIPT_VERSION)" > "$LOG_FILE"
	echo "実行開始日時: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
	echo "実行ユーザー（SUDO_USER): $SUDO_USER（このユーザーのホームディレクトリ等に設定が適用されます)" >> "$LOG_FILE"
	echo "-----------------------------------------------------" >> "$LOG_FILE"
	echo "[ログレベル]について" >> "$LOG_FILE"
	echo " - [INFO]        : 処理内容などを知らせます" >> "$LOG_FILE"
	echo " - [WARN]        : 注意を促すメッセージです" >> "$LOG_FILE"
	echo " - [ERROR]       : 想定外となるエラー状況を知らせます" >> "$LOG_FILE"
	echo " - [CMD_SUCCESS] : 処理に成功したことを示します" >> "$LOG_FILE"
	echo " - [CMD_FAIL]    : 処理に失敗したことを示します" >> "$LOG_FILE"
	echo "-----------------------------------------------------" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
}





# --- スクリプト起動時に表示される初期確認画面 ---
function initialize_confirmation() {
	clear # 一旦それまでの画面を消し、下記の画面を表示
	echo "Crostini（Chromebook Linux 環境）初期設定スクリプト へようこそ！"
	echo ""
	echo "バージョン：$SCRIPT_VERSION"
	echo "ログの出力先：$LOG_FILE"
	echo "スクリプト実行ユーザー（sudo実行前のユーザー): $SUDO_USER"
	echo ""
	echo "--- 設定内容の確認 ---"
  echo ""
	echo "[必須処理]"
	echo "  - aptパッケージリストの更新とアップグレード"
	echo "  - 日本語フォントと絵文字フォントのインストール、フォントキャッシュ更新"
	echo "  - locale設定を日本（ja_JP.UTF-8）に変更"
	echo "  - Visual Studio Code（VSCode）のインストール"
	echo "  - VSCode 日本語拡張機能のインストール"
	echo ""
	echo -e " ※ 日本語入力環境は、\e[93mchrome://flags/#crostini-qt-ime-support\e[0m を有効化することで利用可能になります。"
	echo ""
	echo "[オプション処理]"
	case $OPTION_NANO_INSTALLATION in
    1) echo -e "  - nano: \e[1mインストールする\e[0m";;
    2) echo -e "  - nano: \e[1mインストールしてデフォルトエディタに設定する\e[0m";;
    *) echo -e "  - nano: \e[1mインストールしない\e[0m";;
	esac
	if [[ -n "$OPTION_GIT_CONFIG_USER_NAME" ]] && [[ -n "$OPTION_GIT_CONFIG_USER_EMAIL" ]]; then
			echo -e "  - git: \e[1m設定する\e[0m（ユーザー名: $OPTION_GIT_CONFIG_USER_NAME, メール: $OPTION_GIT_CONFIG_USER_EMAIL, ユーザー: $SUDO_USER）"
	else
			echo -e "  - git: \e[1m設定しない\e[0m（ユーザー名またはメールアドレスが未設定)"
	fi
	[[ "$OPTION_NODEJS_INSTALL" -eq 1 ]] && echo -e "  - Node.js（volta経由): \e[1mインストールする\e[0m（ユーザー: $SUDO_USER)" || echo -e "  - Node.js（volta経由): \e[1mインストールしない\e[0m"
	[[ "$OPTION_KEYRING_INSTALL" -eq 1 ]] && echo -e "  - Keyring（gnome-keyring): \e[1m導入する\e[0m（VSCode連携用、ユーザー: $SUDO_USER)" || echo -e "  - Keyring（gnome-keyring): \e[1m導入しない\e[0m"

	case $OPTION_CPP_DEV_INSTALL in
    1) echo -e "  - C/C++開発環境: \e[1mインストールする\e[0m";;
    2) echo -e "  - C/C++開発環境: \e[1mインストールする\e[0m（VSCode 拡張機能付）";;
    *) echo -e "  - C/C++開発環境: \e[1mインストールしない\e[0m";;
	esac
	case $OPTION_JAVA_INSTALL in
    1) echo -e "  - Java（OpenJDK): \e[1mインストールする\e[0m";;
    2) echo -e "  - Java（OpenJDK): \e[1mインストールする\e[0m（VSCode 拡張機能付）";;
    *) echo -e "  - Java（OpenJDK): \e[1mインストールしない\e[0m";;
	esac
	case $OPTION_DOCKER_INSTALL in
    1) echo -e "  - Docker: \e[1mインストールする\e[0m（ユーザー $SUDO_USER をdockerグループに追加)";;
    2) echo -e "  - Docker: \e[1mインストールする\e[0m（ユーザー $SUDO_USER をdockerグループに追加、VSCode 拡張機能付)";;
    *) echo -e "  - Docker: \e[1mインストールしない\e[0m";;
	esac
	case $OPTION_PYTHON_INSTALL in
    1) echo -e "  - Python（python3, pip3, venv): \e[1mインストールする\e[0m";;
    2) echo -e "  - Python（python3, pip3, venv): \e[1mインストールする\e[0m（VSCode 拡張機能付）";;
    *) echo -e "  - Python（python3, pip3, venv): \e[1mインストールしない\e[0m";;
	esac

	[[ "$OPTION_CHROMIUM_INSTALL" -eq 1 ]] && echo -e "  - Chromiumブラウザ: \e[1mインストールする\e[0m" || echo -e "  - Chromiumブラウザ: \e[1mインストールしない\e[0m"
	[[ "$OPTION_INKSCAPE_INSTALL" -eq 1 ]] && echo -e "  - InkScape: \e[1mインストールする\e[0m" || echo -e "  - InkScape: \e[1mインストールしない\e[0m"
	[[ "$OPTION_GIMP_INSTALL" -eq 1 ]] && echo -e "  - GIMP: \e[1mインストールする\e[0m" || echo -e "  - GIMP: \e[1mインストールしない\e[0m"
	echo ""
	echo "-----------------------------------------------------"
	read -rp "上記の内容で設定を開始してもよろしいですか？（y/N): " confirmation

	if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
		log_message "ユーザーによって処理がキャンセルされました。" "INFO"
		exit 0
	fi

	log_message "ユーザーが処理の実行を承認しました。" "INFO"
	echo "設定を開始します..."
}





# --- apt パッケージリストの更新とアップグレード ---
function apt_update_and_upgrade() {
	log_message "apt パッケージリストの更新とアップグレードを開始します。" "INFO"
	if sudo apt update >> "$LOG_FILE" 2>&1; then
    log_message "apt パッケージリストの更新成功" "CMD_SUCCESS"
    if sudo apt upgrade -y >> "$LOG_FILE" 2>&1; then
      log_message "apt アップグレード成功" "CMD_SUCCESS"
    else
      log_message "apt アップグレード失敗" "CMD_FAIL"
    fi
	else
    log_message "apt パッケージリストの更新失敗" "CMD_FAIL"
	fi
	echo "" | tee -a "$LOG_FILE"
}





# --- 日本語フォントと絵文字フォントのインストール ---
function setup_fonts() {
	log_message "フォントのインストールとキャッシュ更新を開始します。" "INFO"
	local FONTS_TO_INSTALL="fonts-noto-cjk fonts-ipafont fonts-ipaexfont fonts-noto-color-emoji"
	if sudo apt install -y $FONTS_TO_INSTALL >> "$LOG_FILE" 2>&1; then
		log_message "フォント（$FONTS_TO_INSTALL）のインストール成功" "CMD_SUCCESS"
		log_message "フォントキャッシュを更新します..." "INFO"
		if sudo fc-cache -fv >> "$LOG_FILE" 2>&1; then
			log_message "フォントキャッシュの更新成功" "CMD_SUCCESS"
		else
			log_message "フォントキャッシュの更新失敗" "CMD_FAIL"
		fi
	else
		log_message "フォント（$FONTS_TO_INSTALL）のインストール失敗" "CMD_FAIL"
	fi
	echo "" | tee -a "$LOG_FILE"
}





# --- locale設定を日本（ja_JP.UTF-8）に変更 ---
function setup_locale() {
	log_message "locale に関する設定を開始します。" "INFO"

	# locales, locales-all パッケージがなければインストール
	if ! dpkg -s locales > /dev/null 2>&1; then
		log_message "locales をインストールします。" "INFO"
		sudo apt install -y locales >> "$LOG_FILE" 2>&1
	fi
	if ! dpkg -s locales-all > /dev/null 2>&1; then
		log_message "locales-all をインストールします。" "INFO"
		sudo apt install -y locales-all >> "$LOG_FILE" 2>&1
	fi

	local TARGET_LOCALE="ja_JP.UTF-8"
	local TARGET_TIMEZONE="Asia/Tokyo"

	# /etc/locale.gen の該当行のコメントを解除（存在すれば)
	log_message "/etc/locale.gen を編集します。" "INFO"
	if sudo sed -i "/^# ${TARGET_LOCALE}/s/^# //" /etc/locale.gen; then
		log_message "/etc/locale.gen の ${TARGET_LOCALE} を有効化（コメント解除）しました。" "INFO"
	else
		log_message "/etc/locale.gen の編集に失敗したか、${TARGET_LOCALE} が見つかりませんでした。" "WARN"
		log_message "手動で /etc/locale.gen に '${TARGET_LOCALE} UTF-8' を追記する必要があるかもしれません。" "WARN"
	fi

  # .bashrc に環境変数 LANG を追記
	log_message "locale設定を日本（ja_JP.UTF-8）に変更を開始します。" "INFO"
	local BASHRC_PATH="/home/$SUDO_USER/.bashrc"
	echo "export LANG=$TARGET_LOCALE" >> "$BASHRC_PATH"
	log_message "$BASHRC_PATH に環境変数 LANG を追記" "INFO"
	
  # localectl set-locale による locale 変更
	if sudo localectl set-locale LANG="$TARGET_LOCALE" >> "$LOG_FILE" 2>&1; then
		log_message "locale（$TARGET_LOCALE）の設定成功" "CMD_SUCCESS"
		log_message "システム全体にlocale設定を反映させるには、Linux環境の再起動が必要です。" "WARN"
	else
		log_message "locale（$TARGET_LOCALE）の設定失敗" "CMD_FAIL"
	fi

  # タイムゾーンの変更
	log_message "タイムゾーンを Asia/Tokyo に設定します。" "INFO"
	if sudo timedatectl set-timezone "$TARGET_TIMEZONE" >> "$LOG_FILE" 2>&1; then
		log_message "タイムゾーンを $TARGET_LOCALE に設定成功。" "CMD_SUCCESS"
	else
		log_message "タイムゾーンを $TARGET_LOCALE に設定失敗" "CMD_FAIL"
	fi

	echo "" | tee -a "$LOG_FILE"
}





# --- Visual Studio Code（VSCode）のインストール ---
function setup_vscode() {
	log_message "VSCodeのインストールを開始します。" "INFO"
  # HTTPS経由でリポジトリにアクセスするためのソフト等をインストール
	if sudo apt install -y apt-transport-https curl gpg >> "$LOG_FILE" 2>&1; then
		log_message "VSCodeインストールに必要なパッケージ（apt-transport-https, curl, gpg）を確認/インストールしました。" "CMD_SUCCESS"
    # マイクロソフト公開鍵の取得
		curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg >> "$LOG_FILE" 2>&1
		if [[ $? -eq 0 ]]; then
			log_message "Microsoft GPGキーをインストールしました。" "CMD_SUCCESS"
      # apt に VSCode リポジトリを追加
			echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
			if [[ $? -eq 0 ]]; then
				log_message "VSCodeリポジトリをaptに追加しました。" "CMD_SUCCESS"
				if sudo apt update >> "$LOG_FILE" 2>&1; then
					log_message "apt update（VSCodeリポジトリ追加後）成功" "CMD_SUCCESS"
					if sudo apt install -y code >> "$LOG_FILE" 2>&1; then
						log_message "VSCodeのインストール成功" "CMD_SUCCESS"
					else
						log_message "VSCodeのインストール失敗" "CMD_FAIL"
					fi
				else
					log_message "apt update（VSCodeリポジトリ追加後）失敗" "CMD_FAIL"
				fi
			else
				log_message "VSCodeリポジトリのaptへの追加失敗" "CMD_FAIL"
			fi
		else
			log_message "Microsoft GPGキーのインストール失敗" "CMD_FAIL"
		fi
	else
		log_message "VSCodeインストールに必要なパッケージのインストール失敗" "CMD_FAIL"
	fi
	echo "" | tee -a "$LOG_FILE"
}



# --- VSCode 拡張機能インストール関数 ---
# $1: 拡張機能ID
# $2: 拡張機能名（ログ出力用）
function install_vscode_extension() {
	if [[ -n "$SUDO_USER" ]] && [[ "$SUDO_USER" != "root" ]]; then
		log_message "VSCode 拡張機能「$2」のインストールを開始します（ユーザー: $SUDO_USER)。" "INFO"
		if sudo -u "$SUDO_USER" env HOME="/home/$SUDO_USER" XDG_CONFIG_HOME="/home/$SUDO_USER/.config" code --install-extension "$1" --force >> "$LOG_FILE" 2>&1; then
			log_message "VSCode 拡張機能「$2」のインストール成功" "CMD_SUCCESS"
		else
			log_message "VSCode 拡張機能「$2」のインストール失敗。VSCode内で手動インストールをお試しください。" "CMD_FAIL"
			log_message "  拡張機能ID: $1" "CMD_FAIL"
		fi
	else
		log_message "SUDO_USERが不明なため、VSCode 拡張機能「$2」のインストールをスキップしました。" "WARN"
	fi
}



# --- VSCode 日本語拡張機能のインストール ---
function install_vscode_japanese_language() {
	install_vscode_extension "MS-CEINTL.vscode-language-pack-ja" "Japanese Language Pack for VS Code"
}





# --- nano のインストール ---
function setup_nano() {
	if [[ "$OPTION_NANO_INSTALLATION" -ne 0 ]]; then
		log_message "nano の処理を開始します。" "INFO"
		if sudo apt install -y nano >> "$LOG_FILE" 2>&1; then
			log_message "nano のインストール成功" "CMD_SUCCESS"

      # オプション設定により、デフォルトエディタにする
			if [[ "$OPTION_NANO_INSTALLATION" -eq 2 ]]; then
				NANO_PATH=$(which nano)
				if [[ -n "$NANO_PATH" ]]; then
					if sudo update-alternatives --set editor '/bin/nano' || sudo update-alternatives --set editor "$NANO_PATH" >> "$LOG_FILE" 2>&1; then
						log_message "nano をデフォルトエディタに設定成功（update-alternatives)" "CMD_SUCCESS"
					else
						log_message "nano をデフォルトエディタに設定失敗（update-alternatives)" "CMD_FAIL"
					fi
				else
					log_message "nanoのパスが見つからず、デフォルトエディタに設定できませんでした。" "CMD_FAIL"
				fi
			fi

		else
			log_message "nano のインストール失敗" "CMD_FAIL"
		fi
		echo "" | tee -a "$LOG_FILE"
	else
		log_message "nano のインストールはスキップされました。" "INFO"
	fi
}





# --- git の設定 ---
function setup_git_config() {
	if [[ -n "$OPTION_GIT_CONFIG_USER_NAME" ]] && [[ -n "$OPTION_GIT_CONFIG_USER_EMAIL" ]]; then
		log_message "git のグローバル設定（user.name, user.email）を開始します。" "INFO"
		if ! command -v git &> /dev/null; then
			log_message "git コマンドが見つかりません。gitのインストールを試みます。" "WARN"
			sudo apt install -y git >> "$LOG_FILE" 2>&1
			if ! command -v git &> /dev/null; then
				log_message "git のインストールに失敗しました。設定をスキップします。" "CMD_FAIL"
				skip_git_config=true # gitのインストールに失敗した場合は、後続にある処理はスキップ
			fi
		fi
		if [[ "$skip_git_config" != true ]]; then
			if [[ -n "$SUDO_USER" ]] && [[ "$SUDO_USER" != "root" ]]; then
				if sudo -u "$SUDO_USER" git config --global user.name "$OPTION_GIT_CONFIG_USER_NAME" && \
					sudo -u "$SUDO_USER" git config --global user.email "$OPTION_GIT_CONFIG_USER_EMAIL"; then
					log_message "git config --global user.name '$OPTION_GIT_CONFIG_USER_NAME' 設定成功（ユーザー: $SUDO_USER)" "CMD_SUCCESS"
					log_message "git config --global user.email '$OPTION_GIT_CONFIG_USER_EMAIL' 設定成功（ユーザー: $SUDO_USER)" "CMD_SUCCESS"
				else
					log_message "git config の設定に失敗しました（ユーザー: $SUDO_USER)。" "CMD_FAIL"
				fi
			else
				log_message "SUDO_USERが不明なため、git config の設定をスキップしました。" "WARN"
			fi
		fi
		echo "" | tee -a "$LOG_FILE"
	else
		log_message "git のグローバル設定はスキップされました（ユーザー名またはメールアドレスが未設定)。" "INFO"
	fi
}





# --- マニュアル（manpages-ja, manpages-ja-dev）のインストール ---
function setup_manpages() {
	if [[ "$OPTION_MANPAGES_INSTALL" -eq 1 ]]; then
		log_message "マニュアル（manpages-ja, manpages-ja-dev）のインストールを開始します。" "INFO"
		if sudo apt install manpages-ja manpages-ja-dev >> "$LOG_FILE" 2>&1; then
			log_message "マニュアル（manpages-ja, manpages-ja-dev）のインストール/確認成功" "CMD_SUCCESS"
		else
			log_message "マニュアル（manpages-ja, manpages-ja-dev）のインストール失敗" "CMD_FAIL"
		fi
		echo "" | tee -a "$LOG_FILE"
	else
		log_message "マニュアル（manpages-ja, manpages-ja-dev）のインストールはスキップされました。" "INFO"
	fi
}





# --- Node.js（volta経由）のインストール ---
function setup_nodejs() {
	if [[ "$OPTION_NODEJS_INSTALL" -eq 1 ]]; then
		log_message "Node.js（volta経由）のインストールを開始します。" "INFO"
		if ! command -v curl &> /dev/null; then
			log_message "curl コマンドが見つかりません。Node.js（volta）のインストールをスキップします。" "WARN"
		elif [[ -z "$SUDO_USER" ]] || [[ "$SUDO_USER" == "root" ]]; then
			log_message "SUDO_USERが不明なため、Voltaのインストールをスキップしました。" "WARN"
		else
			# Voltaのインストール（ユーザーコンテキストで実行)
			if sudo -u "$SUDO_USER" bash -c "curl -fsSL https://get.volta.sh | bash" >> "$LOG_FILE" 2>&1; then
				log_message "Volta のインストールスクリプト実行成功（ユーザー: $SUDO_USER)。" "CMD_SUCCESS"

				# VoltaのPATHを一時的に設定し、node, npm, yarn をインストール
				local VOLTA_PROFILE_SNIPPET='export VOLTA_HOME="$HOME/.volta"; export PATH="$VOLTA_HOME/bin:$PATH"'
				local INSTALL_SUCCESS=true
				local NODE_INSTALL_LOG_MSG=""

				if sudo -u "$SUDO_USER" bash -c ". /home/$SUDO_USER/.bashrc; ${VOLTA_PROFILE_SNIPPET}; volta install node" >> "$LOG_FILE" 2>&1; then
					NODE_INSTALL_LOG_MSG+="node "
				else
					NODE_INSTALL_LOG_MSG+="node失敗 ";
					INSTALL_SUCCESS=false;
				fi

				if sudo -u "$SUDO_USER" bash -c ". /home/$SUDO_USER/.bashrc; ${VOLTA_PROFILE_SNIPPET}; volta install npm" >> "$LOG_FILE" 2>&1; then
					NODE_INSTALL_LOG_MSG+="npm "
				else
					NODE_INSTALL_LOG_MSG+="npm失敗 ";
					INSTALL_SUCCESS=false;
				fi

				if sudo -u "$SUDO_USER" bash -c ". /home/$SUDO_USER/.bashrc; ${VOLTA_PROFILE_SNIPPET}; volta install yarn" >> "$LOG_FILE" 2>&1; then
					NODE_INSTALL_LOG_MSG+="yarn "
				else
					NODE_INSTALL_LOG_MSG+="yarn失敗";
					INSTALL_SUCCESS=false;
				fi

				if $INSTALL_SUCCESS; then
					log_message "${NODE_INSTALL_LOG_MSG}のインストール成功（ユーザー: $SUDO_USER)" "CMD_SUCCESS"
				else
					log_message "${NODE_INSTALL_LOG_MSG}のインストールに一部失敗（ユーザー: $SUDO_USER)" "CMD_FAIL"
				fi
				log_message "Volta と Node.js の設定を有効にするには、新しいターミナルを開くか、シェルを再起動してください（例: source /home/$SUDO_USER/.bashrc)。" "WARN"
			else
				log_message "Volta のインストールスクリプト実行失敗（ユーザー: $SUDO_USER)。" "CMD_FAIL"
			fi
		fi
		echo "" | tee -a "$LOG_FILE"
	else
		log_message "Node.js（volta経由）のインストールはスキップされました。" "INFO"
	fi
}





# --- Keyring のインストール + VSCode 連携 ---
function setup_keyring() {
	if [[ "$OPTION_KEYRING_INSTALL" -eq 1 ]]; then
		log_message "Keyring（gnome-keyring）の導入を開始します。" "INFO"
		if sudo apt install -y gnome-keyring libsecret-tools jq >> "$LOG_FILE" 2>&1; then
			log_message "gnome-keyring, libsecret-tools, jq のインストール成功" "CMD_SUCCESS"
			if [[ -n "$SUDO_USER" ]] && [[ "$SUDO_USER" != "root" ]]; then

				# 必要なディレクトリやファイル（argv.json）があるかを確認し、なければ作成
				local VSCODE_USER_CONFIG_DIR="/home/$SUDO_USER/.vscode"
				local VSCODE_ARGV_JSON_PATH="$VSCODE_USER_CONFIG_DIR/argv.json"
				sudo -u "$SUDO_USER" mkdir -p "$VSCODE_USER_CONFIG_DIR"
				sudo -u "$SUDO_USER" touch "$VSCODE_ARGV_JSON_PATH"

				# 空だったり適正でない場合は、JSONを初期化
				if ! sudo -u "$SUDO_USER" jq -e . "$VSCODE_ARGV_JSON_PATH" >/dev/null 2>&1; then
					echo '{}' | sudo -u "$SUDO_USER" tee "$VSCODE_ARGV_JSON_PATH" >/dev/null
				fi

				# jq を使って password-store を設定

				local KEY_NAME="password-store"
				local VALUE_NAME="gnome-libsecret"

				# 一時ファイル（正常・異常問わず終了時は削除）
				TMP_FILE_ARGV=$(mktemp)
				trap '[[ -f "$TMP_FILE_ARGV" ]] && rm -f "$TMP_FILE_ARGV"' EXIT
				trap 'trap - EXIT; [[ -f "$TMP_FILE_ARGV" ]] && rm -f "$TMP_FILE_ARGV"; exit -1' INT PIPE TERM

				if jq -n \
					--rawfile file_content "$VSCODE_ARGV_JSON_PATH" \
					--arg key_name "$KEY_NAME" \
					--arg new_val "$VALUE_NAME" \
					'
					(
						try ($file_content | fromjson) catch {}
						| if type == "object" then . else {} end
					)
					| .[$key_name] = $new_val
					' > "$TMP_FILE_ARGV"; then

					# jqコマンドが成功した場合、一時ファイルの内容で元のファイルを上書き
					if install -m 644 "$TMP_FILE_ARGV" "$VSCODE_ARGV_JSON_PATH"; then
						log_message "VSCode（$VSCODE_ARGV_JSON_PATH）に '$KEY_NAME: $VALUE_NAME' を設定しました。" "CMD_SUCCESS"
						log_message "gnome-keyring を利用するには、Linux環境の再起動や、初回利用時にパスワード設定が必要な場合があります。" "WARN"
					else
						# install コマンドが失敗した場合
						log_message "install コマンドの実行に失敗しました。" "CMD_FAIL"
						log_message "VSCode（$VSCODE_ARGV_JSON_PATH）に '$KEY_NAME: $VALUE_NAME' を設定できませんでした。" "CMD_FAIL"
					fi
				fi
			else
				log_message "SUDO_USERが不明なため、VSCodeのKeyring連携設定をスキップしました。" "WARN"
			fi
		else
			log_message "gnome-keyring, libsecret-tools, jq のインストール失敗。VSCode連携設定は行われません。" "CMD_FAIL"
		fi
		echo "" | tee -a "$LOG_FILE"
	else
		log_message "Keyring（gnome-keyring）の導入はスキップされました。" "INFO"
	fi
}





# --- C/C++開発環境のインストール ---
function setup_cpp() {
	if [[ "$OPTION_CPP_DEV_INSTALL" -ne 0 ]]; then
		log_message "C/C++開発環境のインストールを開始します。" "INFO"
		if sudo apt install -y build-essential gdb >> "$LOG_FILE" 2>&1; then
			log_message "C/C++開発環境（build-essential, gdb）のインストール成功" "CMD_SUCCESS"

			# VSCode 拡張機能のインストール
			if [[ "$OPTION_CPP_DEV_INSTALL" -eq 2 ]]; then
				install_vscode_extension "ms-vscode.cpptools-extension-pack" "C/C++ Extension Pack"
			fi
		else
			log_message "C/C++開発環境のインストール失敗" "CMD_FAIL"
		fi
		echo "" | tee -a "$LOG_FILE"
	else
			log_message "C/C++開発環境のインストールはスキップされました。" "INFO"
	fi
}





# --- Java（OpenJDK）のインストール ---
function setup_java() {
	if [[ "$OPTION_JAVA_INSTALL" -ne 0 ]]; then
		log_message "Java（OpenJDK）のインストールを開始します。" "INFO"
		if sudo apt install -y default-jdk jq >> "$LOG_FILE" 2>&1; then
			log_message "Java（default-jdk）のインストール成功" "CMD_SUCCESS"

			# VSCode 拡張機能のインストール
			if [[ "$OPTION_JAVA_INSTALL" -eq 2 ]]; then
				install_vscode_extension "vscjava.vscode-java-pack" "Extension Pack for Java"
			fi

			if [[ -n "$SUDO_USER" ]] && [[ "$SUDO_USER" != "root" ]]; then
				# settings.json の java.jdt.ls.java.home を設定していく
				log_message "VSCode の setting.json に Java のフォルダパスを渡します" "INFO"

        # 一連の処理の結果判定（失敗時は手動設定について説明するため）
				local SETTING_SUCCESS=true

				# 必要なディレクトリやファイル（setting.json）があるかを確認し、なければ作成
				local VSCODE_USER_CONFIG_DIR="/home/$SUDO_USER/.config/Code/User"
				local VSCODE_SETTINGS_JSON_PATH="$VSCODE_USER_CONFIG_DIR/settings.json"
				sudo -u "$SUDO_USER" mkdir -p "$VSCODE_USER_CONFIG_DIR"
				sudo -u "$SUDO_USER" touch "$VSCODE_SETTINGS_JSON_PATH"

				# 空だったり適正でない場合は、JSONを初期化
				if ! sudo -u "$SUDO_USER" jq -e . "$VSCODE_SETTINGS_JSON_PATH" >/dev/null 2>&1; then
					echo '{}' | sudo -u "$SUDO_USER" tee "$VSCODE_SETTINGS_JSON_PATH" >/dev/null
				fi

				# `java` コマンドのパスから、JDK のホームディレクトリを特定する
				#（シンボリックリンクからフルパスを取得し、その親の親ディレクトリを JAVA_HOME と見なす）

				# コマンドからパスを取得し、適正かを判定
				JAVA_PATH=$(which java)
				if [[ -z "$JAVA_PATH" ]]; then
					SETTING_SUCCESS=false
				else
					# フルパスを取得し、適正かを判定
					REAL_JAVA_PATH=$(readlink -f "$JAVA_PATH")
					if [[ -z "$REAL_JAVA_PATH" ]]; then
						SETTING_SUCCESS=false
					else
						# JDK のホームディレクトリ（フルパスの親の親ディレクトリ）を取得し、適正かを判定
						JAVA_HOME=$(dirname "$(dirname "$REAL_JAVA_PATH")")
						if [[ ! -d "$JAVA_HOME" ]] || [[ ! -f "${JAVA_HOME}/bin/java" ]]; then
							SETTING_SUCCESS=false
						else
							# jq を使って java.jdt.ls.java.home を設定（値となるのはこれまで調べてきたパス）
							local KEY_NAME="java.jdt.ls.java.home"

							# 一時ファイル（正常・異常問わず終了時は削除）
							TMP_FILE_SETTING=$(mktemp)
							trap '[[ -f "$TMP_FILE_SETTING" ]] && rm -f "$TMP_FILE_SETTING"' EXIT
							trap 'trap - EXIT; [[ -f "$TMP_FILE_SETTING" ]] && rm -f "$TMP_FILE_SETTING"; exit -1' INT PIPE TERM

							if jq -n \
								--rawfile file_content "$VSCODE_SETTINGS_JSON_PATH" \
								--arg key_name "$KEY_NAME" \
								--arg new_val "$JAVA_HOME" \
								'
								(
									try ($file_content | fromjson) catch {}
									| if type == "object" then . else {} end
								)
								| .[$key_name] = $new_val
								' > "$TMP_FILE_SETTING"; then

								# jqコマンドが成功した場合、一時ファイルの内容で元のファイルを上書き
								if install -m 644 "$TMP_FILE_SETTING" "$VSCODE_SETTINGS_JSON_PATH"; then
									log_message "VSCode（$VSCODE_SETTINGS_JSON_PATH）に '$KEY_NAME: $JAVA_HOME' を設定しました。" "CMD_SUCCESS"
								else
									# install コマンドが失敗した場合
									log_message "install コマンドの実行に失敗しました。" "CMD_FAIL"
									SETTING_SUCCESS=false
								fi
							else
								# jq コマンドが失敗した場合
								log_message "jq コマンドの実行に失敗しました。" "CMD_FAIL"
								SETTING_SUCCESS=false
							fi
							log_message "Java（OpenJDK）を利用するには、Linux環境の再起動が必要な場合があります。" "INFO"
						fi
					fi

					# setting.json への設定が失敗している場合は、その旨を通知
					if ! $SETTING_SUCCESS; then
						log_message "VSCode（$VSCODE_SETTINGS_JSON_PATH）への 'java.jdt.ls.java.home' 設定に失敗しました。手動での設定をお試しください。" "CMD_FAIL"
						log_message "  ファイル: $VSCODE_SETTINGS_JSON_PATH" "CMD_FAIL"
						log_message "  追記内容例: \"java.jdt.ls.java.home\": \"/usr/lib/jvm/java-17-openjdk-amd64\"" "CMD_FAIL"
						echo "" | tee -a "$LOG_FILE"
					fi
				fi
			else
				log_message "SUDO_USER が不明なため、VSCode の Java 設定をスキップしました。" "WARN"
			fi
		else
			log_message "Java（default-jdk）のインストール失敗" "CMD_FAIL"
		fi
		echo "" | tee -a "$LOG_FILE"
	else
		log_message "Java（OpenJDK）のインストールはスキップされました。" "INFO"
	fi
}





# --- Docker のインストール ---
function setup_docker() {
	if [[ "$OPTION_DOCKER_INSTALL" -ne 0 ]]; then
		log_message "Docker のインストールを開始します。" "INFO"
		if ! command -v curl &> /dev/null; then
			sudo apt install -y curl >> "$LOG_FILE" 2>&1
		fi
		if curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh >> "$LOG_FILE" 2>&1; then
			log_message "Docker のインストールスクリプト実行成功" "CMD_SUCCESS"
			rm -f get-docker.sh

			# VSCode 拡張機能のインストール
			if [[ "$OPTION_DOCKER_INSTALL" -eq 2 ]]; then
				install_vscode_extension "ms-azuretools.vscode-docker" "Docker"
			fi

			if [[ -n "$SUDO_USER" ]] && [[ "$SUDO_USER" != "root" ]]; then
				if sudo usermod -aG docker "$SUDO_USER" >> "$LOG_FILE" 2>&1; then
					log_message "ユーザー '$SUDO_USER' を 'docker' グループに追加しました。" "CMD_SUCCESS"
					log_message "この変更を有効にするには、一度Linux環境からログアウトし、再度ログインしてください。" "WARN"
				else
					log_message "ユーザー '$SUDO_USER' を 'docker' グループに追加できませんでした。" "CMD_FAIL"
				fi
			else
				log_message "SUDO_USER が未定義またはrootのため、dockerグループへの自動追加をスキップしました。" "WARN"
				log_message "sudoなしでdockerコマンドを実行するには 'sudo usermod -aG docker YOUR_USERNAME' を手動で実行し、再ログインしてください。" "WARN"
			fi
		else
			log_message "Docker のインストールスクリプト実行失敗" "CMD_FAIL"
			rm -f get-docker.sh
		fi
		echo "" | tee -a "$LOG_FILE"
	else
			log_message "Docker のインストールはスキップされました。" "INFO"
	fi
}





# --- Python（python3, python3-pip, python3-venv）のインストール ---
function setup_python() {
	if [[ "$OPTION_PYTHON_INSTALL" -ne 0 ]]; then
		log_message "Python（python3, python3-pip, python3-venv）のインストールを開始します。" "INFO"
		if sudo apt install -y python3 python3-pip python3-venv >> "$LOG_FILE" 2>&1; then
			log_message "Python（python3, python3-pip, python3-venv）のインストール/確認成功" "CMD_SUCCESS"

			# VSCode 拡張機能のインストール
			if [[ "$OPTION_PYTHON_INSTALL" -eq 2 ]]; then
				install_vscode_extension "ms-python.python" "Python"
			fi

		else
			log_message "Python（python3, python3-pip, python3-venv）のインストール失敗" "CMD_FAIL"
		fi
		echo "" | tee -a "$LOG_FILE"
	else
		log_message "Python のインストールはスキップされました。" "INFO"
	fi
}





# --- Chromium（Crostini側でのブラウザ）のインストール ---
function setup_chromium() {
	if [[ "$OPTION_CHROMIUM_INSTALL" -eq 1 ]]; then
			log_message "Chromium ブラウザのインストールを開始します。" "INFO"
			if sudo apt install -y chromium >> "$LOG_FILE" 2>&1; then
					log_message "Chromium ブラウザのインストール成功" "CMD_SUCCESS"
			else
					log_message "Chromium ブラウザのインストール失敗" "CMD_FAIL"
			fi
			echo "" | tee -a "$LOG_FILE"
	else
			log_message "Chromium ブラウザのインストールはスキップされました。" "INFO"
	fi
}





# --- Inkscape のインストール ---
function setup_inkscape() {
	if [[ "$OPTION_INKSCAPE_INSTALL" -eq 1 ]]; then
			log_message "InkScape のインストールを開始します。" "INFO"
			if sudo apt install -y inkscape >> "$LOG_FILE" 2>&1; then
					log_message "InkScape のインストール成功" "CMD_SUCCESS"
			else
					log_message "InkScape のインストール失敗" "CMD_FAIL"
			fi
			echo "" | tee -a "$LOG_FILE"
	else
			log_message "InkScape のインストールはスキップされました。" "INFO"
	fi
}





# --- Gimp のインストール ---
function setup_gimp() {
	if [[ "$OPTION_GIMP_INSTALL" -eq 1 ]]; then
			log_message "GIMP のインストールを開始します。" "INFO"
			if sudo apt install -y gimp >> "$LOG_FILE" 2>&1; then
					log_message "GIMP のインストール成功" "CMD_SUCCESS"
			else
					log_message "GIMP のインストール失敗" "CMD_FAIL"
			fi
			echo "" | tee -a "$LOG_FILE"
	else
			log_message "GIMP のインストールはスキップされました。" "INFO"
	fi
}





# --- メイン処理 ---
main() {
  # 初期部分
  generate_log_header
	initialize_confirmation

	# 必須処理
	log_message "--- 必須処理開始 ---" "INFO"
	apt_update_and_upgrade
	setup_fonts
	setup_locale
	setup_vscode
	install_vscode_japanese_language
	log_message "--- 必須処理完了 ---" "INFO"
	echo "" | tee -a "$LOG_FILE"

	# オプション処理
	log_message "--- オプション処理開始 ---" "INFO"
	setup_nano
	setup_git_config
	setup_manpages
	setup_nodejs
	setup_keyring
	setup_cpp
	setup_java
	setup_docker
	setup_python
	setup_chromium
	setup_inkscape
	setup_gimp

  # 完了、フッターとなる部分をターミナルとログに出力
  echo "" | tee -a "$LOG_FILE"
	log_message "--- オプション処理完了 ---" "INFO"
	echo "" | tee -a "$LOG_FILE"
	log_message "全ての処理が完了しました。" "INFO"
	echo "-----------------------------------------------------" | tee -a "$LOG_FILE"
	echo "初期設定スクリプトの処理が完了しました。" | tee -a "$LOG_FILE"
	echo "詳細は $LOG_FILE を確認してください。" | tee -a "$LOG_FILE"
	echo "" | tee -a "$LOG_FILE"
	echo "注記: " | tee -a "$LOG_FILE"
	echo "  1. いくつかの設定（特にロケール、Dockerグループ、VoltaのPATH、Keyringなど）を完全に有効にするには、" | tee -a "$LOG_FILE"
	echo "     Linux環境の再起動、または一度ログアウトしてターミナルに再ログインする必要がある場合があります。" | tee -a "$LOG_FILE"
	echo "  2. 日本語入力に関する設定は、スクリプト内では行っていません。" | tee -a "$LOG_FILE"
	echo "     必要な場合は、例えば chrome://flags/#crostini-qt-ime-support から有効化する手段があります。" | tee -a "$LOG_FILE"
	echo "  3. VSCode の日本語化は、アクティビティバー「拡張機能」から Japanese Language Pack for VS Code を選択し、画面の指示に従ってください。" | tee -a "$LOG_FILE"
}







# --- スクリプト実行 ---
check_crostini
check_sudo_and_keep_alive
main "$@"
exit 0