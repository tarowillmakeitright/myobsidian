---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Linux Commands Magazine — 2026-06-24

1) 今日の1コマンド
`curl` — HTTP/HTTPS の疎通確認・APIテスト・ファイル取得を1本でこなせる、運用と開発の定番コマンド。

2) 実務で使う場面
- API のヘルスチェックやレスポンス確認をするとき
- デプロイ後にエンドポイントが 200 を返すか即確認したいとき
- 認証ヘッダ付きで社内 API を手動テストしたいとき
- スクリプトから成果物や設定ファイルを安全に取得したいとき

3) よく使うオプション
- `-I` : レスポンス本文を取らず、ヘッダだけ確認する
- `-L` : リダイレクトを追跡する
- `-o <file>` : 出力をファイルへ保存する
- `-H <header>` : HTTP ヘッダを追加する。認証や Content-Type 指定で多用
- `-X <method>` : HTTP メソッドを明示する
- `-d <data>` : POST/PUT/PATCH の送信データを渡す
- `-f` : HTTP 4xx/5xx を失敗扱いにする。スクリプト向き
- `-sS` : 通常出力を静かにしつつ、エラーだけ表示する

4) 実例コマンド
```bash
# 1. サイトの応答ヘッダだけ確認する
curl -I https://example.com

# 2. リダイレクト込みで最終URLまで確認する
curl -I -L http://example.com

# 3. API の JSON を認証ヘッダ付きで取得する
curl -sS -H "Authorization: Bearer $TOKEN" https://api.example.com/v1/projects

# 4. JSON を POST して動作確認する
curl -sS -X POST https://api.example.com/v1/deployments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"service":"web","version":"1.2.3"}'

# 5. 成果物をファイル保存する
curl -fL -o app.tar.gz https://downloads.example.com/releases/app.tar.gz

# 6. 監視やシェルで使いやすい形でステータスコードだけ取る
curl -sS -o /dev/null -w "%{http_code}\n" https://example.com/health
```

5) よくあるミスと安全ポイント
- `-L` を付けずに 301/302 で止まり、「落ちてる」と誤解しがち
- `-d` を使うのに `Content-Type` を付けず、API 側で解釈ズレが起きやすい
- シェル履歴にトークンを残しやすい。可能なら環境変数や一時ファイル経由で渡す
- ダウンロード用途では `-fL` を付けると、404 HTML を成功扱いで保存しにくい
- `-k` は証明書検証を無効化するので常用しない。本番調査では極力避ける

6) 追加学習
- `man curl` の「-H」「-d」「-o」「-w」「-f」「-L」を先に押さえると実務でかなり使える
- 関連コマンド: `wget`（取得向け）, `jq`（JSON整形）, `openssl s_client`（TLS確認）
