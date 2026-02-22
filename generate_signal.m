clc; clear; close all;

if ~exist('test_data', 'dir')
    mkdir('test_data');
end

%% GENEL AYARLAR VE TEMEL SİNYALLER
dt = 0.01;
simTime = 40;
t = 0 : dt : simTime;
len = length(t);

base_sig1 = 3.4 * ones(size(t));
base_sig2 = 3.2 * ones(size(t));
base_sig3 = 3.0 * ones(size(t));
base_sig4 = 2.9 * ones(size(t));

%% CASE 1: Nominal Çalışma (Baseline)
sig1 = base_sig1; 
sig2 = base_sig2; 
sig3 = base_sig3; 
sig4 = base_sig4;
BIT_flags = zeros(4, len);
save('test_data/case_1_nominal.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');


figure('Name', 'CASE 1: Nominal', 'NumberTitle', 'off');
sgtitle('CASE 1: Nominal Çalışma');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1.5); grid on; title('Signal 1'); ylim([0 10]);
subplot(2,2,2); plot(t, sig2, 'LineWidth', 1.5); grid on; title('Signal 2'); ylim([0 10]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1.5); grid on; title('Signal 3'); ylim([0 10]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1.5); grid on; title('Signal 4'); ylim([0 10]);

%% CASE 2: Instantaneous Miscompare (Anlık Uyumsuzluk)
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

spike_idx = round(10/dt); 
sig2(spike_idx : spike_idx+5) = 8; 

save('test_data/case_2_instant.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 2: Instantaneous', 'NumberTitle', 'off');
sgtitle('CASE 2: Anlık Uyumsuzluk (Spike @ 10s)');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1.5); grid on; title('Signal 1'); ylim([0 25]);
subplot(2,2,2); plot(t, sig2, 'r', 'LineWidth', 1.5); grid on; title('Signal 2 (FAULTY)'); ylim([0 25]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1.5); grid on; title('Signal 3'); ylim([0 25]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1.5); grid on; title('Signal 4'); ylim([0 25]);

%% CASE 3: Persistent Miscompare (Drift)
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

drift_start = round(25/dt);
drift_end = round(35/dt);
sig2(drift_start : drift_end) = linspace(3.2, 15, (drift_end - drift_start + 1));
sig2(drift_end+1 : end) = 3.2; 

save('test_data/case_3_persistent.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 3: Persistent', 'NumberTitle', 'off');
sgtitle('CASE 3: Kalıcı Uyumsuzluk (Drift 5s-15s)');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1.5); grid on; title('Signal 1'); ylim([0 20]);
subplot(2,2,2); plot(t, sig2, 'r', 'LineWidth', 1.5); grid on; title('Signal 2 (FAULTY)'); ylim([0 20]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1.5); grid on; title('Signal 3'); ylim([0 20]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1.5); grid on; title('Signal 4'); ylim([0 20]);

%% CASE 4: Range Check (Hardover)
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

fail_time = round(10/dt);
sig1(fail_time:end) = 100; 

save('test_data/case_4_range.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 4: Range Check', 'NumberTitle', 'off');
sgtitle('CASE 4: Range Hatası (Hardover @ 10s)');
subplot(2,2,1); plot(t, sig1, 'r', 'LineWidth', 1.5); grid on; title('Signal 1 (FAULTY)'); 
subplot(2,2,2); plot(t, sig2, 'LineWidth', 1.5); grid on; title('Signal 2'); ylim([0 10]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1.5); grid on; title('Signal 3'); ylim([0 10]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1.5); grid on; title('Signal 4'); ylim([0 10]);

%% CASE 5: Oscillatory Fault (Osilasyon)
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

osc_start = round(10/dt);
osc_time_vec = t(osc_start:end) - t(osc_start);
oscillation = 3 * sin(22 * osc_time_vec); 
sig3(osc_start:end) = sig3(osc_start:end) + oscillation;

save('test_data/case_5_oscillatory.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 5: Oscillatory', 'NumberTitle', 'off');
sgtitle('CASE 5: Osilasyon Hatası (15 rad/s @ 10s)');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1.5); grid on; title('Signal 1'); ylim([0 10]);
subplot(2,2,2); plot(t, sig2, 'LineWidth', 1.5); grid on; title('Signal 2'); ylim([0 10]);
subplot(2,2,3); plot(t, sig3, 'r', 'LineWidth', 1.5); grid on; title('Signal 3 (FAULTY)'); ylim([0 10]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1.5); grid on; title('Signal 4'); ylim([0 10]);

