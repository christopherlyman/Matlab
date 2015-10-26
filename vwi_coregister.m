function spa_coregister()
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman and Clifford Workman
%
%        Usage: spa_reduce;
%
%       This reduces PET axial slices down to the first 150 frames and
%       converts the PET from Bq to nCi.
%
%
%% Define Dirs and set SPM8 path
clear all
clear globals
[pth] = fileparts(which('spa'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

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
spm_jobman('initcfg');

%% Prompt for study name and the number of subject's to analyze.
stdysubnum = get_stdysubnum;
stdy = stdysubnum{1};
subnum = stdysubnum{2};
clear stdysubnum

%% Prompt to enter subject number and select subject(s) processing directory
for ii=1:1:str2double(subnum);
    box = ('Enter Subject Number for ');
    box1 = sprintf('%s%d',box,ii);
    box2 = {box1};
    box_title = 'SPA';
    num_lines = 1;
    subinfo = inputdlg(box2,box_title,num_lines);
    if isempty(subinfo),
        return,
    end;
    if isempty(subinfo{1}) == 0
        sub = subinfo{1};
    end
    while isempty(subinfo{1})
        uiwait(msgbox('Error: Subject Number not entered.','Error message','error'));
        box = ('Enter Subject Number for ');
        box1 = sprintf('%s%d',box,ii);
        box2 = {box1};
        box_title = 'SPA';
        num_lines = 1;
        subinfo = inputdlg(box2,box_title,num_lines);
        if isempty(subinfo{1}) == 0;
            sub = subinfo{1};
        end
    end
    eval(sprintf('sub_%d = sub;',ii));
end
clear box box1 box2 box_title num_lines subinfo

%% Prompt to select Dynamic PET scans
for ii=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',ii));
    if isempty(stdy) == 0,
        stu_sub = [stdy '-' sub];
    else
        stu_sub = sub;
    end
    
    stringMCI = strfind(sub,'MCI');
    if stringMCI == 1,
        PET_dir = ('Z:\Hopkins-data\MCI_AD_(NA_00026190-34091)\Processed_Images\PET_Data\Processing');
        sub_dir = [PET_dir '\' sub(4:end)];
    else
        PET_dir = ('Z:\Hopkins-data\GD_(NA_00021615)\Processed_Images\PET_Data\Processing');
        sub_dir = [PET_dir '\' sub];
    end
    msg1 = ('Please select the Dynamic PET Summed frame');
    msg2 = (' for ');
    msg = [sprintf('%s%s%s', msg1,msg2,stu_sub)];
    uiwait(msgbox(msg,'SPA'));
    subPET = spm_select(1:1,'image', msg ,[],sub_dir,'\.(nii|img)$');
    eval(sprintf('sub_%d_PET = subPET;',ii));
end

%% Copy files and create array of image files
proc = [proc_dir '\Processing'];

for ii=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',ii));
    if isempty(stdy) == 0,
        stu_sub = [stdy '-' sub];
    else
        stu_sub = sub;
    end
    subO15 = [proc_dir '\' sub];
    subPET = eval(sprintf('sub_%d_PET',ii));
    
    [pathstr, name, ext] = fileparts(subPET);
    
    spm_ext = ext;
    
    sub_proc = [proc '\' stu_sub];
    sub_PET = [sub_proc '\PET\'];
    mkdir(sub_PET);
    
    stringext = strfind(ext,'.img');
    if isempty(stringext)
        ext = ('.nii');
        PET_start = [pathstr '\' name ext];
        PET_end = [sub_PET '\' name ext];
        copyfile(PET_start,PET_end,'f');
    else
        ext = ('.img');
        hdr = ('.hdr');
        PET_start = [pathstr '\' name ext];
        PET_end = [sub_PET '\' name ext];
        copyfile(PET_start,PET_end,'f');
        hdr_start = [pathstr '\' name hdr];
        hdr_end = [sub_PET '\' name hdr];
        copyfile(hdr_start,hdr_end,'f');
    end

    copyfile(subO15,sub_proc);
    eval(sprintf('sub_%d_proc = sub_proc;',ii));
end

%% Coregister O-15 to Summed of 16 frames Dynamic PET
for ii=1:1:str2double(subnum);
    load spa_coreg;
    sub = eval(sprintf('sub_%d',ii));
    if isempty(stdy) == 0,
        stu_sub = [stdy '-' sub];
    else
        stu_sub = sub;
    end
    sub_proc = eval(sprintf('sub_%d_proc',ii));
    subPET = eval(sprintf('sub_%d_PET',ii));
    
    [~, name, ext] = fileparts(subPET);
    
    ref = [sub_proc '\PET\' name ext];
    
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {ref};
    
    sourcecheck = dir([sub_proc, '\*1fr_fr001.img']);
    if size(sourcecheck,1) == 0,
        % Create FU batch file
        matlabbatchfu = matlabbatch;
        
        % Find Baseline O-15 Source File Name
        blsourcecheck = dir([sub_proc, '\BL\*1fr_fr001.img']);
        
        % Load Baseline O-15 Source File 
        blsource = {[sub_proc '\BL\' blsourcecheck.name ',1']};
        matlabbatch{1}.spm.spatial.coreg.estwrite.source = blsource;
        
        % Get Baseline O-15 files names
        blotherdir = dir([sub_proc, '\BL\*.img']);
        blother = {blotherdir.name};
        blother = str2mat(blother);

        % Remove the source O-15 file from the list of O-15 name files
        for jj = 1:1:size(blother,1)
            blsourcename = findstr(char(blsourcecheck.name),blother(jj,:));
            if blsourcename == 1,
                blother(jj,:) = [];
                break
            end
        end
        
        % Preallocate cell array
        blother_array = cell(size(blother,1),1);
        
        % create other images cell array
        for jj = 1:1:size(blother,1)
            blother_array(jj,1) = {[sub_proc '\BL\' deblank(blother(jj,:)) ',1']};
        end;
        
        % ensure other images cell array isn't empty
        if size(blother,1) == 0,
            blother_array = {''};
        end
        
        % load other images cell array
        matlabbatch{1}.spm.spatial.coreg.estwrite.other = blother_array;
        
        % run batch file
        spm_jobman('run', matlabbatch);
        
        clear('matlabbatch');
        clear blother_array blother blsourcename blotherdir blsourcecheck
        
        matlabbatch = matlabbatchfu;
        % Find Follow-up O-15 Source File Name
        fusourcecheck = dir([sub_proc, '\FU\*1fr_fr001.img']);
        
        % Load Follow-up O-15 Source File 
        fusource = {[sub_proc '\FU\' fusourcecheck.name ',1']};
        matlabbatch{1}.spm.spatial.coreg.estwrite.source = fusource;
        
        % Get Follow-up O-15 files names
        fuotherdir = dir([sub_proc, '\FU\*.img']);
        fuother = {fuotherdir.name};
        fuother = str2mat(fuother);
        
        % Remove the source O-15 file from the list of O-15 name files
        for jj = 1:1:size(fuother,1)
            fusourcename = findstr(char(fusourcecheck.name),fuother(jj,:));
            if fusourcename == 1,
                fuother(jj,:) = [];
                break
            end
        end
        
        % Preallocate cell array
        fuother_array = cell(size(fuother,1),1);
        
        % create other images cell array
        for jj = 1:1:size(fuother,1)
            fuother_array(jj,1) = {[sub_proc '\FU\' deblank(fuother(jj,:)) ',1']};
        end;
        
        % ensure other images cell array isn't empty
        if size(fuother,1) == 0,
            fuother_array = {''};
        end
        
        % load other images cell array
        matlabbatch{1}.spm.spatial.coreg.estwrite.other = fuother_array;
        
        % run batch file
        spm_jobman('run', matlabbatch);
        
        clear('matlabbatchfu'); 
        clear fuother fuother_array fusourcename fuotherdir fusource fusourcecheck
    else
        % Load O-15 Source File
        source = {[sub_proc '\' sourcecheck.name ',1']};
        matlabbatch{1}.spm.spatial.coreg.estwrite.source = source;
        
        % Get O-15 files names
        otherdir = dir([sub_proc, '\*.img']);
        other = {otherdir.name};
        other = str2mat(other);
        
        % Remove the source O-15 file from the list of O-15 name files
        for jj = 1:1:size(other,1)
            sourcename = findstr(char(sourcecheck.name),other(jj,:));
            if sourcename == 1,
                other(jj,:) = [];
                break
            end
        end
        
        % Preallocate cell array
        other_array = cell(size(other,1),1);
        
        % create other images cell array
        for jj = 1:1:size(other,1)
            other_array(jj,1) = {[sub_proc '\' deblank(other(jj,:)) ',1']};
        end;
        
        % ensure other images cell array isn't empty
        if size(other,1) == 0,
            other_array = {''};
        end
        
        % load other images cell array
        matlabbatch{1}.spm.spatial.coreg.estwrite.other = other_array;
        
        % run batch file
        spm_jobman('run', matlabbatch);
        clear other_array source otherdir other sourcename
    end
    clear sourcecheck
    clear('matlabbatch');
end

close all;
clear,clc;
disp('DONE!');


end