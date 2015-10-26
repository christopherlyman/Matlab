function vwi_generate_cerebTAC(sub,study)
%
%        Voxel-Wise Institute
%        TAC module for cerebellar gray matter VOIs
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Yun Zhou, Clifford Workman & Christopher H. Lyman
%
%        Usage: generate_cerebTAC(sub,study)
%
%        sub: subject number
%        study: study name
%
%        This module generates time activity curves for dynamic PET scans
%        using a cerebellar gray matter VOI. The TACs will be outputted to
%        the subdirectory "CerGM_VOI" within a given processing directory.
%
%        This module is meant to be used with VWI.
%
%% Declare required variables, if not already declared
if exist('sub','var') == 0,
    Study_Sub;
    waitfor(Study_Sub);
    sub = evalin('base','sub');
    study = evalin('base','study');
end

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

for jj=1:1, %jj=1:str2double(mr_num),
    if str2double(mr_num)>1
        mrtype = sprintf('%s%s%d', mr_name, '_', jj);
    else
        mrtype = mr_name;
    end
    mr_dir = [sub_dir '\' mrtype '\']; % Declare processing directories
    
    %% Prepare for creating TACs
    % Create an output directory for TACs
    if exist([study_dir '\Dynamic\!CerGM_TACs\' sub '\'],'dir') == 0
        mkdir([study_dir '\Dynamic\!CerGM_TACs\' sub '\']);
        outdir = [study_dir '\Dynamic\!CerGM_TACs\' sub '\'];
    else
        outdir = [study_dir '\Dynamic\!CerGM_TACs\' sub '\'];
    end
    
    % Reslice VOI into native space, if needed
    if exist([mr_dir 'CerGM_VOI\' sub '_MR_CerGM.img'],'file'),
        voi2use = [sub '_MR_CerGM.img'];
    elseif exist([mr_dir 'CerGM_VOI\' sub '_MR_CerGM.nii'],'file'),
        voi2use = [sub '_MR_CerGM.nii'];
    end
    raw_voi = spm_vol(deblank([mr_dir 'CerGM_VOI\' voi2use]));
    new_space = spm_vol(deblank([mr_dir 'VWI_VOIs_MRes\' sub '_Non-GM-Mask.nii']));
    if strcmp(num2str(raw_voi.mat),num2str(new_space.mat)) == 0,
        src_ref = {[mr_dir 'r' sub '_MR-' mrtype '.nii'];[mr_dir 'CerGM_VOI\' voi2use]};
        spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
    else copyfile([mr_dir 'CerGM_VOI\' voi2use],[mr_dir 'CerGM_VOI\r' voi2use]);
    end
    current_vols = str2mat([mr_dir 'CerGM_VOI\r' voi2use ',1'],...
        [mr_dir 'VWI_VOIs_MRes\' sub '_Non-GM-Mask.nii,1']);
    vo_name = [mr_dir 'CerGM_VOI\r' sub '_MR_CerGM_SegMask.img,1'];
    exp = '(i1 - i2)>.99';
    spm_imcalc_ui(current_vols,vo_name,exp);
    
    cergm_voi = str2mat([mr_dir 'CerGM_VOI\r' sub '_MR_CerGM_SegMask.img']); % Stores cerebellar gray matter VOI
    read_voi = spm_vol(deblank(cergm_voi));
    thresh_voi = (spm_read_vols(read_voi)>0.5);
    nvox = sum(sum(sum(thresh_voi)));
    
    
    for ii=1:size(pet_names,1),
        Tracer_name = pet_names{ii,1};
        for zz=1:str2double(pet_num{ii,1});
            if str2double(pet_num{ii,1}) > 1,
                pet_name = sprintf('%s%s%d', Tracer_name, '_', zz);
                pet_dir = [sub_dir '\' pet_name '\'];
            else
                pet_name = Tracer_name;
                pet_dir = [sub_dir '\' pet_name '\'];
            end
            
            tracer_frames = dir([pet_dir, 'r*']); % Create array of SPM-ready img files
            tracer_frames = {tracer_frames(~[tracer_frames.isdir]).name};
            tracer_frames = regexprep(tracer_frames, '.img', '.img,1');
            tracer_frames = regexprep(tracer_frames, '(.*).hdr', '');
            tracer_frames = deblank(str2mat(tracer_frames(~cellfun('isempty', tracer_frames))));
            
            [pathstr] = fileparts(which('vwi'));
            FileName = [Tracer_name '.xlsx'];
            PathName = [pathstr '\Tracers\protocols\'];
            [~,~,raw]=xlsread([PathName FileName],'protocol');
            Protocolsize = size(raw,1)-1;
            if size(tracer_frames,1) == Protocolsize,
                disp('Found appropriate tracer protocol');
            else
                disp('No tracer protocol found');
%                 prot_err = questdlg(['Unexpected number of frames in ' pet_name ' directory.'], ...
%                     'VWI', 'Select alternate protocol file', 'Abort', 'Abort');
%                 switch prot_err
%                     case 'Select alternate protocol file'
%                         [FileName,PathName] = uigetfile([pathstr '\Tracers\protocols\*.xlsx'],'Select protocol file for fxf realignment.');
%                         if FileName == 0,
%                             disp('No protocol file specified. Terminating.');
%                             return
%                         end
%                         [~,~,raw]=xlsread([PathName FileName],'protocol');
%                     case 'Abort'
%                         disp('Unexpected number of frames for fxf realignment. Terminating.');
%                         return
%                 end
            end
            
            current_pet_dir = pet_dir;
            tracer = ['_' pet_name '_']; tracer_err = pet_name; [mpro,dur,tm,wt,num_frames,tac] = set_mpro(pathstr,current_pet_dir,sub,tracer_err);
            if isempty(mpro), disp('No protocol file specified. Terminating.'); return; end
            disp(['Generating cerebellar gray matter TAC for subject ' sub '''s ' pet_name ' scan.']);
            
            
            list_frames = dir([pet_dir 'r*.img']);
            tracer_frames = [];
            for kk=1:num_frames
                frame_names = list_frames(kk).name;
                if isempty(tracer_frames); tracer_frames = frame_names;
                else tracer_frames = [tracer_frames;frame_names]; end
            end
            
            for kk=1:num_frames % Kinetic modeling magic
                fpet = [pet_dir deblank(tracer_frames(kk,:))];
                read_pet = spm_vol(fpet);
                conv_pet = spm_read_vols(read_pet);
                tac(kk,2)= sum(sum(sum(conv_pet.*thresh_voi)));
                clear fpet read_pet conv_pet
            end
            
            h = figure; % Generates outputs
            tac(:,2)=tac(:,2)/nvox;
            plot(tm,tac(:,2),'o');
            pout = [outdir sub tracer 'CerebTAC_Fig.tif'];
            print(h, '-dtiff', pout);
            close(h);
            fout = [outdir sub tracer 'CerebTAC.xls'];
            xlswrite(fout,tac);
        end
        clear read_voi Protocolsize
    end
    
end

%% Figure out which protocol file to use
    function [mpro,dur,tm,wt,num_frames,tac] = set_mpro(pathstr,pet_dir,sub,tracer_err)
        pdir_contents = dir([pet_dir 'r*.img']);
%         if size(strvcat({pdir_contents.name}),1) ~= 30, % Reads protocol spreadsheet
        if size(strvcat({pdir_contents.name}),1) ~= Protocolsize, % Reads protocol spreadsheet
            prot_err = questdlg(['Unexpected number of frames in ' sub '''s ' tracer_err ' processing directory. What do?'], ...
                'VWI', 'Select alternate protocol file', 'Abort', 'Abort');
            switch prot_err
                case 'Select alternate protocol file'
                    [FileName,PathName] = uigetfile([pathstr '\Tracers\protocols\alternate_protocols\*.xlsx'],'Select protocol file for generating TACs.');
                    if FileName == 0,
                        mpro = []; dur = []; tm = []; wt = []; num_frames = []; tac = [];
                        return
                    else mpro = xlsread([PathName '\' FileName]);
                    end
                case 'Abort'
                    mpro = []; dur = []; tm = []; wt = []; num_frames = []; tac = [];
                    return
            end
        else mpro = xlsread([pathstr '\Tracers\protocols\' Tracer_name '.xlsx'],'protocol'); end
        dur = mpro(:,2); % Stores values from column 2
        tm = mpro(:,4); % Stores values from column 4
        if max(dur) > 60 % Converts to minutes depending on how "dur" column is stored in spreadsheet
            dur = dur/60;
        end
        wt = diag(sqrt(dur/sum(dur))); % Stores the square roots of "given time" divided by "total time" through a diagonal matrix
        num_frames = max(size(dur));
        tac = cell2mat({tm, zeros(num_frames,1)}); % Creates "tac" array with columns "tm" by zeroes
    end
end