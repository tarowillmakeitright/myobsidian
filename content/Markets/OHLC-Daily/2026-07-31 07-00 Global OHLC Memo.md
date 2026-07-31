---
tags:
  - markets
  - ohlc
  - futures
  - fx
  - daily
---

# Global OHLC Memo — 2026-07-31 07:00 JST

[[Home]]

取得成功 **25/26銘柄**、OHLC取得不可（N/A） **1件**。Yahoo Finance Chart APIを2026-07-31 06:40 JST頃に直接参照。`marketState` は同API応答に含まれなかったため全銘柄N/A。`Close(取得時点)` は最新日足のclose（未確定の日経225のみYahooのregularMarketPrice）であり、確定終値とは限らない。上海総合（`^SSEC`）はYahoo APIが404を返した。

## 日本・中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-07-30 | 61,190.00 | 63,910.00 | 61,190.00 | 63,720.00 | 61,345.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF/) |
| Nikkei 225 | ^N225 | 2026-07-30 | 61,258.34 | 62,924.84 | 61,049.70 | 61,867.43 | 61,434.19 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225/) |
| CSI 300 | 000300.SS | 2026-07-30 | 4,566.05 | 4,596.21 | 4,478.21 | 4,549.72 | 4,600.26 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS/) |
| Shanghai Composite | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC/) |

## 貴金属・商品

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-07-30 | 4,126.50 | 4,180.20 | 4,084.60 | 4,162.30 | 4,036.30 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF/) |
| Silver futures | SI=F | 2026-07-30 | 57.9750 | 59.5700 | 57.1200 | 59.2650 | 57.8630 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI%3DF/) |
| Platinum futures | PL=F | 2026-07-30 | 1,616.60 | 1,673.60 | 1,589.30 | 1,669.50 | 1,590.10 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL%3DF/) |
| Palladium futures | PA=F | 2026-07-30 | 1,266.50 | 1,322.00 | 1,243.50 | 1,321.50 | 1,245.70 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA%3DF/) |
| Copper futures | HG=F | 2026-07-30 | 6.3495 | 6.5085 | 6.3400 | 6.5005 | 6.2735 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG%3DF/) |
| WTI oil futures | CL=F | 2026-07-30 | 84.65 | 85.94 | 82.97 | 83.96 | 84.46 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL%3DF/) |

## 米国株価指数・先物・暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ Composite | ^IXIC | 2026-07-30 | 24,852.05 | 25,171.44 | 24,813.84 | 25,122.18 | 24,442.94 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC/) |
| Philadelphia Semiconductor | ^SOX | 2026-07-30 | 11,085.96 | 11,406.82 | 10,963.90 | 11,302.99 | 10,447.49 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX/) |
| S&P 500 futures | ES=F | 2026-07-30 | 7,338.00 | 7,498.00 | 7,331.00 | 7,474.50 | 7,351.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES%3DF/) |
| Mini Dow | YM=F | 2026-07-30 | 51,759.00 | 52,484.00 | 51,732.00 | 52,427.00 | 51,765.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM%3DF/) |
| Mini NQ100 | NQ=F | 2026-07-30 | 27,202.00 | 28,414.50 | 27,202.00 | 28,333.50 | 27,342.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF/) |
| Mini S&P 500 | MES=F | 2026-07-30 | 7,335.50 | 7,498.00 | 7,330.75 | 7,474.50 | 7,351.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES%3DF/) |
| VIX | ^VIX | 2026-07-30 | 19.56 | 20.08 | 17.00 | 17.09 | 20.66 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX/) |
| Bitcoin / USD | BTC-USD | 2026-07-30 | 63,902.90 | 65,038.38 | 63,547.79 | 64,723.27 | 63,908.17 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD/) |
| Russell 2000 | ^RUT | 2026-07-30 | 2,918.86 | 2,948.41 | 2,912.19 | 2,946.10 | 2,906.31 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT/) |

## 欧州株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | ^FTSE | 2026-07-30 | 10,907.37 | 10,979.60 | 10,865.37 | 10,897.27 | 10,908.40 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE/) |
| CAC 40 | ^FCHI | 2026-07-30 | 8,410.33 | 8,515.36 | 8,409.89 | 8,485.64 | 8,408.27 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI/) |
| EURO STOXX 50 | ^STOXX50E | 2026-07-30 | 6,245.30 | 6,356.31 | 6,245.30 | 6,344.40 | 6,248.84 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E/) |
| DAX | ^GDAXI | 2026-07-30 | 25,487.45 | 25,651.16 | 25,303.11 | 25,612.03 | 25,460.48 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI/) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-07-30 | 2,803.65 | 2,855.64 | 2,803.65 | 2,845.75 | 2,793.74 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD/) |

## FX

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-07-30 | 163.3980 | 163.7390 | 157.9230 | 159.5650 | 163.3000 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX/) |
| EUR/JPY | EURJPY=X | 2026-07-30 | 187.2640 | 187.4400 | 182.0440 | 183.8440 | 187.2540 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX/) |

> データ取得元: Yahoo Finance Chart API (`query1.finance.yahoo.com/v8/finance/chart/…`)。数値はYahoo Finance提供値で、取引所公式値との差異・遅延があり得ます。
