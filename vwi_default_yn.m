function vwi_default_yn(dirs_paths)
%       
% 
% 
% 
%       Script to change the default settings of VWI
% 
% 
% 
% 
% 
%% Find VWI root directory
[pth] = fileparts(which('vwi'));
[~,~,raw]=xlsread([pth '\vwi_ini.xlsx'],'Dirs and Paths'); % This extracts directories from the batch file
dirs_paths = raw; clear raw;

%% Prompt to select Home Dir and SPM8 Dir set as default
if isnumeric(dirs_paths{1}) == 0% OR Save Defaults unchecked.
    uiwait(msgbox('Please select Home directory.','VWI'));
    home_dir = uigetdir(pth, 'Select Home directory.');
    W = {home_dir}; V = [W];
    [x]=xlswrite([pth '\vwi_ini.xlsx'], V, 'Dirs and Paths', 'B1');
    clear W; clear V; clear x;
end
if isnumeric(dirs_paths{2}) == 0, % OR Save Defaults unchecked.
    uiwait(msgbox('Please select SPM8 directory.','VWI'));
    spm8_path = uigetdir(pth, 'Select SPM8 directory.');
    W = {spm8_path}; V = [W];
    [x]=xlswrite([pth '\vwi_ini.xlsx'], V, 'Dirs and Paths', 'B2');
    clear W; clear V; clear x;
end
if isnumeric(dirs_paths{3}) == 0, % OR Save Defaults unchecked.
    [pth] = fileparts(which('vwi'));
    Psuv_path = [pth '\processing\SUV'];
    W = {Psuv_path}; V = [W];
    [x]=xlswrite([pth '\vwi_ini.xlsx'], V, 'Dirs and Paths', 'B3');
    clear W; clear V; clear x;
end
if isnumeric(dirs_paths{3}) == 0, % OR Save Defaults unchecked.
    [pth] = fileparts(which('vwi'));
    Pscanvp_path = [pth '\processing\ScanVP'];
    W = {Pscanvp_path}; V = [W];
    [x]=xlswrite([pth '\vwi_ini.xlsx'], V, 'Dirs and Paths', 'B4');
    clear W; clear V; clear x;
end
[~,~,raw]=xlsread([pth '\vwi_ini.xlsx'],'Dirs and Paths'); % This extracts directories from the batch file
dirs_paths = raw; clear raw;