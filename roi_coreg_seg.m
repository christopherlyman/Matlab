function roi_coreg_seg()
%
%        Voxel-Wise Institute: ROI
%        Coregistration and Segmentation Module
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman Cliff Workman
%
%        Usage: roi_coreg_seg(sub,study)
%
%        sub: subject number e.g.) '01-001'
%        study: study name, e.g.) 'FNMI'
%
%% Declare required variables, if not already declared
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

if exist('sub','var'),
    sub = evalin('base','sub');
else
    sub = 'BATCH';
end
study = evalin('base','study');
[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;
study_dir = [studyprotocol{1,2} '\03_Pre-Processing'];


if strcmp(sub,'BATCH')==1,
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
    
    for ii=1:1:size(sublist(subSelection),1),
        sub = sublist{subSelection(ii)};
        sub_dir = [study_dir '\' sub];
        
        MRfile = dir([sub_dir,'\*.nii']);
        MRimg = [sub_dir '\' MRfile.name ',1'];
        dir_sub = dir(sub_dir);
        for kk = length(dir_sub):-1:1
            % remove folders starting with .
            fname = dir_sub(kk).name;
            if fname(1) == '.'
                dir_sub(kk) = [ ];
            end
            if fname(1) == '!'
                dir_sub(kk) = [ ];
            end
            if ~dir_sub(kk).isdir
                dir_sub(kk) = [ ];
                continue
            end
        end
        Count = 1;
        for jj=1:1:size(dir_sub,1),
            FDG_dir = [sub_dir '\' dir_sub(jj).name];
            dir_FDG = dir([FDG_dir,'\*.nii']);
            for gg = 1:1:size(dir_FDG,1),
                FDG_list{Count,1} = [FDG_dir '\' dir_FDG(gg).name ',1'];
                Count= Count+1;
            end
        end
        
        sub_mask = [sub '_MASK.nii'];
        outputdir = [sub_dir '\'];
        
        spm_jobman('initcfg');
        load([pth '\Realign-Coreg-Seg-Mask2.mat']);
        
         matlabbatch{1}.spm.spatial.realign.estwrite.data = {FDG_list};
         matlabbatch{2}.spm.spatial.coreg.estwrite.source = {MRimg};
         matlabbatch{4}.spm.util.imcalc.output = sub_mask;
         matlabbatch{4}.spm.util.imcalc.outdir = {outputdir};
         job = spm_jobman('run',matlabbatch);
         
         mean_dir = dir([sub_dir '\' dir_sub(1).name '\mean*.nii']);
         mean_in = [sub_dir '\' dir_sub(1).name '\' mean_dir.name];
         mean_out = [sub_dir '\' mean_dir.name];
         movefile(mean_in,mean_out,'f')
         
         clear FDG_list dir_FDG dir_sub
    end
    
else
    sub_dir = [study_dir '\' sub];
    
    MRfile = dir([sub_dir,'\*.nii']);
    MRimg = [sub_dir '\' MRfile.name ',1'];
    dir_sub = dir(sub_dir);
    for kk = length(dir_sub):-1:1
        % remove folders starting with .
        fname = dir_sub(kk).name;
        if fname(1) == '.'
            dir_sub(kk) = [ ];
        end
        if fname(1) == '!'
            dir_sub(kk) = [ ];
        end
        if ~dir_sub(kk).isdir
            dir_sub(kk) = [ ];
            continue
        end
    end
    Count = 1;
    for jj=1:1:size(dir_sub,1),
        FDG_dir = [sub_dir '\' dir_sub(jj).name];
        dir_FDG = dir([FDG_dir,'\*.nii']);
        for gg = 1:1:size(dir_FDG,1),
            FDG_list{Count,1} = [FDG_dir '\' dir_FDG(gg).name ',1'];
            Count= Count+1;
        end
    end
    
    sub_mask = [sub '_MASK.nii'];
    outputdir = [sub_dir '\'];
    
    spm_jobman('initcfg');
    load([pth '\Realign-Coreg-Seg-Mask2.mat']);
    
    matlabbatch{1}.spm.spatial.realign.estwrite.data = {FDG_list};
    matlabbatch{2}.spm.spatial.coreg.estwrite.source = {MRimg};
    matlabbatch{4}.spm.util.imcalc.output = sub_mask;
    matlabbatch{4}.spm.util.imcalc.outdir = {outputdir};
    job = spm_jobman('run',matlabbatch);
end

clc

disp('DONE!');

end