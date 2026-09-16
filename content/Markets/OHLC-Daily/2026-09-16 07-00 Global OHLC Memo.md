# Global OHLC Market Memo — 2026-09-16 07:00 JST

取得成功数: **25/26** / N/A件数: **1**

注意点: Yahoo Financeの日足データを06:40 JST時点で取得。市場が取引中の場合、Closeは取得時点の最新日足値で確定値ではありません。セッション基準日はYahooの各銘柄タイムゾーン基準です。
取得注意: `^SSEC` はYahoo Financeで4回の段階的再試行後も当該シンボルの日足データが提供されずN/A。その他25銘柄のOHLCは取得済み。`marketState` は日足データの品質判定対象外です。

## 日本

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | `NKD=F` | 2026-09-15 | 63,240.00 | 63,965.00 | 62,825.00 | 63,550.00 | 64,010.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF/) |
| Nikkei 225 | `^N225` | 2026-09-14 | 63,659.53 | 63,691.53 | 62,726.18 | 63,492.99 | 65,142.78 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225/) |

## 貴金属・商品

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | `MGC=F` | 2026-09-15 | 4,340.30 | 4,358.20 | 4,301.40 | 4,333.30 | 4,373.70 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF/) |
| Silver futures | `SI=F` | 2026-09-15 | 63.76 | 64.465 | 63.035 | 64.185 | 64.284 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI%3DF/) |
| Platinum futures | `PL=F` | 2026-09-15 | 1,767.60 | 1,789.20 | 1,744.40 | 1,783.70 | 1,797.10 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL%3DF/) |
| Palladium futures | `PA=F` | 2026-09-15 | 1,297.50 | 1,316.50 | 1,282.50 | 1,313.00 | 1,281.30 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA%3DF/) |
| Copper futures | `HG=F` | 2026-09-15 | 6.4035 | 6.47 | 6.3445 | 6.459 | 6.467 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG%3DF/) |
| WTI oil futures | `CL=F` | 2026-09-15 | 102.01 | 106.75 | 101.21 | 105.48 | 102.48 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL%3DF/) |

## 米国株・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | `^IXIC` | 2026-09-15 | 26,140.23 | 26,172.12 | 25,943.31 | 25,981.57 | 26,421.41 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC/) |
| SOX | `^SOX` | 2026-09-15 | 11,233.04 | 11,304.24 | 11,128.88 | 11,175.55 | 11,887.87 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX/) |
| S&P500 futures | `ES=F` | 2026-09-15 | 7,699.25 | 7,701.00 | 7,643.50 | 7,663.75 | 7,598.50 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES%3DF/) |
| Mini Dow | `YM=F` | 2026-09-15 | 52,906.00 | 52,906.00 | 52,317.00 | 52,571.00 | 52,095.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM%3DF/) |
| Mini NQ100 | `NQ=F` | 2026-09-15 | 29,488.50 | 29,495.25 | 29,207.50 | 29,277.00 | 29,135.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF/) |
| Mini S&P500 | `MES=F` | 2026-09-15 | 7,700.25 | 7,701.00 | 7,643.50 | 7,663.75 | 7,598.50 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES%3DF/) |
| VIX | `^VIX` | 2026-09-15 | 17.57 | 18.03 | 16.79 | 17.2 | 16.46 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX/) |
| Russell 2000 | `^RUT` | 2026-09-15 | 2,890.64 | 2,890.64 | 2,861.73 | 2,870.29 | 2,960.20 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT/) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | `BTC-USD` | 2026-09-15 | 78,181.33 | 78,232.38 | 74,984.84 | 75,643.88 | 77,173.80 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD/) |

## 中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| China market index/futures | `000300.SS` | 2026-09-15 | 4,473.81 | 4,496.96 | 4,444.63 | 4,450.04 | 4,480.08 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS/) |
| Shanghai index | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC/) |

## 欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | `^FTSE` | 2026-09-15 | 10,697.76 | 10,697.76 | 10,586.39 | 10,658.13 | 10,811.70 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE/) |
| CAC 40 | `^FCHI` | 2026-09-15 | 8,084.61 | 8,110.58 | 8,033.04 | 8,090.28 | 8,156.67 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI/) |
| EURO STOXX 50 | `^STOXX50E` | 2026-09-15 | 6,248.10 | 6,265.25 | 6,194.18 | 6,236.50 | 6,311.56 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E/) |
| DAX | `^GDAXI` | 2026-09-15 | 25,360.32 | 25,478.98 | 25,172.89 | 25,402.28 | 26,007.63 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI/) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-09-15 | 2,788.53 | 2,796.20 | 2,765.65 | 2,786.43 | 2,813.78 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD/) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | `JPY=X` | 2026-09-15 | 154.279 | 155.238 | 154.202 | 155.088 | 153.478 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX/) |
| EUR/JPY | `EURJPY=X` | 2026-09-15 | 178.171 | 179.117 | 178.118 | 178.901 | 178.454 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX/) |

#markets #ohlc #futures #fx #daily

[[Home]]
