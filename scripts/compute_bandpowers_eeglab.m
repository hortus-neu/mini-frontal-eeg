% run bandpower analysis in batch
function [bpTable, FAA] = compute_bandpowers_eeglab(EEG, labels, ...
    bands, welchCfg)
% labels {'F3','F4','Fz','AFz'}。
% bands → band range like bands.alpha = [8 12];

    fs = EEG.srate; % sampling rate

    idx = pick_channels_by_labels_for_ffa(EEG, labels);

    if any(isnan(idx))
        missing = labels(isnan(idx));
        error("missing channel: %s", strjoin(missing, '.'))
    end

    nCh = numel(idx); % number of channels
    bandNames = fieldnames(bands);
    nband = numel(bandNames);

    bpMat = zeros(nCh, nband);
    
    if EEG.trials <= 1
        X = EEG.data(idx, :);              % [ch x time]
        T = size(X,2); % time series
        X = reshape(X, nCh, T, 1);         % [ch x time x 1]
        nTr = 1;  % number of trials
    else
        % EEGLAB: [ch x time x trials]
        X = EEG.data(idx, :, :);
        nTr = EEG.trials;
    end

    for c = 1:nCh % loop over each channel (e.g., F3, F4, Fz, AFz). Current channel index = c.
        % Create an array to accumulate band power for this channel.
        % Length = number of frequency bands (e.g., alpha, theta → 2).
        % Initialize with zeros.
        acc = zeros(1, numel(bandNames));
        
        % Loop over each trial (experimental epoch).
        % If the EEG is continuous, there will be only 1 trial.
        for tr = 1:nTr
            % Extract data from X [ch × time × trials]:
            % Channel c
            % All time points
            % Trial tr
            % squeeze removes singleton dimensions → resulting in a 1 × time vector.
            % This is the signal of one channel in one trial.
            x = squeeze(X(c, :, tr));
            
            % Call the lower-level function you wrote.
            % Input: one trial from one channel.
            % Output:
            % out.f   → frequency axis
            % out.psd → power spectral density
            % out.bp  → band power for each frequency band
            out = psd_bandpower(x, fs, bands, welchCfg);
            
            % Loop over each frequency band (e.g., alpha, theta).
            % bandNames{j} extracts the band name string ('alpha' / 'theta').
            for j = 1:numel(bandNames)
                % Get the band power value from the result.
                % Accumulate into acc(j).
                % 👉 This way, we sum the results across all trials.
                acc(j) = acc(j) + out.bp.(bandNames{j});
            end
        end
        
        % Divide the accumulated results by the number of trials to get
        % the average band power across trials.
        % Store it into row c of bpMat.
        % Each row corresponds to a channel, each column to a frequency band.
        bpMat(c, :) = acc / nTr;   % trial-averaged band power
    end


    % Build the result table
    % labels are the channel names you want to analyze, e.g.: labels = {'F3','F4','Fz','AFz'};
    % (:) forces it to be a column vector, so each channel name takes one row.
    % MATLAB's table works like an Excel sheet, with column names, and each column can hold different data types.
    % Here we first create a table with only one column for channel names.
    % Assign the column name as "channel".
    % So the first column header will be "channel".
    bpTable = table(labels(:), 'VariableNames', {'channel'});
    
    % Iterate over each frequency band. bandNames = {'alpha','theta'}
    for j = 1:numel(bandNames)
        % bpTable.(bandNames{j}) → dynamically add a new column to the table, with the current band name.
        % bpMat(:, j) → extracts the column of band power values for this band across all channels.
        % Assign this column to the table.
        bpTable.(bandNames{j}) = bpMat(:, j);
    end


    % FAA
    iF3 = find(strcmpi(bpTable.channel,'F3'));
    iF4 = find(strcmpi(bpTable.channel,'F4'));

    if isempty(iF3) || isempty(iF4)
        error('FAA needs F3 and F4');
    end

    Palpha_F3 = bpTable.alpha(iF3);
    Palpha_F4 = bpTable.alpha(iF4);
    FAA = log10(Palpha_F4) - log10(Palpha_F3);
end
    