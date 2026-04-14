# Global OHLC Memo

#markets #ohlc #futures #fx #daily

[[Home]]

- 取得成功数: **23**
- N/A件数: **3**
- 注意点: Yahoo Finance（query1.finance.yahoo.com/v8/finance/chart）再取得。stagger + backoff適用。 一部シンボルは再試行後も取得不可。

## 日本株

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 日経225 | `^N225` | 2026-04-13 | 56,421.4609 | 56,765.7188 | 56,232.7812 | N/A | N/A | N/A | [link](https://finance.yahoo.com/quote/^N225) |

## 中国株

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 中国CSI300 | `000300.SS` | 2026-04-13 | 4,615.1328 | 4,653.3984 | 4,615.1328 | N/A | N/A | N/A | [link](https://finance.yahoo.com/quote/000300.SS) |
| 上海総合 | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [link](https://finance.yahoo.com/quote/^SSEC) |

## 米国株

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ総合 | `^IXIC` | 2026-04-13 | 22,849.2305 | 23,187.9629 | 22,795.8164 | 23,183.7363 | N/A | N/A | [link](https://finance.yahoo.com/quote/^IXIC) |
| SOX | `^SOX` | 2026-04-13 | 8,873.3066 | 9,044.7881 | 8,837.9619 | 9,039.5244 | N/A | N/A | [link](https://finance.yahoo.com/quote/^SOX) |
| VIX | `^VIX` | 2026-04-13 | 21.17 | 21.58 | 18.96 | 19.12 | N/A | N/A | [link](https://finance.yahoo.com/quote/^VIX) |
| Russell 2000 | `^RUT` | 2026-04-13 | 2,625.6902 | 2,671.0491 | 2,622.1348 | 2,670.4919 | N/A | N/A | [link](https://finance.yahoo.com/quote/^RUT) |

## 米国先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| S&P500先物 | `ES=F` | 2026-04-13 | 6,780 | 6,928.25 | 6,767 | 6,927.5 | N/A | N/A | [link](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | `YM=F` | 2026-04-13 | 47,674 | 48,457 | 47,534 | 48,449 | N/A | N/A | [link](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | `NQ=F` | 2026-04-13 | 24,980 | 25,599.25 | 24,904.5 | 25,585.5 | N/A | N/A | [link](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | `MES=F` | 2026-04-13 | 6,793.5 | 6,929.25 | 6,767.25 | 6,927.5 | N/A | N/A | [link](https://finance.yahoo.com/quote/MES=F) |

## 欧州株

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE100 | `^FTSE` | 2026-04-13 | 10,601.4502 | 10,607.6904 | 10,528.5703 | 10,582.96 | N/A | N/A | [link](https://finance.yahoo.com/quote/^FTSE) |
| CAC40 | `^FCHI` | 2026-04-13 | 8,178.2202 | 8,235.9805 | 8,163.3701 | 8,235.9805 | N/A | N/A | [link](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX 50 | `^STOXX50E` | 2026-04-13 | 0 | 0 | 0 | 5,905.02 | N/A | N/A | [link](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | `^GDAXI` | 2026-04-13 | 23,562.1895 | 23,756.8496 | 23,482.0098 | 23,742.4395 | N/A | N/A | [link](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-04-13 | 2,712.23 | 2,743.52 | 2,700.99 | 2,731.3401 | N/A | N/A | [link](https://finance.yahoo.com/quote/^125904-USD-STRD) |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 金ミニ先物 | `MGC=F` | 2026-04-13 | 4,711.7998 | 4,774 | 4,625.1001 | 4,766.2002 | N/A | N/A | [link](https://finance.yahoo.com/quote/MGC=F) |
| 銀先物 | `SI=F` | 2026-04-13 | 74.85 | 76 | 72.545 | 75.74 | N/A | N/A | [link](https://finance.yahoo.com/quote/SI=F) |
| プラチナ先物 | `PL=F` | 2026-04-13 | 2,051.1001 | 2,087.8 | 1,983 | 2,087.7 | N/A | N/A | [link](https://finance.yahoo.com/quote/PL=F) |
| パラジウム先物 | `PA=F` | 2026-04-13 | 1,532 | 1,594.5 | 1,498 | 1,594.5 | N/A | N/A | [link](https://finance.yahoo.com/quote/PA=F) |
| 銅先物 | `HG=F` | 2026-04-13 | 5.8175 | 6.0245 | 5.764 | 6.0035 | N/A | N/A | [link](https://finance.yahoo.com/quote/HG=F) |
| WTI原油先物 | `CL=F` | 2026-04-13 | 102 | 105.63 | 97.03 | 98.01 | N/A | N/A | [link](https://finance.yahoo.com/quote/CL=F) |

## FX/暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | `BTC-USD` | 2026-04-13 | 70,741.2969 | 73,476.6953 | 70,616.4609 | 73,264.2344 | N/A | N/A | [link](https://finance.yahoo.com/quote/BTC-USD) |
| USD/JPY | `JPY=X` | 2026-04-14 | 159.353 | 159.38 | 159.35 | 159.354 | N/A | N/A | [link](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | `EURJPY=X` | 2026-04-14 | 187.308 | 187.39 | 187.287 | 187.368 | N/A | N/A | [link](https://finance.yahoo.com/quote/EURJPY=X) |

## 先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 日経USD先物 | `NKD=F` | 2026-04-13 | 56,505 | 57,760 | 55,950 | 57,705 | N/A | N/A | [link](https://finance.yahoo.com/quote/NKD=F) |

---
補足: 再取得失敗シンボル -> ^SSEC:404 Client Error: Not Found for url: https://query1.finance.yahoo.com/v8/finance/chart/%5ESSEC?interval=1d&range=5d
