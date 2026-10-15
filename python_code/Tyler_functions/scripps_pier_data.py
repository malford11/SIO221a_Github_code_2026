import os
import requests
import xarray as xr

def open_all_scripps_ts(scripps_dir, years):
    for year in years:
        url  = f'https://thredds.sccoos.org/thredds/fileServer/autoss/scripps_pier-{year}.nc'
        path = os.path.join(scripps_dir, f'scripps_pier-{year}.nc')

        if os.path.exists(path):
            print(f'{year}: already downloaded')
            continue

        print(f'{year}: downloading ...')
        response = requests.get(url)
        response.raise_for_status()                    # stop here on a 404 rather than writing an error page as .nc

        with open(path, 'wb') as file:
            file.write(response.content)

        print(f'{year}: saved {os.path.getsize(path) / 1024**2:.1f} MB to {path}')

    file_list = []
    for year in years:
        file_list.append(os.path.join(scripps_dir, f'scripps_pier-{year}.nc'))

    full_scripps_ts = xr.open_mfdataset(file_list, combine='nested', concat_dim='time')
    full_scripps_ts = full_scripps_ts.convert_calendar('standard').sortby('time')
    return full_scripps_ts
