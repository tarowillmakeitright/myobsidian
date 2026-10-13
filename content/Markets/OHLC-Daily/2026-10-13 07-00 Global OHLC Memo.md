# 2026-10-13 07:00 Global OHLC Memo

#markets #ohlc #futures #fx #daily

[[Home]]

## サマリー

- **取得成功:** 26 / 26銘柄
- **N/A:** 0銘柄
- **注意点:** 2026-10-13 06:55 JST再取得。上海総合指数はYahoo Financeで `^SSEC` が404のため、同指数の有効なYahooティッカー `000001.SS` へ切り替えました。`Close(取得時点)` はYahoo Financeの日足最新値で、取引中の銘柄は確定終値ではありません。`marketState` はYahooの `currentTradingPeriod` と取得時刻から判定。前日終値は直前に取得できた日足のCloseです。

## 日本・アジア

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | `NKD=F` | 2026-10-12 | 69,120.00 | 69,445.00 | 68,375.00 | 68,380.00 | 69,120.00 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF) |
| Nikkei 225 | `^N225` | 2026-10-09 | 68,648.50 | 69,143.45 | 68,150.02 | 69,030.92 | 69,042.11 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EN225) |
| China market index/futures | `000300.SS` | 2026-10-12 | 4,305.92 | 4,334.29 | 4,279.71 | 4,287.98 | N/A | CLOSED | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | `000001.SS` | 2026-10-12 | 3,806.98 | 3,828.22 | 3,791.00 | 3,797.24 | 3,813.79 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/000001.SS) |

## 商品先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | `MGC=F` | 2026-10-12 | 4,221.00 | 4,242.30 | 4,178.00 | 4,195.90 | 4,191.00 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF) |
| Silver futures | `SI=F` | 2026-10-12 | 61.29 | 61.745 | 60.395 | 60.57 | 60.67 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/SI%3DF) |
| Platinum futures | `PL=F` | 2026-10-12 | 1,696.00 | 1,716.30 | 1,687.50 | 1,697.10 | 1,679.30 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PL%3DF) |
| Palladium futures | `PA=F` | 2026-10-12 | 1,151.00 | 1,166.00 | 1,141.00 | 1,142.50 | 1,140.50 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PA%3DF) |
| Copper futures | `HG=F` | 2026-10-12 | 6.712 | 6.783 | 6.694 | 6.7645 | 6.6425 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/HG%3DF) |
| WTI oil futures | `CL=F` | 2026-10-12 | 91.83 | 94.36 | 89.61 | 93.16 | 91.85 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/CL%3DF) |

## 米国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | `^IXIC` | 2026-10-12 | 27,352.51 | 27,376.66 | 27,219.42 | 27,245.90 | 27,366.17 | POST | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX | `^SOX` | 2026-10-12 | 12,361.24 | 12,378.31 | 12,216.45 | 12,236.79 | 12,572.42 | POST | [Yahoo](https://finance.yahoo.com/quote/%5ESOX) |
| S&P500 futures | `ES=F` | 2026-10-12 | 7,873.00 | 7,887.00 | 7,846.25 | 7,857.00 | 7,859.75 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/ES%3DF) |
| Mini Dow | `YM=F` | 2026-10-12 | 51,972.00 | 52,182.00 | 51,913.00 | 52,129.00 | 51,926.00 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/YM%3DF) |
| Mini NQ100 | `NQ=F` | 2026-10-12 | 31,145.50 | 31,289.25 | 30,844.25 | 30,877.50 | 31,108.75 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF) |
| Mini S&P500 | `MES=F` | 2026-10-12 | 7,872.50 | 7,887.00 | 7,846.25 | 7,857.00 | 7,859.75 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MES%3DF) |
| VIX | `^VIX` | 2026-10-12 | 15.39 | 15.53 | 15.11 | 15.21 | 14.84 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EVIX) |
| Russell 2000 | `^RUT` | 2026-10-12 | 2,805.29 | 2,805.83 | 2,794.47 | 2,794.48 | 2,806.98 | POST | [Yahoo](https://finance.yahoo.com/quote/%5ERUT) |

## 欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | `^FTSE` | 2026-10-12 | 10,551.55 | 10,656.28 | 10,549.64 | 10,656.28 | 10,552.10 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC 40 | `^FCHI` | 2026-10-12 | 7,826.73 | 7,850.33 | 7,806.49 | 7,832.88 | 7,803.33 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | `^STOXX50E` | 2026-10-12 | 6,176.38 | 6,221.89 | 6,176.38 | 6,201.21 | 6,173.37 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | `^GDAXI` | 2026-10-12 | 25,206.95 | 25,315.75 | 25,166.57 | 25,277.68 | 25,087.27 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-10-12 | 2,701.04 | 2,713.91 | 2,701.04 | 2,706.19 | 2,694.60 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | `BTC-USD` | 2026-10-12 | 83,673.01 | 84,230.83 | 82,285.10 | 82,803.85 | 83,679.47 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## FX

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | `JPY=X` | 2026-10-12 | 158.219 | 158.752 | 158.071 | 158.596 | 158.063 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX) |
| EUR/JPY | `EURJPY=X` | 2026-10-12 | 177.1 | 177.562 | 176.734 | 176.9 | 177.23 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX) |
