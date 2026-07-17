---
tags: [markets, ohlc, futures, fx, daily]
---

# 2026-07-17 07:00 Global OHLC Memo

[[Home]]

## サマリー

- 取得成功数: **25/26**
- N/A件数: **1**
- 注意点: Yahoo Finance の日足チャートAPIを取得時点で参照。Closeは取得時点の regularMarketPrice（ない場合は最新日足Close）。marketStateは同APIに直接含まれないため、Yahooの取引時間帯から推定表記。先物・海外市場は取引所タイムゾーンおよび夜間セッションにより基準日がJST日付と異なる場合があります。
- 取得時刻: 2026-07-17 06:40 JST

#markets #ohlc #futures #fx #daily

## 日本

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| 日経平均先物（ドル建て） | NKD=F | 2026-07-16 | 67,835.00 | 67,965.00 | 65,795.00 | 66,000.00 | 67,430.00 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF) |
| 日経平均株価 | ^N225 | 2026-07-16 | 67,900.43 | 68,069.82 | 66,499.49 | 66,835.54 | 68,557.73 | CLOSED（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5EN225) |

## 貴金属・商品

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| 金ミニ先物 | MGC=F | 2026-07-16 | 4,069.30 | 4,072.00 | 3,973.70 | 3,980.30 | 4,005.70 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF) |
| 銀先物 | SI=F | 2026-07-16 | 58.120 | 58.230 | 55.595 | 55.765 | 57.634 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/SI%3DF) |
| プラチナ先物 | PL=F | 2026-07-16 | 1,682.10 | 1,698.00 | 1,626.20 | 1,629.20 | 1,602.20 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/PL%3DF) |
| パラジウム先物 | PA=F | 2026-07-16 | 1,322.00 | 1,323.00 | 1,253.00 | 1,253.00 | 1,242.70 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/PA%3DF) |
| 銅先物 | HG=F | 2026-07-16 | 6.3865 | 6.4195 | 6.2760 | 6.2830 | 6.2330 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/HG%3DF) |
| WTI原油先物 | CL=F | 2026-07-16 | 80.000 | 80.290 | 78.000 | 78.890 | 78.140 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/CL%3DF) |

## 米国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ総合 | ^IXIC | 2026-07-16 | 26,155.40 | 26,165.37 | 25,765.45 | 25,881.95 | 26,206.89 | POST（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX指数 | ^SOX | 2026-07-16 | 12,114.97 | 12,191.41 | 11,768.96 | 11,867.50 | 12,960.00 | POST（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5ESOX) |
| S&P 500先物 | ES=F | 2026-07-16 | 7,615.00 | 7,632.00 | 7,548.25 | 7,569.25 | 7,563.00 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/ES%3DF) |
| ミニ・ダウ先物 | YM=F | 2026-07-16 | 52,919.00 | 53,108.00 | 52,607.00 | 52,743.00 | 52,764.00 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/YM%3DF) |
| E-mini NASDAQ 100 | NQ=F | 2026-07-16 | 29,709.00 | 29,797.00 | 29,078.50 | 29,179.00 | 29,475.75 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF) |
| Micro E-mini S&P 500 | MES=F | 2026-07-16 | 7,615.75 | 7,632.00 | 7,548.25 | 7,569.00 | 7,563.00 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/MES%3DF) |
| VIX | ^VIX | 2026-07-16 | 15.820 | 17.230 | 15.770 | 16.730 | 15.030 | CLOSED（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5EVIX) |
| Russell 2000 | ^RUT | 2026-07-16 | 2,970.27 | 2,996.28 | 2,963.51 | 2,974.57 | 2,992.54 | POST（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5ERUT) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-07-16 | 64,720.36 | 64,893.33 | 63,848.66 | 64,155.22 | 63,758.22 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| CSI 300 | 000300.SS | 2026-07-16 | 4,711.53 | 4,771.06 | 4,673.35 | 4,698.43 | 4,780.79 | CLOSED（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| 上海総合指数 | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC) |

## 欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | ^FTSE | 2026-07-16 | 10,514.96 | 10,572.24 | 10,447.55 | 10,572.24 | 10,472.50 | CLOSED（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC 40 | ^FCHI | 2026-07-16 | 8,380.84 | 8,380.84 | 8,281.27 | 8,377.86 | 8,338.97 | CLOSED（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-07-16 | 6,273.10 | 6,283.61 | 6,208.26 | 6,283.61 | 6,269.97 | CLOSED（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | ^GDAXI | 2026-07-16 | 25,018.95 | 25,021.51 | 24,696.17 | 24,915.49 | 25,118.27 | CLOSED（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI Europe | ^125904-USD-STRD | 2026-07-16 | 2,808.71 | 2,808.71 | 2,779.26 | 2,803.50 | 2,785.76 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-07-16 | 162.10 | 162.55 | 161.98 | 162.35 | 162.36 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX) |
| EUR/JPY | EURJPY=X | 2026-07-16 | 185.88 | 186.03 | 185.70 | 185.77 | 185.63 | REGULAR（時間帯推定） | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX) |
