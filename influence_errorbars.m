
% Define range of influence strength levels and preallocate storage
influence_levels = 0:0.2:2;
num_levels = length(influence_levels);
num_runs_per_level = 10;
final_wealths = zeros(num_runs_per_level, num_levels);
final_prices = zeros(num_runs_per_level, num_levels);

for i = 1:num_levels
    influence_strength = influence_levels(i);

    for run = 1:num_runs_per_level
        % Initialize parameters
        population_size = 10000;
        time_periods = 360;
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

        % Budget and thresholds
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

            if stock_price == 0
                break;
            end
        end

        final_wealths(run, i) = mean(storebudget(:, end));
        final_prices(run, i) = stock_price;
    end
end

mean_wealth = mean(final_wealths, 1);
std_wealth = std(final_wealths, 0, 1);
mean_prices = mean(final_prices, 1);
std_prices = std(final_prices, 0, 1);

figure;
subplot(2,1,1);
errorbar(influence_levels, mean_wealth, std_wealth, 'o-', 'LineWidth', 2);
xlabel('Influence Strength');
ylabel('Average Final Wealth');
title('Impact of Influence Strength on Final Wealth');
grid on;

subplot(2,1,2);
errorbar(influence_levels, mean_prices, std_prices, 's-', 'LineWidth', 2);
xlabel('Influence Strength');
ylabel('Final Stock Price');
title('Impact of Influence Strength on Final Stock Price');
grid on;
