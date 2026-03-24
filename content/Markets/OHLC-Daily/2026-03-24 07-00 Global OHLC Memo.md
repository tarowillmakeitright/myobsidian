# 2026-03-24 07-00 Global OHLC Memo

#markets #ohlc #futures #fx #daily

[[Home]]

## サマリー
- 取得成功数: 25/26
- N/A件数: 1件
- 注意点: Yahoo Financeのchart API（query1.finance.yahoo.com/v8/finance/chart）時点値。市場休場・時間外・銘柄仕様によりOHLC/前日終値が欠損する場合はN/A表示。

## 日本・アジア株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 日経USD先物 | `NKD=F` | 2026-03-24 | 50780 | 54020 | 50410 | 53075 | 53550 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD=F) |
| 日経225 | `^N225` | 2026-03-23 | 52468.7188 | 52479.8086 | 50688.7617 | 51515.49 | 53751.15 | N/A | [Yahoo](https://finance.yahoo.com/quote/^N225) |
| CSI300 | `000300.SS` | 2026-03-23 | 4499.1006 | 4514.7183 | 4397.5659 | 4417.997 | 4637.44 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| 上海総合 | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/^SSEC) |

## 米国株価指数・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ総合 | `^IXIC` | 2026-03-24 | 21995.7793 | 22189.3398 | 21865.7969 | 21946.76 | 22374.18 | N/A | [Yahoo](https://finance.yahoo.com/quote/^IXIC) |
| SOX指数 | `^SOX` | 2026-03-24 | 7825.8403 | 7958.0029 | 7734.416 | 7773.132 | 7796.24 | N/A | [Yahoo](https://finance.yahoo.com/quote/^SOX) |
| S&P500先物 | `ES=F` | 2026-03-24 | 6510 | 6748 | 6483.5 | 6632.75 | 6626 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES=F) |
| ミニダウ先物 | `YM=F` | 2026-03-24 | 45605 | 47210 | 45453 | 46507 | 46234 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM=F) |
| ミニNQ100先物 | `NQ=F` | 2026-03-24 | 23902 | 24763 | 23772.5 | 24400 | 24434.5 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ=F) |
| ミニS&P500先物 | `MES=F` | 2026-03-24 | 6520.25 | 6748 | 6482.75 | 6633 | 6626 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES=F) |
| ラッセル2000 | `^RUT` | 2026-03-24 | 2465.4036 | 2529.5469 | 2465.4036 | 2494.227 | 2503.29 | N/A | [Yahoo](https://finance.yahoo.com/quote/^RUT) |
| VIX指数 | `^VIX` | 2026-03-24 | 30.04 | 31.04 | 20.28 | 26.15 | 22.37 | N/A | [Yahoo](https://finance.yahoo.com/quote/^VIX) |

## 欧州株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE100 | `^FTSE` | 2026-03-24 | 9918.4805 | 10036.6504 | 9670.46 | 9894.15 | 10317.7 | N/A | [Yahoo](https://finance.yahoo.com/quote/^FTSE) |
| CAC40 | `^FCHI` | 2026-03-24 | 7542.3599 | 7876.7002 | 7505.27 | 7726.2 | 7974.49 | N/A | [Yahoo](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX50 | `^STOXX50E` | 2026-03-24 | 5472.23 | 5683.9199 | 5376.8101 | 5574.32 | 5769.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | `^GDAXI` | 2026-03-24 | 21947.8203 | 23178.6992 | 21863.8105 | 22653.86 | 23564.01 | N/A | [Yahoo](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI Europe USD | `^125904-USD-STRD` | 2026-03-24 | 2488.0601 | 2591.77 | 2443.48 | 2540.65 | 2617.71 | N/A | [Yahoo](https://finance.yahoo.com/quote/^125904-USD-STRD) |

## コモディティ先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 金ミニ先物 | `MGC=F` | 2026-03-24 | 4462.6001 | 4537.1001 | 4100 | 4409.6 | 4896.2 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC=F) |
| 銀先物 | `SI=F` | 2026-03-24 | 66.85 | 71.03 | 61.21 | 69.32 | 77.238 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI=F) |
| プラチナ先物 | `PL=F` | 2026-03-24 | 1910 | 1939.8 | 1703 | 1874.4 | 2052 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL=F) |
| パラジウム先物 | `PA=F` | 2026-03-24 | 1423.5 | 1475.5 | 1315 | 1439 | 1517.1 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA=F) |
| 銅先物 | `HG=F` | 2026-03-24 | 5.312 | 5.585 | 5.246 | 5.4865 | 5.554 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG=F) |
| WTI原油先物 | `CL=F` | 2026-03-24 | 100.51 | 101.67 | 84.37 | 88.87 | 96.32 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL=F) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| ビットコイン | `BTC-USD` | 2026-03-24 | 67854.9844 | 71683.8672 | 67644.9609 | 70827.125 | 69912.79 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | `JPY=X` | 2026-03-24 | 158.351 | 158.41 | 158.313 | 158.386 | 159.105 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | `EURJPY=X` | 2026-03-24 | 183.926 | 183.998 | 183.822 | 183.858 | 182.95 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY=X) |

