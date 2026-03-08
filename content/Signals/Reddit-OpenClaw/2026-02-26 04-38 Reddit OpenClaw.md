---
tags:
  - signals
  - reddit
  - openclaw
created: 2026-02-26 04:38 JST
---

# Reddit Signal — r/OpenClaw

[[Home]]

## Baseline window
- Window: last 7 days (100 recent posts sampled)
- Median upvotes: 1
- 95th percentile: 9.2
- 98th percentile: 71.5
- Dynamic alert threshold used: **>= 71.5 upvotes** (98th percentile, i.e., clearly above normal)

## Unusually high-upvote posts
1. **So true.... Seeing super intelligence in action.**
   - Upvotes: **240**
   - Why unusual: ~34% above the threshold and ~26x the 95th percentile baseline
   - Link: https://reddit.com/r/openclaw/comments/1reb3e6/so_true_seeing_super_intelligence_in_action/
   - Timestamp: 2026-02-26 03:28 JST

2. **SaaS is dead**
   - Upvotes: **192**
   - Why unusual: ~168% above the threshold and ~21x the 95th percentile baseline
   - Link: https://reddit.com/r/openclaw/comments/1re27eg/saas_is_dead/
   - Timestamp: 2026-02-25 19:13 JST

## Notes
- Multiple posts exceeded standard percentile cutoffs due to a low-engagement baseline in this sample.
- To avoid noisy alerts, only extreme outliers (>=98th percentile) were treated as signal-worthy.
