%% ========================================================================
% *************Introduction*************
% ========================================================================

%    This code shows the comparisons between the SDR and ZF methods 
%    in terms of radar MI, including the comparison between the 
%    true radar MI and its surrogate, as well as the direct MI 
%    comparison between SDR and ZF. It also provides DP
%    evaluation (Fig. 6).
%
%    All relevant data comes from struct "results_curve"


%% ========================================================================
% *************Description of results_curve*************
% ========================================================================
%
% results_curve is the main output structure used to store simulation
% results over different SINR thresholds Gamma. The simulation follows a
% two-level Monte Carlo structure:
%
%   1) Outer Monte Carlo: random user distance d in distance_range. 
%   2) Inner Monte Carlo: random user channel H for each fixed distance.
%   3) For each valid channel realization, all Gamma points are evaluated.
%
% Scalar metrics, including MI and runtime, are averaged in two stages:
%
%   First stage:
%       Average over channel realizations for each fixed user distance.
%
%   Second stage:
%       Average the distance-level results over all distance realizations.
%
% The transmit covariance matrices R are NOT averaged. They are saved
% sample-by-sample for every Gamma, every channel realization, and every
% user-distance realization.
%
% ------------------------------------------------------------------------
% Basic x-axis information
% ------------------------------------------------------------------------
%
% ★ results_curve.Gamma_dB
%    Column vector of SINR thresholds in dB.
%    Size: num_gamma x 1.
%    Example: results_curve.Gamma_dB = [5; 10; 15; 20; 25].
%
% ------------------------------------------------------------------------
% Average MI upper-bound values
% ------------------------------------------------------------------------
%
% ★ results_curve.qsdp_Iup
%    Average MI upper-bound obtained by the ZF method.
%    Size: num_gamma x 1.
%    The value at index gamma_idx corresponds to Gamma_dB(gamma_idx).
%
% ★ results_curve.sdr_Iup
%    Average MI upper-bound obtained by the SDR method.
%    Size: num_gamma x 1.
%
% ------------------------------------------------------------------------
% Average true clutter-aware radar MI values
% ------------------------------------------------------------------------
%
% ★ results_curve.qsdp_Ic
%    Average clutter-aware radar mutual information I_c obtained by the
%    ZF method.
%    Size: num_gamma x 1.
%
% ★ results_curve.sdr_Ic
%    Average clutter-aware radar mutual information I_c obtained by the
%    SDR method.
%    Size: num_gamma x 1.
%
% ------------------------------------------------------------------------
% Average clutter-free / target-only radar MI values
% ------------------------------------------------------------------------
%
% ★ results_curve.qsdp_I
%    Average target-only radar mutual information I obtained by the ZF
%    method.
%    Size: num_gamma x 1.
%
% ★ results_curve.sdr_I
%    Average target-only radar mutual information I obtained by the SDR
%    method.
%    Size: num_gamma x 1.
%
% ------------------------------------------------------------------------
% Average CPU runtime
% ------------------------------------------------------------------------
%
% ★ results_curve.qsdp_time_avg
%    Average CPU runtime of the ZF method for each Gamma.
%    Size: num_gamma x 1.
%    Unit: seconds.
%
% ★ results_curve.sdr_time_avg
%    Average CPU runtime of the SDR method for each Gamma.
%    Size: num_gamma x 1.
%    Unit: seconds.
%
% ------------------------------------------------------------------------
% Distance Monte Carlo information
% ------------------------------------------------------------------------
%
% ★ results_curve.distance_all
%    Flattened list of all accepted user distances.
%    Size: total_MC_target x 1.
%    Each entry corresponds to one accepted channel realization.
%
% ★ results_curve.loss_db_all
%    Flattened list of the path-loss values corresponding to distance_all.
%    Size: total_MC_target x 1.
%    Unit: dB.
%
% ★ results_curve.distance_range
%    Range of random user distance.
%    Size: 2 x 1.
%    Example: [40; 50] means d is randomly sampled from [40 m, 50 m].
%
% ★ results_curve.distance_MC
%    Number of outer Monte Carlo realizations for user distance.
%
% ★ results_curve.MC_target_per_distance
%    Number of valid channel realizations collected for each fixed distance.
%
% ★ results_curve.total_MC_target
%    Total number of accepted channel realizations.
%    It satisfies: total_MC_target = distance_MC * MC_target_per_distance.
%
% ------------------------------------------------------------------------
% CVX feasibility and rejection statistics
% ------------------------------------------------------------------------
%
% ★ results_curve.attempt_count_total
%    Total number of attempted random channel generations over all distances.
%
% ★ results_curve.attempt_count_each_distance
%    Number of attempted channel generations for each fixed distance.
%    Size: distance_MC x 1.
%
% ★ results_curve.reject_count_each_distance
%    Number of rejected channel groups for each fixed distance.
%    A channel group is rejected if any Gamma point fails to produce valid
%    solutions for all required methods.
%    Size: distance_MC x 1.
%
% ------------------------------------------------------------------------
% Distance-level average MI upper-bound values
% ------------------------------------------------------------------------
%
% ★ results_curve.Iup_qsdp_dist_avg
%    Distance-level average MI upper-bound for ZF.
%    Size: distance_MC x num_gamma.
%    Entry (dist_idx, gamma_idx) is the average over channel realizations
%    under the dist_idx-th fixed distance and gamma_idx-th SINR threshold.
%
% ★ results_curve.Iup_sdr_dist_avg
%    Distance-level average MI upper-bound for SDR.
%    Size: distance_MC x num_gamma.
%
% ------------------------------------------------------------------------
% Distance-level average clutter-aware radar MI values
% ------------------------------------------------------------------------
%
% ★ results_curve.Ic_qsdp_dist_avg
%    Distance-level average clutter-aware radar MI I_c for ZF.
%    Size: distance_MC x num_gamma.
%
% ★ results_curve.Ic_sdr_dist_avg
%    Distance-level average clutter-aware radar MI I_c for SDR.
%    Size: distance_MC x num_gamma.
%
% ------------------------------------------------------------------------
% Distance-level average target-only radar MI values
% ------------------------------------------------------------------------
%
% ★ results_curve.I_qsdp_dist_avg
%    Distance-level average target-only radar MI I for ZF.
%    Size: distance_MC x num_gamma.
%
% ★ results_curve.I_sdr_dist_avg
%    Distance-level average target-only radar MI I for SDR.
%    Size: distance_MC x num_gamma.
%
% ------------------------------------------------------------------------
% Distance-level average runtime
% ------------------------------------------------------------------------
%
% ★ results_curve.time_qsdp_dist_avg
%    Distance-level average CPU runtime for ZF.
%    Size: distance_MC x num_gamma.
%    Unit: seconds.
%
% ★ results_curve.time_sdr_dist_avg
%    Distance-level average CPU runtime for SDR.
%    Size: distance_MC x num_gamma.
%    Unit: seconds.
%
% ------------------------------------------------------------------------
% Complete transmit covariance matrix storage
% ------------------------------------------------------------------------
%
% ★ results_curve.qsdp_R_all_tensor
%    Complete transmit covariance matrices generated by ZF.
%    Size: Nt x Nt x MC_target_per_distance x distance_MC x num_gamma.
%
% ☛☛☛ Access example:
%       R = results_curve.qsdp_R_all_tensor(:,:,mc_idx,dist_idx,gamma_idx);
%
%  → where:
%       mc_idx     : index of channel Monte Carlo sample under a fixed distance;
%       dist_idx   : index of distance Monte Carlo sample;
%       gamma_idx  : index of SINR threshold.
%
% ★ results_curve.sdr_R_all_tensor
%    Complete transmit covariance matrices generated by SDR.
%    Size:
%       Nt x Nt x MC_target_per_distance x distance_MC x num_gamma.
%
% ☛☛☛  Access example:
%        R = results_curve.sdr_R_all_tensor(:,:,mc_idx,dist_idx,gamma_idx);
%
% ------------------------------------------------------------------------
% R tensor dimension note
% ------------------------------------------------------------------------
%
% ★ results_curve.R_tensor_dimension
%    Text description of the R tensor dimension:
%        'Nt x Nt x MC_target x distance_MC x num_gamma'
%
% ------------------------------------------------------------------------
% Cell-form R storage for each Gamma
% ------------------------------------------------------------------------
%
% ★ results_curve.qsdp_R_all
%    Cell array storing ZF R matrices separately for each Gamma.
%    Size: num_gamma x 1 cell.
%
%   Each cell has size:
%       Nt x Nt x MC_target_per_distance x distance_MC.
%
% ☛☛☛  Access example:
%       R = results_curve.qsdp_R_all{gamma_idx}(:,:,mc_idx,dist_idx);
%
% ★ results_curve.sdr_R_all
%    Cell array storing SDR R matrices separately for each Gamma.
%    Size: num_gamma x 1 cell.
%
%   Each cell has size:
%       Nt x Nt x MC_target_per_distance x distance_MC.
%
% ☛☛☛  Access example:
%       R = results_curve.sdr_R_all{gamma_idx}(:,:,mc_idx,dist_idx);
%
% ------------------------------------------------------------------------
% ☞ Notes :
% ------------------------------------------------------------------------
%
% 1) qsdq naming:
%    In the current code, qsdp refers to the ZF method.
%
%
% 2) Scalar metrics are averaged:
%    Iup, Ic, I, and runtime are first averaged over channel samples under
%    each fixed distance and then averaged over distance samples.
%
% 3) Strict rejection rule:
%    For one channel realization, all Gamma points must be valid. If any
%    Gamma point fails for either ZF or SDR, the whole channel group is
%    discarded.



