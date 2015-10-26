function spa_coreg_seg()
%
%        Kinetic Modeling Pipeline
%        Coregistration and Segmentation Module
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman
%
%        Usage: spa_coreg_seg(sub_stu,mprage_pdir,dasb1_pdir,pib_pdir,dasb2_pdir)
%
%        sub_stu: subject number, prefixed with "MCI" where required
%        mprage_pdir: MPRAGE processing directory
%        dasb1_pdir: baseline DASB processing directory
%        pib_pdir: PIB processing directory
%        dasb2_pdir: follow-up DASB processing directory
%
%        This module coregisters the MPRAGE, PIB, and follow-up DASB (if
%        they exist) to the baseline DASB scan. Alternatively, if the DASB
%        is missing, the MR is coregistered to the PIB. The reference images
%        used for coregistration are the summed image frames 1-30 for DASBs
%        and summed image frames 1-16 for PIB. If the DASB reference is
%        missing, this software will pick the last summed image available.
%        If the PIB reference is missing, it will pick the image closest to
%        and greater than summed image frames 1-16 (for example, summed
%        image frames 1-17). After coregistration, the MPRAGE is segmented
%        into gray matter, white matter, and CSF, and normalization
%        parameters to MNI space are derived.
%
%        This function also implicitly calls "kmp_vois_mres." Type
%        "help kmp_vois_mres" in the MATLAB command window for more information.
%
%        This module is meant to be used with KMP. If using as a
%        standalone module, please note that any missing scans should be
%        specified as is done in the following example: dasb1_pdir = '';

%% Declare required variables, if not already declared
clear all
clear globals
[pth] = fileparts(which('spa'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));


%% Define Dirs and set SPM8 path
uiwait(msgbox('Please select the processing directory.','SPA'));
proc_dir = uigetdir(home_dir, 'Select the Processing directory...');

while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc

spm_get_defaults('cmdline',true);


%% Prompt for study name and number of subjects and number of MRI/PET scans.
stdysubnum = get_stdysubnum;
stdy = stdysubnum{1};
subnum = stdysubnum{2};
for i=1:1:str2double(subnum);
    subinfo = get_subinfo(i);
    sub = subinfo{1};
    MRInum1 = subinfo{2};
    PETnum1 = subinfo{3};
    MRInum = str2double(MRInum1);
    PETnum = str2double(PETnum1);
    stu_sub = [stdy '-' sub];
    eval(sprintf('sub_%d = sub;',i));
    eval(sprintf('MRInum_%d = MRInum;',i));
    eval(sprintf('PETnum_%d = PETnum;',i));
    eval(sprintf('stu_sub_%d = stu_sub;',i));
end
clear PETnum1 MRInum1 

%% Prompt to select MRI scans
for i=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',i));
    stu_sub = [stdy '-' sub];
    MRInum = eval(sprintf('MRInum_%d',i));
    if MRInum > 0,
        for k = 1:1:MRInum;
            msg1 = ('Please select the MRI scan number ');
            msg2 = (' for ');
            msg = [sprintf('%s%d%s%s', msg1,k,msg2,stu_sub)];
            MRI_dir = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');
            eval(sprintf('sub_%d_MRI_%d = MRI_dir;',i,k));
        end
    end
end

%% Prompt to select PET scans
for i=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',i));
    stu_sub = [stdy '-' sub];
    PETnum = eval(sprintf('PETnum_%d',i));
    MRI_dir = eval(sprintf('sub_%d_MRI_1',i));
    [pathstr, name, ext] = fileparts(MRI_dir);
    if PETnum > 0,
        for k = 1:1:PETnum;
            if k == 1,
                msg1 = ('Please select PET scan number ');
                msg2 = (' for ');
                msg = [sprintf('%s%d%s%s', msg1,k,msg2,stu_sub)];
                PET_dir = spm_select(Inf,'image', msg ,[],pathstr,'\.(nii|img)$');
                eval(sprintf('sub_%d_PET_%d = PET_dir;',i,k));
            else
                [pathstr, name, ext] = fileparts(PET_dir);
                msg1 = ('Please select PET scan number ');
                msg2 = (' for ');
                msg = [sprintf('%s%d%s%s', msg1,k,msg2,stu_sub)];
                PET_dir = spm_select(Inf,'image', msg ,[],pathstr,'\.(nii|img)$');
                eval(sprintf('sub_%d_PET_%d = PET_dir;',i,k));
            end
        end
    end
    clear pathstr name ext
