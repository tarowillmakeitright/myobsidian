# Global OHLC Memo

- 取得成功数: 25 / 26
- N/A件数: 1
- 注意点: Yahoo Finance再取得を実施（stagger/backoff）。再試行 4 回、429発生 0 回。

#markets #ohlc #futures #fx #daily
[[Home]]

## 日本株/先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 日経USD先物 | NKD=F | 2026-04-27 | 60,065 | 61,000 | 59,700 | 60,225 | 58,520 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD=F) |

## 日本株/指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 日経平均 | ^N225 | 2026-04-24 | 59,407.4414 | 59,763.6797 | 59,225.3711 | 59,716.1797 | 58,824.89 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225) |

## 米国株/指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ総合 | ^IXIC | 2026-04-27 | 24,799.6367 | 24,899.3652 | 24,694.8242 | 24,887.0996 | 24,468.48 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX指数 | ^SOX | 2026-04-27 | 10,533.3213 | 10,536.8574 | 10,251.7324 | 10,408.0381 | 9,555.88 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX) |
| VIX指数 | ^VIX | 2026-04-27 | 19.21 | 19.27 | 18.02 | 18.02 | 18.87 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX) |
| ラッセル2000 | ^RUT | 2026-04-27 | 2,788.6187 | 2,796.7417 | 2,781.4958 | 2,788.1895 | 2,776.9 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT) |

## 米国株/先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| S&P500先物 | ES=F | 2026-04-27 | 7,185 | 7,211.25 | 7,171.5 | 7,205.25 | 7,100 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES=F) |
| ミニ・ダウ先物 | YM=F | 2026-04-27 | 49,382 | 49,522 | 49,190 | 49,345 | 49,339 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM=F) |
| ミニNASDAQ100先物 | NQ=F | 2026-04-27 | 27,403.25 | 27,542.5 | 27,298.5 | 27,418.5 | 26,634.75 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ=F) |
| マイクロS&P500先物 | MES=F | 2026-04-27 | 7,185 | 7,211.5 | 7,171.25 | 7,205.25 | 7,100 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES=F) |

## 中国株/指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| CSI300 | 000300.SS | 2026-04-24 | 4,771.7402 | 4,786.4399 | 4,735.6099 | 4,769.3701 | 4,757.44 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| 上海総合 | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC) |

## 欧州株/指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE100 | ^FTSE | 2026-04-27 | 10,378.5303 | 10,410.79 | 10,318.3203 | 10,321.0898 | 10,667.6 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC40 | ^FCHI | 2026-04-27 | 8,160.1802 | 8,214.6299 | 8,127.8301 | 8,141.9199 | 8,331.05 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-04-27 | 0 | 0 | 0 | 5,860.3198 | 5,982.63 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | ^GDAXI | 2026-04-27 | 24,196.4297 | 24,382.3203 | 24,049.4395 | 24,083.5293 | 24,702.24 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-04-27 | 2,720.3401 | 2,737.6599 | 2,708.04 | 2,712.48 | 2,747.69 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 金ミニ先物 | MGC=F | 2026-04-27 | 4,717.7998 | 4,745.7998 | 4,681.6001 | 4,697.8999 | 4,698.4 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC=F) |
| 銀先物 | SI=F | 2026-04-27 | 75.5 | 76.555 | 74.59 | 75.46 | 76.411 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI=F) |
| プラチナ先物 | PL=F | 2026-04-27 | 2,015.9 | 2,041.7 | 1,984.6 | 1,993.1 | 2,024.3 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL=F) |
| パラジウム先物 | PA=F | 2026-04-27 | 1,500 | 1,510.5 | 1,474 | 1,479.5 | 1,531.7 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA=F) |
| 銅先物 | HG=F | 2026-04-27 | 6.032 | 6.137 | 6.05 | 6.087 | 6.002 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG=F) |
| WTI原油先物 | CL=F | 2026-04-27 | 95.6 | 97.67 | 94.59 | 96.68 | 92.13 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL=F) |

## FX

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-04-27 | 159.402 | 159.402 | 159.367 | 159.4 | 159.161 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | EURJPY=X | 2026-04-27 | 186.793 | 186.856 | 186.754 | 186.79 | 186.844 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY=X) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| ビットコイン | BTC-USD | 2026-04-27 | 78,670.8516 | 79,420.2734 | 76,579.7891 | 76,837.7188 | 78,203.1 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 補足
- 未取得: ^SSEC: 404 Client Error: Not Found for url: https://query1.finance.yahoo.com/v8/finance/chart/%5ESSEC?interval=1d&range=6d&includePrePost=true&events=div%2Csplits
