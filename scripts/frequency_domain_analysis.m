%% Stage 3: Frequency-domain analysis (Alpha/Theta & FAA)
% Input: the latest .set file under data/cleaned/
% Output: figs/psd.png, figs/faa.png
clear; clc;

addpath('scripts');
% Ensure EEGLAB is on the MATLAB path (already installed in Stage 0)
if exist('eeglab','file') ~= 2
    error('Please add EEGLAB to the MATLAB path first (eeglab.m must be callable)');
end

% Create figs directory if it does not exist
if ~exist('figs','dir'), mkdir('figs'); end


%% A. Load the latest .set file from data/cleaned/
dataDir = fullfile('data','cleaned');
files = dir(fullfile(dataDir, '*.set'));
assert(~isempty(files), 'No .set file found under data/cleaned/');

% files comes from dir(), it is a struct array, each element corresponds to a file.
% files.datenum → the timestamp (numeric date) of each file.
% [files.datenum] → concatenate all timestamps into an array, e.g. [7.4123e+05, 7.4124e+05, ...].
% sort(..., 'descend')
% Sort these timestamps.
% 'descend' = sort from largest to smallest (latest files first).
% Returns two outputs:
%   sorted values
%   the original indices corresponding to those values
% ~ : ignore the sorted values (we don't care about the actual dates).
% ix: keep the indices of the sorted order.
[~,ix] = sort([files.datenum], 'descend');

% The previous line [~,ix] = sort([files.datenum], 'descend'); already sorted the files, newest first.
% ix(1) → takes the first index after sorting, which corresponds to the latest file.
% files(ix(1)) → the struct of the latest file (containing .name, .datenum, etc.).
% Extract the filename string of the latest file, e.g., "subject1_cleaned.set".
% fullfile builds the path according to the operating system, avoiding manual slashes.
% dataDir = 'data/cleaned' (defined earlier).
% Combine to get the full path:
latestSet = fullfile(dataDir, files(ix(1)).name);

fprintf('Loading: %s\n', latestSet);

EEG = pop_loadset('filename', files(ix(1)).name, 'filepath', dataDir);

%% B. Parameter
labels = {'F3','F4','Fz'};
bands.alpha = [8 12];
bands.theta = [4 7];

welchCfg.winSec  = 2;
welchCfg.overlap = 0.5;
welchCfg.nfft    = [];
welchCfg.window  = 'hamming';

%% C. FAA computation
[bpTab, FAA] = compute_bandpowers_eeglab(EEG, labels, bands, welchCfg);
disp('--- Bandpower ---'); disp(bpTab);
fprintf('FAA = log10(Palpha_F4) - log10(Palpha_F3) = %.4f\n', FAA);

%% D. Figure 1: Alpha bar plot across channels
% Create a new figure window
% 'Color','w' → set the background color to white
% 'Position',[120 120 820 420] → set figure window position and size: [left bottom width height]
fig1 = figure('Color','w','Position',[120 120 820 420]);

% Draw a bar chart of the alpha band power for each channel
bar(bpTab.alpha);

% Configure the x-axis:
% XTick = 1 : number of rows in bpTab (i.e., one tick per channel)
% XTickLabel = use the channel names (e.g., F3, F4, Fz, AFz)
set(gca,'XTick',1:height(bpTab),'XTickLabel',bpTab.channel);

% Label the y-axis to indicate it shows alpha band power
ylabel('Alpha band power (8–12 Hz)');

% Add a title describing the figure
title('Alpha power by channel (F3/F4/Fz/AFz)');

% Add a grid to make the bar chart easier to read
grid on;

% Save the figure as a PNG file under the figs directory, named psd.png
saveas(fig1, fullfile('figs','psd.png'));


%% (Optional) Plot Alpha and Theta comparison (grouped bar chart)
% This block generates an additional figure to compare Alpha and Theta band power
% side-by-side for each channel. It is optional — useful if you want to visualize
% more than just Alpha, but also Theta, across the frontal electrodes.

% Create a new figure window
% 'Color','w' → set background color to white (better for exporting)
% 'Position',[120 120 920 440] → specify figure window position and size:
%    left=120 px, bottom=120 px, width=920 px, height=440 px
fig1b = figure('Color','w','Position',[120 120 920 440]);

% Draw a grouped bar chart
% Input to bar() is a matrix:
%   column 1 = alpha power for each channel
%   column 2 = theta power for each channel
% bar() automatically places them side-by-side for each channel
bar([bpTab.alpha bpTab.theta]);

% Configure the x-axis
% XTick = one tick per channel (1,2,...,N where N=height(bpTab))
% XTickLabel = channel names (from bpTab.channel, e.g., F3, F4, Fz, AFz)
set(gca,'XTick',1:height(bpTab),'XTickLabel',bpTab.channel);

% Add a legend to distinguish between the two frequency bands
% 'Location','northwest' places the legend in the upper-left corner of the plot
legend({'Alpha (8–12Hz)','Theta (4–7Hz)'},'Location','northwest');

% Label the y-axis to indicate this shows band power values
ylabel('Band power');

% Add a title for clarity
title('Alpha/Theta power by channel');

% Add grid lines to make it easier to compare bar heights
grid on;

% Save the figure as a PNG file in the figs/ directory
% File name = psd_alpha_theta.png
saveas(fig1b, fullfile('figs','psd_alpha_theta.png'));



%% E. Figure 2: FAA single value 
% This figure shows the computed Frontal Alpha Asymmetry (FAA) as a single bar.
% If you later implement time-resolved FAA (sliding windows), you can replace
% or overwrite this figure with a time-series plot. For now, it's just a static bar.

% Create a new figure window
% 'Color','w' → set the background color to white
% 'Position',[120 120 640 360] → window position and size [left bottom width height]
fig2 = figure('Color','w','Position',[120 120 640 360]);

% Draw a single bar at x=1 with height = FAA value
bar(1, FAA);

% Limit the x-axis from 0 to 2 so the single bar is centered and visible
xlim([0 2]);

% Configure the x-axis ticks and labels:
% XTick = only one tick at position 1
% XTickLabel = a descriptive label showing the formula used for FAA
set(gca,'XTick',1,'XTickLabel',{'FAA = log10(P_{F4}) - log10(P_{F3})'});

% Label the y-axis to indicate this is the FAA value (in log10 power ratio units)
ylabel('FAA (log10 power ratio)');

% Add a title to the figure
% sprintf formats the numeric FAA value into the title (with 3 decimal places)
title(sprintf('Frontal Alpha Asymmetry (FAA): %.3f', FAA));

% Add grid lines to make the plot easier to read
grid on;

% Save the figure as a PNG file under figs/ directory, named faa.png
saveas(fig2, fullfile('figs','faa.png'));

% Print a message to the MATLAB command window to confirm completion
disp('Done: figs/psd.png and figs/faa.png have been generated.');
