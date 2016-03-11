function Data = shearead(file)
%SHEAREAD Reads Shea Climatology text file
%
% Data = shearead(file)
%
% This function reads the data from the Shea Climatology text file,
% including air temperature, precipitation, sea level pressure, and sea
% surface temperature.  This dataset covers the period from 1950-1979.  See
% the following reference for details.
% 
% TN-269+STR Climatological Atlas: 1950-1979 Surface Air Temperature,
% Precipitation, Sea-Level Pressure, and Sea-Surface Temperature (45S-90N).
% Dennis J.  Shea.  AAP, June 1986. (NTIS # PB86 245131/AS).
%
% Input variables:
%
%   file:   filename of text file
%
% Output variables:
%
%   Data:   1 x 1 structure holding data.  The 'lat' and 'lon' fields hold
%           the graticule used to grid the data.  The remaining fields hold
%           the data from the file.  Each data field is a lat x lon x time
%           array of values, stores in a nested structure of the format in
%           a structure of the Data.datatype.timetype.valuetype.
%
%           datatype:   type of data
%                       'airtemp':  air temperature (C)
%                       'precip':   precipitation (mm)
%                       'slp':      sea level pressure (mb)
%                       'sst':      sea surface temperature (C)
%
%           timetype:   time over which data is grouped
%                       'month':    monthly, Jan-Dec
%                       'annual':   annually
%                       'season':   fall, winter, spring, summer
%
%           valuetype:  type of value reported
%                       'mean':     mean field
%                       'var':      interannual variability

% Copyright 2008 Kelly kearney


nlon = 144;
nlat = 73;

Data.lon = mod(linspace(180, 537.5, nlon), 360);
Data.lat = linspace(-90, 90, nlat);

fid = fopen(file);

count = 0;

dataidx = [1 2 3 5];
dataname = {'airtemp', 'precip', 'slp', 'sst'};


while 1
    
    if feof(fid)
        break
    end
    
    count = count + 1;
    
    ihd = textscan(fid, '%d', 24);
    fhd = textscan(fid, '%f', 10);
    
    datatype(count) = ihd{1}(2);
    stat(count) = ihd{1}(3);
    month(count) = ihd{1}(7);
   
    field = textscan(fid, '%f', nlat*nlon);
    if numel(field{1}) ~= (nlat*nlon)
        data{count} = nan(nlat, nlon);
        break
    end
    
    field = reshape(field{1}, nlon, nlat)';
    isnull = field == 1e36;
    field(isnull) = NaN;
    
    data{count} = field;
    
end

fclose(fid);

for itype = 1:length(dataidx)
    
    istype = datatype == dataidx(itype);
    
    ismean = stat == 1;
    isvar = stat == 3;
    
    times = {'month', 'annual', 'season'};
    istime(1,:) = month <= 12;
    istime(2,:) = month == 13;
    istime(3,:) = month >= 14;
    
    for itime = 1:length(times)
        
        Data.(dataname{itype}).(times{itime}).mean = cat(3, data{istype & istime(itime,:) & ismean});
        Data.(dataname{itype}).(times{itime}).var = cat(3, data{istype & istime(itime,:) & isvar});
    end
    
end

