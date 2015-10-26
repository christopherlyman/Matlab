function dyn_coreg_seg(sub,study)
%
%        Voxel-Wise Institute: Dyanmic
%        Coregistration and Segmentation Module
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman and Cliff Workman
%
%        Usage: dyn_coreg_seg(sub,study)
%
%        sub: subject number e.g.) '01-001'
%        study: study name e.g.) 'FNMI'
%
%        This module coregisters the MRI and source PET images to the
%        refrence PET scan. The reference images used for coregistration
%        are the summed image frames 1-30 for DASBs and summed image
%        frames 1-16 for PIB. If the DASB reference is missing, this
%        software will pick the last summed image available.
%        If the PIB reference is missing, it will pick the image closest
%        to and greater than summed image frames 1-16 (for example, summed
%        image frames 1-17). After coregistration, the MRI is segmented
%        into gray matter, white matter, and CSF, and normalization
%        parameters to MNI space are derived.
%
%        This function also implicitly calls "vwi_vois_mres." Type
%        "help vwi_vois_mres" in the MATLAB command window for more information.
%
%        This module is meant to be used with VWI.

%% Declare required variables, if not already declared
if exist('sub','var') == 0,
    Study_Sub;
    waitfor(Study_Sub);
    sub = evalin('base','sub');
    study = evalin('base','study');
end

%% Identify tracer and frames
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

