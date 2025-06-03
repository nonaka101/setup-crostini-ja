# Setup Crostini for Japanese Environment

![リポジトリのロゴ](/image/logo.png)

## 概要

Crostini（Chromebook に搭載されている Linux 環境）の初期設定を行うためのスクリプトです。

日本語環境の設定や VSCodeのインストールを行い、追加の処理として各種開発環境の構築を行います。

## 処理について

本スクリプトでは様々な初期設定を行いますが、その内訳としては「必須処理」と「オプション処理」に分かれます。

必須処理は大多数に便利な設定である一方、オプション設定はユーザーによって利用が分かれるものとなっています。

1. 必須処理:
   - apt パッケージリストの更新とアップグレード
   - 日本語フォントのインストール、フォントキャッシュの更新
   - locale 設定を日本（ja_JP.UTF-8）に変更
   - Visual Studio Code（VSCode）のインストール
   - VSCode 日本語拡張機能（MS-CEINTL.vscode-language-pack-ja）のインストール
2. オプション処理:
   - git の設定（user.name, user.email）
   - nano のインストール
   - マニュアル（manpages-ja, manpages-ja-dev）のインストール
   - Node.js（volta経由）のインストール
   - Keyring（gnome-keyring）を導入し、VSCode と連携
   - C/C++開発環境のインストール
   - Java（OpenJDK）のインストール
   - Docker のインストール
   - Python（python3, python3-pip, python3-venv）のインストール
   - Chromium ブラウザのインストール
   - InkScape（ベクタードローソフト）のインストール
   - GIMP（画像編集ソフト）のインストール

オプション設定の項目を利用するかは、スクリプト内の「設定項目」を編集することで切り替えられます。

## 使い方

このスクリプトを Linux ファイル側にダウンロードまたはコピーします（ファイル名：`setup-crostini-ja.sh`）

その後、テキストエディタなどでスクリプトを開きます。

![ファイルアプリのLinuxファイルに `setup-crostini-ja.sh` を保存し、テキストエディタで開いて編集する](/image/01.png)

テキストエディタを使い、スクリプトの中にある「設定項目」を編集し、必要な設定を行います。

![テキストエディタで、設定項目を編集する](/image/02.png)

設定の完了後、ターミナルからスクリプトを実行します。

```bash
chmod +x setup-crostini-ja.sh
sudo bash setup-crostini-ja.sh
```

![ファイルアプリのLinuxファイルに `setup-crostini-ja.sh` を保存し、ターミナルからスクリプトを実行する](/image/03.png)

実行すると、初期確認画面が表示されます。ここで行う処理を確認し、問題なければ続行してください。

![実行時のターミナル初期確認画面](/image/04.png)

処理は自動で行われます。処理内容は拡張子 `.log` のログファイルに記録されます。

![結果を出力する、`log` 形式のログファイル](/image/05.png)

## 注意

- スクリプト実行には、sudo が必要です。元のユーザー権限で実行したいコマンドがあるため、$SUDO_USER 変数を利用します。
- スクリプトは、Crostini 環境を想定しています。
- 日本語入力の設定はスクリプトでは行っていません、これは環境構築段階で `cros-im` がインストール済みのためです[^1]
- Chromium, InkScape, GIMP は使用する容量が大きいので、インストールする場合は十分なストレージを確保してください[^2]

[^1]: Qt アプリケーションでの日本語入力を使う場合は、`chrome://flags/#crostini-qt-ime-support` を有効化する方法があります
[^2]: 構築時のデフォルト設定（10GB）か、それ以上を推奨します
