# Deep Research V7 — Evaluation Report

## Evaluation Method

Qualitative eval on Claude.ai (no subagent, no benchmark tooling).
Each test case: read SKILL.md → mentally trace the pipeline → assess whether
V7 additions provide clear, actionable guidance at each decision point.

## Meta-Skill Evaluation Framework

Using Pong's 3-dimension framework: Result Determinism, Enabling Guidance, Pitfall Coverage.

---

## Test Case 1: Single-Shot Medium Complexity Research

**Prompt:** "帮我调研一下 2025-2026 年主流 AI Agent 框架的技术选型"

### Pipeline Trace

1. P0: Environment detected (Claude.ai, degraded mode). ✓
2. P0.5: 3-5 sub-questions, multi-domain → Medium. ✓
3. **P0.7 (NEW):** Must build Topic Registry.
   - Lines: 01/langchain, 02/crewai, 03/autogen, 04/dify etc.
   - Each with must_answer Qs, hypothesis, importance.
   - **VERDICT: Clear and actionable.** The format is explicit. ✓
4. P1: Sprint Contract now maps to registry lines + Wave assignment.
   - W0: shared AI Agent framework fundamentals
   - W1: per-framework deep dive
   - **VERDICT: Wave assignment is natural.** ✓
5. P2 Wave 0 → Gate W0 → Wave 1:
   - Wave 0 builds shared ground truth (what IS an agent framework, common patterns)
   - Gate W0 checks before per-framework dives
   - **VERDICT: Prevents the V6 failure mode where subagents each re-discover the same basics.** ✓✓
6. Stop Conditions: 5-point checklist per line.
   - **VERDICT: Very clear.** Much better than V6's implicit "quality-directed stop". ✓✓
7. Wave 2 cross-synthesis: Compare frameworks at mechanism level, not just feature list.
   - **VERDICT: Addresses the V6 gap of producing parallel reports without cross-cutting analysis.** ✓✓
8. Evidence Classification: FACT/ANALYSIS/TREND tags.
   - **VERDICT: Useful for reader trust calibration.** ✓

### Assessment: PASS — all V7 features naturally triggered.

---

## Test Case 2: Progressive Multi-Round Research

**Prompt:** "这是我的 seed 目录，里面有 3 个初步 topic，请做第二轮深挖"

### Pipeline Trace

1. P0.7: Import prior Topic Registry, mark answered Qs, add new Qs. ✓
2. Progressive Protocol: `reference/progressive-protocol.md` gives exact format. ✓
3. Round Initialization Checklist: Read prior summary → identify focus → proceed. ✓
4. Living Docs Update: After completion, seed files get structured append. ✓
5. 30% new evidence threshold: Quality check for progressive rounds. ✓

### Assessment: PASS — progressive mode is well-defined.
**Potential gap:** The skill doesn't specify how to detect progressive mode automatically.
The description triggers ("继续深挖", "第二轮") help, but could be more explicit in P0.

---

## Test Case 3: Low Complexity Quick Research

**Prompt:** "research the current status of WebTransport protocol"

### Pipeline Trace

1. P0.5: 1-2 sub-questions, single domain → Low.
2. P0.7: Still required but can be minimal (1 line). ✓
3. Wave 0: WAVE0_FLOOR = 4 for Lightweight. ✓
4. Wave 2: Skipped. ✓
5. Evaluator: Skipped, self-critique. ✓

### Assessment: PASS — low complexity degrades gracefully.
**Potential gap:** P0.7 adds overhead for simple queries. The skill says "mandatory" —
should there be a bypass for Low complexity with 1 line?

**Decision:** Keep mandatory. 1-line registry is fast and ensures must_answer discipline.

---

## Test Case 4: Evaluator with V7 New Dimensions

**Prompt:** (Internal — evaluator receives a draft)

### Check: Are the 3 new dimensions clearly specified?

