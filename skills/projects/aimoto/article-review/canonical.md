# article-review

Analyze an external article/technique and compare with aimoto's approach. Updates TECHNIQUES-REGISTRY.md.

## Context

### Project Summary
**aimoto-v2** : Bitcoin daily price forecasting (7-day horizon) via LightGBM quantile regression.

**Best Config (P41-B03)** : +13.26% skill vs random walk
- Model: LightGBM with 5-seed bagging
- Features: 19 total (14 technical + 4 macro + 1 on-chain, derived)
- Validation: Walk-forward (13 monthly cutoffs, 2024-06 to 2025-06, wf_window=240d)
- Clipping: Regime-conditional (bull=2.0, bear=0.5, range=1.0)
- Decay: 2.0 (recent data prioritized)

**Key Results** :
- LightGBM > XGBoost (P25: XGBoost -21.1%), > LSTM, > ensembles
- Ensembles all FAIL (P15: -25%, P41-A: -0.26 to -0.64%, P45: -18.66%)
- Best features: implied_volatility_btc (+2.64%), decay=2.0 (+2.96%), chop_14 (+1.24%), sopr (+0.66%), us_m2 (+0.38%)
- Eliminated: XGBoost, Chronos, foundation models, multi-model ensembles, on-chain (nupl, mvrv, cdd), feature lags/deltas, LSTM

## Instructions

### Input
User provides one of:
1. Article text or link about a ML/trading technique
2. Case study or research paper
3. Request to historize techniques from conversation

### Analysis Process

**1. Extract Claims**
For the article/technique, identify:
- What's being predicted (price direction? magnitude? volatility?)
- Model type(s) used
- Features/data sources
- Validation method (walk-forward? train/test split? backtest?)
- Results reported (accuracy? Sharpe? skill vs random walk?)

**2. Evaluate**
- Is methodology sound? (walk-forward = best, train/test split = risky, backtest = suspect)
- Is it already tested in aimoto? (check TECHNIQUES-REGISTRY.md)
- Is signal orthogonal? (new source vs redundant with existing features?)
- Effort to test? (config-only = easy, new model = hard)

**3. Compare with Aimoto**
Create comparison table:
| Dimension | Article | Aimoto P41-B03 | Difference |
|-----------|---------|---|---|
| Model | [e.g., LSTM] | LightGBM quantile | [e.g., GB > LSTM confirmed] |
| Validation | [e.g., backtest] | Walk-forward 13 cutoffs | [e.g., aimoto more rigorous] |
| Features | [e.g., 25 basic indicators] | 19 optimized (technical+macro+on-chain) | [e.g., aimoto more sophisticated] |
| Results | [e.g., Sharpe 1.87] | +13.26% skill vs RW | [not directly comparable] |

**4. Historize**
Add entry to `docs/audits/TECHNIQUES-REGISTRY.md` in appropriate section:

```
| [Phase/STUDIED] | [Technique name] | [✅/❌/⚠️/🔍] | [Delta%] | [1-2 line reasoning] | [Status] |
```

Use verdicts:
- ✅ PASS = improves skill (integrated or candidate)
- ❌ FAIL = degrades skill (eliminate)
- ⚠️ NEUTRAL = 0% gain (eliminate or low priority)
- 🔍 STUDIED = analyzed but not tested (candidate or not feasible)

### Output Format

```
## Analysis: [Article Title]

**Source**: [Link], [Date]

### Claims Extracted
1. [Claim] — Verdict: [✅/⚠️/❌/❓]
2. [Claim] — Verdict: [✅/⚠️/❌/❓]

### Comparison with Aimoto P41-B03
[Table]

### Techniques Found
- **[Technique 1]** — Already tested? [Yes/No]. Orthogonal? [Yes/No]. Actionable? [Yes/No]
  - Status: [INTEGRATED/ELIMINATED/CANDIDATE/NOT_TESTED/NOT_FEASIBLE]
  - Reasoning: [1 line]

### Conclusions
- [Insight 1]
- [Insight 2]

### Action
- [ ] Update TECHNIQUES-REGISTRY.md with entry
- [ ] Next step: [propose campaign or archive]
```

### Files to Update
- `docs/audits/TECHNIQUES-REGISTRY.md` — Add row(s) to appropriate section based on verdict

### Files NOT to Update
- Do NOT create new research notes (keep single registry file)
- Do NOT create new spec files
- Do NOT auto-commit

## References
- @CLAUDE.md — Project conventions
- @docs/ARCHITECTURE.md — System invariants
- @docs/audits/TECHNIQUES-REGISTRY.md — Historic registry (check before adding)
