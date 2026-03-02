# Publish Allowlist Checklist

このチェックリストは、Obsidian Publish に出してよいノートだけを安全に公開するためのものです。

## ✅ 公開してよい（推奨）

- [ ] `Home.md`
- [ ] `Tea/`
- [ ] `Weather/Tokyo/`
- [ ] `Stocks/Buzzing/`
- [ ] `Books/Daily/`
- [ ] `Sources/Daily-5/`（公開したい場合のみ）

## ⚠️ 原則 非公開（機密/個人）

- [ ] `Markets/`（個人の取引詳細・損益）
- [ ] `Receipts/`（生活費・レシート情報）
- [ ] APIキーやトークンを含むノート
- [ ] 個人情報（住所、電話、メール、口座情報）
- [ ] ローカル絶対パスを含むメモ

## 🔍 公開前チェック

- [ ] ノート内に APIキー/パスワード/トークンがない
- [ ] 個人名・連絡先・IDの露出がない
- [ ] 不要な内部ログを含めていない
- [ ] 外部リンクが正しく動く
- [ ] タグが整理されている（例: `#tea #daily #stocks`）

## 🚀 Publish 手順

1. Settings → Core plugins → **Publish** をON
2. Settings → **Publish** でログイン
3. 公開対象を選ぶ（このチェックリストに沿う）
4. **Publish changes** を実行

## 🧭 初回の安全運用

最初は小さく公開して様子を見る:

- `Home.md`
- `Tea/`
- `Weather/Tokyo/`

問題なければ `Stocks/Buzzing/` や `Books/Daily/` を追加。

---

必要なら次に「公開版ホーム（Public Home）」を作成して、公開導線をさらに分かりやすくできます。
