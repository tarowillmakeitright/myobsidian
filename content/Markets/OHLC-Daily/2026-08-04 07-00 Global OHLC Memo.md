---
tags:
  - markets
  - ohlc
  - futures
  - fx
  - daily
---

# Global OHLC Market Memo

> 取得時点: 2026-08-04 08:20:42 JST  
> 取得成功数: **25/26** / N/A件数: **1**  
> 注意点: Yahoo Financeの日足Chart APIを使用。Close(取得時点)はregularMarketPrice、前日終値は直前の有効な日足Close。状態はYahooのcurrentTradingPeriodから算出（marketState相当）しています。

[[Home]]

## 日本・中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Nikkei/USD Futures | `NKD=F` | 2026-08-03 | 63,550 | 63,635 | 63,550 | 63,580 | 63,330 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF/) |
| Nikkei 225 | `^N225` | 2026-08-03 | 63,834.9492 | 63,905.1211 | 62,703.4688 | 63,754.9 | 64,362.0195 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EN225/) |
| CSI 300 | `000300.SS` | 2026-08-03 | 4,561.8169 | 4,572.5879 | 4,529.186 | 4,543.178 | 4,588.197 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/000300.SS/) |
| 上海総合 | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC/) |

## 米国株価指数・ボラティリティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| NASDAQ | `^IXIC` | 2026-08-03 | 25,452.6621 | 25,967.4414 | 25,420.3516 | 25,913.896 | 25,373.8496 | POST | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC/) |
| SOX | `^SOX` | 2026-08-03 | 11,046.0879 | 11,495.2783 | 10,922.3086 | 11,430.352 | 11,311.0801 | POST | [Yahoo](https://finance.yahoo.com/quote/%5ESOX/) |
| S&P500 Futures | `ES=F` | 2026-08-03 | 7,631 | 7,636.5 | 7,629 | 7,634 | 7,519.25 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/ES%3DF/) |
| Mini Dow | `YM=F` | 2026-08-03 | 53,381 | 53,445 | 53,370 | 53,418 | 52,635 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/YM%3DF/) |
| Mini NQ100 | `NQ=F` | 2026-08-03 | 28,930 | 28,962.25 | 28,919 | 28,938 | 28,404.25 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF/) |
| Mini S&P500 | `MES=F` | 2026-08-03 | 7,630.75 | 7,636.75 | 7,628.75 | 7,634 | 7,519.25 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MES%3DF/) |
| VIX | `^VIX` | 2026-08-03 | 16.03 | 16.3 | 15.54 | 15.86 | 15.99 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EVIX/) |
| Russell 2000 | `^RUT` | 2026-08-03 | 2,935.2625 | 2,985.6802 | 2,935.2625 | 2,981.908 | 2,931.3401 | POST | [Yahoo](https://finance.yahoo.com/quote/%5ERUT/) |

## 欧州株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| FTSE 100 | `^FTSE` | 2026-08-03 | 10,868.0898 | 10,917.4102 | 10,832.5 | 10,857.7 | 10,868.0996 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE/) |
| CAC 40 | `^FCHI` | 2026-08-03 | 8,566.7402 | 8,642.3203 | 8,559.5801 | 8,613.82 | 8,509.6396 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI/) |
| EURO STOXX 50 | `^STOXX50E` | 2026-08-03 | 0 | 0 | 0 | 6,426.5 | 6,358.0098 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E/) |
| DAX | `^GDAXI` | 2026-08-03 | 25,855.1191 | 26,096.9297 | 25,855.1191 | 26,001.31 | 25,629.2402 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI/) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-08-03 | 2,859.27 | 2,863.0601 | 2,853.3799 | 2,857.06 | 2,842.3301 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD/) |

## 貴金属・産業金属・エネルギー

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Gold mini futures | `MGC=F` | 2026-08-03 | 4,109.6001 | 4,111 | 4,104.7002 | 4,106.9 | 4,049.1001 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF/) |
| Silver futures | `SI=F` | 2026-08-03 | 58.38 | 58.44 | 58.21 | 58.31 | 57.591 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/SI%3DF/) |
| Platinum futures | `PL=F` | 2026-08-03 | 1,638.1 | 1,641.1 | 1,636.8 | 1,638.7 | 1,650.3 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PL%3DF/) |
| Palladium futures | `PA=F` | 2026-08-03 | 1,262 | 1,265 | 1,260.5 | 1,263 | 1,275.6 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PA%3DF/) |
| Copper futures | `HG=F` | 2026-08-03 | 6.5395 | 6.549 | 6.5345 | 6.547 | 6.436 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/HG%3DF/) |
| WTI oil futures | `CL=F` | 2026-08-03 | 80.1 | 80.31 | 79.62 | 80.18 | 84.67 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/CL%3DF/) |

## 暗号資産・為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Bitcoin | `BTC-USD` | 2026-08-03 | 63,497.2461 | 64,020.3242 | 62,235.1328 | 63,474.45 | 63,482 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/BTC-USD/) |
| USD/JPY | `JPY=X` | 2026-08-04 | 157.19 | 157.438 | 157.131 | 157.358 | 157.582 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX/) |
| EUR/JPY | `EURJPY=X` | 2026-08-04 | 180.876 | 181.164 | 180.846 | 181.1 | 181.899 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX/) |

## 取得エラー

- `^SSEC: HTTP Error 404: Not Found`
