# Global OHLC Market Memo

- 取得日時: 2026-09-08 07:16 JST（2026-09-07 22:16 UTC）
- 取得成功数: **25/26**
- N/A件数: **1銘柄**（項目別N/Aは別途あり）
- 注意点: Yahoo Finance Chart APIの取得時点値。未確定セッションではClose(取得時点)にregularMarketPriceを使用。marketStateは同APIで返らないためN/A。先物は期近継続ティッカーで、限月切替の影響を受けます。

#markets #ohlc #futures #fx #daily

[[Home]]

## 日本

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | `NKD=F` | 2026-09-07 | 66,030.00 | 66,670.00 | 65,860.00 | 65,820.00 | 65,820.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF/) |
| Nikkei 225 | `^N225` | 2026-09-07 | 65,600.42 | 66,668.71 | 65,600.42 | 66,399.84 | 65,020.94 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225/) |

## 商品先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | `MGC=F` | 2026-09-07 | 4,466.70 | 4,481.50 | 4,426.20 | 4,476.60 | 4,441.90 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF/) |
| Silver futures | `SI=F` | 2026-09-07 | 66.735 | 67.375 | 66.025 | 66.748 | 66.047 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI%3DF/) |
| Platinum futures | `PL=F` | 2026-09-07 | 1,824.90 | 1,841.40 | 1,802.50 | 1,826.00 | 1,821.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL%3DF/) |
| Palladium futures | `PA=F` | 2026-09-07 | 1,403.00 | 1,416.50 | 1,393.50 | 1,403.90 | 1,390.10 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA%3DF/) |
| Copper futures | `HG=F` | 2026-09-07 | 6.669 | 6.734 | 6.636 | 6.6825 | 6.597 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG%3DF/) |
| WTI oil futures | `CL=F` | 2026-09-07 | 92.26 | 93.29 | 90.87 | 91.48 | 91.48 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL%3DF/) |

## 米国株価指数・先物・暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | `^IXIC` | 2026-09-04 | 26,587.90 | 26,628.58 | 26,444.84 | 26,506.99 | 26,584.06 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC/) |
| SOX | `^SOX` | 2026-09-04 | 11,508.70 | 11,750.25 | 11,467.34 | 11,735.26 | 11,352.13 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX/) |
| S&P500 futures | `ES=F` | 2026-09-07 | 7,715.50 | 7,728.50 | 7,703.50 | 7,722.00 | 7,722.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES%3DF/) |
| Mini Dow | `YM=F` | 2026-09-07 | 53,261.00 | 53,336.00 | 53,042.00 | 53,440.00 | 53,440.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM%3DF/) |
| Mini NQ100 | `NQ=F` | 2026-09-07 | 29,535.25 | 29,683.50 | 29,530.50 | 29,565.25 | 29,565.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF/) |
| Mini S&P500 | `MES=F` | 2026-09-07 | 7,715.25 | 7,728.50 | 7,703.50 | 7,722.00 | 7,722.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES%3DF/) |
| VIX | `^VIX` | 2026-09-07 | 15.02 | 15.32 | 14.99 | 15.3 | 14.53 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX/) |
| Bitcoin | `BTC-USD` | 2026-09-07 | 80,351.40 | 80,387.91 | 78,773.36 | 79,071.92 | 80,350.05 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD/) |
| Russell 2000 | `^RUT` | 2026-09-04 | 2,956.75 | 2,976.66 | 2,951.04 | 2,975.65 | 2,968.27 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT/) |

## 中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| 中国市場指数（CSI 300） | `000300.SS` | 2026-09-07 | 4,567.89 | 4,580.70 | 4,545.41 | 4,575.02 | 4,548.05 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS/) |
| 上海総合指数 | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC/) |

## 欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | `^FTSE` | 2026-09-07 | 10,830.97 | 10,868.27 | 10,794.17 | 10,822.13 | 10,831.10 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE/) |
| CAC 40 | `^FCHI` | 2026-09-07 | 8,272.76 | 8,317.37 | 8,255.72 | 8,306.15 | 8,278.77 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI/) |
| EURO STOXX 50 | `^STOXX50E` | 2026-09-07 | 0 | 0 | 0 | 6,403.99 | 6,392.93 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E/) |
| DAX | `^GDAXI` | 2026-09-07 | 26,039.54 | 26,069.99 | 25,919.61 | 26,006.53 | 26,046.40 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI/) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-09-07 | 2,872.98 | 2,881.76 | 2,862.17 | 2,877.40 | 2,873.19 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD/) |

## FX

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | `JPY=X` | 2026-09-07 | 154.352 | 154.374 | 154.269 | 154.287 | 156.197 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX/) |
| EUR/JPY | `EURJPY=X` | 2026-09-07 | 179.393 | 179.443 | 179.345 | 179.364 | 181.403 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX/) |
