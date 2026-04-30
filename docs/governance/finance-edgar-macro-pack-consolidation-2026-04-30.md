# Finance-EDGAR-Macro Pack Consolidation

Date: 2026-04-30

## Conclusion

`finance-edgar-macro` remains a 7-owner direct routing pack with no stage assistants.

This pass hardens route boundaries for EDGAR/SEC filings, Alpha Vantage market prices, FRED macro time series, U.S. Treasury Fiscal Data, OFR Hedge Fund Monitor, market research reports, and Data Commons statistical graph queries.

This pass does not physically delete any of the 7 retained skill directories.

## Direct Owners

| Problem ID | User Task Boundary | Direct Owner |
|---|---|---|
| `sec_filing_analysis` | EDGAR, SEC filing, 10-K, 10-Q, 8-K, 13F, XBRL, listed-company disclosure, financial statement extraction | `edgartools` |
| `market_price_data` | Alpha Vantage, stock price, OHLCV, technical indicators, intraday/daily price CSV | `alpha-vantage` |
| `macro_timeseries` | FRED, Federal Reserve Economic Data, CPI, PCE, GDP, unemployment, Fed funds rate | `fred-economic-data` |
| `us_treasury_fiscal_data` | U.S. Treasury Fiscal Data, national debt, federal spending, deficit, Treasury securities | `usfiscaldata` |
| `hedge_fund_monitoring` | OFR Hedge Fund Monitor and Form PF aggregate statistics | `hedgefundmonitor` |
| `market_research_report` | Market research report, industry report, competitive analysis, consulting-style strategic report | `market-research-reports` |
| `datacommons_statistical_graph` | Data Commons/datacommons, public statistical data, statistical variables, population/economic indicators | `datacommons-client` |

## Simplified Routing State

```text
candidate skill -> selected skill -> used / unused
```

No extra routing state was added:

```text
stage_assistant_candidates = 0
advisory / consultation state = not used
primary / secondary skill hierarchy = not used
```

## Boundary Fixes

### Data Commons

`datacommons-client` no longer uses standalone `public data`, `open data`, `公共数据`, or `开放数据` as strong keyword-index triggers.

Generic public/open dataset search is not enough to select this skill. The route now needs Data Commons/datacommons, public statistical data, statistical variables, or population/economic indicator context.

### Market Research Reports

`market-research-reports` is limited to market/industry/competitive/consulting-style strategy reports.

It should not own scientific reports, paper writing, LaTeX manuscript construction, submission PDF builds, PubMed evidence tables, ClinicalTrials.gov lookups, EDGAR/FRED/Treasury/Data Commons retrieval, or generic PDF/document tasks.

### FRED vs Treasury Fiscal Data

`fred-economic-data` owns FRED/Federal Reserve Economic Data macro time series.

`usfiscaldata` owns U.S. Treasury Fiscal Data, national debt, federal spending, deficit, and Treasury securities.

Explicit FRED prompts must not select `usfiscaldata`; explicit Treasury Fiscal Data prompts must not select `fred-economic-data`.

### SEC 13F vs OFR Monitor

SEC 13F holdings stay under `edgartools`.

OFR Hedge Fund Monitor and Form PF aggregate statistics stay under `hedgefundmonitor`.

## Verification Results

Run after implementation:

```powershell
python -m pytest tests/runtime_neutral/test_finance_edgar_macro_pack_consolidation.py -q
.\scripts\verify\probe-scientific-packs.ps1
.\scripts\verify\vibe-skill-index-routing-audit.ps1
.\scripts\verify\vibe-pack-regression-matrix.ps1
.\scripts\verify\vibe-pack-routing-smoke.ps1
.\scripts\verify\vibe-offline-skills-gate.ps1
git diff --check
```

Record exact pass counts and any important route snippets here before the final commit.

## Evidence Boundary

This governance note proves routing configuration, bundled skill documentation, tests, and verification scripts were consolidated.

It does not prove that these skills were materially used in a real Vibe task. Material use still requires task-run artifacts such as specialist execution records, produced files, scripts, logs, figures, reports, or final deliverables.