%% CASE 6: Healing (İyileşme)
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

fail_start = round(5/dt);
fail_end = round(20/dt); 
sig2(fail_start : fail_end) = 8; 

save('test_data/case_6_healing.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 6: Healing', 'NumberTitle', 'off');
sgtitle('CASE 6: İyileşme (Arıza 5s-20s)');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1.5); grid on; title('Signal 1'); ylim([0 25]);
subplot(2,2,2); plot(t, sig2, 'r', 'LineWidth', 1.5); grid on; title('Signal 2 (HEALING)'); ylim([0 25]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1.5); grid on; title('Signal 3'); ylim([0 25]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1.5); grid on; title('Signal 4'); ylim([0 25]);

%% CASE 7: Flagged Fault (BIT Hatası)
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

bit_start = round(10/dt);
bit_end = round(25/dt);
BIT_flags(4, bit_start:bit_end) = 1; 

save('test_data/case_7_bit.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 7: BIT Fault', 'NumberTitle', 'off');
sgtitle('CASE 7: BIT Hatası (Sinyal 4 @ 10s-25s)');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1.5); grid on; title('Signal 1'); ylim([0 6]);
subplot(2,2,2); plot(t, sig2, 'LineWidth', 1.5); grid on; title('Signal 2'); ylim([0 6]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1.5); grid on; title('Signal 3'); ylim([0 6]);
subplot(2,2,4); plot(t, sig4, 'r', 'LineWidth', 1.5); grid on; title('Signal 4 (BIT ACTIVE)'); ylim([0 6]);
xline(10, '--k', 'BIT Start');
xline(25, '--k', 'BIT End');

%% CASE 8: ORİJİNAL KARMAŞIK SENARYO (Senin İlk Kodundaki Senaryo)

sig1 = 3.4 * ones(size(t));
sig1(1 + 30/dt:end) = 0;

sig2 = 3.2 * ones(size(t));
sig2(round(4.5/dt) + 1) = 5.5; 
sig2((round(5/dt) + 1) : (round(9/dt) + 1)) = linspace(3.2, 8 , length((round(5/dt) + 1) : (round(9/dt) + 1))); % Drift
sig2((1 + round(35/dt)) : end) = 10; % Hardover
sig2((round(40/dt) + 1):end) = 3.2; % End

sig3 = 3.0 * ones(size(t));
f_idx = t >= 12.5;
f_t = t(f_idx) - 12.5;
sig3(f_idx) = 3.0 + 2.5 * sin(1 * f_t); 

sig4 = 2.9 * ones(size(t));

BIT_flags = zeros(4, len);
BIT_flags(4, round(45/dt): round(68/dt)) = 1; 

save('test_data/case_8_original_mixed.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 8: Original Mixed', 'NumberTitle', 'off');
sgtitle('CASE 8: Orijinal Karmaşık Senaryo (Makaledeki Test)');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1.5); grid on; title('Signal 1 (Fail @30s)'); ylim([0 5]);
subplot(2,2,2); plot(t, sig2, 'LineWidth', 1.5); grid on; title('Signal 2 (Spike, Drift, Hardover)'); ylim([0 12]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1.5); grid on; title('Signal 3 (Osc @12.5s)'); ylim([0 6]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1.5); grid on; title('Signal 4 (Healthy)'); ylim([0 5]);

%% CASE 9: 2 Invalid (Step @5s) + 3rd Persistent Miscompare (Total Loss)


sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

step_fail_time = round(5/dt);
sig1(step_fail_time : end) = 15.0; 
sig2(step_fail_time : end) = 20.0; 

drift_start = round(15/dt);
sig3(drift_start : end) = linspace(3.0, 20.0, len - drift_start + 1);

save('test_data/case_9_total_loss.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');


figure('Name', 'CASE 9: Total Loss', 'NumberTitle', 'off');
sgtitle('CASE 9: 2 Step Hatası (@5s) + 3. Drift Hatası (@15s)');
subplot(2,2,1); plot(t, sig1, 'r', 'LineWidth', 1.5); grid on; title('Signal 1 (STEP FAIL @5s)'); ylim([0 25]);
subplot(2,2,2); plot(t, sig2, 'r', 'LineWidth', 1.5); grid on; title('Signal 2 (STEP FAIL @5s)'); ylim([0 25]);
subplot(2,2,3); plot(t, sig3, 'm', 'LineWidth', 1.5); grid on; title('Signal 3 (DRIFT @15s)'); ylim([0 25]);
subplot(2,2,4); plot(t, sig4, 'g', 'LineWidth', 1.5); grid on; title('Signal 4 (HEALTHY)'); ylim([0 25]);