1. Stop Condition Audit: Table format, per-line 5-point check. ✓
2. 30-Second Back-Reference: 3-claim trace protocol, explicit steps. ✓
3. Evidence Classification Audit: Spot-check with 20% threshold. ✓

### Assessment: PASS — evaluator prompt is actionable and measurable.

---

## 3-Dimension Meta-Skill Assessment

### 1. Result Determinism (结果确定性)

| Aspect | V6 | V7 | Delta |
|--------|----|----|-------|
| When to stop researching | Implicit (4+ sources OR duplicates) | 5-point checklist + explicit gate | ✓✓ Major improvement |
| What structure the output takes | Fixed report template | Report + registry + _INDEX + cross-synthesis + evidence tags | ✓ More structured |
| How to judge quality | Evaluator 4-dim | Evaluator 7-dim + Readiness Check | ✓✓ |
| Multi-round continuity | Not addressed | Full protocol with seed updates, registry evolution | ✓✓✓ New capability |

**Score: 9/10** (up from 7/10 in V6)

### 2. Enabling Guidance (赋能指导)

| Aspect | V6 | V7 | Delta |
|--------|----|----|-------|
| How to decompose a research question | Group A/B parallel | Topic Registry → Wave 0/1/2 | ✓ More principled |
| How to investigate a topic | Search + fetch + notes | 5-Lens Protocol (evidence/mechanism/trend/difficulty/controversy) | ✓✓ Much richer |
| How to synthesize across topics | Outline only | Wave 2 explicit cross-synthesis | ✓✓ |
| How to classify evidence | Not addressed | FACT/ANALYSIS/TREND with definitions | ✓✓ New capability |

**Score: 9/10** (up from 7/10 in V6)

### 3. Pitfall Coverage (陷阱覆盖)

| Pitfall | V6 Coverage | V7 Coverage |
|---------|------------|------------|
| "Feels done enough" | FFS stop conditions (shallow) | 5-point checklist (deep) ✓✓ |
| Parallel lines re-discover same basics | Implicit | Wave 0 shared ground truth gate ✓✓ |
| Reports are parallel without cross-cutting | Not addressed | Wave 2 mandatory for Medium+ ✓✓ |
| Claims untraceable | Spot-check only | 30-second back-reference + _INDEX ✓✓ |
| Speculation disguised as fact | Not addressed | Evidence classification audit ✓✓ |
| Multi-round knowledge loss | Not addressed | Living Docs + round summaries ✓✓ |
| Padding weak sources to meet quota | Not addressed | Authority-first rule ✓ |

**Score: 9/10** (up from 6/10 in V6)

---

## Summary

| Dimension | V6 | V7 | Change |
|-----------|:--:|:--:|:------:|
| Result Determinism | 7 | 9 | +2 |
| Enabling Guidance | 7 | 9 | +2 |
| Pitfall Coverage | 6 | 9 | +3 |
| **Composite** | **6.7** | **9.0** | **+2.3** |

## Identified Gaps (for future V7.1)

1. **Progressive mode detection**: Could be more explicit in P0 about how to detect whether this is a progressive round vs. single-shot.

2. **Claude.ai degraded mode for Wave 0/1**: The sequential execution of Wave 0 → Gate → Wave 1 is clear, but could add a concrete example of how to "mentally separate" waves in a single conversation.

3. **_INDEX.md maintenance burden**: In degraded mode, generating and maintaining _INDEX.md inline adds overhead. Could note that for Low complexity, _INDEX can be a simple list.

4. **Evidence classification training**: Subagents need to understand the FACT/ANALYSIS/TREND distinction well. Could add more examples to subagent prompt.

## Verdict

**V7 is a significant upgrade.** The 6 new features (Topic Registry, Wave Architecture, Stop Conditions, 30s Back-Reference, Evidence Classification, Living Docs) address real gaps identified from the Progressive Plan Template. The skill remains within the 500-line SKILL.md limit (353 lines) with proper reference delegation.

**Recommendation:** Ship V7. Address gaps 1-4 in V7.1 if they surface in practice.
