# 2026-04-02 07:00 Global OHLC Memo

#markets #ohlc #futures #fx #daily

[[Home]]

## サマリー
取得成功数: 25/26 / N/A件数: 1 / 注意点: Yahoo Financeのv8/chart API（query2.finance.yahoo.com）を使用。marketStateは同APIで取得できないためN/A。^SSEC はYahoo側で当該シンボルのチャートデータ未提供のため、バックオフ付き再試行（5回）後もN/Aを維持。

## FX

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-04-02 | 158.707 | 159.013 | 158.266 | 158.746 | 155.859 | N/A | https://finance.yahoo.com/quote/JPY=X |
| EUR/JPY | EURJPY=X | 2026-04-02 | 183.322 | 184.364 | 183.278 | 183.918 | 183.947 | N/A | https://finance.yahoo.com/quote/EURJPY=X |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-04-02 | 4,697.7 | 4,821 | 4,688.4 | 4,784.6 | 5,311.6 | N/A | https://finance.yahoo.com/quote/MGC=F |
| Silver futures | SI=F | 2026-04-02 | 75.48 | 76.265 | 74 | 75.2 | 88.284 | N/A | https://finance.yahoo.com/quote/SI=F |
| Platinum futures | PL=F | 2026-04-02 | 1,968.4 | 1,993.9 | 1,948.2 | 1,965.5 | 2,311.9 | N/A | https://finance.yahoo.com/quote/PL=F |
| Palladium futures | PA=F | 2026-04-02 | 1,492 | 1,519 | 1,463.5 | 1,481.5 | 1,762.6 | N/A | https://finance.yahoo.com/quote/PA=F |
| Copper futures | HG=F | 2026-04-02 | 5.648 | 5.663 | 5.584 | 5.617 | 5.894 | N/A | https://finance.yahoo.com/quote/HG=F |
| WTI oil futures | CL=F | 2026-04-02 | 101.72 | 103.31 | 96.5 | 98.91 | 71.23 | N/A | https://finance.yahoo.com/quote/CL=F |

## 中国/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| China market index/futures | 000300.SS | 2026-04-01 | 4,517.27 | 4,532.11 | 4,492.05 | 4,526.07 | 4,710.65 | N/A | https://finance.yahoo.com/quote/000300.SS |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | https://finance.yahoo.com/quote/^SSEC |

## 日本/先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-04-02 | 53,100 | 54,730 | 52,785 | 54,290 | 57,710 | N/A | https://finance.yahoo.com/quote/NKD=F |

## 日本/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei 225 | ^N225 | 2026-04-01 | 51,959.47 | 53,739.68 | 51,902.84 | 53,739.68 | 58,850.27 | N/A | https://finance.yahoo.com/quote/^N225 |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-04-02 | 68,224.47 | 69,191.27 | 67,591.14 | 68,357.41 | 65,738.1 | N/A | https://finance.yahoo.com/quote/BTC-USD |

## 欧州/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | ^FTSE | 2026-04-02 | 10,174.94 | 10,396.6 | 10,169.3 | 10,364.79 | 10,910.6 | N/A | https://finance.yahoo.com/quote/^FTSE |
| CAC 40 | ^FCHI | 2026-04-02 | 8,004.81 | 8,006.47 | 7,918.52 | 7,981.27 | 8,580.75 | N/A | https://finance.yahoo.com/quote/^FCHI |
| EURO STOXX 50 | ^STOXX50E | 2026-04-02 | 5,621.98 | 5,735.41 | 5,621.98 | 5,732.71 | 6,138.41 | N/A | https://finance.yahoo.com/quote/^STOXX50E |
| DAX | ^GDAXI | 2026-04-02 | 23,326.89 | 23,377.65 | 23,027.04 | 23,298.89 | 25,284.26 | N/A | https://finance.yahoo.com/quote/^GDAXI |
| MSCI EUROPE | ^125904-USD-STRD | 2026-04-02 | 2,611.64 | 2,640.76 | 2,611.64 | 2,639.51 | 2,769.64 | N/A | https://finance.yahoo.com/quote/^125904-USD-STRD |

## 欧米/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Russell 2000 | ^RUT | 2026-04-02 | 2,510.88 | 2,540.59 | 2,510.88 | 2,512.37 | 2,632.36 | N/A | https://finance.yahoo.com/quote/^RUT |

## 米国/ボラティリティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| VIX | ^VIX | 2026-04-02 | 24.3 | 25.35 | 23.5 | 24.54 | 19.86 | N/A | https://finance.yahoo.com/quote/^VIX |

## 米国/先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| S&P500 futures | ES=F | 2026-04-02 | 6,562 | 6,653.75 | 6,561 | 6,617.25 | 6,888.25 | N/A | https://finance.yahoo.com/quote/ES=F |
| Mini Dow | YM=F | 2026-04-02 | 46,492 | 47,090 | 46,492 | 46,825 | 48,945 | N/A | https://finance.yahoo.com/quote/YM=F |
| Mini NQ100 | NQ=F | 2026-04-02 | 23,889 | 24,348.25 | 23,880 | 24,187.25 | 25,025.25 | N/A | https://finance.yahoo.com/quote/NQ=F |
| Mini S&P500 | MES=F | 2026-04-02 | 6,563 | 6,654.75 | 6,560.75 | 6,617.25 | 6,888.25 | N/A | https://finance.yahoo.com/quote/MES=F |

## 米国/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | ^IXIC | 2026-04-02 | 21,742.79 | 21,983.07 | 21,723.72 | 21,840.95 | 22,668.21 | N/A | https://finance.yahoo.com/quote/^IXIC |
| SOX | ^SOX | 2026-04-02 | 7,680.61 | 7,893.75 | 7,677.54 | 7,802.31 | 8,098.37 | N/A | https://finance.yahoo.com/quote/^SOX |
