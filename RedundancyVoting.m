clc; clear; close all;

%% TEST Cases
% 'case_1_nominal.mat', 'case_2_instant.mat', 'case_3_persistent.mat'
% 'case_4_range.mat', 'case_5_oscillatory.mat', 'case_6_healing.mat',
% 'case_7_bit.mat' , 'case_8_original_mixed.mat' , 'case_9_total_loss.mat'
% 'case_10_range_survival.mat' , 'case_11_turbulence.mat', case_12_split
% 'case_13_reset.mat'

case_file = 'case_13_reset.mat';

% Dosyayı yükle
if exist(['test_data/' case_file], 'file')
    load(['test_data/' case_file]);
else
    error('File dont exist');
end

%% Sim Params
alpha = 0.98;
persist_on_th = 3.0; % 3.0 < - > 1.5 
persist_off_th = 2.5; % 2.5 < - > 1.0
instant_th = 3.5;   % 3.5 < - > 2.0 
osc_th = 2;
osc_cross_th = 15;
max_range = 20;
min_range = -5;
len = length(t); 
N = 20;
No = 1000;
split_t = 1/dt + 1 ; 
heal_t = 10/dt + 1;
reset_t = 2/dt + 1;
BIT_flag_th = 15;
state_changed = 0;
sc_count = 0;
state_change_time = [];
instant_flag = zeros(4,len);
t_trans = 1; % transition time
greater_th  = 2 ; 
smaller_th = 1 ; 

%% Histories & Flags Initialization
persist_err_s = zeros(4, len);
instant_err_s = zeros(4, len);
osc_filtered_sig = zeros(4, len);
osc_counter = zeros(4, len);
validity = ones(4, len);
hold_val = zeros(4, 1);
split_hold = 0;
is_holding = [false, false, false, false];
persist_miscompare_flag = zeros(4, 1);
osc_error_flag = zeros(4, 1);
osc_trigger_flag = zeros(4, 1);
range_err_flag = zeros(4,1);
healing_cnt = zeros(4, 1);
split_cnt = 0;
is_split = 0;
voted_val = zeros(size(t));
voted_val(1:N) = 3.1; 
latest_fail_t = zeros(4,1);
flagged_error = zeros(4,1);
hard_fail = zeros(size(t));
fail_time = [];
faded_val = zeros(size(t));
dummy_hist = zeros(size(t));
total_fault = zeros(4,1);
quality = zeros(size(t));
quality(1:21) = 4; % due to initial zeros
range_persisten_th = 2/dt+1 ; 
range_pers_counter = zeros(4,1);

% reset_penalty_th = 5;
% reset_penalty_counter_max = 50;
% reset_penalty_counter = 0;
% reset_button = zeros(size(t));

reset_active = zeros(4,1);





if ~exist('BIT_flags', 'var')
    BIT_flags = zeros(4, len);
end

