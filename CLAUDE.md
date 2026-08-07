# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

kmizu（水島宏太）のGitHub Pagesリポジトリ。静的サイトとしてそのまま公開されるため、**ビルド・lint・テストの仕組みは一切ない**（`package.json` も存在しない）。master ブランチへの push がそのまま本番公開（デプロイ）になる。

内容は大きく3種類：

- **`apps/`** — 単一ファイル完結のWebアプリ群（txt2qr, shogi, char-counter, o3-prolog など）。各アプリは `apps/<name>/index.html` の1ファイルにHTML/CSS/JSをすべてインラインで記述し、外部ライブラリはCDN（cdnjs, jsDelivr, Google Fonts等）から読み込む。新しいアプリを作るときもこのパターンに従う
- **スライド資料** — 過去の発表資料（understanding-scala, ScalaMatsuri系, parser-study系 など多数）。歴史的資産であり基本的に編集しない
- **プロフィール／文書** — ルートの `index.html`（日本語）と `en.html`（英語）は本人のプロフィール・業績ページで、論文リスト等を変更するときは日英を対で更新する。`papers/`, `articles/` は文書置き場

## 開発・動作確認

- 動作確認はブラウザでHTMLファイルを直接開くか、リポジトリルートで `python3 -m http.server` を起動して `http://localhost:8000/apps/<name>/` を開く
- master への push ＝ 即公開。公開してよい状態でのみ push する

## 規約

- コミットメッセージは日本語（`git log` 参照）
