clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

while true
    try spm_rmpath;
    catch
        break;
    end
end

addpath(spm8_path,'-frozen');

clc

spm_get_defaults('cmdline',true);

proc_dir = uigetdir(home_dir, 'Select the directory to process the data.');

norm_dir = uigetdir(home_dir, 'Select the directory of DARTEL normalization.');

Template = [norm_dir,'\Template_6.nii'];

msg = 'Please select Flow Fields:';
FlowFields = spm_select(inf,'image', msg ,[],norm_dir,'\u_.*.(nii|img)$');

msg = 'Please select images to normalize in the same order in which the Flow Fields were selcted:';
data = spm_select(inf,'image', msg ,[],proc_dir,'\.(nii|img)$');

spm_jobman('initcfg');
load([pth '\Normalize_fMRI-DASB.mat']);



for ii = 1:1:210
    data_cell = cell(210,1);
    for jj = 1:1:210
        data_cell(jj,1) = [proc_dir '\

end

clc

disp('DONE!');