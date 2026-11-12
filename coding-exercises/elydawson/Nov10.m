dataDir = fullfile(getenv('HOME'), 'SIO221a_Github_code_2026', ...
    'homework', 'HW5_data');

files = {
    'DM134A', 'OS_T8S110W_DM134A-20150425_D_WIND_10min.nc';
    'DM183A', 'OS_T8S110W_DM183A-20160321_D_WIND_10min.nc';
    'DM231A', 'OS_T8S110W_DM231A-20170606_D_WIND_10min.nc'
};

wind = struct();

for k = 1:size(files, 1)
    deployment = files{k, 1};
    filePath = fullfile(dataDir, files{k, 2});

    info = ncinfo(filePath);
    names = {info.Variables.Name};
    fields = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(names));

    timeIndex = find(strcmpi(names, 'time'), 1);

    timeInfo = info.Variables(timeIndex);

    timeDimName = timeInfo.Dimensions(1).Name;
    time = ncread(filePath, timeInfo.Name);
    time = double(time(:));

    data = struct();
    for j = 1:numel(names)
        values = ncread(filePath, names{j});
        dimNames = {info.Variables(j).Dimensions.Name};
        timeDim = find(strcmp(dimNames, timeDimName), 1);

        if j ~= timeIndex && ~isempty(timeDim) && ...
                isfloat(values) && any(isnan(values(:)))
            values = fillmissing(values, 'linear', timeDim, ...
                'SamplePoints', time, 'EndValues', 'none');
        end

        data.(fields{j}) = values;
    end

    wind.(deployment).data = data;
    wind.(deployment).info = info;
end

% Show the loaded variable names for the first deployment.
fieldnames(wind.DM134A.data)
%%
function [f, P] = windSpectrum(data, dt, doDetrend, doDemean, useHann)
    
% WINDSPECTRUM Compute the PSD of a signal.
%   [f, P] = windSpectrum(data, dt) uses the input samples as supplied.
%   [f, P] = windSpectrum(data, dt, doDetrend, doDemean, useHann)
%   optionally removes a linear trend, removes the mean, or applies a
%   periodic Hann (Hanning) window. All three options default to false.
%
%
%   data is a finite row or column vector.
%   dt is the sample interval in seconds.
%   f is the frequency vector in Hz, including zero.
%   P is the one-sided power spectral density in input units squared per Hz.
% 
% 
% Ely J. Dawson
% Nov 8, 2026
% SIOC - 221A

    % Set defaults for omitted preprocessing options.
    if nargin < 3
        doDetrend = false;
    end
    if nargin < 4
        doDemean = false;
    end
    if nargin < 5
        useHann = false;
    end

    % The FFT requires finite samples and a positive sample interval.
    validateattributes(data, {'numeric'}, {'vector', 'real', 'finite'});
    validateattributes(dt, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});

    x = double(data(:));
    N = numel(x);
    if N < 2
        error('The input must contain at least two samples.');
    end

    % A linear detrend removes the fitted slope and intercept.
    % Demeaning alone removes only the sample mean.
    if doDetrend
        x = detrend(x, 1);
    elseif doDemean
        x = x - mean(x);
    end

    % Use unit weights by default, or taper with a periodic Hann window.
    w = ones(N, 1);
    if useHann
        n = (0:N-1)';
        w = 0.5 - 0.5*cos(2*pi*n/N);
    end

    % Convert the sample interval to a sampling frequency and build the
    % nonnegative frequency grid, including Nyquist when N is even.
    Fs = 1 / dt;
    nFreq = floor(N/2) + 1;
    f = (0:nFreq-1)' * Fs / N;

    % Normalize by sampling frequency and window energy to obtain a PSD.
    X = fft(x .* w);
    P = abs(X(1:nFreq)).^2 / (Fs * sum(w.^2));

    % Fold negative-frequency power into the matching positive bins.
    lastBin = nFreq - (mod(N, 2) == 0);
    P(2:lastBin) = 2 * P(2:lastBin);
