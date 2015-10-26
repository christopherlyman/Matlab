function vwi_rois()
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman and Clifford Workman
%
%        Usage: vwi_rois;
%
%       First, you will be prompted to select the "\Processing" directory
%       created during vwi_coreg_seg. E.g.) Z:\TEST\MCI\Processing\
%       Click the folder named "Processing" and click "OK".
%
%       Second, you will be prompted to enter a study name (e.g. MCI) and
%       the number of subjects to be analyzed. This is the total number of
%       subjects you wish to analyize for the study name you entered.
%
%       Third, you will be prompted to enter the name of each subject.
%       E.g.) 2005
%       Fourth, you will be prompted to select each subject's Processing
%       directory. E.g.) Z:\TEST\MCI\Processing\MCI-2005
%
%       The program will run through the following steps:
%       ----------------------------- Steps -----------------------------
%       1) Transform ROIs from MNI to participant's native space using
%          normalization parameters derived during MR segmentation (module
%          vwi_coreg_seg).
%       2) Reslice ROIs to subject space.
%       3) Create copies of ROIs and dilate. Mask original ROIs with
%          dilated copies. This excludes areas in which voxels might
%          overlap across ROIs. Then, larger ROIs are eroded a bit more.
%       4) Create non-gray matter masks, denoise the masks, and then
%          remove non-gray matter voxels from gray-matter ROIs.
%       5) Create non-white matter mask, denoise the mask, and then
%          remove non-white matter voxels from white-matter VOI.
%       6) Apply a cluster threshold (k >= 100) to remove noise from ROIs
%          larger than 100 voxels.
%       7) Make masks of whole regions by summing subregion masks.
%       8) Run get_roivals.m to get statistics and print to spreadsheet in
%          subject directory.

%% Ensure SPM8 path has been added, define home directory %%%%%%%%%%%%%%%%
%                                                                        %
% Code to remove/add SPM paths developed by K-lab:                       %
% http://www.nemotos.net/?p=21                                           %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
Study_Sub;
waitfor(Study_Sub);

