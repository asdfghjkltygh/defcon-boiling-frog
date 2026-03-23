# Detection Engineering & Infrastructure Hardening

If you are defending against the boiling frog extraction attack:

## SIEM Detection Logic

1. **Alert on repeated near-threshold readings.** Clusters of telemetry values within 2% of your scaling threshold are almost certainly probes. Write a Splunk/Elastic correlation rule that fires when 3+ readings land in this band within a 10-minute window.
2. **Correlate across metrics.** A single CPU spike is noise. CPU + memory + network I/O spiking in lockstep from the same source IP is a coordinated probe. Use cross-metric correlation in your SIEM to catch multi-vector inference attacks.
3. **Monitor for scale-out/scale-in oscillation.** Rapid cycling between scaling states (out, in, out, in) indicates an attacker is binary-searching your boundary. Flag any ASG that oscillates more than 3 times in an hour.

## Infrastructure Hardening (Terraform/CloudFormation)

4. **Deploy the DP-Governor** between raw telemetry and your agent's decision logic. This is the only defense that introduces per-probe uncertainty. Deploy as a CloudWatch Metric Stream filter Lambda that injects calibrated Laplace noise before metrics reach your ASG scaling policy.
5. **Set trigger_persistence >= 5** (consecutive breaches required before scaling). Individual DP noise spikes above p95 occur ~5% of the time; P(5 consecutive) < 1e-6. Configure via `ConsecutiveBreachesBeforeScaling` in your CloudFormation ASG template.
6. **Pin your CloudWatch evaluation periods.** Use 3+ consecutive 1-minute data points before triggering scale-out. This forces attackers to sustain load through the full evaluation window, dramatically increasing their exposure time and detection surface.
7. **The Goldilocks Zone** for epsilon is 0.5 to 2.0. Below 0.25, the DP noise floor exceeds the clip bounds and the agent becomes blind to real anomalies (false-negative rate hits 100%). Above 2.0, noise is too low to meaningfully absorb probes.

   **Streaming composition note:** Each data point participates in W sliding window outputs, so the formal epsilon-DP bound degrades to W * epsilon under basic composition (Dwork et al., 2006). At window=20 and epsilon=1.5, the streaming bound is epsilon=30. In the primary threat model the attacker observes binary scale/no-scale outcomes, not the raw noisy stream, so each probe remains an independent Bernoulli trial with ~17% absorption. If the attacker can observe continuous noisy telemetry (e.g., via a public status page), the streaming bound applies; see evasion vector 4 (Noise Fingerprinting) in the walkthrough.

## Calibration

8. **Use burn-in calibration** (first 25% of clean data) to set thresholds without data leakage. The agent should never see future values when calibrating its operating point.

## Performance

The DP-Governor adds sub-millisecond latency to each telemetry reading (vectorized numpy on typical hardware). This is negligible compared to the 5-second to 5-minute polling intervals used by AWS CloudWatch, Kubernetes HPA, and similar infrastructure agents. SMA and Kalman filters in the same pipeline typically cost 1-15ms for comparison. The trap costs nothing operationally.

Note: CloudWatch Custom Metric Streams (Kinesis Firehose to Lambda to CW Custom Metric) introduce a ~60-120s propagation delay. The ASG will trail live traffic by at least a minute. For the defender, this is acceptable: the DP-Governor's goal is noise injection for probe absorption, not real-time response. The attacker must sustain probes through the full evaluation window regardless of pipeline latency.

Collateral damage to legitimate operations is <0.001% false triggers on stationary traces (EC2 CPU, ELB request count), validated via 100-seed Monte Carlo. Non-stationary traces (RDS CPU) exhibit concept drift that inflates spurious rates across all filter types. Real anomalies are still caught at 100% detection rate.

For the full DP calibration procedure, see the [technical whitepaper](https://github.com/asdfghjkltygh/paranoid-agent/blob/main/whitepaper.pdf).
