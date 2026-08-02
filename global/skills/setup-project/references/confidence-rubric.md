# Confidence rubric

How to turn the `Confianza: NN%` line required by the global instructions into a number that
means something. Read this when a report covers more than a single verified change — a config
proposal, a multi-file plan, or a "work is done" claim with parts you could not execute.

## Why a number at all

Verbalized confidence is the best black-box signal available from a model — better calibrated
than token probabilities or self-consistency sampling — but it is **systematically
overconfident and prompt-sensitive**. It is a trigger for human review, never a measurement.
That is why the rule forbids a bare number: the named cause is the useful part, the percentage
is just its summary.

## Scoring

Start at 100 and subtract. Every deduction must name what caused it.

| Deduction | When |
|---|---|
| −10 to −25 | A claim you did not execute: a documented command you never ran, a path you did not confirm exists, a convention inferred from fewer than 3 samples of real code. Use the top of the range when the claim is load-bearing. |
| −20 | A third-party API, version or signature not confirmed against official docs **in this session** (the `research` skill did not run, or ran on a cached answer). |
| −15 | Conflicting signals resolved without asking — two package managers, two test runners, docs contradicting code. |
| −10 | An architecture principle documented as adopted without spot-checking it against today's code. |
| −10 | Work verified only by a proxy: types compile but no test exercises the change, or only a subset of the suite ran. |

Floors, regardless of arithmetic:

- Any part of the deliverable was **not executed at all** → cap at 75.
- You are reporting someone else's result (a subagent, a cached file) without re-checking it →
  cap at 80.
- Below 70 → say plainly that human review is needed before merging, and say which part to
  review first.

## Writing the line

```
Confianza: 85% — los comandos corrieron aquí, pero la convención de naming viene de
2 archivos de ejemplo y el deploy no se probó.
```

Bad (bare number, no cause): `Confianza: 85%`
Bad (false precision): `Confianza: 87.5%` — the input is a judgement, not a measurement.
Good when everything really ran: `Confianza: 100% — nada sin verificar: los 6 comandos
documentados se ejecutaron y los 4 paths existen.`

## Calibration check

If the number is always 90-95%, the rubric is not biting: either the work genuinely is that
verified (then say what was executed, every time) or the deductions are being skipped. Review
the last few reports against what actually turned out wrong.