[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;
study_dir = studyprotocol{1,2};
sub_dir = [study_dir '\Dynamic\' sub];

textfile = [sub_dir '\' sub '_MR-Scans.txt'];
fid = fopen(textfile);
mri_scans = textscan(fid,'%s%s','Whitespace','\t');
fclose(fid);
mr_name = cell2mat(mri_scans{1});
mr_num = cell2mat(mri_scans{2});


textfile = [sub_dir '\' sub '_PET-Scans.txt'];
fid = fopen(textfile);
pet_scans = textscan(fid,'%s%s','Whitespace','\t');
fclose(fid);
pet_names = pet_scans{1};
pet_num = pet_scans{2};
sizepet_num = size(pet_num,1);
petscannum = str2double('0');
for ii=1:sizepet_num
    petscannum = petscannum+str2double(pet_num{ii,1});
end
ref_list = cell(petscannum+1,1);

for ii=1:size(pet_names,1),
    Tracer_name = pet_names{ii,1};
    for jj=1:str2double(pet_num{ii,1});
        if str2double(pet_num{ii,1}) > 1,
            pet_name = sprintf('%s%s%d', Tracer_name, '_', jj);
            A = cellfun('isempty', ref_list);
            for zz=1:size(A,1),
                if A(zz,1) == 1,
                    ref_list{zz,1} = pet_name;
                    break
                end
            end
        else
            pet_name = Tracer_name;
            A = cellfun('isempty', ref_list);
            for zz=1:size(A,1),
                if A(zz,1) == 1,
                    ref_list{zz,1} = pet_name;
                    break
                end
            end
        end
    end
end
clear A

ref_list{size(ref_list,1),1} = 'Mean';

% Declare required variables

%% Prompt to select Reference Image or use mean
[Selection,ok] = listdlg('PromptString','Select Reference Image:',...
    'SelectionMode','single','ListSize',[160 300],'Name','Dynamic','ListString',ref_list);
while isempty(Selection)
    uiwait(msgbox('Error: You must select a Reference Image.','Error message','error'));
    [Selection,ok] = listdlg('PromptString','Select Reference Image:',...
        'SelectionMode','single','ListSize',[160 300],'Name','Dynamic','ListString',ref_list);
end

if strcmp(ref_list{Selection,1},'Mean');
    ref_name = 'Mean';
else
    ref_dir = [sub_dir '\' ref_list{Selection,1}];
    ref_name = ref_list{Selection,1};
end

segment_question = questdlg('Which segmentation method would you like to use?', ...
    'VWI', ...
    'SPM Segment','VBM8 Segment','SPM Segment');
% Handle response
switch segment_question
    case 'SPM Segment'
        Answer = 1;
    case 'VBM8 Segment'
        Answer = 2;
end


%% Desginate reference images
if strfind(ref_list{Selection,1},'DASB') == 1,
    if isempty(ref_dir) == 0, % First, Reference images
        ref_frames = dir([ref_dir '\Summed\*.img']);
        ref_frames = flipdim(strvcat({ref_frames.name}),1);
        ref_file = [ref_dir '\Summed\' ref_frames(1,:)];
    end; clear ref_frames;
elseif strfind(ref_list{Selection,1},'PIB') == 1,
    if isempty(ref_dir) == 0, % Second, Source images
        ref_frames = dir([ref_dir '\Summed\*.img']);
        ref_frames = strvcat({ref_frames.name});
        for ii=1:size(ref_frames,1),
            current_frame = deblank(ref_frames(ii,:));
            ref_nums{ii,1} = str2num(current_frame(end-6:end-4));
            ref_nums{ii,1} = cell2mat(ref_nums(ii,1))-16;
            ref_nums{ii,2} = current_frame;
        end
        for ii=1:size(ref_frames,1),
            if cell2mat(ref_nums((size(ref_frames,1)+1-ii),1))<0,
                ref_nums((size(ref_frames,1)+1-ii),:) = [];
            end
        end
        ref_file = [ref_dir '\Summed\' cell2mat(ref_nums(1,2))];
        clear ref_nums current_frame ref_frames
    end
else
    msg1 = ('Please select ');
    msg2 = ('''s Reference file for ');
    msg3 = (':');
    msg = sprintf('%s%s%s', msg1,sub,msg2,ref_name,msg3);
    ref_file = spm_select(1:1,'image', msg ,[],sub_dir,'.(nii|img)$');
    clear msg msg1 msg2
end

for ii=1:size(pet_names,1),
    Tracer_name = pet_names{ii,1};
    for jj=1:str2double(pet_num{ii,1});
        if str2double(pet_num{ii,1}) > 1,
            pet_name = sprintf('%s%s%d', Tracer_name, '_', jj);
            pet_dir = [sub_dir '\' pet_name '\'];
        else
            pet_name = Tracer_name;
            pet_dir = [sub_dir '\' pet_name '\'];
        end
        
        %% Coregister Source to Refrence
        if strcmp(pet_name,ref_name) == 0,
            if strfind(Tracer_name,'DASB') == 1,
                if isempty(pet_dir) == 0, % First, Reference images
                    sour_frames = dir([pet_dir 'Summed\*.img']);
                    sour_frames = flipdim(strvcat({sour_frames.name}),1);
                    sour_file = [pet_dir 'Summed\' sour_frames(1,:)];
                end; clear sour_frames;
            elseif strfind(Tracer_name,'PIB') == 1,
                if isempty(pet_dir) == 0, % Second, Source images
                    sour_frames = dir([pet_dir 'Summed\*.img']);
                    sour_frames = strvcat({sour_frames.name});
                    for zz=1:size(sour_frames,1),
                        current_frame = deblank(sour_frames(zz,:));
                        sour_nums{zz,1} = str2num(current_frame(end-6:end-4));
                        sour_nums{zz,1} = cell2mat(sour_nums(zz,1))-16;
                        sour_nums{zz,2} = current_frame;
                    end
                    for zz=1:size(sour_frames,1),
                        if cell2mat(sour_nums((size(sour_frames,1)+1-zz),1))<0,
                            sour_nums((size(sour_frames,1)+1-zz),:) = [];
                        end
                    end
                    sour_file = [pet_dir 'Summed\' cell2mat(sour_nums(1,2))];
                    clear sour_frames sour_nums current_frame
                end
            else
                msg1 = ('Please select ');
                msg2 = ('''s Source file for ');
                msg3 = (':');
                msg = sprintf('%s%s%s', msg1,sub,msg2,pet_name,msg3);
                sour_file = spm_select(1:1,'image', msg ,[],sub_dir,'.(nii|img)$');
                clear msg msg1 msg2
            end
            
            if isempty(ref_dir) == 0 && isempty(pet_dir) == 0,
                if exist([pet_dir 'FxF_Resliced\'],'dir') == 0;
                    disp('Creating directory to store resliced fxf realigned frames.');
                    mkdir([pet_dir 'FxF_Resliced\']);
                end
                movefile([pet_dir 'r*.*'],[pet_dir 'FxF_Resliced\'],'f');
                
                ref_vol = ref_file;
                src_vol = sour_file;
                x = spm_coreg(ref_vol,src_vol,...
                    struct('cost_fun','nmi'));
                
                sour_img = dir([pet_dir '*.img']); % Coregister frames (resliced and not)
                nsour_img = size(sour_img,1);
                for zz=1:nsour_img
                    other_vol = [pet_dir sour_img(zz).name];
                    spm_get_space(other_vol,spm_matrix(x)\spm_get_space(other_vol));
                    src_other = {ref_vol;other_vol};
                    spm_reslice(src_other, struct('mean',0,'interp',1,'which',1));
                end
                clear sour_img nsour_img other_vol
                
                sour_img = dir([pet_dir 'Summed\*.img']); %Coregister summed images
                nsour_img = size(sour_img,1);
                for j=1:nsour_img
                    other_vol = [pet_dir '\Summed\' sour_img(j).name];
                    spm_get_space(other_vol,spm_matrix(x)\spm_get_space(other_vol));
                end
                clear sour_img nsour_img other_vol x
            end
            
        end
    end
end

%% Coregister MRI to Reference image, segment
% for jj=1:str2double(mr_num),
if str2double(mr_num)>1
    mrlist = cell(str2double(mr_num),1);
    for ii=1:1:str2double(mr_num),
        mrtypelist = sprintf('%s%s%d',mr_name, '_',ii);
        mri_pdirlist = [sub_dir '\' mrtypelist]; % Declare processing directories
        MR_dir = dir(mri_pdirlist);
        MR_dir = dir(mri_pdirlist);
        [MRpath,MRname, ext] = fileparts(MR_dir(3).name);
        
        if strcmp(ext,'.nii') == 1,
            MRext = '.nii';
        else
            MRext = '.img';
            MRhdr = '.hdr';
        end
        
        if ii==1,
            mrlist{ii,1}= [mri_pdirlist '\r' MRname ext ',1'];
            MRsource = [MRname ext];
        else
            mrlist{ii,1}= [mri_pdirlist '\' MRname ext ',1'];
        end
        if ii==1,
            mrtype = mrtypelist;
            mri_pdir = mri_pdirlist;
        end
    end
    
    if isempty(ref_dir) == 0, %%%%%% MAY WANT TO FIX for new way
        ref_vol = ref_file;
    elseif isempty(ref_dir) && isempty(pet_dir) == 0,
        ref_vol = sour_ref;
    end
    
    src_vol = [mri_pdir '\' MRsource];
    x = spm_coreg(ref_vol,src_vol,...
        struct('cost_fun','nmi'));
    spm_get_space(src_vol,spm_matrix(x)\spm_get_space(src_vol));
    src_ref = {ref_vol;src_vol};
    spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
    
    spm_jobman('initcfg');
    load vwi_realign;
    matlabbatch{1}.spm.spatial.realign.estwrite.data = {mrlist};
    spm_jobman('run', matlabbatch);
    clear('matlabbatch');
    

else
    mrtype = mr_name;
    mri_pdir = [sub_dir '\' mrtype]; % Declare processing directories
    MR_dir = dir(mri_pdir);
    [~, ~, ext] = fileparts(MR_dir(3).name);
    if strcmp(ext,'.nii') == 1,
        MRext = '.nii';
    else
        MRext = '.img';
        MRhdr = '.hdr';
    end
    
        if isempty(ref_dir) == 0, %%%%%% MAY WANT TO FIX for new way
        ref_vol = ref_file;
    elseif isempty(ref_dir) && isempty(pet_dir) == 0,
        ref_vol = sour_ref;
    end
    
    src_vol = [mri_pdir '\' sub '_MR-' mrtype MRext];
    x = spm_coreg(ref_vol,src_vol,...
        struct('cost_fun','nmi'));
    spm_get_space(src_vol,spm_matrix(x)\spm_get_space(src_vol));
    src_ref = {ref_vol;src_vol};
    spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
    
end

if exist([mri_pdir '\Segment\'],'dir') == 0; 
    mkdir([mri_pdir '\Segment\']); 
end % Segment coregistered MRI
copyfile([mri_pdir '\r' sub '_MR-' mrtype MRext],[mri_pdir '\Segment\r' sub '_MR-' mrtype MRext]);

%% SPM Segment
if Answer == 1,
    spm_jobman('initcfg');
    [pth,nam,ext] = spm_fileparts([mri_pdir '\Segment\r' sub '_MR-' mrtype MRext]);
    matlabbatch{1}.spm.spatial.preproc.data = {[pth '\' nam ext]};
    matlabbatch{1}.spm.spatial.preproc.output.GM = [0 0 1];
    matlabbatch{1}.spm.spatial.preproc.output.WM = [0 0 1];
    matlabbatch{1}.spm.spatial.preproc.output.CSF = [0 0 1];
    matlabbatch{1}.spm.spatial.preproc.output.biascor = 0;
    matlabbatch{1}.spm.spatial.preproc.output.cleanup = 1;
    matlabbatch{1}.spm.spatial.preproc.opts.tpm = {[spm('Dir') '\tpm\grey.nii'] [spm('Dir') '\tpm\white.nii'] [spm('Dir') '\tpm\csf.nii']};
    matlabbatch{1}.spm.spatial.preproc.opts.ngaus = [2 2 2 4];
    matlabbatch{1}.spm.spatial.preproc.opts.regtype = 'mni';
    matlabbatch{1}.spm.spatial.preproc.opts.warpreg = 1;
    matlabbatch{1}.spm.spatial.preproc.opts.warpco = 25;
    matlabbatch{1}.spm.spatial.preproc.opts.biasreg = 0.0001;
    matlabbatch{1}.spm.spatial.preproc.opts.biasfwhm = 60;
    matlabbatch{1}.spm.spatial.preproc.opts.samp = 3;
    matlabbatch{1}.spm.spatial.preproc.opts.msk = {''};
    spm_jobman('run', matlabbatch);
    clear('matlabbatch');
    
    %% VBM8 Segment
else
    load VBM8_segment
    spm_jobman('initcfg');
    [pth,nam,ext] = spm_fileparts([mri_pdir '\Segment\r' sub '_MR-' mrtype MRext]);
    matlabbatch{1}.spm.tools.vbm8.estwrite.data = {[pth '\' nam ext ',1']};
    spm_jobman('run', matlabbatch);
    clear('matlabbatch');
end

if exist([mri_pdir '\CerGM_VOI\'],'dir') == 0; % Create directory to store cerebellar GM VOI
    disp('Creating directory to store cerebellar gray matter VOI.');
    mkdir([mri_pdir '\CerGM_VOI\']);
end


%% Generate VWI VOIs
clearvars -except sub study Answer;
vwi_vois_mres(sub,study,Answer);
end