# Global OHLC Memo (Yahoo Finance)

取得成功数: 25/31、N/A件数: 6。注意点: Yahoo Finance日足(chart)を再取得。429対策でstagger+backoffを適用。
## 日本・米国指数/ボラ
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Nikkei 225 | ^N225 | 2026-05-01 | 59,379.1211 | 59,706.6992 | 59,263.5 | 59,513.1211 | 59,716.18 | N/A | [link](https://finance.yahoo.com/quote/%5EN225) |
| NASDAQ | ^IXIC | 2026-05-01 | 24,977.7891 | 25,223.1191 | 24,967.0898 | 25,114.4395 | 24,836.6 | N/A | [link](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX | ^SOX | 2026-05-01 | 10,388.8203 | 10,624.21 | 10,364.4004 | 10,595.3398 | 10,513.66 | N/A | [link](https://finance.yahoo.com/quote/%5ESOX) |
| Russell 2000 | ^RUT | 2026-05-01 | 2,803.8501 | 2,815.6899 | 2,788.52 | 2,812.8201 | 2,787 | N/A | [link](https://finance.yahoo.com/quote/%5ERUT) |
| VIX | ^VIX | 2026-05-01 | 17.01 | 17.39 | 16.44 | 16.99 | 18.02 | N/A | [link](https://finance.yahoo.com/quote/%5EVIX) |

## 株価指数先物
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-05-01 | 59,845 | 59,930 | 59,120 | 59,445 | 59,160 | N/A | [link](https://finance.yahoo.com/quote/NKD%3DF) |
| S&P500 futures | ES=F | 2026-05-01 | 7,256 | 7,300.75 | 7,240.75 | 7,258 | 7,171 | N/A | [link](https://finance.yahoo.com/quote/ES%3DF) |
| Mini Dow | YM=F | 2026-05-01 | 49,901 | 50,138 | 49,561 | 49,646 | 49,297 | N/A | [link](https://finance.yahoo.com/quote/YM%3DF) |
| Mini NQ100 | NQ=F | 2026-05-01 | 27,631.75 | 27,917 | 27,536.25 | 27,835.75 | 27,168.75 | N/A | [link](https://finance.yahoo.com/quote/NQ%3DF) |
| Mini S&P500 | MES=F | 2026-05-01 | 7,254.75 | 7,300.75 | 7,240.75 | 7,258 | 7,171 | N/A | [link](https://finance.yahoo.com/quote/MES%3DF) |

## コモディティ先物
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-05-01 | 4,636.3999 | 4,672.7998 | 4,570.2998 | 4,644.5 | 4,591.5 | N/A | [link](https://finance.yahoo.com/quote/MGC%3DF) |
| Silver futures | SI=F | 2026-05-01 | 74.315 | 77.525 | 73.435 | 76.431 | 73.205 | N/A | [link](https://finance.yahoo.com/quote/SI%3DF) |
| Platinum futures | PL=F | 2026-05-01 | 1,998.9 | 2,028.7 | 1,962.3 | 2,011.9 | 1,942.3 | N/A | [link](https://finance.yahoo.com/quote/PL%3DF) |
| Palladium futures | PA=F | 2026-05-01 | 1,548.5 | 1,568 | 1,519 | 1,546.1 | 1,461.1 | N/A | [link](https://finance.yahoo.com/quote/PA%3DF) |
| Copper futures | HG=F | 2026-05-01 | 6.027 | 6.04 | 5.9565 | 5.9845 | 5.9145 | N/A | [link](https://finance.yahoo.com/quote/HG%3DF) |
| WTI oil futures | CL=F | 2026-05-01 | 105.14 | 106.65 | 99.3 | 101.94 | 99.93 | N/A | [link](https://finance.yahoo.com/quote/CL%3DF) |

## 中国・欧州指数
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| China market index/futures | 000300.SS | 2026-04-30 | 4,820.9702 | 4,829.27 | 4,797.54 | 4,807.3101 | 4,769.37 | N/A | [link](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [link](https://finance.yahoo.com/quote/%5ESSEC) |
| FTSE 100 | ^FTSE | 2026-05-01 | 10,378.4004 | 10,378.5 | 10,294.2002 | 10,363.9004 | 10,379.1 | N/A | [link](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC 40 | ^FCHI | 2026-04-30 | 7,962.8398 | 8,115.0801 | 7,957.8301 | 8,114.8398 | 8,157.82 | N/A | [link](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-05-01 | 0 | 0 | 0 | 5,881.5098 | 5,883.48 | N/A | [link](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | ^GDAXI | 2026-04-30 | 23,715.7109 | 24,293.1094 | 23,715.7109 | 24,292.3809 | 24,155.45 | N/A | [link](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-05-03 | 2,721.72 | 2,733.99 | 2,717.1101 | 2,729.8799 | 2,692.25 | N/A | [link](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## FX・暗号資産
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-05-01 | 156.562 | 157.326 | 155.453 | 157.033 | 159.576 | N/A | [link](https://finance.yahoo.com/quote/JPY%3DX) |
| EUR/JPY | EURJPY=X | 2026-05-03 | 183.74 | 184.582 | 182.624 | 184.161 | 186.808 | N/A | [link](https://finance.yahoo.com/quote/EURJPY%3DX) |
| Bitcoin | BTC-USD | 2026-05-03 | 78,669.5547 | 79,040.4609 | 78,093.3047 | 78,770.2891 | 75,776.13 | N/A | [link](https://finance.yahoo.com/quote/BTC-USD) |

#markets #ohlc #futures #fx #daily

[[Home]]
