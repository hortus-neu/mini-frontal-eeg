% clear workspace
clear; clc;

% launch eeg
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% make directory for preprocessed clean data
% repo root = the parent folder of this script's folder
thisFileDir = fileparts(mfilename('fullpath'));    % .../repo/scripts
repoRoot    = fileparts(thisFileDir);              % .../repo
cleanDir    = fullfile(repoRoot, 'data', 'cleaned');
if ~exist(cleanDir, 'dir'); mkdir(cleanDir); end

% load data
%% This is loading sample data.
%% Change to your own data later.
demoSet = fullfile(fileparts(which('eeglab')), ...
    'sample_data', ...
    'eeglab_data.set');

if exist(demoSet, 'file')
    EEG = pop_loadset('filename', 'eeglab_data.set', ...
                      'filepath', fileparts(demoSet));
else
    error('Your data file not found. Please check the path.');
end

% validate the imported eeg dataset
EEG = eeg_checkset(EEG);
fprintf('You have load eeg dataset named: %s\n', EEG.setname)

% save current eeg data to the global variable
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

% BPF
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'hicutoff', 40);
EEG = eeg_checkset(EEG)

% Notch filter
EEG = pop_eegfiltnew(EEG, 'locutoff', 59, 'hicutoff', 61, 'revfilt', 1); % 59–61 Hz bandstop
EEG = eeg_checkset(EEG);

% Average reference
EEG = pop_reref(EEG, []);
EEG = eeg_checkset(EEG);

% ICA
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt', 'on');
EEG = eeg_checkset(EEG);

% check ICLabel
if exist('iclabel','file') == 2
    EEG = iclabel(EEG);
    th_muscle    = 0.80;
    th_eye       = 0.80;
    th_heart     = 0.80;
    th_linenoise = 0.90;

    labels = EEG.etc.ic_classification.ICLabel.classifications; % (#IC x 7)
    isMuscle = labels(:,2) >= th_muscle;
    isEye    = labels(:,3) >= th_eye;
    isHeart  = labels(:,4) >= th_heart;
    isLine   = labels(:,5) >= th_linenoise;

    toRemove = find(isMuscle | isEye | isHeart | isLine);
    if ~isempty(toRemove)
        fprintf('Removing ICs: %s\n', mat2str(toRemove));
        EEG = pop_subcomp(EEG, toRemove, 0);
        EEG = eeg_checkset(EEG);
    else
        fprintf('No ICs met removal thresholds.\n');
    end
else
    warning('ICLabel not installed. Skipping automatic IC removal.');
end

% save cleaned data
%% rename your cleaned dataset later:
outName = 'sample_cleaned.set';
EEG = pop_saveset(EEG, 'filename', outName, 'filepath', cleanDir);
fprintf('Saved cleaned dataset to: %s\n', fullfile(cleanDir, outName));

disp('Pipeline done ✅');