study = evalin('base','study');
[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;

study_question = questdlg('What type of PET studies?', ...
    'VWI', ...
    'Static','Dynamic','Static');
% Handle response
switch study_question
    case 'Static'
        Answer = 1;
        study_dir = [studyprotocol{1,2} '\03_Pre-Processing'];
    case 'Dynamic'
        Answer = 2;
        study_dir = [studyprotocol{1,2} '\Dynamic'];
end


if exist('sub','var'),
    sub = evalin('base','sub');
    sublength{:,:} = sub;
    sub = sublength;
else
    dir_study = dir(study_dir);
    for kk = length(dir_study):-1:1
        % remove folders starting with .
        fname = dir_study(kk).name;
        if fname(1) == '.'
            dir_study(kk) = [ ];
        end
        if fname(1) == '!'
            dir_study(kk) = [ ];
        end
        if ~dir_study(kk).isdir
            dir_study(kk) = [ ];
            continue
        end
    end
    
    sublist = cell(size(dir_study,1),1);
    for kk = 1:1:size(dir_study,1),
        sublist{kk,:} = [dir_study(kk).name];
    end
    
    [subSelection,sok] = listdlg('PromptString','Select Subject(s) to Process:',...
        'SelectionMode','multiple','ListSize',[200 500],'Name','VWI','ListString',sublist);
    while isempty(subSelection)
        uiwait(msgbox('Error: You must select at least one Select Subject to Process.','Error message','error'));
        [subSelection,sok] = listdlg('PromptString','Select Subject(s) to Process:',...
            'SelectionMode','multiple','ListSize',[200 500],'Name','VWI','ListString',sublist);
    end
    
    sub = sublist(subSelection);
    sublength = sub;
end

%% Prompt to select type of ROI analysis
S = {'All ROIs','Brodmann Areas', 'Lobes' 'KMPs'};
[Group,ok] = listdlg('PromptString','Select type of ROI analysis:',...
    'SelectionMode','single','ListString',S);

if Group == 1,
    rois_home = [pth '\ROIs\aal_rois'];
    D = cell(textread([rois_home '\ROIs.txt'],'%s'));
    [Selection,ok] = listdlg('PromptString','Select which ROIs:',...
        'SelectionMode','multiple','ListSize',[160 300],'Name','ROI','ListString',D);
    while isempty(Selection)
        uiwait(msgbox('Error: You must select at least 1 ROI.','Error message','error'));
        [Selection,ok] = listdlg('PromptString','Select which ROIs:',...
            'SelectionMode','multiple','ListSize',[160 300],'Name','ROI','ListString',D);
    end
    
    for ii=1:1:size(sublength,1),
        sub = sublength{ii,:};
        sub_dir = [study_dir '\' sub];
        ROI_MNI_dir = [sub_dir '\ROI\ROI_MNI\'];
        mkdir(ROI_MNI_dir);
        for jj = 1:1:size(Selection,2),
            roitext = textread([rois_home '\' num2str(Selection(jj)) '.txt'],'%s');
            roitextsize = size(roitext,1);
            for gg = 1:1:roitextsize
                ROI_home = [pth '\ROIs\' roitext{gg}];
                copyfile(ROI_home,ROI_MNI_dir);
            end
        end
    end
end

if Group == 2,
    rois_home = [pth '\ROIs\ba_rois'];
    D = cell(textread([rois_home '\ROIs.txt'],'%s'));
    [Selection,ok] = listdlg('PromptString','Select which ROIs:',...
        'SelectionMode','multiple','ListSize',[160 300],'Name','ROI','ListString',D);
    while isempty(Selection)
        uiwait(msgbox('Error: You must select at least 1 ROI.','Error message','error'));
        [Selection,ok] = listdlg('PromptString','Select which ROIs:',...
            'SelectionMode','multiple','ListSize',[160 300],'Name','ROI','ListString',D);
    end
    for ii=1:1:size(sublength,1),
        sub = sublength{ii,:};
        sub_dir = [study_dir '\' sub];
        ROI_MNI_dir = [sub_dir '\ROI\ROI_MNI\'];
        mkdir(ROI_MNI_dir);
        for jj = 1:1:size(Selection,2),
            roitext = textread([rois_home '\' num2str(Selection(jj)) '.txt'],'%s');
            roitextsize = size(roitext,1);
            for gg = 1:1:roitextsize
                ROI_home = [pth '\ROIs\' roitext{gg}];
                copyfile(ROI_home,ROI_MNI_dir);
            end
        end
    end
end

if Group == 3,
    rois_home = [pth '\ROIs\lobe_rois'];
    D = cell(textread([rois_home '\ROIs.txt'],'%s'));
    [Selection,ok] = listdlg('PromptString','Select which ROIs:',...
        'SelectionMode','multiple','ListSize',[160 300],'Name','ROI','ListString',D);
    while isempty(Selection)
        uiwait(msgbox('Error: You must select at least 1 ROI.','Error message','error'));
        [Selection,ok] = listdlg('PromptString','Select which ROIs:',...
            'SelectionMode','multiple','ListSize',[160 300],'Name','ROI','ListString',D);
    end
    for ii=1:1:size(sublength,1),
        sub = sublength{ii,:};
        sub_dir = [study_dir '\' sub];
        ROI_MNI_dir = [sub_dir '\ROI\ROI_MNI\'];
        mkdir(ROI_MNI_dir);
        for jj = 1:1:size(Selection,2),
            roitext = textread([rois_home '\' num2str(Selection(jj)) '.txt'],'%s');
            roitextsize = size(roitext,1);
            for gg = 1:1:roitextsize
                ROI_home = [pth '\ROIs\' roitext{gg}];
                copyfile(ROI_home,ROI_MNI_dir);
            end
        end
    end
end

if Group == 4,
    rois_home = [pth '\ROIs\kmp_rois'];
    D = cell(textread([rois_home '\ROIs.txt'],'%s'));
    [Selection,ok] = listdlg('PromptString','Select which ROIs:',...
        'SelectionMode','multiple','ListSize',[160 300],'Name','ROI','ListString',D);
    for ii=1:1:size(sublength,1),
        sub = sublength{ii,:};
        sub_dir = [study_dir '\' sub];
        ROI_MNI_dir = [sub_dir '\ROI\ROI_MNI\'];
        mkdir(ROI_MNI_dir);
        for jj = 1:1:size(Selection,2),
            roitext = textread([rois_home '\' num2str(Selection(jj)) '.txt'],'%s');
            roitextsize = size(roitext,1);
            for gg = 1:1:roitextsize
                ROI_home = [pth '\ROIs\' roitext{gg}];
                copyfile(ROI_home,ROI_MNI_dir);
            end
        end
    end
end
clear S D roitext rois_home roitextsize

spm_jobman('initcfg');

%% Generate ROIs: The subject's MRI must have the inverse spatial...
%  normalization parameters file (*_seg_inv_sn.mat). %%%%
for ii=1:1:size(sublength,1),
    sub = sublength{ii,:};
    sub_dir = [study_dir '\' sub];
    inv_mat = dir([sub_dir, '\*inv_sn.mat']);
    mat_name = inv_mat.name;
    mat_name = [sub_dir '\' mat_name];
    vwi_roi_names = dir([sub_dir, '\ROI\ROI_MNI\*.nii']);
    vwi_roi_names = {vwi_roi_names.name};
    vwi_roi_names = str2mat(vwi_roi_names);
    vwi_size = size(vwi_roi_names,1);
    roi_array = cell(vwi_size,1);
    for jj=1:vwi_size
        roi_array(jj,1) = {[sub_dir '\ROI\ROI_MNI\' deblank(vwi_roi_names(jj,:)) ',1']};
    end;
    matlabbatch{1}.spm.spatial.normalise.write.subj.matname = {mat_name};
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = roi_array;
    matlabbatch{1}.spm.spatial.normalise.write.roptions.preserve = 0;
    matlabbatch{1}.spm.spatial.normalise.write.roptions.bb = [-100 -150 -100
        100  100  100];
    matlabbatch{1}.spm.spatial.normalise.write.roptions.vox = [2 2 2];
    matlabbatch{1}.spm.spatial.normalise.write.roptions.interp = 1;
    matlabbatch{1}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.normalise.write.roptions.prefix = [sub '_'];
    spm_jobman('run', matlabbatch);
    clear('matlabbatch');
    ROI_dir = [sub_dir '\ROI\'];
    ROI_MNI_dir = [sub_dir '\ROI\ROI_MNI\'];
    ROI_MNI_name = [ROI_MNI_dir sub];
    movefile([ROI_MNI_name '*.nii'], ROI_dir);
    rmdir([sub_dir '\ROI\ROI_MNI\'],'s'); % Delete MNI ROIs
    clear ROI_MNI_name vwi_size
end

%% Create an array of native space ROIs
for ii=1:1:size(sublength,1),
    sub = sublength{ii,:};
    sub_dir = [study_dir '\' sub];
    ROI_dir = [sub_dir '\ROI\'];
       
    % Create an arry of ROI names
    vwi_rois_dir = dir([ROI_dir,'*.nii']);
    sub_vwi_rois = {vwi_rois_dir.name};
    sub_vwi_rois = str2mat(sub_vwi_rois);
    clear roi_array
    for jj=1:size(sub_vwi_rois)
        roi_array(jj,1) = {[ROI_dir deblank(sub_vwi_rois(jj,:)) ',1']};
    end;
    % Reslice ROIs to PET space
    MRI_dir = dir([sub_dir, '\r*.nii']);
    MRI_name = MRI_dir.name;
    %     seg_dir = dir([sub_dir, '\p1*.nii']);
    %     seg_name = seg_dir.name;
    
    for zz=1:size(sub_vwi_rois) % Reslice and threshold ROIs
        vwi_rois_rname = [ROI_dir 'r' vwi_rois_dir(zz,:).name];
        vwi_rois_name = [ROI_dir vwi_rois_dir(zz,:).name];
        src_ref = {deblank([sub_dir '\' MRI_name ',1']),deblank([ROI_dir str2mat(vwi_rois_dir(zz,:).name) ',1'])};
        spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
        roi_name = [ROI_dir str2mat(vwi_rois_dir(zz,:).name)];
        delete(roi_name);
        movefile(vwi_rois_rname,vwi_rois_name);
        clear roi_name vwi_rois_rname vwi_rois_name
    end

    clear sub_vwi_rois vwi_rois_dir roi_array
    vwi_rois_dir = dir([ROI_dir,'*.nii']);
    sub_vwi_rois = {vwi_rois_dir.name};
    sub_vwi_rois = str2mat(sub_vwi_rois);
    clear roi_array
    for jj=1:size(sub_vwi_rois)
        roi_array(jj,1) = {[ROI_dir deblank(sub_vwi_rois(jj,:)) ',1']};
    end;
    % Threshold binary ROIs.
    for zz=1:size(sub_vwi_rois,1) % Reslice and threshold ROIs
        current_vols = [ROI_dir str2mat(vwi_rois_dir(zz,:).name)];
        vo_name = [ROI_dir vwi_rois_dir(zz,:).name];
        exp = 'i1>0';
        spm_imcalc_ui(current_vols,vo_name,exp);
    end
    
    clear roi_array vwi_rois_dir sub_vwi_rois
    vwi_rois_dir = dir([ROI_dir,'*.nii']);
    sub_vwi_rois = {vwi_rois_dir.name};
    sub_vwi_rois = str2mat(sub_vwi_rois);
end

clear exp vo_name current_vols inv_mat mat_name ROI_MNI_dir ROI_home
% clear exp rseg_dir vo_name current_vols segvol segvol_name segvol_size inv_mat mat_name ROI_MNI_dir ROI_home

%% Dilate ROIs
for ii=1:1:size(sublength,1),
    sub = sublength{ii,:};
    sub_dir = [study_dir '\' sub];
    ROI_dir = [sub_dir '\ROI\'];
    vwi_rois_dir = dir([ROI_dir,'*.nii']);
    sub_vwi_rois = {vwi_rois_dir.name};
    sub_vwi_rois = str2mat(sub_vwi_rois);
    if exist([sub_dir '\ROI\dilated\'],'dir') == 0, mkdir([sub_dir '\ROI\dilated\']); end
    for jj=1:size(sub_vwi_rois), copyfile([sub_dir '\ROI\' deblank(sub_vwi_rois(jj,:))],[sub_dir '\ROI\dilated\']); end
    roi_fnames = dir([sub_dir, '\ROI\dilated\']);
    roi_fnames = {roi_fnames(~[roi_fnames.isdir]).name};
    roi_fnames = char(rot90(roi_fnames)); %Replaces strvcat
    roi_fnames = flipud(roi_fnames); %Replaces strvcat
    [rows,~] = size(roi_fnames);
    for zz=1:rows,
        this_roi = [sub_dir '\ROI\dilated\' deblank(roi_fnames(zz,:))];
        roi_hdr = spm_vol(this_roi);
        roi = spm_read_vols(roi_hdr);
        dilated_roi = spm_dilate(roi);
        spm_write_vol(roi_hdr,dilated_roi);
    end
end

%% Subtract dilation masks from ROIs
if Group == 1 || Group == 4,
    for ii=1:1:size(sublength,1),
        sub = sublength{ii,:};
        sub_dir = [study_dir '\' sub];
        exp = []; % Define expression for ImCalc
        ROI_dir = [sub_dir '\ROI\'];
        NoLobe = dir([ROI_dir,'*ROI.nii']);
        sub_NoLobe = {NoLobe.name};
        sub_NoLobe = char(rot90(sub_NoLobe)); %Replaces strvcat
        sub_NoLobe = flipud(sub_NoLobe);  %Replaces strvcat
        NoLobe_size = size(sub_NoLobe,1);
        if NoLobe_size > 1,
            for zz=2:NoLobe_size,
                if isempty(exp); exp = ['i' num2str(zz)];
                else exp = [exp '+i' num2str(zz)]; end
            end;
        else
            continue
        end
        exp = ['(i1-(' exp '))>0'];
        for zz=1:NoLobe_size,
            calc_array(1,1) = {[sub_dir '\ROI\dilated\' deblank(sub_NoLobe(zz,:)) ',1']};
            counter = 2;
            for gg=1:NoLobe_size,
                if zz~=gg, calc_array(counter,1) = {[sub_dir '\ROI\dilated\' deblank(sub_NoLobe(gg,:)) ',1']}; counter=counter+1; end
            end;
            sub_NoLobe_out = [sub_dir '\ROI\' deblank(sub_NoLobe(zz,:))];
            spm_imcalc_ui(calc_array,sub_NoLobe_out,exp);
        end
    end
    clear calc_array
end

%% Subtract dilation masks from Brodmann Areas
if Group == 1 || Group == 2,
    for ii=1:1:size(sublength,1),
        sub = sublength{ii,:};
        sub_dir = [study_dir '\' sub];
        exp = []; % Define expression for ImCalc
        ROI_dir = [sub_dir '\ROI\'];
        BArea = dir([ROI_dir,'*_BA.nii']);
        sub_BArea = {BArea.name};
        sub_BArea = char(rot90(sub_BArea)); %Replaces strvcat
        sub_BArea = flipud(sub_BArea);  %Replaces strvcat
        BArea_size = size(sub_BArea,1);
        if BArea_size > 1,
            for zz=2:BArea_size,
                if isempty(exp); exp = ['i' num2str(zz)];
                else exp = [exp '+i' num2str(zz)];
                end
            end;
        else
            continue
        end
        exp = ['(i1-(' exp '))>0'];
        for zz=1:BArea_size,
            calc_array(1,1) = {[sub_dir '\ROI\dilated\' deblank(sub_BArea(zz,:)) ',1']};
            counter = 2;
            for gg=1:BArea_size,
                if zz~=gg, calc_array(counter,1) = {[sub_dir '\ROI\dilated\' deblank(sub_BArea(gg,:)) ',1']}; counter=counter+1; end
            end;
            sub_BArea_out = [sub_dir '\ROI\' deblank(sub_BArea(zz,:))];
            spm_imcalc_ui(calc_array,sub_BArea_out,exp);
        end
    end
    clear calc_array
end

%% Subtract dilation masks from LOBEs
if Group == 1 || Group == 3,
    for ii=1:1:size(sublength,1),
        sub = sublength{ii,:};
        sub_dir = [study_dir '\' sub];
        ROI_dir = [sub_dir '\ROI\'];
        exp = []; % Define expression for ImCalc
        lobe = dir([ROI_dir,'*Lobe_GM.nii']);
        sub_lobe = {lobe.name};
        sub_lobe = char(rot90(sub_lobe)); %Replaces strvcat
        sub_lobe = flipud(sub_lobe);  %Replaces strvcat
        lobe_size = size(sub_lobe,1);
        if lobe_size > 1,
            for zz=2:lobe_size,
                if isempty(exp); exp = ['i' num2str(zz)];
                else exp = [exp '+i' num2str(zz)]; end
            end;
            exp = ['(i1-(' exp '))>0'];
            for zz=1:lobe_size,
                calc_array(1,1) = {[sub_dir '\ROI\dilated\' deblank(sub_lobe(zz,:)) ',1']};
                counter = 2;
                for gg=1:lobe_size,
                    if zz~=gg, calc_array(counter,1) = {[sub_dir '\ROI\dilated\' deblank(sub_lobe(gg,:)) ',1']}; counter=counter+1; end
                end;
                sub_lobe_out = [sub_dir '\ROI\' deblank(sub_lobe(zz,:))];
                spm_imcalc_ui(calc_array,sub_lobe_out,exp);
            end
            continue
        else
            exp = [];
            dilated = [sub_dir '\ROI\dilated\'];
            cerb = dir([dilated,'*CerGM_*']);
            sub_cerb = {cerb.name};
            sub_cerb = char(rot90(sub_cerb)); %Replaces strvcat
            sub_cerb = flipud(sub_cerb);  %Replaces strvcat
            clear calc_array;
            if size(sub_cerb) > 1,
                for zz = 1:lobe_size,
                    exp = '(i1-(i2+i3)>0)';
                    calc_array(1,1) = {[sub_dir '\ROI\' deblank(sub_lobe(zz,:)) ',1']};
                    calc_array(2,1) = {[sub_dir '\ROI\dilated\' deblank(sub_cerb(1,:)) ',1']};
                    calc_array(3,1) = {[sub_dir '\ROI\dilated\' deblank(sub_cerb(2,:)) ',1']};
                    sub_cerb_out = [sub_dir '\ROI\' deblank(sub_lobe(zz,:))];
                    spm_imcalc_ui(calc_array,sub_cerb_out,exp);
                end
            else
                rmdir([sub_dir '\ROI\dilated\'],'s'); % Delete dilation masks
                continue
            end
        end
%         clear calc_array
%         exp = ['(i1-(' exp '))>0'];
%         for zz=1:lobe_size,
%             calc_array(1,1) = {[sub_dir '\ROI\dilated\' deblank(sub_lobe(zz,:)) ',1']};
%             counter = 2;
%             for gg=1:lobe_size,
%                 if zz~=gg, calc_array(counter,1) = {[sub_dir '\ROI\dilated\' deblank(sub_lobe(gg,:)) ',1']}; counter=counter+1; end
%             end;
%             sub_lobe_out = [sub_dir '\ROI\' deblank(sub_lobe(zz,:))];
%             spm_imcalc_ui(calc_array,sub_lobe_out,exp);
%         end
%         exp = [];
%         dilated = [sub_dir '\ROI\dilated\'];
%         cerb = dir([dilated,'*CerGM_*']);
%         sub_cerb = {cerb.name};
%         sub_cerb = char(rot90(sub_cerb)); %Replaces strvcat
%         sub_cerb = flipud(sub_cerb);  %Replaces strvcat
%         clear calc_array;
%         if size(sub_cerb,1) > 0,
%             for zz = 1:lobe_size,
%                 exp = '(i1-(i2+i3)>0)';
%                 calc_array(1,1) = {[sub_dir '\ROI\' deblank(sub_lobe(zz,:)) ',1']};
%                 calc_array(2,1) = {[sub_dir '\ROI\dilated\' deblank(sub_cerb(1,:)) ',1']};
%                 calc_array(3,1) = {[sub_dir '\ROI\dilated\' deblank(sub_cerb(2,:)) ',1']};
%                 sub_cerb_out = [sub_dir '\ROI\' deblank(sub_lobe(zz,:))];
%                 spm_imcalc_ui(calc_array,sub_cerb_out,exp);
%             end
%         end
    end
    clear calc_array
end

%% Subtract Frontal Temporal Space from ROIs and remove dilation dir
for ii=1:1:size(sublength,1),
    sub = sublength{ii,:};
    sub_dir = [study_dir '\' sub];
    space = dir([sub_dir, '\ROI\dilated\*Frontal-Temporal_Space.nii']);
    ROI_dir = [sub_dir '\ROI\'];
    if size(space,1) > 0,
        space_name = {space.name};
        space_name = char(rot90(space_name)); %Replaces strvcat
        space_name = flipud(space_name);  %Replaces strvcat
        rois = dir([ROI_dir, '*.nii']);
        rois_name = {rois.name};
        rois_name = char(rot90(rois_name)); %Replaces strvcat
        rois_name = flipud(rois_name); %Replaces strvcat
        rois_size = size(rois_name,1);
        exp = '((i1>0)-(i2>0))>0';
        clear calc_array
        for zz=1:rois_size,
            roi_temp = rois_name(zz,:);
            if strcmp(deblank(roi_temp),space_name) == 1
                continue
            else
                calc_array(1,1) = {[sub_dir '\ROI\' deblank(rois_name(zz,:)) ',1']};
                calc_array(2,1) = {[sub_dir '\ROI\dilated\' deblank(space_name) ',1']};
                rois_out = [sub_dir '\ROI\' deblank(rois_name(zz,:))];
                spm_imcalc_ui(calc_array,rois_out,exp);
            end
        end
        delete([sub_dir '\ROI\*Frontal-Temporal_Space.nii']);
    end
    rmdir([sub_dir '\ROI\dilated\'],'s'); % Delete dilation masks
    ROI_dir = [sub_dir '\ROI\'];
    vwi_rois_dir = dir([ROI_dir,'*.nii']);
    sub_vwi_rois = {vwi_rois_dir.name};
    sub_vwi_rois = str2mat(sub_vwi_rois);
    eval(sprintf('sub_vwi_rois_%d = sub_vwi_rois;',ii));
    for jj=1:size(sub_vwi_rois)
        roi_array(jj,1) = {[ROI_dir deblank(sub_vwi_rois(jj,:)) ',1']};
    end;
    roi_fnames = dir([sub_dir, '\ROI\*.nii']);
    roi_fnames = {roi_fnames.name};
    roi_fnames = char(rot90(roi_fnames)); %Replaces strvcat
    roi_fnames = flipud(roi_fnames); %Replaces strvcat
    eval(sprintf('roi_array_%d = roi_array;',ii));
    eval(sprintf('roi_fnames_%d = roi_fnames;',ii))
    eval(sprintf('vwi_rois_dir_%d = vwi_rois_dir;',ii))
end

%% Create non-gray and non-white matter masks
for ii=1:1:size(sublength,1),
    sub = sublength{ii,:};
    sub_dir = [study_dir '\' sub];
    MRI_dir = dir([sub_dir, '\r*.nii']);
    MRI_name = MRI_dir.name;
    GM_dir = dir([sub_dir, '\p1*.nii']);
    if size(GM_dir,1) == 0,
        GM_dir = dir([sub_dir, '\c1*.nii']);
    end
    GM_name = GM_dir.name;
    WM_dir = dir([sub_dir, '\p2*.nii']);
    if size(WM_dir,1) == 0,
        WM_dir = dir([sub_dir, '\c2*.nii']);
    end
    WM_name = WM_dir.name;
    CSF_dir = dir([sub_dir, '\p3*.nii']);
    if size(CSF_dir,1) == 0,
        CSF_dir = dir([sub_dir, '\c3*.nii']);
    end
    CSF_name = CSF_dir.name;
    ROI_dir = [sub_dir '\ROI\'];
    
    current_vols = str2mat([sub_dir '\' CSF_name ',1'],...
        [sub_dir '\' GM_name ',1']);
    vo_name = [ROI_dir sub '_Non-CSF-Mask.nii'];
    exp = '((i1>.25) - (i2>.1))>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
    roi_mask_csf = [sub '_Non-CSF-Mask.nii'];
    
    current_vols = str2mat([sub_dir '\' MRI_name ',1'],...
        [sub_dir '\' GM_name ',1'],...
        [sub_dir '\' WM_name ',1'],...
        [sub_dir '\' CSF_name ',1']);
    vo_name = [ROI_dir sub '_Non-Brain-Mask.nii'];
    exp = '((i1>0)-(((i2>.1)+(i3>.1))-(i4>.25)))>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
    roi_mask_Brain = [sub '_Non-Brain-Mask.nii'];
    
    current_vols = str2mat([sub_dir '\' MRI_name ',1'],...
        [sub_dir '\' GM_name ',1']);
    vo_name = [ROI_dir sub '_Non-GM-Mask.nii']; % CerGM VOI mask
    exp = '((i1>0)-(i2>.75))>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
    roi_mask_75 = [sub '_Non-GM-Mask.nii'];
    
    clear vo_name exp % More stringent mask
    vo_name = [ROI_dir sub '_Non-GM-Mask_3.nii'];
    exp = '((i1>0)-(i2>.5))>0';
    %     exp = '((i1>0)-(i2>.3))>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
    roi_mask_3 = [sub '_Non-GM-Mask_3.nii'];
    
    clear vo_name exp % Least stringent mask
    vo_name = [ROI_dir sub '_Non-GM-Mask_1.nii'];
    exp = '((i1>0)-(i2>0.01))>0';
    %     exp = '((i1>0)-(i2>0.1))>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
    roi_mask_1 = [sub '_Non-GM-Mask_1.nii'];
    
    clear current_vols vo_name exp
    current_vols = str2mat([sub_dir '\' MRI_name ',1'],...
        [sub_dir '\' WM_name ',1']);
    vo_name = [ROI_dir sub '_Non-WM-Mask_6.nii']; % White matter mask
    exp = '((i1>0)-(i2>.6))>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
    roi_mask_wm = [sub '_Non-WM-Mask_6.nii'];
    
    clear current_vols vo_name exp
    current_vols = str2mat([ROI_dir sub '_Non-GM-Mask.nii'],...
        [ROI_dir sub '_Non-GM-Mask_3.nii'],...
        [ROI_dir sub '_Non-GM-Mask_1.nii'],...
        [ROI_dir sub '_Non-CSF-Mask.nii']);
    exp = '((i1>0)+(i2>0))>0';
    for dd = 1:1:3
        imgs_in = str2mat(current_vols(dd,:),(current_vols(4,:)));
        imgs_out = str2mat(current_vols(dd,:));
        spm_imcalc_ui(imgs_in,imgs_out,exp);
    end
    
    
    
    %Clean segment partitions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                                                                        %
    % Chris Rorden's adaptation of John Ashburner's script to clean segment  %
    % partitions.                                                            %
    %                                                                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for zz=1:4,
        if zz==1, roi_mask = roi_mask_75; elseif zz==2, roi_mask = roi_mask_3; elseif zz==3, roi_mask = roi_mask_1; elseif zz==4, roi_mask = roi_mask_wm; end
        wi = spm_vol([ROI_dir roi_mask]);
        w = spm_read_vols(wi)*255;
        b = w;
        kx=[0.75 1 0.75]; % Build a 3x3x3 seperable smoothing kernel
        ky=[0.75 1 0.75];
        kz=[0.75 1 0.75];
        sm=sum(kron(kron(kz,ky),kx))^(1/3);
        kx=kx/sm; ky=ky/sm; kz=kz/sm;
        th1 = 0.2;
        niter = 32;
        spm_progress_bar('Init',niter,'Cleaning tissue masks (x4)','Iterations completed');
        for gg=1:niter,
            if gg>2, th=th1; else th=0.6; end; % Dilate after two its of erosion.
            for jj=1:size(b,3),
                wp = double(w(:,:,jj));
                bp = double(b(:,:,jj))/255;
                bp = (bp>th).*(wp);
                b(:,:,jj) = uint8(round(bp));
            end;
            spm_conv_vol(b,b,kx,ky,kz,-[1 1 1]);
            spm_progress_bar('Set',gg);
        end;
        th = 0.05;
        for hh=1:size(b,3),
            wp = double(w(:,:,hh))/255;
            bp = double(b(:,:,hh))/255;
            bp = ((bp>th).*(wp))>th;
            w(:,:,hh) = uint8(round(255*wp.*bp));
        end;
        spm_progress_bar('Clear');
        [pth,nam,ext]=fileparts(wi.fname);
        wi.fname = fullfile(pth,[nam, ext]);
        spm_write_vol(wi,w/255);
    end
    
    %% Reslice non-gray and non-white matter masks
%     for zz=1:4,
%         if zz==1, roi_mask = roi_mask_75; elseif zz==2, roi_mask = roi_mask_3; elseif zz==3, roi_mask = roi_mask_1; elseif zz==4, roi_mask = roi_mask_wm; end
%         src_ref = {[sub_dir '\' MRI_name ',1'];[ROI_dir roi_mask ',1']};
%         spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
%         current_vols = [ROI_dir 'r' roi_mask];
%         vo_name = [ROI_dir roi_mask];
%         exp = 'i1>0.5';
%         delete(vo_name);
%         spm_imcalc_ui(current_vols,vo_name,exp);
%         delete([ROI_dir 'r' roi_mask]);
%     end
    clear current_vols vo_name exp nam ext
    %% Subtract non-gray matter tissue from ROIs
    sub_vwi_rois = eval(sprintf('sub_vwi_rois_%d',ii));
    roi_fnames = eval(sprintf('roi_fnames_%d',ii));
    roi_array = eval(sprintf('roi_array_%d',ii));
    vwi_rois_dir = eval(sprintf('vwi_rois_dir_%d',ii));
    clear rows
    rows = size(sub_vwi_rois,1);
    for zz=1:rows,
        size_check = spm_read_vols(spm_vol([ROI_dir sub_vwi_rois(zz,:)]));
        roi_fname = deblank(sub_vwi_rois(zz,:));
        [~,remain] = strtok(deblank(roi_fnames(zz,:)), '_'); roi_region = deblank(strtok(remain(2:end), '_'));
%         if strcmp(roi_region,'Putamen') == 0 && strcmp(roi_region,'Thalamus') == 0,
%             if isempty(strfind(roi_fname(end-12:end-9),'_WM_')),
%                 disp([roi_fname ' 6']);
%                 current_vols = strvcat({[str2mat(roi_array(zz))], [sub_dir '\ROI\' roi_mask_3 ',1']});
%                 [~,nam,ext] = fileparts(vwi_rois_dir(zz,:).name);
%                 vo_name = [ROI_dir nam ext];
%                 exp = '(i1 - i2)>.99';
%                 spm_imcalc_ui(current_vols,vo_name,exp);
%             elseif isempty(strfind(roi_fname(end-12:end-9),'_WM_')) == 0,
%                 disp([roi_fname ' WM']);
%                 current_vols = strvcat({[str2mat(roi_array(zz))], [sub_dir '\ROI\' roi_mask_wm ',1']});
%                 [~,nam,ext] = fileparts(vwi_rois_dir(zz,:).name);
%                 vo_name = [ROI_dir nam ext];
%                 exp = '(i1 - i2)>.99';
%                 spm_imcalc_ui(current_vols,vo_name,exp);
%             end
%         elseif strcmp(roi_region,'Putamen') || strcmp(roi_region,'Thalamus'),
%             disp([roi_fname ' 2']);
%             current_vols = strvcat({[str2mat(roi_array(zz))], [sub_dir '\ROI\' roi_mask_1 ',1']});
%             [~,nam,ext] = fileparts(vwi_rois_dir(zz,:).name);
%             vo_name = [ROI_dir nam ext];
%             exp = '(i1 - i2)>.99';
%             spm_imcalc_ui(current_vols,vo_name,exp);
%         end
        disp([roi_fname ' CSF Masking...']);
        current_vols = strvcat({[str2mat(roi_array(zz))], [sub_dir '\ROI\' roi_mask_Brain ',1']});
        [~,nam,ext] = fileparts(vwi_rois_dir(zz,:).name);
        vo_name = [ROI_dir nam ext];
        exp = '(i1 - i2)>.99';
        spm_imcalc_ui(current_vols,vo_name,exp);
        clear size_check current_vols vo_name exp nam ext
    end
    
    % Threshold ROIs to k >= 100 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                                                                        %
    % Martin Pyka's adaptation of John Ashburner's script to apply extent    %
    % thresholds: http://spm.martinpyka.de/?p=29                             %
    %                                                                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    j = 100;
    %     j = 75;
    %     j = 50;
    for hh = 1:rows,
        size_check = spm_read_vols(spm_vol([ROI_dir sub_vwi_rois(hh,:)]));
        %         if size(find(size_check>0),1) > 75
        if size(find(size_check>0),1) > 100
            %             if size(find(size_check>0),1) > 50
            hdr = spm_vol([ROI_dir sub_vwi_rois(hh,:)]);
            image = spm_read_vols(hdr);
            indices = find(image>0);
            [x, y, z] = ind2sub(size(image), indices);
            XYZ = [x y z];
            A     = spm_clusters(XYZ');
            Q     = [];
            for mm = 1:max(A)
                d = find(A == mm);
                if length(d) >= j; Q = [Q d]; end
            end
            XYZ   = XYZ(Q,:);
            result = zeros(size(image));
            inds = sub2ind(size(image), XYZ(:,1), XYZ(:,2), XYZ(:,3));
            result(inds) = image(inds);
            spm_write_vol(hdr,result);
        end
    end
    %% Sum ROIs
    vwi_sum_rois([sub_dir '\ROI\']);
end
clear calc_array
% % Subtract Cerebellar GM from ROIs.
% for ii=1:1:str2double(SubNum);
%     sub_dir = eval(sprintf('sub_dir_%d',ii));
%     ROI_dir = [sub_dir '\ROI\Summed\'];
%     cereb = dir([ROI_dir,'*Cerebellar-GM.nii']);
%     if size(cereb,1) > 0,
%         cereb_name = {cereb.name};
%         cereb_name = char(rot90(cereb_name)); %Replaces strvcat
%         cereb_name = flipud(cereb_name);  %Replaces strvcat
%         rois = dir([ROI_dir, '*.nii']);
%         rois_name = {rois.name};
%         rois_name = char(rot90(rois_name)); %Replaces strvcat
%         rois_name = flipud(rois_name); %Replaces strvcat
%         rois_size = size(rois_name,1);
%         exp = '((i1>0)-(i2>0))>0';
%         clear calc_array
%         for zz=1:rois_size,
%             roi_temp = rois_name(zz,:);
%             if strcmp(deblank(roi_temp),cereb_name) == 1
%                 continue
%             else
%                 calc_array(1,1) = {[sub_dir '\ROI\Summed\' deblank(rois_name(zz,:)) ',1']};
%                 calc_array(2,1) = {[sub_dir '\ROI\Summed\' deblank(cereb_name) ',1']};
%                 rois_out = [sub_dir '\ROI\Summed\' deblank(rois_name(zz,:))];
%                 spm_imcalc_ui(calc_array,rois_out,exp);
%             end
%         end
%     end
% end

%% Get ROI values and print to spreadsheet.
for ii=1:1:size(sublength,1),
    sub = sublength{ii,:};
    sub_dir = [study_dir '\' sub];
    vwi_get_roivals(sub_dir,sub,study,Answer);
end

close all;
clear,clc;
disp('DONE!');

end