clearvars;
clc;
rng('shuffle');

%% settings
Nt = 9; Nr = 9; U = 4; K = 3; S = 2; L = 1024; e = 1e-4; c = 1e-4;

P_list = [db2pow(-4) db2pow(-2) db2pow(0) db2pow(2) db2pow(4) ...
          db2pow(6) db2pow(8) db2pow(10) db2pow(12) db2pow(14)];
P_dB_list = [-4 -2 0 2 4 6 8 10 12 14];

Gamma = db2pow(10);
Gamma_dB = 10;

distance_MC=10; % 
distance_range=[40, 50];   % m

sigma_r = db2pow(-145);
sigma_0 = db2pow(-160);
sigma_1 = db2pow(-160);
sigma_u = db2pow(-145);
tao = sigma_0 / sigma_r;


MC_target=20;            % 
MC_max_attempts = 2000;        % 
total_MC_target = distance_MC * MC_target;

loc_t_fixed = deg2rad([-30, 0, 30]);
loc_s_fixed = deg2rad([-60, 60]);

%% Curve 
num_power = length(P_list);
results_curve = struct();
results_curve.P_dB = P_dB_list(:);
results_curve.P_list = P_list(:);
results_curve.fixed_Gamma_dB = Gamma_dB;
results_curve.qsdp_Iup = zeros(num_power,1);
results_curve.qsdp_Ic  = zeros(num_power,1);
results_curve.qsdp_I   = zeros(num_power,1);
results_curve.sdr_Iup  = zeros(num_power,1);
results_curve.sdr_Ic   = zeros(num_power,1);
results_curve.sdr_I    = zeros(num_power,1);
results_curve.qsdp_time_avg = zeros(num_power,1);
results_curve.sdr_time_avg  = zeros(num_power,1);
results_curve.qsdp_R_all = cell(num_power,1);
results_curve.sdr_R_all  = cell(num_power,1);

