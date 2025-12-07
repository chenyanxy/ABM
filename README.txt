Agent-Based Market Simulation Scripts
-------------------------------------
This repository contains MATLAB scripts that explore how behavioral and market parameters influence outcomes in an agent-based stock-trading simulation. Each script adjusts a specific variable and visualizes the resulting wealth distribution or price dynamics.

Common Model Assumptions
- Population setup: 10,000 agents start with heavy-tailed initial wealth sampled with scale A = 1000 and tail parameter alpha = 2.
- Trading behavior: Agents open or close long or short positions based on price-momentum signals plus budget-dependent noise. Profit and loss thresholds introduce risk management, and a per-step trade_prob controls whether an agent follows a signal.
- Risk sizing: The Risk_fraction parameter sets how much of an agent's budget can be deployed per trade; some experiments split agents into groups with different risk appetites.
- Price dynamics: The stock price follows a geometric Brownian motion with drift mu, volatility sigma, and an additive influence term driven by the net trading direction.
- Outputs: Simulations record price paths, per-agent wealth over time, and summary statistics such as mean wealth and decile averages. Several scripts produce error-bar plots across repeated runs.

Script Guide
- NMsim2_influencefactor1.m: Runs a single simulation with an additive price influence term derived from recent trading direction. Records initial and final mean wealth and price in simInfluence.xlsx, plots the price path, and prints the average starting wealth.
- Noiseerrorbar.m: Sweeps noise levels from 0 to 1 in 0.1 increments to study how stronger signal noise for low-budget agents affects mean final wealth. Runs 20 simulations per level and plots mean plus standard deviation with error bars.
- compare_risk_levels.m: Compares heterogeneous risk appetites by splitting agents into low-risk and high-risk halves while varying volatility sigma between 0.01 and 0.1. Runs 10 simulations per sigma and plots error bars for average final wealth for both groups.
- influence_errorbars.m: Varies influence_strength from 0 to 2 in 0.2 steps, runs 10 simulations per level, and produces stacked error-bar plots showing average final wealth and final stock price versus influence strength.
- mu_sigma_variation.m: Runs a grid of experiments across multiple drifts (mu) and volatilities (sigma). Executes 10 simulations for each combination and plots mean and standard deviation of the final average budget.
- risk_fraction_errorbars.m: Adjusts the base Risk_fraction from 0 to 1 to see how risk-taking affects wealth concentration. Runs 10 simulations per level and plots total mean wealth along with mean wealth for the top and bottom 10 percent of agents.
- top_bottom_sigma.m: Varies sigma from 0.01 to 0.1 to study the impact of price volatility on inequality. Tracks average wealth of the top and bottom deciles across 10 runs and plots error bars for both cohorts.
- trade_probability_segmented_errorbars.m: Changes the per-step trade probability from 0 to 1 and observes total, top 10 percent, and bottom 10 percent mean wealth across 10 runs per level, plotting error bars for each metric.
- wealth_inequality_10years.m: Extends the base simulation to a 10-year horizon (3,600 periods) and repeats it 10 times. Records yearly average wealth for the top and bottom 10 percent of agents and plots error bars to show long-run inequality trends.

Running the Scripts
Open any script in MATLAB or Octave and run it directly. Outputs include on-screen figures for comparisons and, in the case of NMsim2_influencefactor1.m, a simInfluence.xlsx file containing summary statistics. You can adjust parameter ranges or run counts inside each script to explore additional scenarios.
