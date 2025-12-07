 (cd "$(git rev-parse --show-toplevel)" && git apply --3way <<'EOF' 
diff --git a/README.md b/README.md
new file mode 100644
index 0000000000000000000000000000000000000000..4bd5abd58effed7976636541dd0084907454c3cd
--- /dev/null
+++ b/README.md
@@ -0,0 +1,46 @@
+# Agent-Based Market Simulation Scripts
+
+This repository contains MATLAB scripts for exploring how different behavioral and market parameters influence outcomes in an agent-based stock-trading simulation. Each script tweaks a specific variable and visualizes the resulting wealth distribution or price dynamics.
+
+## Common model assumptions
+
+Most scripts share the following structure:
+
+- **Population setup:** 10,000 agents start with heavy-tailed initial wealth sampled with scale `A = 1000` and tail parameter `alpha = 2`.
+- **Trading behavior:** Agents open or close long/short positions based on price-momentum signals plus budget-dependent noise. Profit and loss thresholds introduce risk management, and a per-step `trade_prob` controls whether an agent follows a signal.
+- **Risk sizing:** The `Risk_fraction` parameter scales how much of an agent's budget can be deployed per trade; some experiments segment agents into groups with different risk appetites.
+- **Price dynamics:** The stock price follows a geometric Brownian motion with drift `mu`, volatility `sigma`, and an additive influence term driven by the net trading direction.
+- **Outputs:** Simulations record price paths, per-agent wealth over time, and summary statistics (e.g., mean wealth, top/bottom deciles). Many scripts produce error-bar plots across repeated runs.
+
+## Script guide
+
+### `NMsim2_influencefactor1.m`
+Runs a single simulation while enabling an additive price influence term derived from recent trading direction. Records initial/final mean wealth and price in `simInfluence.xlsx`, plots the price path, and prints the average starting wealth. Intended as a baseline run with trading influence active.【F:NMsim2_influencefactor1.m†L1-L111】【F:NMsim2_influencefactor1.m†L114-L146】
+
+### `Noiseerrorbar.m`
+Sweeps noise levels from 0 to 1 in 0.1 increments to study how stronger signal noise for low-budget agents affects mean final wealth. For each noise level, it runs 20 simulations, aggregates the final mean wealth, and plots mean ± standard deviation with error bars.【F:Noiseerrorbar.m†L3-L101】【F:Noiseerrorbar.m†L103-L114】
+
+### `compare_risk_levels.m`
+Compares heterogeneous risk appetites by splitting agents into low-risk and high-risk halves while varying volatility `sigma` between 0.01 and 0.1. For each sigma, it runs 10 simulations, then plots error bars of average final wealth for both groups to highlight sensitivity to volatility under different risk sizing.【F:compare_risk_levels.m†L3-L79】【F:compare_risk_levels.m†L81-L111】
+
+### `influence_errorbars.m`
+Explores how the strength of trading influence on price formation shapes outcomes. It varies `influence_strength` from 0 to 2 in 0.2 steps, runs 10 simulations per level, and produces stacked error-bar plots showing average final wealth and final stock price versus influence strength.【F:influence_errorbars.m†L3-L83】【F:influence_errorbars.m†L85-L123】
+
+### `mu_sigma_variation.m`
+Runs a grid of experiments across multiple drifts (`mu`) and volatilities (`sigma`). For each combination, it executes 10 simulations, computes the mean and standard deviation of the final average budget, and overlays error-bar curves to compare how return drift interacts with volatility in the model.【F:mu_sigma_variation.m†L3-L91】【F:mu_sigma_variation.m†L93-L125】
+
+### `risk_fraction_errorbars.m`
+Examines how adjusting the base `Risk_fraction` from 0 to 1 affects wealth concentration. For each level, it runs 10 simulations, then reports total mean wealth and separate mean wealth for the top and bottom 10% of agents, plotting error bars for each segment to visualize inequality shifts as risk-taking grows.【F:risk_fraction_errorbars.m†L3-L95】【F:risk_fraction_errorbars.m†L97-L141】
+
+### `top_bottom_sigma.m`
+Studies the impact of price volatility on inequality by varying `sigma` from 0.01 to 0.1. It tracks the average wealth of the top and bottom deciles across 10 runs per volatility value and plots error bars comparing these two cohorts, highlighting how volatility disperses wealth.【F:top_bottom_sigma.m†L3-L88】【F:top_bottom_sigma.m†L90-L118】
+
+### `trade_probability_segmented_errorbars.m`
+Varies the per-step trade probability from 0 to 1 and observes total, top 10%, and bottom 10% mean wealth across 10 runs per level. The resulting error-bar plots show how more frequent participation changes aggregate outcomes and wealth stratification.【F:trade_probability_segmented_errorbars.m†L3-L95】【F:trade_probability_segmented_errorbars.m†L97-L141】
+
+### `wealth_inequality_10years.m`
+Extends the base simulation to a 10-year horizon (3,600 periods) and repeats it 10 times. Each year it records the average wealth of the top and bottom 10% of agents, then plots yearly error bars for both groups to illustrate long-run inequality trends.【F:wealth_inequality_10years.m†L3-L96】【F:wealth_inequality_10years.m†L98-L124】
+
+## Running the scripts
+
+Open any script in MATLAB or Octave and run it directly. Outputs include on-screen figures (for comparisons) and, in the case of `NMsim2_influencefactor1.m`, an `simInfluence.xlsx` file containing summary statistics. Adjust parameter ranges or run counts inside each script to explore additional scenarios.
 
EOF
)
