# Bibliography

## Differential Privacy Foundations

1. C. Dwork, F. McSherry, K. Nissim, and A. Smith, "Calibrating Noise
   to Sensitivity in Private Data Analysis," TCC 2006.
   https://doi.org/10.1007/11681878_14
   Laplace mechanism, sensitivity calibration, composition theorems.
   Used for the DP-Governor's single-metric noise injection.

2. M. Abadi, A. Chu, I. Goodfellow, H.B. McMahan, I. Mironov,
   K. Talwar, and L. Zhang, "Deep Learning with Differential Privacy,"
   CCS 2016.
   https://doi.org/10.1145/2976749.2978318
   Gaussian mechanism with L2-norm clipping. Used for the
   cross-correlated multivariate DP-Governor.

## Datasets

3. A. Lavin and S. Ahmad, "Evaluating Real-Time Anomaly Detection
   Algorithms -- the Numenta Anomaly Benchmark," IEEE ICMLA 2015.
   https://doi.org/10.1109/ICMLA.2015.141
   https://github.com/numenta/NAB
   EC2 CPU utilization, RDS CPU, ELB request count traces used as
   realistic auto-scaler telemetry.

4. Y. Su, Y. Zhao, C. Niu, R. Liu, W. Sun, and D. Pei, "Robust
   Anomaly Detection for Multivariate Time Series through Stochastic
   Recurrent Neural Network," KDD 2019.
   https://doi.org/10.1145/3292500.3330672
   https://github.com/NetManAIOps/OmniAnomaly
   Server Machine Dataset (SMD). Natively correlated 38-feature
   server telemetry from machine-1-1 used for multivariate evaluation.

## Cloud Auto-Scaling Architecture

5. AWS, "Amazon EC2 Auto Scaling Target Tracking Scaling Policies."
   https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html
   Documents deterministic CloudWatch alarm evaluation that the
   extraction attack targets.

6. Kubernetes, "Horizontal Pod Autoscaler," Kubernetes Documentation.
   https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
   Documents the HPA controller's deterministic ratio-based scaling
   algorithm.

## Related Offensive Tools

7. Rhino Security Labs, "Pacu -- The AWS Exploitation Framework."
   https://github.com/RhinoSecurityLabs/pacu

8. DataDog, "Stratus Red Team -- Granular, Actionable Adversary
   Emulation for the Cloud."
   https://github.com/DataDog/stratus-red-team

## Adversarial ML (Related but Distinct)

9. A. Kurakin, I. Goodfellow, and S. Bengio, "Adversarial examples
   in the physical world," ICLR 2017.
   https://arxiv.org/abs/1607.02533
   Adversarial perturbations against classifiers. Related threat
   model but targets classification, not threshold extraction.

10. N. Carlini and D. Wagner, "Towards Evaluating the Robustness of
    Neural Networks," IEEE S&P 2017.
    https://doi.org/10.1109/SP.2017.49
    L2/L-inf adversarial attacks. Establishes that deterministic
    decision boundaries are extractable, which we extend to
    infrastructure agents.

## Visualization

11. B. Wong, "Points of view: Color blindness," Nature Methods 8, 441
    (2011). https://doi.org/10.1038/nmeth.1618
    Colorblind-safe palette used in all evaluation plots.
