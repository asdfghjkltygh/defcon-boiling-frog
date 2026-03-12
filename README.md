# Boiling Frog

**Extracting and Trapping Cloud Auto-Scaler Decision Boundaries**

DEF CON: Supplementary PoC

---

## The Problem

Cloud auto-scalers, SecOps isolation bots, and autonomous SRE agents all make threshold-breach decisions on live telemetry. Every one of them running a deterministic filter (moving averages, Kalman filters, static margins) leaks its exact decision boundary to any attacker who can inject telemetry.

One probe. 100% success rate. Silent.

This is the "boiling frog" attack: slow, controlled probes that map the agent's decision boundary without triggering any alerts. Once the boundary is known, the attacker holds load just below it, preventing scale-out during a real surge, or just above it, burning cloud spend on phantom instances.

## The Catch

A Differential Privacy Governor makes the boundary probabilistic. Your probe succeeds ~83% of the time instead of 100%. The other ~17%? Your injected readings hit the SOC logs while the agent does nothing. You got zero information and burned operational cover.

Five probes to map the boundary. By probe five, there is a >60% chance the SOC is already investigating you.

A wider Kalman margin just moves the finish line. Differential Privacy turns the finish line into a minefield.

---

## Quick Start

```bash
# Install
make install

# Run the full evaluation (6 plots, 2 metric tables, burn rate analysis)
make run

# Run the exploit demo (silent video-friendly, ~2 min)
make demo
```

Requires Python 3.8+ and the packages in `requirements.txt` (numpy, pandas, matplotlib, seaborn, scikit-learn, tabulate).

## Key Numbers

| Metric | Deterministic Filters | DP-Governor |
|--------|----------------------|-------------|
| Probing success | 100% (every time) | 82.6% +/- 10.8% |
| Per-probe burn rate | 0% (undetectable) | 17.4% |
| P(survive 5 probes) | 100% | ~38.5% |
| Spurious triggers | 0% | <0.001% |
| False negatives | 0% | 0% |
| Latency (4032 pts) | SMA: 10.5ms, Kalman: 1.9ms | 0.2ms |

The DP-Governor is faster than the filters it replaces and adds zero collateral damage.

## What the Demo Shows

Six phases from the attacker's perspective:

1. **TARGET ACQUISITION** -- Recon on a cloud auto-scaler's CPU telemetry
2. **EXPLOIT EXECUTION** -- Probe injection at threshold * 1.005
3. **PAYLOAD DELIVERED** -- Boundary fully extracted against all deterministic filters
4. **THE TRAP IS SPRUNG** -- Target activates DP-Governor; exploit starts failing
5. **BURN RATE ANALYSIS** -- 200-probe Monte Carlo: your stealth erodes geometrically
6. **OPERATIONAL ASSESSMENT** -- The trap costs 0.2ms and has zero collateral

## Repository Structure

```
defcon-boiling-frog/
  boiling_frog_exploit.py    Main PoC (~2500 lines)
  requirements.txt           Python dependencies
  Makefile                   install / run / demo / clean
  EXPLOIT_WALKTHROUGH.md     Offensive walkthrough
  defcon_review_prompt.md    DEF CON review criteria
  assets/                    Generated plots and CSVs
  data/                      Downloaded NAB trace cache
```

## Conference Artifacts

- [Exploit Walkthrough](EXPLOIT_WALKTHROUGH.md) -- step-by-step offensive guide
- [Technical Whitepaper (PDF)](https://github.com/asdfghjkltygh/paranoid-agent/blob/main/whitepaper.pdf) -- the underlying stochastic mathematics
- [Video Demo](https://youtu.be/2MHVeOF3rCI) -- terminal recording of the exploit demo

## License

MIT
