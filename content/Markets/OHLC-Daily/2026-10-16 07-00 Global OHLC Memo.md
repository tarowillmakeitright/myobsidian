---
tags:
  - markets
  - ohlc
  - futures
  - fx
  - daily
---

# Global OHLC Memo — 2026-10-16 07:00 JST

> **取得結果:** 成功 25/26件 / N/A 1件  
> **注意点:** Yahoo Financeの日足Chart APIを取得時点で参照。Close(取得時点)は当日足のcloseが未確定の場合、regularMarketPriceを使用。marketStateはChart APIで提供されない場合N/A。先物・暗号資産・海外市場は取引所タイムゾーン基準日のため、JST日付と異なることがあります。

#markets #ohlc #futures #fx #daily

[[Home]]

## 日本・中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | `NKD=F` | 2026-10-15 | 66,520 | 66,560 | 64,235 | 65,640 | 66,775 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF) |
| Nikkei 225 | `^N225` | 2026-10-15 | 66,880.367188 | 66,929.296875 | 64,092.738281 | 64,425.95 | 67,744.289062 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225) |
| China market index/futures | `000300.SS` | 2026-10-15 | 4,145.947266 | 4,176.094727 | 4,115.071777 | 4,166.012207 | 4,217.68 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC) |

## 米国株価指数・ボラティリティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | `^IXIC` | 2026-10-15 | 26,380.773438 | 26,754.015625 | 26,308.845703 | 26,713.025391 | 26,692.869141 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX | `^SOX` | 2026-10-15 | 11,280.888672 | 11,620.135742 | 11,171.53418 | 11,581.214844 | 11,684.379883 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX) |
| S&P500 futures | `ES=F` | 2026-10-15 | 7,768.25 | 7,801.75 | 7,717.25 | 7,786 | 7,770.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES%3DF) |
| Mini Dow | `YM=F` | 2026-10-15 | 51,859 | 52,503 | 51,783 | 52,438 | 51,858 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM%3DF) |
| Mini NQ100 | `NQ=F` | 2026-10-15 | 30,154.75 | 30,196.75 | 29,622.5 | 30,078.25 | 30,182.75 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF) |
| Mini S&P500 | `MES=F` | 2026-10-15 | 7,768.25 | 7,801.75 | 7,717.25 | 7,786.25 | 7,770.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES%3DF) |
| VIX | `^VIX` | 2026-10-15 | 17.549999 | 18.01 | 16.34 | 16.459999 | 16.870001 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX) |
| Russell 2000 | `^RUT` | 2026-10-15 | 2,730.452393 | 2,768.018066 | 2,725.057129 | 2,767.269287 | 2,729.530029 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT) |

## 欧州株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | `^FTSE` | 2026-10-15 | 10,723.370117 | 10,868.530273 | 10,695.839844 | 10,840.349609 | 10,724.900391 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC 40 | `^FCHI` | 2026-10-15 | 7,853.399902 | 7,937.290039 | 7,853.399902 | 7,934.700195 | 7,873.109863 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | `^STOXX50E` | 2026-10-15 | 6,170.700195 | 6,175.919922 | 6,119.490234 | 6,168.259766 | 6,190.370117 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | `^GDAXI` | 2026-10-15 | 25,145.070312 | 25,420.619141 | 25,133.710938 | 25,382.619141 | 25,298.609375 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-10-15 | 2,717.570068 | 2,737.909912 | 2,709.379883 | 2,733.070068 | 2,702.340088 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## 貴金属・商品

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | `MGC=F` | 2026-10-15 | 4,128 | 4,197.700195 | 4,120.899902 | 4,192.899902 | 4,084.800049 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF) |
| Silver futures | `SI=F` | 2026-10-15 | 55.799999 | 57.689999 | 55.619999 | 57.605 | 55.549999 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI%3DF) |
| Platinum futures | `PL=F` | 2026-10-15 | 1,605.099976 | 1,639.199951 | 1,603 | 1,635.400024 | 1,601.300049 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL%3DF) |
| Palladium futures | `PA=F` | 2026-10-15 | 1,096.5 | 1,140 | 1,096.5 | 1,136 | 1,087.099976 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA%3DF) |
| Copper futures | `HG=F` | 2026-10-15 | 6.633 | 6.638 | 6.5245 | 6.5625 | 6.6115 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG%3DF) |
| WTI oil futures | `CL=F` | 2026-10-15 | 95.190002 | 96.739998 | 92.459999 | 96.120003 | 95.089996 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL%3DF) |

## 暗号資産・為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | `BTC-USD` | 2026-10-15 | 81,573.101562 | 82,496.742188 | 79,789.359375 | 82,225.867188 | 81,562.492188 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |
| USD/JPY | `JPY=X` | 2026-10-15 | 158.298996 | 158.330994 | 157.544006 | 157.977005 | 157.957001 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX) |
| EUR/JPY | `EURJPY=X` | 2026-10-15 | 176.494995 | 177.412003 | 176.488007 | 177.149002 | 176.828003 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX) |

## 取得エラー

- `^SSEC` (HTTPError)
