function out = psd_bandpower(x, fs, bands, welchCfg)
% x : single channel input [1xN] or [Nx1]
% bands: eeg band which you wanna analyze [lowerbond, upperbond]
% welchCfg: structure for Welch
% bandpower = ∑(PSD(f) × Δf),  f 在 [f_low, f_high]

     x = x(:);
     if ~isfield(welchCfg,'winSec'),  welchCfg.winSec = 2;   end
     if ~isfield(welchCfg,'winSec'),  welchCfg.winSec = 2;   end
     if ~isfield(welchCfg,'overlap'), welchCfg.overlap = 0.5; end
     if ~isfield(welchCfg,'nfft'),    welchCfg.nfft = [];     end
     if ~isfield(welchCfg,'window'),  welchCfg.window = 'hamming'; end

     % The number of sampling points of the window
     winL = max(1, round(welchCfg.winSec * fs));
     noverlap = max(0, min(winL-1, round(welchCfg.overlap * winL)));
     if isempty(welchCfg.nfft)
         nfft = 2^nextpow2(winL);
     else
         nfft = welchCfg.nfft;
     end

     switch lower(welchCfg.window)
        case 'hann',    win = hann(winL,'periodic');
        otherwise,      win = hamming(winL,'periodic');
     end
     
     % MATLAB Welch method
     [Pxx, f] = pwelch(x, win, noverlap, nfft, fs);

     df = mean(diff(f));

     names = fieldnames(bands); % names = {'alpha','theta'}

     for i = 1:numel(names)
        fr = bands.(names{i});
        mask = (f >= fr(1)) & (f <= fr(2)); % fr(1) = lowerbond fr(2) = upperbond
        % formula
        bp.(names{i}) = sum(Pxx(mask)) * df;
     end
    % Frequency coordinates (horizontal axis), 
    % such as [0, 0.5, 1.0, 1.5,..., 125] Hz
    out.f   = f;
    % Power Spectral Density, PSD
    out.psd = Pxx;
    % band power
    out.bp  = bp;
end
