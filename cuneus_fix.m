function cuneus_fix()

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

% prompt = {'Enter subject number:'};
% dlg_title = 'AAL rois';
% num_lines = 1;
% sub = inputdlg(prompt,dlg_title,num_lines);
% sub = sub{1};

proc_dir = uigetdir(home_dir, 'Select the subject''s direcotry..');

cortical_dir = [proc_dir '\NIfTI\Cortical'];
exp = '((i1>0)+(i2>0))>0';

dir_cortex = dir([cortical_dir '\*bankssts.nii']);
dir_cortex = {dir_cortex.name};
out_name = deblank(dir_cortex{1});
[sub,remain] = strtok(deblank(out_name), ['_']);

dir_cortex = dir([cortical_dir '\*cuneus.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{3}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{5}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end


[pathstr, name, ext] = fileparts(proc_dir);
clc

disp([name ' is Fixed!']);

clear

end