results_all = cell(num_power,1);

%% Warm-up CVX
cvx_clear;
cvx_begin quiet
    variable dummy(2,1)
    minimize(norm(dummy))
    subject to
        dummy >= 0
cvx_end
cvx_clear;

%% 
accepted_count = 0;
attempt_count_total = 0;
reject_count = 0;
reject_power_count = zeros(num_power,1);
attempt_count_each_distance = zeros(distance_MC, 1);
reject_count_each_distance  = zeros(distance_MC, 1);
Iup_qsdp_all = zeros(total_MC_target,num_power);
Iup_sdr_all  = zeros(total_MC_target,num_power);
Ic_qsdp_all  = zeros(total_MC_target,num_power);
Ic_sdr_all   = zeros(total_MC_target,num_power);
I_qsdp_all   = zeros(total_MC_target,num_power);
I_sdr_all    = zeros(total_MC_target,num_power);
time_qsdp_all = zeros(total_MC_target,num_power);
time_sdr_all  = zeros(total_MC_target,num_power);

distance_all = zeros(total_MC_target,1);
loss_db_all  = zeros(total_MC_target,1);

%% R storage: Nt x Nt x channel-MC x distance-MC x power
R_qsdp_all = zeros(Nt, Nt, MC_target, distance_MC, num_power);
R_sdr_all  = zeros(Nt, Nt, MC_target, distance_MC, num_power);


Iup_qsdp_dist_avg = zeros(distance_MC,num_power);
Iup_sdr_dist_avg  = zeros(distance_MC,num_power);
Ic_qsdp_dist_avg  = zeros(distance_MC,num_power);
Ic_sdr_dist_avg   = zeros(distance_MC,num_power);
I_qsdp_dist_avg   = zeros(distance_MC,num_power);
I_sdr_dist_avg    = zeros(distance_MC,num_power);
time_qsdp_dist_avg = zeros(distance_MC,num_power);
time_sdr_dist_avg  = zeros(distance_MC,num_power);