%% CASE 10: 2 Invalid (Step @5s) + 3rd Range Error (Survival)


sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

step_fail_time = round(5/dt);
sig1(step_fail_time : end) = 18.0; 
sig2(step_fail_time : end) = 22.0; 

range_fail_time = round(20/dt);
sig3(range_fail_time : end) = 150; 

save('test_data/case_10_range_survival.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 10: Range Survival', 'NumberTitle', 'off');
sgtitle('CASE 10: 2 Step Hatası (@5s) + 3. Range Hatası (@20s)');
subplot(2,2,1); plot(t, sig1, 'r', 'LineWidth', 1.5); grid on; title('Signal 1 (STEP FAIL @5s)'); ylim([0 30]);
subplot(2,2,2); plot(t, sig2, 'r', 'LineWidth', 1.5); grid on; title('Signal 2 (STEP FAIL @5s)'); ylim([0 30]);
subplot(2,2,3); plot(t, sig3, 'm', 'LineWidth', 1.5); grid on; title('Signal 3 (RANGE FAIL @20s)'); 
subplot(2,2,4); plot(t, sig4, 'g', 'LineWidth', 1.5); grid on; title('Signal 4 (SURVIVOR)'); ylim([0 30]);

%% CASE 11: All Signals Oscillating (Turbulence/Common Mode)
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);

turb_start = round(5/dt);
turb_freq = 15; 
turbulence = 3 * sin(22 * t(turb_start:end));

sig1(turb_start:end) = sig1(turb_start:end) + turbulence;
sig2(turb_start:end) = sig2(turb_start:end) + turbulence;
sig3(turb_start:end) = sig3(turb_start:end) + turbulence;
sig4(turb_start:end) = sig4(turb_start:end) + turbulence;

save('test_data/case_11_turbulence.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');

figure('Name', 'CASE 11: Turbulence', 'NumberTitle', 'off');
sgtitle('CASE 11: Tüm Sinyaller Osile (Türbülans)');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1); grid on; title('Signal 1'); ylim([0 10]);
subplot(2,2,2); plot(t, sig2, 'LineWidth', 1); grid on; title('Signal 2'); ylim([0 10]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1); grid on; title('Signal 3'); ylim([0 10]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1); grid on; title('Signal 4'); ylim([0 10]);

%% CASE 12: All Signals Drifts
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);


drift_time = 30 / dt;

sig1(drift_time : end) = linspace(3.4 , 16, length(sig1(drift_time : end)));
sig2(drift_time : end) = linspace(3.2 , 15, length(sig1(drift_time : end)));
sig3(drift_time : end) = linspace(3.0 , 7, length(sig1(drift_time : end)));
sig4(drift_time : end) = linspace(2.9 , 8, length(sig1(drift_time : end)));

save('test_data/case_12_split.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags');


figure('Name', 'CASE 12: 2by2 Split', 'NumberTitle', 'off');
sgtitle('CASE 12: 2by2 Split');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1); grid on; title('Signal 1'); ylim([0 10]);
subplot(2,2,2); plot(t, sig2, 'LineWidth', 1); grid on; title('Signal 2'); ylim([0 10]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1); grid on; title('Signal 3'); ylim([0 10]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1); grid on; title('Signal 4'); ylim([0 10]); 

%% CASE 13: Reset
sig1 = base_sig1; sig2 = base_sig2; sig3 = base_sig3; sig4 = base_sig4;
BIT_flags = zeros(4, len);
reset_button = zeros(size(t));

error_start = 10/dt; 
error_end = 15/dt;
sig2(error_start : error_end) = 8; 
reset_button(22/dt + 1 ) = 1  ; % assumed reset button pressed at t = 17s

save('test_data/case_13_reset.mat', 't', 'dt', 'sig1', 'sig2', 'sig3', 'sig4', 'BIT_flags','reset_button');

figure('Name', 'CASE 13: Reset', 'NumberTitle', 'off');
subplot(2,2,1); plot(t, sig1, 'LineWidth', 1.5); grid on; title('Signal 1'); ylim([0 25]);
subplot(2,2,2); plot(t, sig2, 'r', 'LineWidth', 1.5); grid on; title('Signal 2'); ylim([0 25]);
subplot(2,2,3); plot(t, sig3, 'LineWidth', 1.5); grid on; title('Signal 3'); ylim([0 25]);
subplot(2,2,4); plot(t, sig4, 'LineWidth', 1.5); grid on; title('Signal 4'); ylim([0 25]);