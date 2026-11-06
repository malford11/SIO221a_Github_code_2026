import numpy as np
from scipy.signal import detrend as scipy_detrend          # renamed so the detrend= argument doesn't hide it


def calculate_spectrum(data = None, var = None, sampling_interval = None, segment_lenth = 60, detrend = True, Hanning = True, dimension = 'TIME'):
    """This function calculates the spectrum of a single variable in a dataset, with options to have smaller or larger segments
    or to use a Hanning window.
    Example usage: freqs, Sc, nu = calculate_spectrum(data = data, var = 'WSPD', sampling_interval = 10/1440, segment_lenth = 60, detrend = True, Hanning = True, dimension = 'TIME')"""          # FIX: one triple-quoted docstring
    
    data[var] = data[var].interpolate_na(dim=dimension, method='linear')  #First fill gaps
    data = data.dropna(dim=dimension, subset=[var])   # Then remove any nas that survived at the tails
    # If no sampling frequency is provided, calculate it
    if sampling_interval is None:
        sampling_interval = np.median((data[dimension].diff(dimension) / np.timedelta64(1, 'D')))

    dt = sampling_interval
    N = len(data[dimension])
    p = int(round(segment_lenth/dt))

    if Hanning is True and detrend is True:
        # Calculate from detrended data with a Hanning window
        w = np.hanning(p)
        scale = np.sqrt(8/3)
        starts = np.arange(0, N - p + 1, p//2)
        Sc = np.zeros((p//2 + 1, len(starts)))
        for k, s in enumerate(starts):
            sgi = scipy_detrend(data[var][s:s+p])
            Xc = np.fft.fft(sgi*w*scale)
            tmp = np.abs(Xc[:p//2+1])**2 / p**2;  tmp[1:-1] *= 2
            Sc[:, k] = tmp/(1/(dt*p))
        Sc = np.mean(Sc, axis=1)
        nu = round(2*len(starts)*0.9)

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

    elif Hanning is True:
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
