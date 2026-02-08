clc; clear; close all;
%% Sim Params
dt = 0.01; 
simTime = 40;  
t = 0 : dt : simTime; 
alpha = 0.98; 
persist_on_th = 1.5;
persist_off_th = 1;
instant_th = 2.0;
osc_th = 0.5; 
osc_cross_th = 30;
max_range = 12;
min_range = 0 ;  
len = length(t);
N = 20; 
No = 1000; 
heal_t = 10/dt + 1; 
BIT_flag_th = 15;
state_changed = 0 ; 
sc_count = 0 ; 
%% Signal Generation 
sig1 = 3.4 * ones(size(t));
sig1(1 + 30/dt:end) = 0;
sig2 = 3.2 * ones(size(t));
sig2(4.5/dt + 1) = 5.5;
sig2((5/dt + 1) : (9/dt + 1)) = linspace(3.2, 8 , 1+ 4/dt);
sig2((1 + 35/dt) : end) = 10; 
sig2((40/dt + 1):end) = 3.2; 
f_idx = t >= 12.5;
f_t = t(f_idx) - 12.5;
sig3 = 3.0 * ones(size(t));
sig3(f_idx) = 3.0 + 2.5 * sin(1 * f_t);
sig4 = 2.9 * ones(size(t));

%% Histories & Flags Initialization
persist_err_s = zeros(4, len);
instant_err_s = zeros(4, len);
osc_filtered_sig = zeros(4, len);
osc_counter = zeros(4, len);
validity = ones(4, len); 
hold_val = zeros(4, 1);
is_holding = [false, false, false, false];
persist_miscompare_flag = zeros(4, 1);
osc_error_flag = zeros(4, 1);
osc_trigger_flag = zeros(4, 1);
range_err_flag = zeros(4,1);
healing_cnt = zeros(4, 1);
voted_val = zeros(size(t));
voted_val(1:N) = 3.1; 
latest_fail_t = zeros(4,1); 
BIT_flags = zeros(4, len);
flagged_error = zeros(4,1);
hard_fail = zeros(size(t));
fail_time = [];
dummy_hist = zeros(size(t));
BIT_flags(4, round(45/dt): round(68/dt)) = 1;
state_change_time = [];
instant_flag = zeros(4,len);
t_trans = 1; % transition time 
faded_val = zeros(size(t));



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
                hold_val(s) = current_sigs(s); 
                is_holding(s) = true;
            end
            active_s_current(s) = hold_val(s); 
        else
            is_holding(s) = false;
            active_s_current(s) = current_sigs(s);
            
            % If possibly oscillated signal exceeds threshold activate
            % error flag 
            if sum(osc_counter(s, max(1, i-No) : i)) > osc_cross_th
                osc_error_flag(s) = 1;
            end
        end
            
        % Miscompare errors 
        instant_err_s(s, i) = abs(active_s_current(s) - voted_val(i-1));
        persist_err_s(s, i) = 0.995 * persist_err_s(s, i-1) + 0.005 *instant_err_s(s,i);

        
        if persist_err_s(s, i) > persist_on_th
            persist_miscompare_flag(s) = 1;
        elseif persist_err_s(s, i) < persist_off_th
            persist_miscompare_flag(s) = 0;
        end

        if active_s_current(s) > max_range || active_s_current(s) < min_range
            range_err_flag(s) = 1; 
        else 
            range_err_flag(s) = 0; 
        end
    
        % if all signals oscillates this means physical phenomena not error
        if ~any(~osc_error_flag)
            osc_error_flag = [0;0;0;0];
        end
        
        % If total BIT error flags exceeds thres. activate error 
        if (sum(BIT_flags(s, max(1, i-N) : i))) > BIT_flag_th
           flagged_error(s) = 1;
        end
            
        % Validation
        current_fault = persist_miscompare_flag(s) | osc_error_flag(s) | range_err_flag(s) | flagged_error(s);
        
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

    %If there are 2 sensors left and one of them fails, otherone fails too
    if sum(validity(:,i)) == 1 
        [~,idx] = max(latest_fail_t);
        if ~range_err_flag(idx) 
            healing_cnt(find(validity(:,i))) = 0;
            validity(:,i) = [0;0;0;0];
        end
    end 
    
    % Voting
    active_pool = []; 
    current_valid_count = sum(validity(:, i));
    for s = 1:4
        if validity(s, i) == 1
            
            % If there is two signal left include instantenous signal to
            % voting 
            if current_valid_count > 2
                %If there is instant err. dont involve signal to voting
                if instant_err_s(s, i) < instant_th
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
    for s = 1 :  4
        if instant_err_s(s, i) > instant_th
            instant_flag(s,i) = 1 ; 
        end 
       
        if sum(abs(validity(:,i) - validity(:,i-1))) ~=0 || ( instant_flag(s,i) && validity(s,i) == 1 && (instant_flag(s,i) - instant_flag(s,i-1)) ~= 0)
            if voted_val(i) ~= voted_val(i-1)
                state_change_time = [state_change_time i];
                sc_count = sc_count + 1; 
            end   
        end
    end


if ~isempty(state_change_time)
    faded_val(state_change_time(sc_count)) = voted_val(state_change_time(sc_count) - 1); 
    if state_change_time(sc_count) <= i && i <= state_change_time(sc_count) + t_trans / dt 
    faded_val(i) = voted_val(i)*(i - state_change_time(sc_count))*(dt / t_trans)...
        + faded_val(state_change_time(sc_count))*(1 - (i - state_change_time(sc_count)) *(dt / t_trans)); 

     else
    faded_val(i) = voted_val(i);
    end

else 
        faded_val(i) = voted_val(i);    
end

faded_val(1: 0.3/dt) = 3.1;

end 


%% Plot 
figure(1); 
subplot(2,1,1)
plot(t, faded_val, 'LineWidth', 2); hold on;
if ~isempty(fail_time), xline(fail_time*dt, "r--", 'LineWidth', 2); end
if ~isempty(state_change_time), xline(state_change_time *dt, "g--");end
ylim([0 7]); grid on; title("Voted Value"); legend("Voted Val", "Fail Start/End", "State Transition");
subplot(2,1,2)
plot(t, voted_val, 'LineWidth', 2); hold on;
if ~isempty(fail_time), xline(fail_time*dt, "r--", 'LineWidth', 2); end
if ~isempty(state_change_time), xline(state_change_time *dt, "g--");end
ylim([0 7]); grid on; title("Voted Value"); legend("Voted Val", "Fail Start/End","State Transition");


figure(2); sgtitle("Signal Validities");
titles = ["Signal 1 Validity", "Signal 2 Validity", "Signal 3 Validity", "Signal 4 Validity"];
for s=1:4, subplot(2,2,s); plot(t, validity(s,:), 'LineWidth', 2); ylim([-0.5 1.5]); title(titles(s)); end

figure(3); sgtitle("Signals");
for s=1:4, subplot(2,2,s); plot(t, eval(['sig' num2str(s)]), 'LineWidth', 2); title(['Signal ' num2str(s)]); end