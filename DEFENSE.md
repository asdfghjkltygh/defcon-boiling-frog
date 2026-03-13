# Blue Team Mitigations

If you are defending against the boiling frog extraction attack:

1. **Deploy the DP-Governor** between raw telemetry and your agent's decision logic. This is the only defense that introduces per-probe uncertainty.
2. **Set trigger_persistence >= 5** to absorb noise-induced single-timestep breaches. Individual DP noise spikes above p95 occur ~5% of the time; P(5 consecutive) < 1e-6.
3. **Monitor for repeated near-threshold readings** in your SIEM. Clusters of readings slightly above your scaling threshold are almost certainly probes.
4. **Use burn-in calibration** (first 25% of clean data) to set thresholds without data leakage. The agent should never see future values when calibrating its operating point.
5. **The Goldilocks Zone** for epsilon is 0.5 to 2.0. Below 0.25, the DP noise floor exceeds the clip bounds and the agent becomes blind to real anomalies (FNR=100%). Above 2.0, noise is too low to meaningfully absorb probes.

For the full DP calibration procedure, see the [technical whitepaper](https://github.com/asdfghjkltygh/paranoid-agent/blob/main/whitepaper.pdf).