end
clear msg;
clear msg1;
clear msg2;

%% Copy baseline MRI to PET folders and Coregister, Segment, and ImCalc

for i=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',i));
    stu_sub = [stdy '-' sub];
    PETnum = eval(sprintf('PETnum_%d',i));
    MRI_source = eval(sprintf('sub_%d_MRI_1',i));
    [pathstr, name, ext] = fileparts(MRI_source);
    sub_dir = [proc_dir '\Processing\' stu_sub];
    stringext = strfind(ext,'.img');
    if isempty(stringext)
        ext = ('.nii');
    else
        ext = ('.img');
    end
    MRI_proc = [sub_dir '\' name ext];
    MRI_source = [pathstr '\' name ext];
    mkdir(sub_dir);
    copyfile(MRI_source,MRI_proc,'f');
    images(1,:) = cellstr([name ext]);
    for k = 1:1:PETnum;
        PET_source = eval(sprintf('sub_%d_PET_%d',i,k));
        [pathstr, name, ext] = fileparts(PET_source);
            stringext = strfind(ext,'.img');
        if isempty(stringext)
            ext = ('.nii');
            PET_proc = [sub_dir '\' name ext];
            PET_source = [pathstr '\' name ext];
            copyfile(PET_source,PET_proc,'f');
        else
            ext = ('.img');
            hdr = ('.hdr');
            PET_proc = [sub_dir '\' name ext];
            PET_source = [pathstr '\' name ext];
            copyfile(PET_source,PET_proc,'f');
            hdr_proc = [sub_dir '\' name hdr];
            hdr_source = [pathstr '\' name hdr];
            copyfile(hdr_source,hdr_proc,'f');
        end
        
        images(k+1,:) = cellstr([name ext]);
        PET_name = [sub_dir '\' name ext ',1'];
        PET_array(k,1) = {PET_name};
    end
    
    textfile = [sub_dir '\Images.txt'];
    fid=fopen(textfile,'wt');
    
    [rows,cols]=size(images);
    
    for ii=1:rows
        fprintf(fid,'%s\n',images{ii,:});
    end
    fclose(fid);


    eval(sprintf('PET_array_%d = PET_array;',i));
    MRI_name = [MRI_proc ',1'];
    
    if PETnum < 2
        load Coreg-Seg-VBM8-Mask;
        spm_jobman('initcfg');
        matlabbatch{1}.spm.spatial.coreg.estwrite.source = {MRI_name};
        matlabbatch{1}.spm.spatial.coreg.estwrite.ref = PET_array;
        mask = [sprintf('%s%s',stu_sub,'_PET-MASK.nii')];
        matlabbatch{4}.spm.util.imcalc.output = mask;
        matlabbatch{4}.spm.util.imcalc.outdir = {sub_dir};
    else
        load Realign-Coreg-Seg-VBM8-Mask_2;
        spm_jobman('initcfg');
        matlabbatch{1}.spm.spatial.realign.estwrite.data = {PET_array};
        matlabbatch{2}.spm.spatial.coreg.estwrite.source = {MRI_name};
        mask = [sprintf('%s%s',stu_sub,'_PET-MASK.nii')];
        matlabbatch{5}.spm.util.imcalc.output = mask;
        matlabbatch{5}.spm.util.imcalc.outdir = {sub_dir};
    
    end
    RealignCoregSeg = spm_jobman('run',matlabbatch);
end

clc
close all;

disp('DONE!');

end