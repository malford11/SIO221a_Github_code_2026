import numpy as np
from scipy.signal import detrend as scipy_detrend          # renamed so the detrend= argument doesn't hide it


def calculate_spectrum(data = None, var = None, sampling_interval = None, segment_length = 60, detrend = True, demean = True, Hanning = True, dimension = 'TIME'):
    """Segment-averaged, one-sided power spectrum of one variable in an xarray Dataset.

    NOTE: unlike most class spectrum routines, this takes an xarray Dataset plus a
    variable name (not a plain array), and all time units are in DAYS (not seconds).

    The record is split into segments of length `segment_length` with 50% overlap.
    Each segment is linearly detrended, demeaned, or left raw, optionally Hanning-windowed,
    FFT'd, and the resulting spectra are averaged together.

    Parameters
    ----------
    data : xarray.Dataset
        Dataset holding the variable. It must have a time coordinate named `dimension`.
        Gaps (NaNs) in `var` are linearly interpolated first, and NaNs left at the start
        or end of the record are dropped. Note that this overwrites data[var] in the
        Dataset you pass in, so pass data.copy() to keep the original.
    var : str
        Name of the variable to analyze, e.g. 'WSPD'.
    sampling_interval : float, optional
        Time between samples in DAYS, e.g. 10/1440 for 10-minute data or 1/24 for hourly.
        If None, it is taken as the median spacing of the `dimension` coordinate, which
        must then be datetime64.
    segment_length : float, default 60
        Length of each segment in DAYS (the same units as sampling_interval). Shorter
        segments give more averaging (more degrees of freedom, smaller error bars) but
        coarser frequency resolution, since df = 1/segment_length.
    detrend : bool, default True
        If True, remove a linear trend from each segment (this also removes the mean,
        so `demean` is not needed).
    demean : bool, default True
        Only used when detrend=False. If True, subtract each segment's mean before the
        FFT. Set detrend=False, demean=False, Hanning=False to get the spectrum of the
        raw data, or detrend=False, demean=False, Hanning=True to window the raw data.
    Hanning : bool, default True
        If True, apply a Hanning window to each segment, scaled by sqrt(8/3) to keep
        the total variance the same.
    dimension : str, default 'TIME'
        Name of the time dimension/coordinate in `data`.

    Returns
    -------
    freqs : numpy.ndarray
        Frequencies in cycles per day, from 0 to the Nyquist frequency 1/(2*sampling_interval).
    Sc : numpy.ndarray
        Spectral density in (units of var)^2 per cycle per day, the same length as freqs.
    nu : int
        Approximate degrees of freedom for confidence intervals: 2*(number of segments),
        reduced by a factor of 0.9 when a Hanning window is used.

    Example
    -------
    >>> freqs, Sc, nu = calculate_spectrum(data=data, var='WSPD', sampling_interval=10/1440,
    ...                                     segment_length=60, detrend=True, demean=True, Hanning=True,
    ...                                     dimension='TIME')
    """
    
    data[var] = data[var].interpolate_na(dim=dimension, method='linear')  #First fill gaps
    data = data.dropna(dim=dimension, subset=[var])   # Then remove any nas that survived at the tails
    # If no sampling frequency is provided, calculate it
    if sampling_interval is None:
        sampling_interval = np.median((data[dimension].diff(dimension) / np.timedelta64(1, 'D')))

    dt = sampling_interval
    N = len(data[dimension])
    p = int(round(segment_length/dt))

    if Hanning is True and detrend is True:
        # Calculate from detrended data with a Hanning window
        w = np.hanning(p)
        scale = np.sqrt(8/3)                                              # makes up for the variance the Hanning window removes
        starts = np.arange(0, N - p + 1, p//2)                            # segment start indices, stepping p/2 for 50% overlap
        Sc = np.zeros((p//2 + 1, len(starts)))
        for k, s in enumerate(starts):
            sgi = scipy_detrend(data[var][s:s+p])
            Xc = np.fft.fft(sgi*w*scale)
            tmp = np.abs(Xc[:p//2+1])**2 / p**2;  tmp[1:-1] *= 2          # one-sided spectrum: x2 restores negative-frequency variance, except at 0 and Nyquist
            Sc[:, k] = tmp/(1/(dt*p))                                     # divide by frequency spacing df = 1/(dt*p) to get spectral density
        Sc = np.mean(Sc, axis=1)
        nu = round(2*len(starts)*0.9)                                     # 2 dof per segment, reduced by 0.9 to account for the window

    elif detrend is True:
            # Calculate from detrended data
        starts = np.arange(0, N - p + 1, p//2)
        Sc = np.zeros((p//2 + 1, len(starts)))
        for k, s in enumerate(starts):
            sgi = scipy_detrend(data[var][s:s+p])
            Xc = np.fft.fft(sgi)
            tmp = np.abs(Xc[:p//2+1])**2 / p**2;  tmp[1:-1] *= 2
            Sc[:, k] = tmp/(1/(dt*p))
        Sc = np.mean(Sc, axis=1)
        nu = 2*(N//p)

    elif Hanning is True and demean is True:
        # Calculate from demeaned data with a Hanning window
        w = np.hanning(p)
        scale = np.sqrt(8/3)
        starts = np.arange(0, N - p + 1, p//2)
        Sc = np.zeros((p//2 + 1, len(starts)))
        for k, s in enumerate(starts):
            sgi = data[var][s:s+p] - data[var][s:s+p].mean()
            Xc = np.fft.fft(sgi*w*scale)
            tmp = np.abs(Xc[:p//2+1])**2 / p**2;  tmp[1:-1] *= 2
            Sc[:, k] = tmp/(1/(dt*p))
        Sc = np.mean(Sc, axis=1)
        nu = round(2*len(starts)*0.9)

    elif Hanning is True:
        # Calculate from raw (not demeaned) data with a Hanning window
        w = np.hanning(p)
        scale = np.sqrt(8/3)
        starts = np.arange(0, N - p + 1, p//2)
        Sc = np.zeros((p//2 + 1, len(starts)))
        for k, s in enumerate(starts):
            Xc = np.fft.fft(data[var][s:s+p]*w*scale)
            tmp = np.abs(Xc[:p//2+1])**2 / p**2;  tmp[1:-1] *= 2
            Sc[:, k] = tmp/(1/(dt*p))
        Sc = np.mean(Sc, axis=1)
        nu = round(2*len(starts)*0.9)

    elif demean is True:
        # Calculate from demeaned data, no window
        starts = np.arange(0, N - p + 1, p//2)
        Sc = np.zeros((p//2 + 1, len(starts)))
        for k, s in enumerate(starts):
            sgi = data[var][s:s+p] - data[var][s:s+p].mean()
            Xc = np.fft.fft(sgi)
            tmp = np.abs(Xc[:p//2+1])**2 / p**2;  tmp[1:-1] *= 2
            Sc[:, k] = tmp/(1/(dt*p))
        Sc = np.mean(Sc, axis=1)
        nu = 2*(N//p)

    else:
        # Calculate spectrum from raw data
        starts = np.arange(0, N - p + 1, p//2)
        Sc = np.zeros((p//2 + 1, len(starts)))
        for k, s in enumerate(starts):
            Xc = np.fft.fft(data[var][s:s+p])
            tmp = np.abs(Xc[:p//2+1])**2 / p**2;  tmp[1:-1] *= 2
            Sc[:, k] = tmp/(1/(dt*p))
        Sc = np.mean(Sc, axis=1)
        nu = 2*(N//p)

    fn = 1/2/dt
    freqs = np.arange(0, fn + 1/(dt*p)/2, 1/(dt*p))
    return freqs, Sc, nu
