function vwi_coreg_seg(sub,study)
%
%        Voxel-Wise Institute: Dyanmic
%        Coregistration and Segmentation Module
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman and Cliff Workman
%
%        Usage: vwi_coreg_seg(sub,study)
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

manAC_question = questdlg('Have you manually aligned all images to the AC?', ...
    'VWI', ...
    'Yes','No','No');
% Handle response
switch manAC_question
    case 'Yes'
        manACAnswer = 1;
    case 'No'
        uiwait(msgbox('Please manually align all images to the AC before continuing.','VWI'));
        disp('Please manually align all images to the AC before continuing.')
        manACAnswer = 2;
end

if manACAnswer == 1,
    Study_Sub;
    waitfor(Study_Sub);
    if exist('sub','var'),
        sub = evalin('base','sub');
        sub{1} = sub;
    else
        sub{1} = [];
    end
    study = evalin('base','study');
    [~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
    studyprotocol = raw;
    clear raw;
    study_dir = studyprotocol{1,2};
    
    proc_dir = [study_dir '\03_Pre-Processing\'];
    manAC_dir = [study_dir '\02_Manual-AC\'];
    
    if isempty(sub{1}),
        dir_manAC = dir(manAC_dir);
        for kk = length(dir_manAC):-1:1
            % remove non-folders
            if ~dir_manAC(kk).isdir
                dir_manAC(kk) = [ ];
                continue
            end
            
            % remove folders starting with .
            fname = dir_manAC(kk).name;
            if fname(1) == '.'
                dir_manAC(kk) = [ ];
            end
        end
        for gg=1:1:size(dir_manAC,1),
            sub{gg,1} = dir_manAC(gg).name;
        end
    end
    
    for ii=1:1:size(sub,1),   
        sub_dir = [proc_dir sub{ii}];
        manAC_sub = [manAC_dir sub{ii}];
        if exist(sub_dir,'dir') == 0;
            mkdir(sub_dir);
            copyfile(manAC_sub,sub_dir,'f');
        else
            continue
        end
        
        dir_sub = dir(sub_dir);
        
        for kk = length(dir_sub):-1:1
            % remove non-folders
            if ~dir_sub(kk).isdir
                mr_name = dir_sub(kk).name;
                dir_sub(kk) = [ ];
                continue
            end
            
            % remove folders starting with .
            fname = dir_sub(kk).name;
            if fname(1) == '.'
                dir_sub(kk) = [ ];
            end
        end
        
        bmicount = 1;
        bsacount = 1;
        bwcount = 1;
        lbmcount = 1;
        
        for jj=1:1:size(dir_sub,1),
            dir_sub_sub = dir([sub_dir '\' dir_sub(jj).name]);
            for kk = length(dir_sub_sub):-1:1
                % remove folders starting with .
                fname = dir_sub_sub(kk).name;
                if fname(1) == '.'
                    dir_sub_sub(kk) = [ ];
                end
            end
            
            for zz=1:1:size(dir_sub_sub,1),
                BMI = strfind(dir_sub_sub(zz).name,'SUV-BMI');
                BSA = strfind(dir_sub_sub(zz).name,'SUV-BSA');
                BW = strfind(dir_sub_sub(zz).name,'SUV-BW');
                LBM = strfind(dir_sub_sub(zz).name,'SUV-LBM');
                
                if isempty(BMI) == 0,
                    BMIlist{bmicount,1} = [sub_dir '\' dir_sub(jj).name '\' dir_sub_sub(zz).name];
                    bmicount = bmicount+1;
                elseif isempty(BSA) == 0
                    BSAlist{bsacount,1} = [sub_dir '\' dir_sub(jj).name '\' dir_sub_sub(zz).name];
                    bsacount = bsacount+1;
                elseif isempty(BW) == 0
                    BWlist{bwcount,1} = [sub_dir '\' dir_sub(jj).name '\' dir_sub_sub(zz).name];
                    bwcount = bwcount+1;
                elseif isempty(LBM) == 0
                    LBMlist{lbmcount,1} = [sub_dir '\' dir_sub(jj).name '\' dir_sub_sub(zz).name];                
                    lbmcount = lbmcount+1;
                end
            end
        end
        
        flags.quality=0.9000;
        flagsC.fwhm=5;
        flagsC.sep=4;
        flagsC.rtm=1;
        flagsC.interp=1;
        
        if exist('BMIlist','var'),
            BMIrealign = spm_realign(BMIlist,flags);
        end
        if exist('BSAlist','var'),
            BSArealign = spm_realign(BSAlist,flags);
        end
        if exist('BWlist','var'),
            BWrealign = spm_realign(BWlist,flags);
        end
        if exist('LBMlist','var'),
            LBMrealign = spm_realign(LBMlist,flags);
        end
        
    end
end
        
        
        
    
    if exist(suv_dir,'dir') == 7;
        data_dir = [study_dir '\SUV\' sub];
    else
        data_dir = uigetdir(study_dir, 'Please select directory containing the data..');
    end
    
    text_test = dir([data_dir, '\' sub '_Scans.txt']);
    if isempty(text_test) == 0,
        textfile = [suv_dir '\' sub '_Scans.txt'];
        fid = fopen(textfile);
        scans_cell = textscan(fid,'%s%s','Whitespace','\t');
        fclose(fid);
        scan_names = scans_cell{1};
        scan_num = scans_cell{2};
        sizeprotocol = size(scans_cell,1)/2;
        ref_list = cell(sum(str2double(scan_num{:})),1);
    end
    
    for ii=1:size(scan_names,1),
        Tracer_name = scan_names{ii,1};
        for jj=1:str2double(scan_num{ii,1});
            if scan_num{ii,1} > 1,
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
    
    ref_list{size(ref_list,1)+1,1} = 'Mean';
    
    % Declare required variables, reslice cerebellar GM VOI to resliced MPRAGE
    mri_pdir = [sub_dir '\MRI\']; % Declare processing directories
    
    %% Prompt to select Reference Image or use mean
    [Selection,ok] = listdlg('PromptString','Select Reference Image:',...
        'SelectionMode','single','ListSize',[160 300],'Name','Pre-Processing','ListString',ref_list);
    while isempty(Selection)
        uiwait(msgbox('Error: You must select a Reference Image.','Error message','error'));
        [Selection,ok] = listdlg('PromptString','Select Reference Image:',...
            'SelectionMode','single','ListSize',[160 300],'Name','Pre-Processing','ListString',ref_list);
    end
    
    if strcmp(ref_list{Selection,1},'Mean');
        ref_name = 'Mean';
    else
        ref_dir = [sub_dir '\' ref_list{Selection,1}];
        ref_name = ref_list{Selection,1};
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
        msg2 = ('''s Reference file:');
        msg = sprintf('%s%s%s', msg1,sub,msg2);
        ref_file = spm_select(1:1,'image', msg ,[],sub_dir,'.(nii|img)$');
        clear msg msg1 msg2
    end
    
    for ii=1:size(scan_names,1),
        Tracer_name = scan_names{ii,1};
        for jj=1:str2double(scan_num{ii,1});
            if scan_num{ii,1} > 1,
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
                    msg2 = ('''s Source file:');
                    msg = sprintf('%s%s%s', msg1,sub,msg2);
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
    MR_dir = dir(mri_pdir);
    [~, ~, ext] = fileparts(MR_dir(3).name);
    if strcmp(ext,'.nii') == 1,
        MRext = '.nii';
    else
        MRext = '.img';
        MRhdr = '.hdr';
    end
    
    % if isempty(ref_dir) == 0, %%%%%% MAY WANT TO FIX for new way
    ref_vol = ref_file;
    % elseif isempty(ref_dir) && isempty(pet_dir) == 0,
    %     ref_vol = sour_ref;
    % end
    
    src_vol = [mri_pdir sub '_MR_T1' MRext];
    x = spm_coreg(ref_vol,src_vol,...
        struct('cost_fun','nmi'));
    spm_get_space(src_vol,spm_matrix(x)\spm_get_space(src_vol));
    src_ref = {ref_vol;src_vol};
    spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
    
    %%%% ADD VBM8 Segment %%%%%%
    
    if exist([mri_pdir 'Segment\'],'dir') == 0; mkdir([mri_pdir 'Segment\']); end % Segment coregistered MRI
    copyfile([mri_pdir sub '_MR_T1' MRext],[mri_pdir 'Segment\' sub '_MR_T1' MRext]);
    spm_jobman('initcfg');
    [pth,nam,ext] = spm_fileparts([mri_pdir 'Segment\' sub '_MR_T1' MRext]);
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
    
    if exist([mri_pdir 'CerGM_VOI\']) == 0; % Create directory to store cerebellar GM VOI
        disp('Creating directory to store cerebellar gray matter VOI.');
        mkdir([mri_pdir 'CerGM_VOI\']);
    end
    
    %% Generate VWI VOIs
    clearvars -except sub study;
    vwi_vois_mres(sub,study);
end

end