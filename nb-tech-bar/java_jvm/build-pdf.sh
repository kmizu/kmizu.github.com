#!/bin/bash

# marp-mermaid-to-pdf.sh
# MarpのMarkdownファイル（Mermaidスクリプト埋め込み済み）をPDFに変換するスクリプト

# --- 設定項目 ---
# ご自身の環境に合わせてChromium/Google Chromeの実行可能ファイルへのパスを設定してください。
# macOS の Google Chrome の一般的なパス:
CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# Linux の google-chrome の一般的なパス (環境変数 PATH に含まれている場合):
# CHROME_EXECUTABLE="google-chrome"
# Linux の chromium-browser の一般的なパス (環境変数 PATH に含まれている場合):
# CHROME_EXECUTABLE="chromium-browser"

# --- スクリプト本体 ---

# ヘルプメッセージを表示する関数
show_help() {
    echo "使用法: $0 <input_markdown_file.md> [output_pdf_file.pdf]"
    echo "  <input_markdown_file.md>: (必須) Mermaidスクリプトが埋め込まれたMarp Markdownファイル。"
    echo "  [output_pdf_file.pdf]: (任意) 出力するPDFファイル名。指定しない場合は入力ファイル名.pdf になります。"
    echo ""
    echo "前提:"
    echo "  - Marp CLI (@marp-team/marp-cli) がインストールされていること。"
    echo "  - Google Chrome または Chromium がインストールされており、上記の CHROME_EXECUTABLE 変数が正しく設定されていること。"
    echo "  - 入力Markdownファイルには、Mermaid.jsを読み込み初期化する <script> タグが埋め込まれていること。"
    echo "    例:"
    echo "    <script src=\"[https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js](https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js)\"></script>"
    echo "    <script>mermaid.initialize({ startOnLoad:true });</script>"
}

INPUT_MD_FILE=slide.md
BASENAME_NO_EXT=$(basename "${INPUT_MD_FILE%.md}")

# 出力PDFファイル名の設定
OUTPUT_PDF_FILE="${BASENAME_NO_EXT}.pdf"

HTML_TEMP_FILE=$(mktemp "${BASENAME_NO_EXT}_XXXXXX.html") # 一時HTMLファイル

# クリーンアップ関数 (スクリプト終了時に一時ファイルを削除)
cleanup() {
    echo "一時ファイル ($HTML_TEMP_FILE) を削除しています..."
    rm -f "$HTML_TEMP_FILE"
}
trap cleanup EXIT # スクリプト終了時にcleanup関数を実行

# 1. Marp CLIでHTMLに変換 (Mermaidスクリプトが埋め込まれている前提)
echo "ステップ1: Marp MarkdownファイルをHTMLに変換中..."
# --html オプションでHTMLタグを許可
# --allow-local-files はローカル画像などがある場合に必要
if ! npx @marp-team/marp-cli@latest --html --allow-local-files "$INPUT_MD_FILE" -o "$HTML_TEMP_FILE"; then
    echo "エラー: Marp CLIでのHTML変換に失敗しました。"
    echo "入力ファイルパスやMarp CLIのインストールを確認してください。"
    exit 1
fi
echo "一時HTMLファイルが生成されました: $HTML_TEMP_FILE"

# 2. Chromium/Google ChromeのヘッドレスモードでPDFに変換
echo "ステップ2: HTMLをPDFに変換中 (Chromium/Google Chromeを使用)..."
# --headless: ヘッドレスモードで実行
# --disable-gpu: GPUアクセラレーションを無効化 (ヘッドレスでは推奨)
# --run-all-compositor-stages-before-draw: レンダリング完了を待つためのフラグ
# --virtual-time-budget=10000: JavaScript実行のタイムアウト (ミリ秒)。Mermaidのレンダリングに十分な時間を確保。
#                                 複雑な図が多い場合は長めに設定してください。
# --print-to-pdf: 指定したパスにPDFとして出力
if ! "$CHROME_EXECUTABLE" \
    --headless \
    --disable-gpu \
    --run-all-compositor-stages-before-draw \
    --virtual-time-budget=15000 \
    --print-to-pdf="$OUTPUT_PDF_FILE" \
    "$HTML_TEMP_FILE"; then
    echo "エラー: Chromium/Google ChromeでのPDF変換に失敗しました。"
    echo "CHROME_EXECUTABLE のパスや、ブラウザが正しく動作するか確認してください。"
    exit 1
fi

echo "PDFファイルが正常に生成されました: $OUTPUT_PDF_FILE"
echo "処理完了。"

# cleanup関数がtrapによって自動的に実行される

exit 0
