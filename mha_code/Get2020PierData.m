function pier=Get2020PierData(date_start,date_end,file)
%function pier=Get2020PierData(date_start,date_end,file)
%Return temperature, pressure and time (datenum format) from the 2020
%Scripps pier record.
%
%  date_start, date_end   datenums bracketing the period you want.
%                         Omit both to get the whole record.
%  file                   path to the netCDF file.  Omit it and we find
%                         data/scripps_pier-2020.nc inside the class repo.
%
%MHA SIO221a
%10/4/2023
% MHA: v2: include option to specify file path and name.
% v3 8/24/2026: locate the data file automatically instead of hard-coding a
%               path that goes stale whenever the class folder moves.
%

if nargin < 3 || isempty(file)
    file = FindPierFile();
end

time        = ncread(file,'time');
temperature = ncread(file,'temperature');
pressure    = ncread(file,'pressure');

date0 = datenum(1970,1,1);
dnum  = double(time)/3600/24 + date0;

if nargin < 1
    i1 = 1:numel(dnum);          %no dates given: return the whole record
else
    i1 = find(dnum > date_start & dnum < date_end);
end

pier.dnum        = dnum(i1);
pier.temperature = temperature(i1);
pier.pressure    = pressure(i1);
pier.readme      = '2020 Pier data, SIO221a, function Get2020PierData.m';

%pier will then be returned.

end

%-------------------------------------------------------------------------
function file = FindPierFile()
%Locate data/scripps_pier-2020.nc without hard-coding anybody's home
%directory.  This function knows where IT lives, so the data must be its
%sibling: mha_code/ and data/ are both inside the class repo.

here     = fileparts(mfilename('fullpath'));   %.../SIO221a_Github_code/mha_code
repo     = fileparts(here);                    %.../SIO221a_Github_code
sentinel = fullfile('data','scripps_pier-2020.nc');

candidates = {fullfile(repo,sentinel), ...
              fullfile(getenv('SIO221A_ROOT'),sentinel)};

for k = 1:numel(candidates)
    if isfile(candidates{k})
        file = candidates{k};
        return
    end
end

error(['Could not find ' sentinel '.  Expected it inside your clone of ' ...
       'SIO221a_Github_code, next to mha_code.']);
end
%% Test