%% Simulation Loop
for i = N + 1 : len
    current_sigs = [sig1(i), sig2(i), sig3(i), sig4(i)];
    sig_2t = [sig1(i-2), sig2(i-2), sig3(i-2), sig4(i-2)];
    active_s_current = zeros(1, 4);
    is_oscillating_now = false(1, 4);

    for s = 1:4
        % Bandpass filter for oscillary fault detection
        osc_filtered_sig(s, i) = 0.18318 * current_sigs(s) - 0.18318 * sig_2t(s) + ...
            1.61765 * osc_filtered_sig(s, i-1) - 0.63363 * osc_filtered_sig(s, i-2);
        
        % add counter in each crossing
        if osc_trigger_flag(s) == 0 && abs(osc_filtered_sig(s, i)) > osc_th
            osc_counter(s, i) = 1;
            osc_trigger_flag(s) = 1;
        elseif abs(osc_filtered_sig(s, i)) < osc_th
            osc_trigger_flag(s) = 0;
        end
        
        % if at least 3 crossing occurs there might be oscillation error
        if sum(osc_counter(s, max(1, i-No) : i)) >= 3
            is_oscillating_now(s) = true;
        end
    end

    total_valid_prev = sum(validity(:, i-1));
    %if signal is not valid dont include oscillation
    total_oscillating = sum(is_oscillating_now & validity(:, i-1)');

    for s = 1:4
        %if there is at least 3 valid signal, and only one signal is
        %possibly oscillated hold the prev val.
        if is_oscillating_now(s) && total_oscillating == 1 && total_valid_prev >= 3
            if ~is_holding(s)
                hold_val(s) = sig_2t(s);  % Take val at 2 ts before
                is_holding(s) = true;
            end
            active_s_current(s) = hold_val(s);
        else
            is_holding(s) = false;
            active_s_current(s) = current_sigs(s);
            % If possibly oscillated signal exceeds threshold activate
            % error flag
        end
            if sum(osc_counter(s, max(1, i-No) : i)) > osc_cross_th
                osc_error_flag(s) = 1;
                is_holding(s) = false;
            end        

        % Miscompare errors
        instant_err_s(s, i) = abs(active_s_current(s) - voted_val(i-1));

        % Persist err is Low-pass filtered instantenous err
        persist_err_s(s, i) = 0.995 * persist_err_s(s, i-1) + 0.005 *instant_err_s(s,i);

        %if there is range error hold the filter
        if range_pers_counter(s)
            persist_err_s(s,i) = persist_err_s(s,i-1);
        end

        if persist_err_s(s, i) > persist_on_th
            persist_miscompare_flag(s) = 1;
        elseif persist_err_s(s, i) < persist_off_th
            persist_miscompare_flag(s) = 0;
        end


        %Range errors
        if active_s_current(s) > max_range || active_s_current(s) < min_range
            range_pers_counter(s) = range_pers_counter(s) + 1;
        else
            range_pers_counter(s) = 0; 
        end

        range_err_flag(s) = range_pers_counter(s) >= range_persisten_th;



        % If total BIT error flags exceeds thres. activate error
        if (sum(BIT_flags(s, max(1, i-N) : i))) > BIT_flag_th
            flagged_error(s) = 1;
        else
            flagged_error(s) = 0 ;
        end

        % Validation
        current_fault = persist_miscompare_flag(s) | osc_error_flag(s) | range_err_flag(s) | flagged_error(s);
        total_fault(s)  = current_fault;
        if current_fault
            validity(s, i) = 0;
            healing_cnt(s) = 0;
            if validity(s,i-1 ) == 1
                latest_fail_t(s) = i;
            end
        elseif validity(s, i-1) == 0
            healing_cnt(s) = healing_cnt(s) + 1;
            if healing_cnt(s) >= heal_t
                validity(s, i) = 1;
                osc_error_flag(s) = 0;
            else
                validity(s, i) = 0;
            end
        else
            validity(s, i) = 1;
        end


   
    end
    
        
        % if all signals oscillates this means physical phenomena not error
        if sum(osc_error_flag) == 4 && (~any(persist_miscompare_flag) && ~any(range_err_flag))
            validity(:,i) = [1;1;1;1];
            healing_cnt = [heal_t;heal_t;heal_t;heal_t];

        end
    

    %If there are 2 sensors left and one of them fails, otherone fails too
    if sum(validity(:,i)) == 1 || (is_split && any(total_fault))
        [~,idx] = max(latest_fail_t);
        if ~range_err_flag(idx)
            healing_cnt(find(validity(:,i))) = 0;
            validity(:,i) = [0;0;0;0];
        end
    end

    % Check for 2by2 split
    if all(validity)
        greater_diff = abs(diff(maxk(current_sigs,2)));
        smaller_diff = abs(diff(mink(current_sigs,2)));
        
        d1 = abs(voted_val(i-1) - current_sigs(1));
        d2 = abs(voted_val(i-1) - current_sigs(2));
        d3 = abs(voted_val(i-1) - current_sigs(3));
        d4 = abs(voted_val(i-1) - current_sigs(4));
    
        if all([d1,d2,d3,d4] > greater_th) && greater_diff < smaller_th && smaller_diff < smaller_th
            split_cnt = split_cnt + 1;
            if split_cnt >= split_t
                is_split = 1;
                validity(:,i) = [0;0;0;0];
            else
                is_split = 0 ;
            end
            
        else
            split_cnt = 0; 
        end
    end

    % reset logic
    % if any(flagged_error) || any(persist_miscompare_flag) || any(range_err_flag) || any(osc_error_flag)
    %     reset_penalty_counter = reset_penalty_counter + 2;
    % elseif any(instant_flag)
    %     reset_penalty_counter = reset_penalty_counter + 1;
    % else
    %     reset_penalty_counter = reset_penalty_counter - 1; 
    % end
    % 
    %Limit reset counter
    % if reset_penalty_counter > reset_penalty_counter_max
    %     reset_penalty_counter = reset_penalty_counter_max;
    % elseif reset_penalty_counter < 0 
    %     reset_penalty_counter = 0;
    % end
    % 
    % 
    % reset_button(30) = 1;
    % 
    % if reset_button(i) && (reset_penalty_counter < reset_penalty_th)
    %     validity(:,i) = [1;1;1;1];
    % end
    

    for s = 1 : 4 
        if validity(s,i) || healing_cnt(s) > reset_t
            reset_active(s) = 1 ;
        else 
            reset_active(s) = 0 ;
        end    
    end
 
    if all(reset_active) && reset_button(i)
        validity(:,i) = [1;1;1;1];
    end

                   
        
    
    % Voting
    active_pool = [];
    current_valid_count = sum(validity(:, i));
    for s = 1:4
        if validity(s, i) == 1
            % If there is two signal left include instantenous signal to
            % voting
            if current_valid_count > 2
                %If there is instant err. or range error suspicion dont involve signal to voting
                if instant_err_s(s, i) < instant_th || ~range_pers_counter(s)
                    active_pool = [active_pool, active_s_current(s)];
                end
            else
                active_pool = [active_pool, active_s_current(s)];
            end
        end
    end

    if ~isempty(active_pool)
        voted_val(i) = median(active_pool);
    else
        voted_val(i) = voted_val(i-1); % Take prev. val in case of hardfail
        hard_fail(i) = 1;
    end

    % Take fail times fot plotting
    if i > 1 && (hard_fail(i) ~= hard_fail(i-1))
        fail_time = [fail_time i];
    end

    % Get state changes
    for s = 1 : 4
        if instant_err_s(s, i) > instant_th
            instant_flag(s,i) = 1;
        end
        if sum(abs(validity(:,i) - validity(:,i-1))) ~=0 || ( instant_flag(s,i) && validity(s,i) == 1 && (instant_flag(s,i) - instant_flag(s,i-1)) ~= 0)
            if voted_val(i) ~= voted_val(i-1)
                state_change_time = [state_change_time i];
                sc_count = sc_count + 1;
            end
        end
    end

    if hard_fail(i)
        quality(i) = 0;
    else
        quality(i) = length(active_pool);
    end


    if ~isempty(state_change_time)
        if sc_count > 0 && sc_count <= length(state_change_time)
            idx_change = state_change_time(sc_count);
            faded_val(idx_change) = voted_val(idx_change - 1);
            if idx_change <= i && i <= idx_change + t_trans / dt
                faded_val(i) = voted_val(i)*(i - idx_change)*(dt / t_trans)...
                    + faded_val(idx_change)*(1 - (i - idx_change) *(dt / t_trans));
            else
                faded_val(i) = voted_val(i);
            end
        else
            faded_val(i) = voted_val(i);
        end
    else
        faded_val(i) = voted_val(i);
    end
    
    faded_val(1: N) = voted_val(1:N);
    dummy_hist(i) = persist_miscompare_flag(2);
    
end

%% Plot Results
figure(1);
sgtitle(['RESULTS FOR: ' strrep(case_file, '_', '\_')]); 
subplot(2,1,1)
plot(t, faded_val, 'LineWidth', 2); hold on;
if ~isempty(fail_time), xline(fail_time*dt, "r--", 'LineWidth', 2); end
if ~isempty(state_change_time), xline(state_change_time *dt, "g--");end
ylim([-2 10]); grid on; title("Faded Voted Value"); 

subplot(2,1,2)
% plot(t, voted_val, 'LineWidth', 2); hold on;
% if ~isempty(fail_time), xline(fail_time*dt, "r--", 'LineWidth', 2); end
% if ~isempty(state_change_time), xline(state_change_time *dt, "g--");end
% ylim([-2 18]); grid on; title("Raw Voted Value");

plot(t,quality,"LineWidth",3);
title("Value Quality")
grid on

%Comment out for other cases except 12
% plot(t,sig1,'Color',[0.8 0.8 0.8]);plot(t,sig2,'Color',[0.8 0.8 0.8]);plot(t,sig3,'Color',[0.8 0.8 0.8]);plot(t,sig4,'Color',[0.8 0.8 0.8]);
% xline(3657 *dt, "g--")


figure(2); sgtitle("Signal Validities");
titles = ["Signal 1 Validity", "Signal 2 Validity", "Signal 3 Validity", "Signal 4 Validity"];
for s=1:4, subplot(2,2,s); plot(t, validity(s,:), 'LineWidth', 2); ylim([-0.5 1.5]); title(titles(s)); end

figure(3); sgtitle("Input Signals");
subplot(2,2,1); plot(t, sig1, 'LineWidth', 2); title('Signal 1'); grid on;
subplot(2,2,2); plot(t, sig2, 'LineWidth', 2); title('Signal 2'); grid on;
subplot(2,2,3); plot(t, sig3, 'LineWidth', 2); title('Signal 3'); grid on;
subplot(2,2,4); plot(t, sig4, 'LineWidth', 2); title('Signal 4'); grid on;


figure(4)

plot(t,dummy_hist)


