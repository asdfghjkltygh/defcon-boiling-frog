# Boiling Frog

**Extracting Cloud Auto-Scaler Decision Boundaries**

DEF CON 33 // Tool Release

---

## The Attack

Every cloud auto-scaler, every Kubernetes HPA, every Datadog monitor running a deterministic filter is leaking its decision boundary to you right now.

One probe at threshold x 1.005. The filter produces the same output every time. You extract the boundary, hold load just below it during a real surge, and watch their infrastructure choke. Or hold it just above and bleed their cloud bill on phantom instances.

This is the boiling frog attack. It works against every SMA, every Kalman filter, every static margin. 100% success rate. Zero detection risk. Silent.

## What's Vulnerable

Any system that makes a threshold-breach decision on deterministic-filtered telemetry. Concretely:

- **AWS Auto Scaling Groups** with CloudWatch CPU alarms (the default). `PutMetricData` lets you inject custom metrics. The alarm evaluates a static threshold over a fixed number of periods. One probe maps the boundary.
- **Kubernetes HPA** using `metrics-server` CPU/memory targets. The HPA controller compares current vs. desired utilization using a simple ratio. Deterministic. Extractable.
- **Datadog Monitors** with threshold alerts on any metric. Query, compare, alert. No noise in the pipeline.
- **Prometheus Alertmanager** with PromQL threshold rules. `avg_over_time(cpu_usage[5m]) > 0.8` is deterministic, same input same output.
- **PagerDuty** threshold-based event rules. Deterministic evaluation, no jitter.

If the filter between raw telemetry and the decision is `f(x) = f(x)` every time, you can extract the boundary. That's all of them.

## What Exists Today

Cloud red team tools (Pacu, Stratus Red Team) focus on IAM misconfigurations, credential theft, and service exploitation. Nobody is targeting the decision logic of autonomous infrastructure agents. The auto-scaler's threshold isn't a config you can read from an API; it's an emergent property of the filter pipeline. There's no `aws autoscaling describe-threshold` command.

This is a new attack surface: the telemetry-to-decision pipeline itself. The tool extracts information that doesn't exist in any config file, any API response, any IAM policy.

---

## Quick Start

```bash
# Install
make install

# Run the exploit demo (~2 min, terminal-friendly)
make demo

# Run the full evaluation (6 plots, 2 metric tables, burn rate analysis)
make run
```

Requires Python 3.8+ and the packages in `requirements.txt` (numpy, pandas, matplotlib, seaborn, scikit-learn, tabulate).

## Key Numbers

| Metric | Deterministic Filters | With DP-Governor Trap |
|--------|----------------------|----------------------|
| Probing success | 100% (every time) | 82.6% +/- 10.8% |
| Per-probe burn rate | 0% (undetectable) | 17.4% |
| P(survive 5 probes) | 100% | ~38.5% |
| Spurious triggers | 0% | <0.001% |
| False negatives | 0% | 0% |

## What the Demo Shows

Six phases from the attacker's perspective:

1. **TARGET ACQUISITION** -- Recon on an AWS Auto Scaling Group's CPU telemetry
2. **EXPLOIT EXECUTION** -- Probe injection at threshold x 1.005
3. **PAYLOAD DELIVERED** -- Boundary fully extracted against all deterministic filters
4. **THE TRAP IS SPRUNG** -- Target activates DP-Governor; exploit starts failing
5. **BURN RATE ANALYSIS** -- 200-probe Monte Carlo: your stealth erodes geometrically
6. **OPERATIONAL ASSESSMENT** -- The trap adds sub-millisecond latency and zero collateral

## The Trap (For the Math Nerds)

A Differential Privacy Governor makes the boundary probabilistic. Your probe succeeds ~83% of the time instead of 100%. The other ~17%? Your injected readings hit the SOC logs while the agent does nothing. You got zero information and burned operational cover.

Five probes to map the boundary. By probe five, there is a >60% chance the SOC is already investigating you. A wider Kalman margin just moves the finish line. Differential Privacy turns the finish line into a minefield.

## Repository Structure

```
defcon-boiling-frog/
  boiling_frog_exploit.py    Main PoC (~2500 lines)
  requirements.txt           Python dependencies
  Makefile                   install / run / demo / clean
  EXPLOIT_WALKTHROUGH.md     Offensive walkthrough
  DEFENSE.md                 Blue team mitigations
  assets/                    Generated plots and CSVs
  data/                      Downloaded NAB trace cache
```

## Conference Artifacts

- [Exploit Walkthrough](EXPLOIT_WALKTHROUGH.md) -- step-by-step offensive guide
- [Video Demo](https://youtu.be/2MHVeOF3rCI) -- terminal recording of the exploit demo
- [Formal Proofs (PDF)](https://github.com/asdfghjkltygh/paranoid-agent/blob/main/whitepaper.pdf) -- for the math nerds

## Why This Matters

A compromised auto-scaler threshold means the attacker controls when your infrastructure scales. Hold load at threshold - 0.1% during a traffic surge: your users get 503s while the scaler does nothing. Hold it at threshold + 0.1% during off-peak: you're paying for phantom instances 24/7. The attacker extracts the boundary with a single silent probe, and your deterministic filter gives them the same answer every time they ask.

There is no log entry. There is no alert. The filter worked exactly as designed.

## Limitations

- **Requires telemetry injection.** If the attacker can't influence the metric the agent reads (e.g., no `PutMetricData` access, no ability to generate load), the attack doesn't apply.
- **Assumes deterministic filter pipeline.** Systems that already add random jitter to scaling decisions (rare in production, but they exist) are partially resistant.
- **Sub-millisecond systems are out of scope.** HFT engines and inline packet inspectors operate on timescales where even 0.2ms matters. This targets infrastructure agents with 5s to 5min polling intervals.
- **Multi-variate cross-correlation.** If the target monitors multiple correlated metrics simultaneously, injecting a probe on one metric without matching the others could be detectable.

## License

MIT
