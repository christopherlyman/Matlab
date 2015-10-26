function [sub,proc_dir,base_pet] = AAL_batch()

clear all
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));


%% Define Dirs and set SPM8 path
while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc

spm_get_defaults('cmdline',true);

%% Prompt for subject number and validity checks
prompt = {'How many subjects:'};
dlg_title = 'AAL rois';
num_lines = 1;
num = inputdlg(prompt,dlg_title,num_lines);
num = num{1};

for ii=1:1:str2double(num),
    prompt = {'Enter subject number:'};
    dlg_title = 'AAL rois';
    num_lines = 1;
    sub = inputdlg(prompt,dlg_title,num_lines);
    sub = sub{1};
    sub_list{ii,1} = sub;
    
    proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');
    
    proc_dir_list{ii,1} = proc_dir;
    
    msg = ('Please select base PET image(s):');
    base_pet = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
    
    clear msg;
    while isempty(base_pet) == 1,
        msg = ('Please select base PET image(s):');
        base_pet = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
        clear msg;
    end
    
    eval(sprintf('base_pet_%d = base_pet;',ii));
    clear base_pet
end

for ii=1:1:str2double(num),
    sub = sub_list{ii,1};
    proc_dir = proc_dir_list{ii,1};
    base_pet = eval(sprintf('base_pet_%d',ii));
    
    AAL_rois(sub,proc_dir,base_pet);
    clear base_pet proc_dir sub
end

disp('DONE!');

end