for dist_idx = 1:distance_MC

    d_current = distance_range(1) + diff(distance_range) * rand;
    loss_db_current = 72 + 29.2 * log10(d_current);

    dist_valid_count = 0;
    dist_start_idx = accepted_count + 1;

    attempt_count_dist = 0;
    reject_count_dist  = 0;

    fprintf('[Distance MC %d/%d] d = %.4f m, loss_db = %.4f dB\n', ...
        dist_idx, distance_MC, d_current, loss_db_current);

    while dist_valid_count < MC_target && attempt_count_dist < MC_max_attempts

        attempt_count_dist = attempt_count_dist + 1;
        attempt_count_total = attempt_count_total + 1;

        loc_t = loc_t_fixed;
        loc_s = loc_s_fixed;

        A_t = zeros(Nt, K); B_t = zeros(Nr, K);
        for k = 1:K
            A_t(:, k) = steering_ula(loc_t(k), Nt).';
            B_t(:, k) = steering_ula(loc_t(k), Nr).';
        end

        A_s = zeros(Nt, S); B_s = zeros(Nr, S);
        for s = 1:S
            A_s(:, s) = steering_ula(loc_s(s), Nt).';
            B_s(:, s) = steering_ula(loc_s(s), Nr).';
        end

        [Rr, ~] = build_target_covariance(A_t, B_t, sigma_0); 
        Rsc = build_target_covariance(A_s, B_s, sigma_1);

        H = zeros(U, Nt);
        for u = 1:U
            H(u, :) = generate_user_channel(Nt, loss_db_current);
        end

        R_qsdp_group = zeros(Nt, Nt, num_power);
        R_sdr_group  = zeros(Nt, Nt, num_power);

        Iup_qsdp_group = zeros(num_power,1);
        Iup_sdr_group  = zeros(num_power,1);
        Ic_qsdp_group  = zeros(num_power,1);
        Ic_sdr_group   = zeros(num_power,1);
        I_qsdp_group   = zeros(num_power,1);
        I_sdr_group    = zeros(num_power,1);
        time_qsdp_group = zeros(num_power,1);
        time_sdr_group  = zeros(num_power,1);

        group_valid = true;

        for power_idx = 1:num_power

            P = P_list(power_idx);

            tic;
            [~, R_qsdp, ~, status_qsdp, valid_qsdp] = solve_zf_qsdp(A_t, A_s, H, P, Gamma, tao, L, Nt, U, K, S, sigma_u, e, c);
            time_qsdp = toc;

            tic;
            [~, R_sdr,  ~, status_sdr,  valid_sdr ] = SDPU3(A_t, A_s, H, P, Gamma, tao, L, Nt, Nr, U, K, S, sigma_u, e, c);
            time_sdr = toc;

            if ~(valid_qsdp && valid_sdr)
                group_valid = false;
                reject_power_count(power_idx) = reject_power_count(power_idx) + 1;
                fprintf('[Dist %d][Attempt %d/%d][Global Attempt %d][Group Skip][P=%2d dB] status: QSDP=%s | SDR=%s\n', ...
                    dist_idx,attempt_count_dist,MC_max_attempts,attempt_count_total, ...
                    P_dB_list(power_idx), status_qsdp,status_sdr);
                break;
            end

            R_qsdp_group(:,:,power_idx) = R_qsdp;
            R_sdr_group(:,:,power_idx)  = R_sdr;

            time_qsdp_group(power_idx) = time_qsdp;
            time_sdr_group(power_idx)  = time_sdr;

            Iup_qsdp_group(power_idx) = compute_upperbound_from_R(A_t, R_qsdp, tao, L);
            Iup_sdr_group(power_idx)  = compute_upperbound_from_R(A_t, R_sdr,  tao, L);

            [Ic_qsdp_group(power_idx), I_qsdp_group(power_idx)] = compute_mi(Nt, Nr, sigma_r, L, R_qsdp, Rr, Rsc);
            [Ic_sdr_group(power_idx),  I_sdr_group(power_idx)]  = compute_mi(Nt, Nr, sigma_r, L, R_sdr,  Rr, Rsc);
        end

        if ~group_valid
            reject_count=reject_count + 1;
            reject_count_dist=reject_count_dist + 1;
            continue;
        end

        accepted_count = accepted_count + 1;
        idx_keep = accepted_count;

        dist_valid_count = dist_valid_count + 1;
        mc_idx = dist_valid_count;

        distance_all(idx_keep) = d_current;
        loss_db_all(idx_keep)  = loss_db_current;

        Iup_qsdp_all(idx_keep,:) = Iup_qsdp_group.';
        Iup_sdr_all(idx_keep,:)  = Iup_sdr_group.';
        Ic_qsdp_all(idx_keep,:)  = Ic_qsdp_group.';
        Ic_sdr_all(idx_keep,:)   = Ic_sdr_group.';
        I_qsdp_all(idx_keep,:)   = I_qsdp_group.';
        I_sdr_all(idx_keep,:)    = I_sdr_group.';
        time_qsdp_all(idx_keep,:)= time_qsdp_group.';
        time_sdr_all(idx_keep,:) = time_sdr_group.';

        
        for power_idx = 1:num_power
            R_qsdp_all(:,:,mc_idx,dist_idx,power_idx) = R_qsdp_group(:,:,power_idx);
            R_sdr_all(:,:,mc_idx,dist_idx,power_idx)  = R_sdr_group(:,:,power_idx);
        end

        for power_idx = 1:num_power
            fprintf('[Dist %d][Attempt %d/%d][Group Keep %d/%d][P=%2d dB] QSDP=%.4f, SDR=%.4f | time(s): QSDP=%.4f, SDR=%.4f\n', ...
                dist_idx, attempt_count_dist, MC_max_attempts, idx_keep, total_MC_target, ...
                P_dB_list(power_idx), Ic_qsdp_group(power_idx), Ic_sdr_group(power_idx), ...
                time_qsdp_group(power_idx), time_sdr_group(power_idx));
        end
    end

    attempt_count_each_distance(dist_idx) = attempt_count_dist;
    reject_count_each_distance(dist_idx)  = reject_count_dist;

    fprintf('[Distance MC %d/%d Finished] valid = %d/%d, attempts = %d, rejects = %d, acceptance ratio = %.4f\n', ...
        dist_idx, distance_MC, dist_valid_count, MC_target, ...
        attempt_count_dist, reject_count_dist, dist_valid_count / max(attempt_count_dist, 1));

    if dist_valid_count < MC_target
        error(['Only %d valid channel realizations were collected for distance MC %d ', ...
               'before reaching MC_max_attempts=%d. You may increase MC_max_attempts ', ...
               'or relax feasibility thresholds e/c/Gamma.'], ...
            dist_valid_count, dist_idx, MC_max_attempts);
    end

    
    dist_end_idx = accepted_count;
    dist_sample_idx = dist_start_idx:dist_end_idx;

    Iup_qsdp_dist_avg(dist_idx,:) = mean(Iup_qsdp_all(dist_sample_idx,:), 1);
    Iup_sdr_dist_avg(dist_idx,:)  = mean(Iup_sdr_all(dist_sample_idx,:), 1);
    Ic_qsdp_dist_avg(dist_idx,:)  = mean(Ic_qsdp_all(dist_sample_idx,:), 1);
    Ic_sdr_dist_avg(dist_idx,:)   = mean(Ic_sdr_all(dist_sample_idx,:), 1);
    I_qsdp_dist_avg(dist_idx,:)   = mean(I_qsdp_all(dist_sample_idx,:), 1);
    I_sdr_dist_avg(dist_idx,:)    = mean(I_sdr_all(dist_sample_idx,:), 1);
    time_qsdp_dist_avg(dist_idx,:) = mean(time_qsdp_all(dist_sample_idx,:), 1);
    time_sdr_dist_avg(dist_idx,:)  = mean(time_sdr_all(dist_sample_idx,:), 1);

    fprintf('[Distance MC %d/%d Average] Ic: QSDP=%s | SDR=%s\n', ...
        dist_idx, distance_MC, mat2str(Ic_qsdp_dist_avg(dist_idx,:), 4), mat2str(Ic_sdr_dist_avg(dist_idx,:), 4));