end


%% Prepare the inputs for windSpectrum

x2015 = wind.DM134A.data.WSPD(:);  % Full 2015 wind speed as a column vector
dt = 600;                        % 10-minute sample interval in seconds

% Trim leading and trailing missing values left by the gap-filling step.
firstValid = find(isfinite(x2015), 1, 'first');
lastValid  = find(isfinite(x2015), 1, 'last');
x2015 = x2015(firstValid:lastValid);

%% Compute the three 2015 spectra

% Optional arguments are ordered as doDetrend, doDemean, useHann.
[f, Praw]  = windSpectrum(x2015, dt, false, false, false);
[~, Pdet]  = windSpectrum(x2015, dt, true,  false, false);
[~, Phann] = windSpectrum(x2015, dt, true,  false, true);

% Match the column order expected by your plotting code.
P = [Praw, Pdet, Phann];

%% Plot the three 2015 wind speed spectra

spectrumTitles = {'Raw', 'Linearly Detrended', 'Detrended + Hann'};
colors = lines(3);

% Skip the zero-frequency bin because the frequency axis is logarithmic.
positiveFreq = f > 0;

for j = 1:numel(spectrumTitles)
    figure('Name', spectrumTitles{j}, 'NumberTitle', 'off');
    loglog(f(positiveFreq), P(positiveFreq, j), ...
        'Color', colors(j, :), 'LineWidth', 1.2);

    grid on;
    xlabel('Frequency (Hz)');
    ylabel('Power spectral density ((m/s)^2/Hz)');
    title(['2015 Wind Speed Spectrum (' spectrumTitles{j} ')']);
end
%%
function [f, spectrum, CI]= plotSpectra3way_error_final(data, sampleInterval, varargin)

% Function to calculate a power spectrum and its 95% confidence interval.
% Each column of data represents one segment.
%
% Inputs:
% 1) data: data matrix, with each column representing one segment
% 2) sampleInterval: sampling interval in minutes
%
% Optional inputs:
% 'Detrend': remove a linear trend (default: false)
% 'Demean': remove the mean (default: false)
% 'Hanning': apply a Hanning window (default: false)
% 'Overlap': fraction of overlap between segments (default: 0.50)
%
% Outputs:
% 1) f: frequency in cycles per day
% 2) spectrum: averaged one-sided power spectrum
% 3) CI: lower and upper 95% confidence intervals

% Read optional inputs (Had to use AI, didn't know you could do optional
% inputs)
p= inputParser;

addParameter(p,'Detrend',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'Demean',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'Hanning',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'Overlap',0.50,@(x) isnumeric(x) && isscalar(x) && x >= 0 && x < 1);

parse(p,varargin{:});

doDetrend= p.Results.Detrend;
doDemean= p.Results.Demean;
doHanning= p.Results.Hanning;
overlap= p.Results.Overlap;

% Check inputs
if ~isnumeric(data) || isempty(data) || any(~isfinite(data(:)))
    error('Data must be a nonempty numeric matrix without NaNs or Inf values.')
end

if ~isscalar(sampleInterval) || ~isfinite(sampleInterval) || sampleInterval <= 0
    error('Sample interval must be a positive number in minutes.')
end

% Get number of points and segments
[N,nSegments]= size(data);

% Sampling frequency in samples per day
Fs= 24*60/sampleInterval;

% Frequency vector in cycles per day
f= (0:floor(N/2))' * Fs/N;

% Create Hanning window using the cosine-squared equation
tw= linspace(-0.5,0.5,N)';
hanwin= cos(pi*tw).^2;

% Choose window
if doHanning
    window= hanwin;
else
    window= ones(N,1);
end

% Preallocate spectra
segmentSpectra= zeros(length(f),nSegments);

