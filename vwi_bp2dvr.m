function vwi_bp2dvr()
%
%        Kinetic Modeling Pipeline
%        Coregistration and Segmentation Module
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman
%
%        Usage: vwi_bp2dvr;
%
%% Declare required variables, if not already declared
clear all
clear globals
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));


%% Define Dirs
uiwait(msgbox('Please select the processing directory.','VWI'));
proc_dir = uigetdir(home_dir, 'Select Processing directory...');


%% Prompt to select BP images
msg = ('Please select the BP images:');
BP_dir = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');
sizeBP = size(BP_dir,1);

%% set SPM8 path
while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc

spm_get_defaults('cmdline',true);


%% Make DVR directory
DVR_dir = [proc_dir '\DVR\'];
if exist(DVR_dir) == 0;
    mkdir(DVR_dir);
end

%% ImCalc

for ii=1:1:sizeBP,
    [pathstr, name, ext] = fileparts(BP_dir(ii,:));
    current_vols = BP_dir(ii,:);
    
    %% If strfind 'BP' is true do the following:
    BP_place = strfind(name,'BP');
    DVR_add = 'DVR';
    DVR_name = [name(1:BP_place-1) DVR_add name(BP_place+2:end)];
    vo_name = [DVR_dir DVR_name ext];
    exp = 'i1+1.00';
    spm_imcalc_ui(current_vols,vo_name,exp);
end
clc
disp('DONE!');

end