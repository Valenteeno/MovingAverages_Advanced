# MovingAverages_Advanced

Advanced multicolor moving-average indicator (multiple MA methods incl. T3 and quantile smoothing). Used as a signal source by EAOne.

> **Proprietary software** — © Teenodi Ltd. All rights reserved. Private repository; not for distribution. See [LICENSE](LICENSE).

## MovingAverages_Advanced.mq5

### Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `TimeFrame` | ENUM_TIMEFRAMES | `PERIOD_CURRENT` | Time frame |
| `Price` | ENUM_APPLIED_PRICE | `PRICE_CLOSE` | Apply to  |
| `AveragePeriod` | int | `14` | Calculation period |
| `AverageType` | enumAveragesType | `0` | Calculation type |
| `_` | string | `""` | T3 parameters (used only if T3 chosen) |
| `T3Hot` | double | `0.7` | T3 hot value |
| `T3Original` | bool | `false` | T3 original Tillson calculation? |
| `__` | string | `""` | Quantile parameters (used only if Quantiles chosen) |
| `QuantPercent` | double | `50.0` | Quantile percent (50 == Median) |
| `Multicolor` | bool | `true` | Multi color mode? |
| `Interpolate` | bool | `true` | Interpolate mtf data ? |

## Archive

Earlier versions / forks are preserved under [`archive/`](archive/) for reference.

## Install

1. Copy the source file(s) into your MetaTrader 5 `MQL5/` tree (`Experts/`, `Indicators/`, or `Scripts/` as appropriate).
2. In MetaEditor, open the file and compile (**F7**).
3. Attach the compiled program to a chart from the terminal Navigator.

## License

Proprietary and confidential. © Teenodi Ltd. All rights reserved. See [LICENSE](LICENSE).
