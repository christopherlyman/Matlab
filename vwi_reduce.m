function spa_reduce()
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


%% Prompt to select O-15 scans
for ii=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',ii));
    if isempty(stdy) == 0,
        stu_sub = [stdy '-' sub];
    else
        stu_sub = sub;
    end
    msg1 = ('Please select the O-15 folder');
    msg2 = (' for ');
    msg = sprintf('%s%s%s', msg1,msg2,stu_sub);
    uiwait(msgbox(msg,'SPA'));
    subO15 = uigetdir(proc_dir,msg);
    eval(sprintf('sub_%d_O15 = subO15;',ii));
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
    subO15 = eval(sprintf('sub_%d_O15',ii));
    sub_proc = [proc '\' sub];
    mkdir(sub_proc);
    copyfile(subO15,sub_proc);
    eval(sprintf('sub_%d_proc = sub_proc;',ii));
end

%% Reduce frames to 150 axial slices and convert from Bq to nCi
affine_pars = [-1.2188         0         0          160.0000
    0              1.2188    0           -195.0000
    0              0         1.2188      -50.0000
    0              0         0           1.0000];

%% Coregister O-15 to Summed of 16 frames Dynamic PET
for ii=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',ii));
    if isempty(stdy) == 0,
        stu_sub = [stdy '-' sub];
    else
        stu_sub = sub;
    end
    sub_proc = eval(sprintf('sub_%d_proc',ii));
    
    
    sourcecheck = dir([sub_proc, '\*1fr_fr001.img']);
    if size(sourcecheck,1) == 0,
     
        % Get Baseline O-15 files names
        blotherdir = dir([sub_proc, '\BL\*.img']);
        blother = {blotherdir.name};
        blother = str2mat(blother);
        
        % Preallocate cell array
        blimgs_in = cell(size(blother,1),1);
        blimgs_out = cell(size(blother,1),1);
        
        % define input and output cell array
        for jj = 1:1:size(blother,1)
            blimgs_in(jj,1) = {[sub_proc '\BL\' deblank(blother(jj,:))]};
            blimgs_out(jj,1) = {[sub_proc '\BL\' deblank(blother(jj,:))]};
        end;
        
        % clean-up cell array
        blimgs_in = deblank(str2mat(blimgs_in(~cellfun('isempty', blimgs_in))));
        blimgs_out = deblank(str2mat(blimgs_out(~cellfun('isempty', blimgs_out))));
        
        % Reduce frames and convert units
        for kk=1:size(blother,1)
            read_pet = spm_vol(deblank(blimgs_in(kk,:)));
            conv_pet = (1/(37))*(spm_read_vols(read_pet));
            conv_pet = conv_pet(:,:,1:150);
            read_pet.mat = affine_pars;
            read_pet.dim(1,1:3) = [256 256 150];
            read_pet.fname = blimgs_out(kk,:);
            spm_write_vol(read_pet,conv_pet);
        end
        clear blimgs_in blimgs_out blotherdir blother
        
        % Get Follow-up O-15 files names
        fuotherdir = dir([sub_proc, '\FU\*.img']);
        fuother = {fuotherdir.name};
        fuother = str2mat(fuother);
        
        % Preallocate cell array
        fuimgs_in = cell(size(fuother,1),1);
        fuimgs_out = cell(size(fuother,1),1);
        
        % define input and output cell array
        for jj = 1:1:size(fuother,1)
            fuimgs_in(jj,1) = {[sub_proc '\FU\' deblank(fuother(jj,:))]};
            fuimgs_out(jj,1) = {[sub_proc '\FU\' deblank(fuother(jj,:))]};
        end;
        
        % clean-up cell array
        fuimgs_in = deblank(str2mat(fuimgs_in(~cellfun('isempty', fuimgs_in))));
        fuimgs_out = deblank(str2mat(fuimgs_out(~cellfun('isempty', fuimgs_out))));
        
        % Reduce frames and convert units
        for kk=1:size(fuother,1)
            read_pet = spm_vol(deblank(fuimgs_in(kk,:)));
            conv_pet = (1/(37))*(spm_read_vols(read_pet));
            conv_pet = conv_pet(:,:,1:150);
            read_pet.mat = affine_pars;
            read_pet.dim(1,1:3) = [256 256 150];
            read_pet.fname = fuimgs_out(kk,:);
            spm_write_vol(read_pet,conv_pet);
        end
        clear fuotherdir fuother fuimgs_in fuimgs_out
    else
        
        % Get O-15 files names
        otherdir = dir([sub_proc, '\*.img']);
        other = {otherdir.name};
        other = str2mat(other);
        
        % Preallocate cell array
        imgs_in = cell(size(other,1),1);
        imgs_out = cell(size(other,1),1);
        
        % define input and output cell array
        for jj = 1:1:size(other,1)
            imgs_in(jj,1) = {[sub_proc '\' deblank(other(jj,:))]};
            imgs_out(jj,1) = {[sub_proc '\' deblank(other(jj,:))]};
        end;
        
        % clean-up cell array
        imgs_in = deblank(str2mat(imgs_in(~cellfun('isempty', imgs_in))));
        imgs_out = deblank(str2mat(imgs_out(~cellfun('isempty', imgs_out))));
        
        % Reduce frames and convert units
        for kk=1:size(other,1),
            read_pet = spm_vol(deblank(imgs_in(kk,:)));
            conv_pet = (1/(37))*(spm_read_vols(read_pet));
            conv_pet = conv_pet(:,:,1:150);
            read_pet.mat = affine_pars;
            read_pet.dim(1,1:3) = [256 256 150];
            read_pet.fname = imgs_out(kk,:);
            spm_write_vol(read_pet,conv_pet);
        end
        
        clear imgs_in imgs_out other otherdir
    end

end

close all;
clear,clc;
disp('DONE!');


end