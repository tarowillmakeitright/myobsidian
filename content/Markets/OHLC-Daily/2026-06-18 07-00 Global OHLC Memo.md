# Global OHLC Memo

#markets #ohlc #futures #fx #daily

[[Home]]

## サマリー

- 取得成功数: 25 / 26
- N/A件数: 1
- 注意点: 一部ティッカーで取得失敗あり: ^SSEC(HTTP Error 404: Not Found)
- 注意点: Yahoo Finance chart endpointにはmarketStateがないため、currentTradingPeriodから推定した状態を記載。
- 注意点: Close(取得時点)はregularMarketPriceを使用。

## 日本株/日経

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-06-17 | 69240 | 71070 | 68950 | 70035 | 67335 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NKD=F) |
| Nikkei 225 | ^N225 | 2026-06-17 | 69005.8828 | 70125.75 | 68985.6328 | 69902.25 | 64217.27 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^N225) |

## 貴金属・資源

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-06-17 | 4353.2002 | 4403.1001 | 4237.6001 | 4276.5 | 4215 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MGC=F) |
| Silver futures | SI=F | 2026-06-17 | 70.135 | 71.65 | 66.85 | 67.96 | 67.859 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/SI=F) |
| Platinum futures | PL=F | 2026-06-17 | 1806 | 1824.8 | 1721.6 | 1737.2 | 1709.2 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PL=F) |
| Palladium futures | PA=F | 2026-06-17 | 1365.5 | 1373.5 | 1312.5 | 1326.5 | 1276.2 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PA=F) |
| Copper futures | HG=F | 2026-06-17 | 6.482 | 6.5525 | 6.3255 | 6.363 | 6.4305 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/HG=F) |

## エネルギー

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| WTI oil futures | CL=F | 2026-06-17 | 75.72 | 79.18 | 74.09 | 75.01 | 84.88 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/CL=F) |

## 米国株

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | ^IXIC | 2026-06-17 | 26493.8242 | 26511.5547 | 25960.4102 | 26021.656 | 25169.5 | POST | [Yahoo](https://finance.yahoo.com/quote/^IXIC) |
| SOX | ^SOX | 2026-06-17 | 13694.0127 | 13965.6016 | 13471.2168 | 13477.072 | 12206.46 | POST | [Yahoo](https://finance.yahoo.com/quote/^SOX) |
| S&P500 futures | ES=F | 2026-06-17 | 7581.25 | 7612.5 | 7472.25 | 7511 | 7435 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | YM=F | 2026-06-17 | 52408 | 52734 | 51839 | 52049 | 51227 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | NQ=F | 2026-06-17 | 30306.5 | 30584.5 | 29923 | 30141.75 | 29662 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | MES=F | 2026-06-17 | 7583.5 | 7612.5 | 7472.25 | 7511 | 7435 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MES=F) |
| VIX | ^VIX | 2026-06-17 | 16.08 | 18.84 | 16.02 | 18.44 | 19.44 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^VIX) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-06-17 | 65605.4453 | 66231.3359 | 64107.8555 | 64190.88 | 64421.324 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国・欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| China market index/futures | 000300.SS | 2026-06-17 | 4859.7012 | 4933.9287 | 4859.7012 | 4931.386 | 4722.41 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/^SSEC) |
| Russell 2000 | ^RUT | 2026-06-17 | 2945.7883 | 2977.2 | 2910.9548 | 2917.982 | 2835.46 | POST | [Yahoo](https://finance.yahoo.com/quote/^RUT) |
| FTSE 100 | ^FTSE | 2026-06-17 | 10494.4004 | 10508.6104 | 10468.4297 | 10508.61 | 10254.8 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^FTSE) |
| CAC 40 | ^FCHI | 2026-06-17 | 8435.1201 | 8476.79 | 8408.9004 | 8430.79 | 8200.8 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-06-17 | 6257.9702 | 6300.0698 | 6253.9302 | 6300.07 | 6056.96 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | ^GDAXI | 2026-06-17 | 24816.9609 | 24956.4805 | 24763.5293 | 24934.67 | 24195.31 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-06-17 | 2809.4199 | 2822.47 | 2792.3501 | 2820.13 | 2788.51 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^125904-USD-STRD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-06-17 | 160.388 | 160.796 | 160.112 | 160.539 | 160.527 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | EURJPY=X | 2026-06-17 | 186.222 | 186.315 | 184.534 | 184.638 | 185.171 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/EURJPY=X) |
