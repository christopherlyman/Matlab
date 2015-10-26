function FreeSurfer_parcellation()

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

proc_dir = uigetdir(home_dir, 'Select the subject''s direcotry..'); %% For example, Z:\02_Analyses\FreeSurfer\1002

% msg = ('Please select base Image(s):');
% base_image = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
% clear msg;
% while isempty(base_image) == 1,
%     msg = ('Please select base Image(s):');
%     base_image = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
%     clear msg;
% end

base_image = dir([proc_dir '\*_aseg2raw.nii']);
base_image = {base_image.name};
base_image = [proc_dir '\' base_image{1}];

% MRI_image = dir([proc_dir '\*_MR-MPRAGE*.nii']);
% MRI_image = {MRI_image.name};
% MRI_image = [proc_dir '\' MRI_image{1}];

subcort_dir = [proc_dir '\NIfTI\Subcortical'];

if exist(subcort_dir,'dir') == 0;
    mkdir(subcort_dir);
end

% src_ref = {deblank([MRI_image ',1']),deblank([base_image ',1'])};
% spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));

% clear base_image
% 
% base_image = dir([proc_dir '\r*_aseg2raw.nii']);
% base_image = {base_image.name};
% base_image = [proc_dir '\' base_image{1}];

read_base = spm_vol(base_image(1,:));
conv_base = spm_read_vols(read_base);
roi_header = read_base;

max_val = max(conv_base(:));

[~,~,raw]=xlsread([pth '\FreeSurfer_ROIs.xlsx'],'ROIs');
FreeSurfer_rois = raw; clear raw;

cortical_dir = [proc_dir '\NIfTI\Cortical'];
exp = '((i1>0)+(i2>0))>0';

%1
dir_cortex = dir([cortical_dir '\*bankssts.nii']);
dir_cortex = {dir_cortex.name};
out_name = deblank(dir_cortex{1});
[sub,remain] = strtok(deblank(out_name), ['_']);

clear dir_cortex out_name remain


for ii=1:1:max_val,
    roinum = ii;
    roi_voxels = conv_base(:)==roinum;
    sum_voxels = sum(roi_voxels);
    
    if sum_voxels > 0,
        roi_name_list = [FreeSurfer_rois{:,1}]';
        roi_name_search = find(roi_name_list(:)==roinum);
        roiname = FreeSurfer_rois{roi_name_search,2};
        
        roi_backup = conv_base;
        roi_backup(:,:,:)= 0;
        roi_backup(roi_voxels) = 1;
        roi_name = [subcort_dir '\' sub '_' roiname '.nii'];
        roi_header.fname = roi_name;
        spm_write_vol(roi_header,roi_backup);
        clear roi_backup roiname roinum roi_voxels roi_name_search roi_name_list
        
%         exp = 'i1>0';
%         spm_imcalc_ui(roi_name,roi_name,exp);
    end    
end

%% Create Bilateral Cortical ROIs

%1
dir_cortex = dir([cortical_dir '\*bankssts.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%2
dir_cortex = dir([cortical_dir '\*caudalanteriorcingulate.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%3
dir_cortex = dir([cortical_dir '\*caudalmiddlefrontal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%4
dir_cortex = dir([cortical_dir '\*cuneus.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{3}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%5
dir_cortex = dir([cortical_dir '\*entorhinal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%6
dir_cortex = dir([cortical_dir '\*frontalpole.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%7
dir_cortex = dir([cortical_dir '\*fusiform.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%8
dir_cortex = dir([cortical_dir '\*inferiorparietal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%9
dir_cortex = dir([cortical_dir '\*inferiortemporal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%10
dir_cortex = dir([cortical_dir '\*insula.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%11
dir_cortex = dir([cortical_dir '\*isthmuscingulate.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%12
dir_cortex = dir([cortical_dir '\*lateraloccipital.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%13
dir_cortex = dir([cortical_dir '\*lateralorbitofrontal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%14
dir_cortex = dir([cortical_dir '\*lingual.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%15
dir_cortex = dir([cortical_dir '\*medialorbitofrontal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%16
dir_cortex = dir([cortical_dir '\*middletemporal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%17
dir_cortex = dir([cortical_dir '\*paracentral.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%18
dir_cortex = dir([cortical_dir '\*parahippocampal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%19
dir_cortex = dir([cortical_dir '\*parsopercularis.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%20
dir_cortex = dir([cortical_dir '\*parsorbitalis.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%21
dir_cortex = dir([cortical_dir '\*parstriangularis.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%22
dir_cortex = dir([cortical_dir '\*pericalcarine.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%23
dir_cortex = dir([cortical_dir '\*postcentral.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%24
dir_cortex = dir([cortical_dir '\*posteriorcingulate.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%25
dir_cortex = dir([cortical_dir '\*precentral.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%26
dir_cortex = dir([cortical_dir '\*precuneus.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%27
dir_cortex = dir([cortical_dir '\*rostralanteriorcingulate.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%28
dir_cortex = dir([cortical_dir '\*rostralmiddlefrontal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%29
dir_cortex = dir([cortical_dir '\*superiorfrontal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%30
dir_cortex = dir([cortical_dir '\*superiorparietal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%31
dir_cortex = dir([cortical_dir '\*superiortemporal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%32
dir_cortex = dir([cortical_dir '\*supramarginal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%33
dir_cortex = dir([cortical_dir '\*temporalpole.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex

%34
dir_cortex = dir([cortical_dir '\*transversetemporal.nii']);
if size(dir_cortex,1) > 1,
    dir_cortex = {dir_cortex.name};
    out_name = deblank(dir_cortex{1});
    [sub,remain] = strtok(deblank(out_name), ['_']);
    [~,remain] = strtok(deblank(remain), ['_']);
    output_name = [cortical_dir '\' sub '_Bi' remain];
    input_names{1,1} = [cortical_dir '\' dir_cortex{1}];
    input_names{2,1} = [cortical_dir '\' dir_cortex{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_cortex exp


%% Create Combined Bilateral regions.

roi_dir = dir([cortical_dir, '\*Bi_pars*']);
if size(roi_dir,1) > 2,
    vwi_rois = {roi_dir.name};
    vwi_rois = str2mat(vwi_rois); 
    for jj=1:size(vwi_rois,1)
        input_rois(jj,1) = {[cortical_dir '\' deblank(vwi_rois(jj,:)) ',1']};
    end;   
    exp = '((i1>0)+(i2>0)+(i3>0))>0';
    output_roi = [cortical_dir '\' sub '_Bi_inferiorfrontal.nii'];
    spm_imcalc_ui(input_rois,output_roi,exp);
    clear input_rois output_roi roi_dir exp
else
    errordlg('Bi_pars File(s) not found','File Error');
end

roi_dir = dir([cortical_dir, '\*Bi_*anteriorcingulate*']);
if size(roi_dir,1) > 1,  
    vwi_rois = {roi_dir.name};
    vwi_rois = str2mat(vwi_rois);
    for jj=1:size(vwi_rois,1)
        input_rois(jj,1) = {[cortical_dir '\' deblank(vwi_rois(jj,:)) ',1']};
    end;
    exp = '((i1>0)+(i2>0))>0';
    output_roi = [cortical_dir '\' sub '_Bi_anteriorcingulate.nii'];
    spm_imcalc_ui(input_rois,output_roi,exp);
    clear input_rois output_roi roi_dir exp
else
    errordlg('Bi_anteriorcingulate File(s) not found','File Error');
end

roi_dir = dir([cortical_dir, '\*Bi_*orbitofrontal*']);
if size(roi_dir,1) > 1,
    vwi_rois = {roi_dir.name};
    vwi_rois = str2mat(vwi_rois);
    for jj=1:size(vwi_rois,1)
        input_rois(jj,1) = {[cortical_dir '\' deblank(vwi_rois(jj,:)) ',1']};
    end;
    exp = '((i1>0)+(i2>0))>0';
    output_roi = [cortical_dir '\' sub '_Bi_orbitofrontal.nii'];
    spm_imcalc_ui(input_rois,output_roi,exp);
    clear input_rois output_roi roi_dir exp
else
    errordlg('Bi_orbitofrontal File(s) not found','File Error');
end

roi_dir = dir([cortical_dir, '\*Bi_*middlefrontal*']);
if size(roi_dir,1) > 1,
    vwi_rois = {roi_dir.name};
    vwi_rois = str2mat(vwi_rois);
    for jj=1:size(vwi_rois,1)
        input_rois(jj,1) = {[cortical_dir '\' deblank(vwi_rois(jj,:)) ',1']};
    end;
    exp = '((i1>0)+(i2>0))>0';
    output_roi = [cortical_dir '\' sub '_Bi_middlefrontal.nii'];
    spm_imcalc_ui(input_rois,output_roi,exp);
    clear input_rois output_roi roi_dir
else
    errordlg('Bi_middlefrontal File(s) not found','File Error');
end


%% Create Bilateral Subcortical ROIs
exp = '((i1>0)+(i2>0))>0';
%1
dir_subcort = dir([subcort_dir '\*Accumbens-area.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%2
dir_subcort = dir([subcort_dir '\*Amygdala.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%3
dir_subcort = dir([subcort_dir '\*Caudate.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%4
dir_subcort = dir([subcort_dir '\*Cerebellum-Cortex.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%5
dir_subcort = dir([subcort_dir '\*Cerebellum-White-Matter.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%6
dir_subcort = dir([subcort_dir '\*Cerebral-Cortex.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%7
dir_subcort = dir([subcort_dir '\*Cerebral-White-Matter.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%8
dir_subcort = dir([subcort_dir '\*choroid-plexus.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%9
dir_subcort = dir([subcort_dir '\*Hippocampus.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%10
dir_subcort = dir([subcort_dir '\*Inf-Lat-Vent.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%11
dir_subcort = dir([subcort_dir '\*Lateral-Ventricle.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%12
dir_subcort = dir([subcort_dir '\*Pallidum.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%13
dir_subcort = dir([subcort_dir '\*Putamen.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%14
dir_subcort = dir([subcort_dir '\*Thalamus-Proper.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%15
dir_subcort = dir([subcort_dir '\*VentralDC.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort

%16
dir_subcort = dir([subcort_dir '\*vessel.nii']);
if size(dir_subcort,1) > 1,
    dir_subcort = {dir_subcort.name};
    out_name = deblank(dir_subcort{1});
    [~,remain] = strtok(deblank(out_name), ['-']);
    output_name = [subcort_dir '\' sub '_Bi_' remain(2:end)];
    input_names{1,1} = [subcort_dir '\' dir_subcort{1}];
    input_names{2,1} = [subcort_dir '\' dir_subcort{2}];
    spm_imcalc_ui(input_names,output_name,exp);
    clear output_name input_names remain
end
clear dir_subcort
[pathstr, name, ext] = fileparts(proc_dir);
clc

disp([name ' is Done!']);

end