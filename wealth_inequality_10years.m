
% Parameters
population_size = 10000;
years = 10;
time_periods = 360 * years;
time_step = 0.1;
mu = 0.005;
sigma = 0.02;
A = 1000;
alpha = 2;
based_profit_threshold = 0.1;
based_loss_threshold = -0.1;
min_budget_threshold = 0;
noise = 0.8; 
Risk_fraction = 0.4;
trade_prob = 0.8;
influence_strength = 1;
num_runs = 10;

top10_matrix = zeros(num_runs, years);
bottom10_matrix = zeros(num_runs, years);

for run = 1:num_runs
    budget = A ./ (1 - rand(1, population_size)).^(1 / alpha);
    profit_threshold = based_profit_threshold * (1 + 0.5 * rand(1, population_size));
    loss_threshold = based_loss_threshold * (1 + 0.5 * rand(1, population_size));
    signal_history = zeros(population_size, 3);
    stock_price = A/10;
    stock_prices = stock_price * [1, zeros(1, time_periods - 1)];

    positions = zeros(1, population_size);
    entry_prices = zeros(1, population_size);
    position_sizes = zeros(1, population_size);
    storebudget = zeros(population_size, time_periods);
    storebudget(:,1) = budget;

    all_rand_trade = rand(population_size, time_periods);
    Risk = Risk_fraction .* (Risk_fraction + 0.6 * rand(1, population_size));

    for t = 2:time_periods
        price_trend = stock_prices(t-1) - stock_prices(max(t-2, 1));
        current_budget = storebudget(:, t-1)';
        adjusted_noise = zeros(population_size, 1);
        low_budget_idx = current_budget <= 3000;
        adjusted_noise(low_budget_idx) = noise * randn(sum(low_budget_idx), 1);
        raw_signal = price_trend + adjusted_noise';

        signal_agent = zeros(1, population_size);
        signal_agent(raw_signal > 0) = 1;
        signal_agent(raw_signal < 0) = -1;
        signal_history = [signal_history(:,2:3), signal_agent'];

        idx_open = positions ~= 0;
        profit = (stock_price - entry_prices) ./ entry_prices;
        profit(positions == -1) = -profit(positions == -1);
        signal_flip = all(signal_history == -positions', 2)';
        idx_close = idx_open & (signal_flip | ...
            profit >= profit_threshold | ...
            profit <= loss_threshold);

        budget(idx_close) = budget(idx_close) + position_sizes(idx_close) .* (1 + profit(idx_close));
        trading_influence = zeros(1, population_size);
        trading_influence(idx_close & positions == 1) = -1;
        trading_influence(idx_close & positions == -1) = 1;
        positions(idx_close) = 0;
        entry_prices(idx_close) = 0;
        position_sizes(idx_close) = 0;

        idx_trade = all_rand_trade(:, t)' < trade_prob;
        idx_new = positions == 0 & budget >= min_budget_threshold & idx_trade & signal_agent ~= 0;
        signal_agreement = sum(signal_history == positions', 2)';
        idx_reentry = positions ~= 0 & ...
            budget >= min_budget_threshold & ...
            idx_trade & (signal_agreement >= 2);

        investment = budget .* Risk;
        new_invest_new = zeros(1, population_size);
        new_invest_reentry = zeros(1, population_size);
        new_invest_new(idx_new) = investment(idx_new);
        new_invest_reentry(idx_reentry) = investment(idx_reentry);

        idx_afford_new = idx_new & (budget - new_invest_new >= min_budget_threshold);
        idx_afford_reentry = idx_reentry & (budget - new_invest_reentry >= min_budget_threshold);

        positions(idx_afford_new) = signal_agent(idx_afford_new);
        entry_prices(idx_afford_new) = stock_price;
        position_sizes(idx_afford_new) = new_invest_new(idx_afford_new);
        budget(idx_afford_new) = budget(idx_afford_new) - new_invest_new(idx_afford_new);

        original_sizes = position_sizes(idx_afford_reentry);
        added_sizes = new_invest_reentry(idx_afford_reentry);
        total_size = original_sizes + added_sizes;

        entry_prices(idx_afford_reentry) = ...
            (entry_prices(idx_afford_reentry) .* original_sizes + ...
            stock_price .* added_sizes) ./ total_size;
        position_sizes(idx_afford_reentry) = total_size;
        budget(idx_afford_reentry) = budget(idx_afford_reentry) - added_sizes;

        influence_factor = sum(trading_influence) / population_size;
        volume_effect = abs(influence_factor);
        influence_factor = influence_strength * influence_factor * volume_effect;

        stock_price = stock_price * exp((mu - 0.5*sigma^2) * time_step + sigma * sqrt(time_step) * randn) + ...
                       influence_factor;
        stock_price = max(stock_price, 0.01);
        stock_prices(t) = stock_price;

        profit_temp = zeros(1, population_size);
        idx_open = positions ~= 0;
        profit_temp(idx_open) = (stock_price - entry_prices(idx_open)) ./ entry_prices(idx_open);
        profit_temp(positions == -1) = -profit_temp(positions == -1);

        wealth = storebudget(:, t-1);
        wealth(idx_open) = budget(idx_open) + position_sizes(idx_open) .* (1 + profit_temp(idx_open));
        storebudget(:, t) = wealth;

        if mod(t, 360) == 0
            year = t / 360;
            sorted_wealth = sort(wealth);
            top10 = sorted_wealth(end - floor(0.1 * population_size) + 1:end);
            bottom10 = sorted_wealth(1:floor(0.1 * population_size));
            top10_matrix(run, year) = mean(top10);
            bottom10_matrix(run, year) = mean(bottom10);
        end
    end
end

% Calculate mean and std for error bars
top10_mean = mean(top10_matrix, 1);
top10_std = std(top10_matrix, 0, 1);
bottom10_mean = mean(bottom10_matrix, 1);
bottom10_std = std(bottom10_matrix, 0, 1);

% Plot
figure;
errorbar(1:years, top10_mean, top10_std, '-o', 'LineWidth', 2); hold on;
errorbar(1:years, bottom10_mean, bottom10_std, '-s', 'LineWidth', 2);
xlabel('Year');
ylabel('Average Wealth');
legend('Top 10%', 'Bottom 10%');
title('Wealth Trend Over 10 Years with Error Bars');
grid on;
