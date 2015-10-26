clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc
spm_get_defaults('cmdline',true);



proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

MR_dir = dir([proc_dir, '\r*.nii']);

fmri_dir = dir([proc_dir, '\a*.nii']);

for ii = 1:1:size(MR_dir,1),
    MR_name = MR_dir(ii).name;
    subfind = strfind(MR_name,'_');
    sub_name = MR_name(2:subfind-1);