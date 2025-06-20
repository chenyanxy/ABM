% Parameters
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
influence_strength = 1;


num_runs = 1;
results = zeros(num_runs, 4);  % Columns: [mean_initial_wealth, mean_final_wealth, initial_price, final_price]

for run = 1:num_runs
% Budget and thresholds
budget = A ./ (1 - rand(1, population_size)).^(1 / alpha);  % Heavy-tailed wealth distribution
profit_threshold = based_profit_threshold * (1 + 0.5 * rand(1, population_size));
loss_threshold = based_loss_threshold * (1 + 0.5 * rand(1, population_size));

signal_history = zeros(population_size, 3); % signal loop 

% Stock and agent initialization
stock_price = A/10;
stock_prices = stock_price * [1, zeros(1, time_periods - 1)];

positions = zeros(1, population_size);       % -1 short, 0 neutral, 1 long
entry_prices = zeros(1, population_size);    % Entry prices for positions
position_sizes = zeros(1, population_size);  % Amount invested per agent

buy_count = zeros(1, time_periods);
sell_count = zeros(1, time_periods);

storebudget = zeros(population_size, time_periods);
storebudget(:,1) = budget;

% Random data
all_rand_trade = rand(population_size, time_periods);

Risk = Risk_fraction .* (Risk_fraction + 0.6 * rand(1, population_size));

storebudget(:,1) = budget;
positions_history = zeros(population_size, time_periods);
positions_history(:, 1) = positions;
position_sizes_history = zeros(population_size, time_periods);

for t = 2:time_periods

    % Signal generate
    price_trend = stock_prices(t-1) - stock_prices(max(t-2, 1));

    current_budget = storebudget(:, t-1)';%changed
    adjusted_noise = zeros(population_size, 1);%changed
    low_budget_idx = current_budget <= 3000;%changed
    adjusted_noise(low_budget_idx) = noise * randn(sum(low_budget_idx), 1);%changed
    raw_signal = price_trend + adjusted_noise'; %changed
    
    signal_agent = zeros(1, population_size);
    signal_agent(raw_signal > 0) = 1;
    signal_agent(raw_signal < 0) = -1;
    
    % Signal History
    signal_history = [signal_history(:,2:3), signal_agent'];
    
    % Closing Existing Position
    idx_open = positions ~= 0;
    profit = (stock_price - entry_prices) ./ entry_prices;
    profit(positions == -1) = -profit(positions == -1);
    
    signal_flip = all(signal_history == -positions' , 2)';
    idx_close = idx_open & (signal_flip | ...
        profit >= profit_threshold | ...
        profit <= loss_threshold);
    
    % Closing bookkeeping
    budget(idx_close) = budget(idx_close) + position_sizes(idx_close) .* (1 + profit(idx_close));
    trading_influence = zeros(1, population_size);
    trading_influence(idx_close & positions == 1) = -1;
    trading_influence(idx_close & positions == -1) = 1;
    
    sell_count(t) = sell_count(t) + sum(trading_influence == -1);
    buy_count(t)  = buy_count(t)  + sum(trading_influence == 1);
    
    positions(idx_close) = 0;
    entry_prices(idx_close) = 0;
    position_sizes(idx_close) = 0;
    
    % Open new position or reentry
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
    
    % Apply new positions 
    positions(idx_afford_new) = signal_agent(idx_afford_new);
    entry_prices(idx_afford_new) = stock_price;
    position_sizes(idx_afford_new) = new_invest_new(idx_afford_new);
    budget(idx_afford_new) = budget(idx_afford_new) - new_invest_new(idx_afford_new);
    
    % Influence from new positions
    trading_influence(idx_afford_new & signal_agent == 1) = 1;
    trading_influence(idx_afford_new & signal_agent == -1) = -1;
    
    % Re-entry positions (combine entries)
    original_sizes = position_sizes(idx_afford_reentry);
    added_sizes = new_invest_reentry(idx_afford_reentry);
    total_size = original_sizes + added_sizes;

    entry_prices(idx_afford_reentry) = ...
        (entry_prices(idx_afford_reentry) .* original_sizes + ...
        stock_price .* added_sizes) ./ total_size;
    position_sizes(idx_afford_reentry) = total_size;
    budget(idx_afford_reentry) = budget(idx_afford_reentry) - added_sizes;
    
    % Influence from re-entry
    trading_influence(idx_afford_reentry & signal_agent == 1) = 1;
    trading_influence(idx_afford_reentry & signal_agent == -1) = -1;
    
    % Count Trades
    buy_count(t) = buy_count(t) + sum(trading_influence == 1);
    sell_count(t) = sell_count(t) + sum(trading_influence == -1);

    % Price update using GBM + influence
    influence_factor = sum(trading_influence) / population_size;

    volume_effect = abs(influence_factor);
    influence_factor = influence_strength * influence_factor * volume_effect;

    stock_price = stock_price * exp((mu - 0.5*sigma^2) * time_step + sigma * sqrt(time_step) * randn) + ...
                   influence_factor; %Changed "time_step * influence_factor;"
    stock_price = max(stock_price, 0.01);
    stock_prices(t) = stock_price;
    
    % Wealth calculation
    profit_temp = zeros(1, population_size);
    idx_open = positions ~= 0;
    
    % Calculate profit only for agents with open positions
    profit_temp(idx_open) = (stock_price - entry_prices(idx_open)) ./ entry_prices(idx_open);
    profit_temp(positions == -1) = -profit_temp(positions == -1);
    
    % Calculate wealth only for active agents; keep previous wealth otherwise
    wealth = storebudget(:, t-1);  % Start from previous value
    wealth(idx_open) = budget(idx_open) + position_sizes(idx_open) .* (1 + profit_temp(idx_open));
    
    % Store updated wealth
    storebudget(:, t) = wealth;
    
    positions_history(:, t) = positions;
    position_sizes_history(:, t) = position_sizes;  % Track all agent sizes

    % Stop simulation if price crashes
    if stock_price == 0
        break;
    end
end

%% Record the Results for This Run
    mean_initial_wealth = mean(storebudget(:,1));   % Initial wealth (should equal the average of 'budget' at t=1)
    mean_final_wealth = mean(storebudget(:, t));       % Final wealth at the last time step
    initial_price = stock_prices(1);
    final_price = stock_prices(t);
    
    results(run,:) = [mean_initial_wealth, mean_final_wealth, initial_price, final_price];
end

% Write the collected results to an Excel file
writematrix(results, 'simInfluence.xlsx');

% Plot results
figure;
plot(1:time_periods, stock_prices, 'b-', 'LineWidth', 1.5);
xlabel('Days');
ylabel('Stock Price');
title('Stock Price Over Time');
grid on;

closeWealth = mean(storebudget(:, end));
openWealth = mean(storebudget(:,1));
closeprice = stock_prices(:,end);
disp(['Average open wealth = ', num2str(openWealth)]);
disp(['Average final wealth = ', num2str(closeWealth)]);
disp(['Closing price = ', num2str(closeprice)]);
