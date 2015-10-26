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

proc_dir = ('Z:\External\YunZhou\Paraimg_SRTM_CHLrefinput\Thresholded\DASB\DVR\KMP\Coreg');

dir_proc = dir(proc_dir);

for ii = 4:1:size(dir_proc,1),
    work_dir = [proc_dir '\' dir_proc(ii).name '\Other'];
    roi_files = dir([work_dir, '\coreg*.nii']);
    
    roi_size = size(roi_files,1);
    
    for jj = 1:1:roi_size
        current_vol = [work_dir '\' roi_files(jj).name ',1'];
        vo_name = current_vol;
        exp = 'i1>0';
        spm_imcalc_ui(current_vol,vo_name,exp);
        clear current_vol vo_name exp
    end
end

clc

disp('DONE!');