% Calculate spectrum for each segment
for k= 1:nSegments

    x= data(:,k);

    % Remove linear trend if requested
    if doDetrend
        x= detrend(x);

    % Otherwise, remove mean if requested
    elseif doDemean
        x= x - mean(x);
    end

    % Apply Hanning window if requested
    x= x .* window;

    % Calculate Fourier transform
    X= fft(x);

    % Calculate power spectrum
    P= abs(X).^2/(Fs*sum(window.^2));

    % Keep positive frequencies
    P= P(1:floor(N/2)+1);

    % Convert to one-sided spectrum
    if rem(N,2) == 0
        P(2:end-1)= 2*P(2:end-1);
    else
        P(2:end)= 2*P(2:end);
    end

    % Store segment spectrum
    segmentSpectra(:,k)= P;

end

% Average spectra across all segments
spectrum= mean(segmentSpectra,2);

% Calculate effective degrees of freedom
% This accounts approximately for correlation between overlapping segments.
step= round(N*(1-overlap));
windowEnergy= sum(window.^2);
correlationSum= 0;

for m= 1:nSegments-1

    shift= m*step;

    if shift >= N
        break
    end

    overlapCorrelation= sum(window(1:N-shift).*window(1+shift:N)) / windowEnergy;

    correlationSum= correlationSum + ...
        (1-m/nSegments)*overlapCorrelation^2;

end

nu= 2*nSegments/(1+2*correlationSum);

% Calculate 95% confidence intervals
alpha= 0.05;

CI.lower= nu*spectrum/chi2inv(1-alpha/2,nu);
CI.upper= nu*spectrum/chi2inv(alpha/2,nu);
CI.dof= nu;

end


%% Compute three spectra from the full 2015 wind speed record

x2015 = wind.DM134A.data.WSPD(:);
sampleInterval = 10;  % Minutes

% Trim leading and trailing missing values left by interpolation.
firstValid = find(isfinite(x2015), 1, 'first');
lastValid  = find(isfinite(x2015), 1, 'last');
x2015 = x2015(firstValid:lastValid);

% Raw here means the gap-filled series before spectral preprocessing.
[f2015, Praw, CIraw] = plotSpectra3way_error_final(x2015, sampleInterval);

[~, Pdet, CIdet] = plotSpectra3way_error_final(x2015, sampleInterval, ...
    'Detrend', true);

[~, Phann, CIhann] = plotSpectra3way_error_final(x2015, sampleInterval, ...
    'Detrend', true, 'Hanning', true);

% Keep the column order used by your three-figure plotting loop.
P2015 = [Praw, Pdet, Phann];

%% Plot the three 2015 spectra with 95% confidence limits

spectrumTitles = {'Raw', 'Linearly Detrended', 'Detrended + Hann'};
confidenceLimits = [CIraw, CIdet, CIhann];
colors = lines(3);

% Skip zero frequency on the logarithmic x-axis.
plotBins = f2015 > 0;

% The nominal confidence limits also exclude Nyquist for even-length data.
ciBins = plotBins;
if mod(numel(x2015), 2) == 0
    ciBins(end) = false;
end

for j = 1:numel(spectrumTitles)
    figure('Name', ['2015 WSPD - ' spectrumTitles{j}], 'NumberTitle', 'off');

    hPSD = loglog(f2015(plotBins), P2015(plotBins, j), ...
        'Color', colors(j, :), 'LineWidth', 1.5);
    hold on;

    limits = confidenceLimits(j);
    hLower = loglog(f2015(ciBins), limits.lower(ciBins), '--', ...
        'Color', colors(j, :));
    hUpper = loglog(f2015(ciBins), limits.upper(ciBins), '--', ...
        'Color', colors(j, :));

    grid on;
    xlabel('Frequency (cycles/day)');
    ylabel('Power spectral density ((m/s)^2 per cycle/day)');
    title(['2015 Wind Speed Spectrum (' spectrumTitles{j} ')']);

    legend([hPSD, hLower, hUpper], ...
        {'PSD estimate', '95% lower limit', '95% upper limit'}, ...
        'Location', 'southoutside');
end