end

if accepted_count < total_MC_target
    error('Only %d valid power-groups were collected before reaching total_MC_target=%d.', accepted_count, total_MC_target);
end

%% Save
results_curve.distance_all = distance_all;
results_curve.loss_db_all = loss_db_all;
results_curve.distance_range = distance_range(:);
results_curve.distance_MC = distance_MC;
results_curve.MC_target_per_distance = MC_target;
results_curve.total_MC_target = total_MC_target;
results_curve.attempt_count_total = attempt_count_total;
results_curve.attempt_count_each_distance = attempt_count_each_distance;
results_curve.reject_count_each_distance = reject_count_each_distance;

results_curve.Iup_qsdp_dist_avg = Iup_qsdp_dist_avg;
results_curve.Iup_sdr_dist_avg  = Iup_sdr_dist_avg;
results_curve.Ic_qsdp_dist_avg  = Ic_qsdp_dist_avg;
results_curve.Ic_sdr_dist_avg   = Ic_sdr_dist_avg;
results_curve.I_qsdp_dist_avg   = I_qsdp_dist_avg;
results_curve.I_sdr_dist_avg    = I_sdr_dist_avg;
results_curve.time_qsdp_dist_avg = time_qsdp_dist_avg;
results_curve.time_sdr_dist_avg  = time_sdr_dist_avg;
results_curve.qsdp_R_all_tensor = R_qsdp_all;
results_curve.sdr_R_all_tensor  = R_sdr_all;
results_curve.R_tensor_dimension = 'Nt x Nt x MC_target x distance_MC x num_power';

for power_idx = 1:num_power

    results = struct();
    results.summary = struct( ...
        'accepted_count', accepted_count, ...
        'attempt_count_total', attempt_count_total, ...
        'reject_count', reject_count, ...
        'reject_power_count', reject_power_count(power_idx), ...
        'acceptance_ratio', accepted_count / max(attempt_count_total, 1), ...
        'P_dB', P_dB_list(power_idx), ...
        'Gamma_dB', Gamma_dB, ...
        'distance_range', distance_range, ...
        'distance_MC', distance_MC, ...
        'MC_target_per_distance', MC_target, ...
        'total_MC_target', total_MC_target, ...
        'distance_all', distance_all, ...
        'attempt_count_each_distance', attempt_count_each_distance, ...
        'reject_count_each_distance', reject_count_each_distance);

    results.qsdp = struct( ...
        'Iup_avg', mean(Iup_qsdp_dist_avg(:,power_idx)), ...
        'Ic_avg', mean(Ic_qsdp_dist_avg(:,power_idx)), ...
        'I_avg', mean(I_qsdp_dist_avg(:,power_idx)), ...
        'time_avg', mean(time_qsdp_dist_avg(:,power_idx)), ...
        'R_all', R_qsdp_all(:,:,:,:,power_idx));

    results.sdr = struct( ...
        'Iup_avg', mean(Iup_sdr_dist_avg(:,power_idx)), ...
        'Ic_avg', mean(Ic_sdr_dist_avg(:,power_idx)), ...
        'I_avg', mean(I_sdr_dist_avg(:,power_idx)), ...
        'time_avg', mean(time_sdr_dist_avg(:,power_idx)), ...
        'R_all', R_sdr_all(:,:,:,:,power_idx));

    results_curve.qsdp_Iup(power_idx) = results.qsdp.Iup_avg;
    results_curve.qsdp_Ic(power_idx)  = results.qsdp.Ic_avg;
    results_curve.qsdp_I(power_idx)   = results.qsdp.I_avg;

    results_curve.sdr_Iup(power_idx) = results.sdr.Iup_avg;
    results_curve.sdr_Ic(power_idx)  = results.sdr.Ic_avg;
    results_curve.sdr_I(power_idx)   = results.sdr.I_avg;

    results_curve.qsdp_time_avg(power_idx) = results.qsdp.time_avg;
    results_curve.sdr_time_avg(power_idx)  = results.sdr.time_avg;

    results_curve.qsdp_R_all{power_idx} = results.qsdp.R_all;
    results_curve.sdr_R_all{power_idx}  = results.sdr.R_all;

    results_all{power_idx} = results;
end

%% DP
A_t_dp = zeros(Nt, K);
B_t_dp = zeros(Nr, K);
A_s_dp = zeros(Nt, S);
B_s_dp = zeros(Nr, S);

