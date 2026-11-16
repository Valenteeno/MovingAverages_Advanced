# MovingAverages_Advanced

Indicator for MetaTrader 5: one moving average with ten methods (Hull, T3, quantile and more), on any timeframe, coloured by trend.

> **Proprietary software.** © Teenodi Ltd. All rights reserved. The code is shared for viewing only. It is not licensed for reuse or redistribution. See [LICENSE](LICENSE).

## What it does

- **Ten methods in one.** Simple, exponential, smoothed, linear weighted, linear regression, triangular, sine weighted, Hull, T3 and quantile. A 50% quantile is the median.
- **Multi-timeframe.** Show the average of a higher timeframe on the current chart. Interpolation keeps the line smooth.
- **Colour by trend.** The line changes colour when it turns up or down.
- **Built to be read by robots.** My Expert Advisors use it as a signal source.

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

## Risk note

Trading carries risk. This code shows how the strategy is built. It is not financial advice.

## License

Proprietary. © Teenodi Ltd. All rights reserved. The code is shared for viewing only. See [LICENSE](LICENSE).