for k = 1:K
    A_t_dp(:, k) = steering_ula(loc_t_fixed(k), Nt).';
    B_t_dp(:, k) = steering_ula(loc_t_fixed(k), Nr).';
end
for s = 1:S
    A_s_dp(:, s) = steering_ula(loc_s_fixed(s), Nt).';
    B_s_dp(:, s) = steering_ula(loc_s_fixed(s), Nr).';
end

Pfa = 1e-5;
DP_qsdp_all = zeros(MC_target, distance_MC, num_power);
DP_sdr_all  = zeros(MC_target, distance_MC, num_power);
DP_qsdp_dist_avg = zeros(distance_MC, num_power);
DP_sdr_dist_avg  = zeros(distance_MC, num_power);

fprintf('\n========== DP Computation from Saved R ==========\n');
for power_idx = 1:num_power
    fprintf('P = %.2f dB\n', P_dB_list(power_idx));

    for dist_idx = 1:distance_MC
        for mc_idx = 1:MC_target
            R_q = R_qsdp_all(:, :, mc_idx, dist_idx, power_idx);
            R_s = R_sdr_all(:, :, mc_idx, dist_idx, power_idx);
            R_q = (R_q + R_q') / 2;
            R_s = (R_s + R_s') / 2;

            [DP_qsdp_all(mc_idx, dist_idx, power_idx), ~, ~] = ...
                np_dp_kth_target_with_other_targets_as_interference( ...
                R_q, A_t_dp, B_t_dp, A_s_dp, B_s_dp, ...
                L, sigma_0, sigma_1, sigma_r, Pfa);

            [DP_sdr_all(mc_idx, dist_idx, power_idx), ~, ~] = ...
                np_dp_kth_target_with_other_targets_as_interference( ...
                R_s, A_t_dp, B_t_dp, A_s_dp, B_s_dp, ...
                L, sigma_0, sigma_1, sigma_r, Pfa);
        end

        DP_qsdp_dist_avg(dist_idx, power_idx) = mean(DP_qsdp_all(:, dist_idx, power_idx), 1);
        DP_sdr_dist_avg(dist_idx, power_idx)  = mean(DP_sdr_all(:, dist_idx, power_idx), 1);
    end

    results_curve.qsdp_DP_avg(power_idx) = mean(DP_qsdp_dist_avg(:, power_idx), 1);
    results_curve.sdr_DP_avg(power_idx)  = mean(DP_sdr_dist_avg(:, power_idx), 1);

    fprintf('    ZF  DP = %.6e\n', results_curve.qsdp_DP_avg(power_idx));
    fprintf('    SDR DP = %.6e\n', results_curve.sdr_DP_avg(power_idx));
end

results_curve.DP_qsdp_dist_avg = DP_qsdp_dist_avg;
results_curve.DP_sdr_dist_avg  = DP_sdr_dist_avg;
results_curve.DP_note = 'DP is computed from every saved R, then averaged over channel MC and distance MC.';

save('result_power_SDR_ZF_with_DP.mat', 'results_curve', 'results_all', '-v7.3');

%% Plot:ZF Ic, SDR Ic, SDR Iup
figure('Color', 'w', 'Units', 'pixels', 'Position', [120, 120, 760, 520]);
hold on; grid on; box on;

color_zf   = [0.08, 0.22, 0.48];  
color_sdr  = [0.55, 0.12, 0.10];   
color_iup  = [0.05, 0.38, 0.20];   

p1 = plot(results_curve.P_dB, results_curve.qsdp_Ic, '-o', ...
    'Color', color_zf, 'LineWidth', 2.2, 'MarkerSize', 7.5, ...
    'MarkerFaceColor', color_zf, 'MarkerEdgeColor', color_zf);

p2 = plot(results_curve.P_dB, results_curve.sdr_Ic, '--s', ...
    'Color', color_sdr, 'LineWidth', 2.2, 'MarkerSize', 7.5, ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_sdr);

p3 = plot(results_curve.P_dB, results_curve.sdr_Iup, '-.^', ...
    'Color', color_iup, 'LineWidth', 2.2, 'MarkerSize', 7.5, ...
    'MarkerFaceColor', color_iup, 'MarkerEdgeColor', color_iup);

xlabel('Transmit power $P$ (dB)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 15);
ylabel('Radar MI', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 15);
legend([p1, p2, p3], {'ZF, $I_c$', 'SDR, $I_c$', 'SDR, $I_{\rm up}$'}, ...
    'Interpreter', 'latex', 'Location', 'best', 'FontSize', 12, 'Box', 'off');

set(gca, 'FontName', 'Times New Roman', 'FontSize', 13, 'LineWidth', 1.05, ...
    'GridAlpha', 0.18, 'MinorGridAlpha', 0.10, 'XMinorGrid', 'off', ...
    'YMinorGrid', 'off', 'TickDir', 'in');

xlim([min(results_curve.P_dB)-0.5, max(results_curve.P_dB)+0.5]);
xticks(results_curve.P_dB);

Ic_all_plot = [results_curve.qsdp_Ic(:); results_curve.sdr_Ic(:); results_curve.sdr_Iup(:)];
y_min = min(Ic_all_plot);
y_max = max(Ic_all_plot);
y_pad = 0.08 * (y_max - y_min + eps);
ylim([y_min - y_pad, y_max + y_pad]);

ax = gca;
ax.Position = [0.115, 0.145, 0.835, 0.80];

%% Plot:Detection Probability
figure('Color', 'w', 'Units', 'pixels', 'Position', [160, 140, 760, 520]);
hold on; grid on; box on;

p4 = plot(results_curve.P_dB, results_curve.qsdp_DP_avg, '-o', ...
    'Color', color_zf, 'LineWidth', 2.2, 'MarkerSize', 7.5, ...
    'MarkerFaceColor', color_zf, 'MarkerEdgeColor', color_zf);

p5 = plot(results_curve.P_dB, results_curve.sdr_DP_avg, '--s', ...
    'Color', color_sdr, 'LineWidth', 2.2, 'MarkerSize', 7.5, ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_sdr);

xlabel('Transmit power $P$ (dB)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 15);
ylabel('Detection probability', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 15);
legend([p4, p5], {'ZF', 'SDR'}, 'Interpreter', 'latex', 'Location', 'best', 'FontSize', 12, 'Box', 'off');

set(gca, 'FontName', 'Times New Roman', 'FontSize', 13, 'LineWidth', 1.05, ...
    'GridAlpha', 0.18, 'MinorGridAlpha', 0.10, 'XMinorGrid', 'off', ...
    'YMinorGrid', 'off', 'TickDir', 'in');

xlim([min(results_curve.P_dB)-0.5, max(results_curve.P_dB)+0.5]);
xticks(results_curve.P_dB);

dp_all = [results_curve.qsdp_DP_avg(:); results_curve.sdr_DP_avg(:)];
dp_all = dp_all(~isnan(dp_all));
dp_min = min(dp_all);
dp_max = max(dp_all);
dp_pad = 0.08 * (dp_max - dp_min + eps);
ylim([max(0, dp_min - dp_pad), min(1, dp_max + dp_pad)]);

ax = gca;
ax.Position = [0.115, 0.145, 0.835, 0.80];

function [Ic, I] = compute_mi(Nt, Nr, sigma_r, L, R, Rr, Rsc)
    A = eye(Nt*Nr) + (L / sigma_r) * kron(eye(Nr), R) * Rr;
    B = eye(Nt*Nr) + (L / sigma_r) * kron(eye(Nr), R) * (Rr + Rsc);
    C = eye(Nt*Nr) + (L / sigma_r) * kron(eye(Nr), R) * Rsc;
    I  = real(log(det(A)));
    Ic = real(log(det(B)) - log(det(C)));
end

function Iup = compute_upperbound_from_R(a_t, R, tao, L)
    [~, K] = size(a_t);
    Iup = 0;
    for k = 1:K
        Iup = Iup + log(1 + real(tao * L * a_t(:,k)' * R * a_t(:,k)));
    end
end

function h = generate_user_channel(Nt, loss_db)
    beta = 10^(-0.1 * loss_db);
    h = sqrt(beta/2) * (randn(1, Nt) + 1i * randn(1, Nt));
end

function [Rr, Rr_sqrt] = build_target_covariance(a_t, a_r, sigma_0)
    [~, ct] = size(a_t);
    Rr = 0;
    for i = 1:ct
        Ai = a_t(:, i) * a_r(:, i)';
        vi = Ai(:);
        Rr = Rr + sigma_0 * (vi * vi');
    end
    Rr = (Rr + Rr') / 2;
    [V, D] = eig(Rr);
    d = real(diag(D));
    d(d < 0) = 0;
    Rr_sqrt = V * diag(sqrt(d)) * V';
    Rr_sqrt = (Rr_sqrt + Rr_sqrt') / 2;
end

function [opt, R, Ru, status, is_valid] = SDPU3(a_t, a_st, H, P, Gamma, tao, L, Nt, Nr, U, K, S, sigma_u, e, c)
    try
        cvx_clear;
        cvx_begin sdp quiet
            cvx_solver mosek
            cvx_precision low
            variable R(Nt,Nt) complex hermitian
            variable Ru(Nt,Nt,U) complex
            expression obj
            expression sumRu(Nt,Nt)

            obj = 0;
            sumRu = 0;

            for i = 1:K
                obj = obj + log(1 + real(tao * L * a_t(:,i)' * R * a_t(:,i)));
            end

            for u = 1:U
                Ru(:,:,u) == hermitian_semidefinite(Nt);
                sumRu = sumRu + Ru(:,:,u);
            end

            maximize(obj)
            subject to
                trace(R) <= P;
                R == hermitian_semidefinite(Nt);
                R - sumRu == hermitian_semidefinite(Nt);

                for i = 1:K-1
                    for j = i+1:K
                        abs(a_t(:,i)' * R * a_t(:,j)) <= e;
                    end
                end

                for i = 1:S
                    real(a_st(:,i)' * R * a_st(:,i)) <= c;
                end

                for u = 1:U
                    real((1 + Gamma^(-1)) * H(u,:) * Ru(:,:,u) * H(u,:)') / sigma_u ...
                        >= real(H(u,:) * R * H(u,:)') / sigma_u + 1;
                end
        cvx_end

        Ru_rec = zeros(Nt, Nt, U);
        for u = 1:U
            hu = H(u, :).';
            denom = real(trace((hu * hu') * Ru(:, :, u)));
            if denom <= 1e-12
                Ru_rec(:, :, u) = zeros(Nt, Nt);
            else
                Ru_tmp = (Ru(:, :, u) * (hu * hu') * Ru(:, :, u)) / denom;
                Ru_rec(:, :, u) = (Ru_tmp + Ru_tmp') / 2;
            end
        end
        Ru = Ru_rec;

        status = cvx_status;
        is_valid = is_cvx_status_acceptable(status, cvx_optval);
        if ~is_valid
            R = zeros(Nt, Nt); Ru = zeros(Nt, Nt, U); opt = inf;
        else
            opt = cvx_optval;
        end

    catch ME
        cvx_clear;
        R = zeros(Nt, Nt); Ru = zeros(Nt, Nt, U); opt = inf;
        status = ['exception: ', ME.identifier];
        is_valid = false;
    end
end

function [opt, R, p, status, is_valid] = solve_zf_qsdp(a_t, a_st, H, P, Gamma, tao, L, Nt, U, K, S, sigma_u, e, c)
    try
        cvx_clear;
        cvx_begin sdp quiet
            cvx_solver mosek
            cvx_precision low
            variable R(Nt,Nt) complex hermitian
            variable p(U,1)
            expression obj

            obj = 0;
            for i = 1:K
                obj = obj + log(1 + real(tao * L * a_t(:,i)' * R * a_t(:,i)));
            end

            maximize(obj)
            subject to
                trace(R) <= P;
                R == hermitian_semidefinite(Nt);

                H * R * H' / sigma_u == diag(p) / sigma_u + eps;

                for i = 1:K-1
                    for j = i+1:K
                        abs(a_t(:,i)' * R * a_t(:,j)) <= e;
                    end
                end

                for i = 1:S
                    real(a_st(:,i)' * R * a_st(:,i)) <= c;
                end

                for u = 1:U
                    p(u)/sigma_u >= Gamma;
                end
        cvx_end

        status = cvx_status;
        is_valid = is_cvx_status_acceptable(status, cvx_optval);
        if ~is_valid
            R = zeros(Nt, Nt); p = zeros(U, 1); opt = inf;
        else
            opt = cvx_optval;
        end

    catch ME
        cvx_clear;
        R = zeros(Nt, Nt); p = zeros(U, 1); opt = inf;
        status = ['exception: ', ME.identifier];
        is_valid = false;
    end
end

function ok = is_cvx_status_acceptable(status, optval)
    status_lower = lower(strtrim(status));
    good_status = strcmp(status_lower, 'solved');
    good_opt = ~(isempty(optval) || isnan(optval) || isinf(optval));
    ok = good_status && good_opt;
end

function ula_sv = steering_ula(theta, M)
    m = 0:M-1;
    ula_sv = exp(1i*pi*m*sin(theta)) / sqrt(M);
end

function [DP_avg, DP_each, d_each] = np_dp_kth_target_with_other_targets_as_interference( ...
    R, A_t, B_t, A_s, B_s, L, sigma0_2, sigma1_2, sigma_r2, Pfa)

    K = size(A_t, 2);
    S = size(A_s, 2);

    DP_each = zeros(K, 1);
    d_each  = zeros(K, 1);

    Gtt = zeros(K, K);
    for i = 1:K
        for j = 1:K
            Gtt(i, j) = L * (A_t(:, i)' * R * A_t(:, j)) * (B_t(:, j)' * B_t(:, i));
        end
    end
    Gtt = (Gtt + Gtt') / 2;

    Gss = zeros(S, S);
    for m = 1:S
        for n = 1:S
            Gss(m, n) = L * (A_s(:, m)' * R * A_s(:, n)) * (B_s(:, n)' * B_s(:, m));
        end
    end
    Gss = (Gss + Gss') / 2;

    Gts = zeros(K, S);
    for i = 1:K
        for s = 1:S
            Gts(i, s) = L * (A_t(:, i)' * R * A_s(:, s)) * (B_s(:, s)' * B_t(:, i));
        end
    end

    for k = 1:K

        other_idx = setdiff(1:K, k);
        num_other = K - 1;

        G_other_other = Gtt(other_idx, other_idx);
        G_other_s     = Gts(other_idx, :);
        G_s_other     = G_other_s';
        G_s_s         = Gss;

        G_int = [G_other_other, G_other_s;
                 G_s_other,     G_s_s];
        G_int = (G_int + G_int') / 2;

        var_int = [sigma0_2 * ones(num_other, 1);
                   sigma1_2 * ones(S, 1)];
        Dinv = diag(1 ./ var_int);

        Awood = Dinv + (1 / sigma_r2) * G_int;
        Awood = (Awood + Awood') / 2;

        g_other = Gtt(other_idx, k);
        g_s     = Gts(k, :).';
        g_k = [g_other; g_s];

        qk_norm2 = real(Gtt(k, k));

        d_k = qk_norm2 / sigma_r2 - real(g_k' * (Awood \ g_k)) / (sigma_r2^2);
        d_k = max(real(d_k), 0);
        d_each(k) = d_k;

        DP_each(k) = Pfa^(1 / (1 + sigma0_2 * d_k));
    end

    DP_avg = mean(DP_each);
end
