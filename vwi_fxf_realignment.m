function vwi_fxf_realignment(sub,study)
%
%        VWI Pipeline
%        Frame-by-Frame Realignment Module
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman & Yun Zhou
%
%        Usage: fxf_realignment(sub,pet_dir)
%
%        sub: subject number
%        pet_dir: directory where PET data is located for processing
%
%        If a PET scan has 30 frames, VWI will default to a standard
%        protocol for frame-by-frame realignment (protocol file location
%        below). If 30 frames are not present, the user will be prompted
%        to specify the location for an alternate protocol file. To make an
%        alternate protocol file, copy the existing protocol file and
%        remove rows which correspond to frames that will not be used. This
%        module is meant to be used with VWI, but may be used for motion
%        correcting other PET scans.
%
%        Location of standard protocol file:
%        ~\vwi\protocols\standard.xlsx
%        The first column is the frame number, second is the acquisition
%        time for a given frame, this is the start time post-injection for
%        a given frame, and the fourth column is the mid-time for a given
%        frame.
%
%        Example non-standard protocol file:
%        ~\vwi\protocols\1007_DASB.xlsx
%        Frames 7 through 15 were not usable for this participant's DASB
%        scan. This alternate protocol file is identical except that the
%        rows corresponding to frames 7 through 15 have been removed from
%        the spreadsheet.

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

%% Prompt for subject number and validity checks
[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;
study_dir = studyprotocol{1,2};
sub_dir = [study_dir '\Dynamic\' sub];

textfile = [sub_dir '\' sub '_PET-Scans.txt'];
fid = fopen(textfile);
pet_scans = textscan(fid,'%s%s','Whitespace','\t');
fclose(fid);
pet_names = pet_scans{1};
pet_num = pet_scans{2};

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
        
        tracer_frames = dir(pet_dir); % Create array of SPM-ready img files
        tracer_frames = {tracer_frames(~[tracer_frames.isdir]).name};
        tracer_frames = regexprep(tracer_frames, '.img', '.img,1');
        tracer_frames = regexprep(tracer_frames, '(.*).hdr', '');
        tracer_frames = deblank(str2mat(tracer_frames(~cellfun('isempty', tracer_frames))));
        
        % Read in protocol for fxf realignment
        [pathstr] = fileparts(which('vwi'));
        FileName = [Tracer_name '.xlsx'];
        PathName = [pathstr '\Tracers\protocols\'];
        [~,~,raw]=xlsread([PathName FileName],'protocol');
        Protocolsize = size(raw,1)-1;
        if size(tracer_frames,1) == Protocolsize,
            disp('Found appropriate tracer protocol');
        else
            prot_err = questdlg(['Unexpected number of frames in ' sub '''s' pet_name ' directory.'], ...
                'VWI', 'Select alternate protocol file', 'Abort', 'Abort');
            switch prot_err
                case 'Select alternate protocol file'
                    [FileName,PathName] = uigetfile([pathstr '\Tracers\protocols\*.xlsx'],'Select protocol file for fxf realignment.');
                    if FileName == 0,
                        disp('No protocol file specified. Terminating.');
                        return
                    end
                    [~,~,raw]=xlsread([PathName FileName],'protocol');
                case 'Abort'
                    disp('Unexpected number of frames for fxf realignment. Terminating.');
                    return
            end
        end
        
        if (size(raw,1)-1) ~= size(tracer_frames),
            prot_err = questdlg(['Protocol does not match the number of frames. What do?'], ...
                'VWI', 'Select alternate protocol file', 'Continue', 'Abort', 'Abort');
            switch prot_err
                case 'Select alternate protocol file'
                    [FileName,PathName] = uigetfile([pathstr '\protocols\*.xlsx'],'Select protocol file for fxf realignment.');
                    if FileName == 0
                        disp('No protocol file specified. Terminating.');
                        return
                    end
                case 'Continue'
                    disp('Protocol file appears incorrect. Continuing anyway.');
                case 'Abort'
                    disp('Protocol file appears incorrect. Terminating.');
                    return
            end
            clear raw
            [~,~,raw]=xlsread([PathName FileName],'protocol');
        end
        
        %% Generate initial reference for coregistration
        exp_num = []; exp_den = [];
        if size(tracer_frames,1)>15
            for zz=1:8,
                framen = deblank(tracer_frames(zz,:));
                if exist([pet_dir framen(1:end-8) '0' num2str(zz) '.img'],'file'),
                    vols_array{zz} = [pet_dir tracer_frames(zz,:)];
                    [~,cols] = size(vols_array);
                    if isempty(exp_num),
                        exp_num = ['(i1*' num2str(cell2mat(raw(cols+1,2))) ')'];
                        exp_den = num2str(cell2mat(raw(cols+1,2)));
                    else
                        exp_num = [exp_num '+(i' num2str(zz) '*' num2str(cell2mat(raw(cols+1,2))) ')'];
                        exp_den = [exp_den '+' num2str(cell2mat(raw(cols+1,2)))];
                    end
                end
            end
            current_vols = strvcat(vols_array);
            if size(current_vols,1) < 8,
                disp(['Only ' num2str(size(current_vols,1)) ' of the first 8 frames available. Continuing with these frames.']);
            end
            exp = ['(' exp_num ')/(' exp_den ')'];
            first_vol = deblank(current_vols(1,:)); last_vol = deblank(current_vols(size(current_vols,1),:));
            vo_name = [pet_dir 'Summed\' sub '_PET_Raw-' pet_name '_frs0' first_vol(end-7:end-6) '-0' last_vol(end-7:end-6) '.img'];
            ref_vol = spm_imcalc_ui(current_vols,vo_name,exp);
            ref_vol = [ref_vol ',1'];
            nstart = size(current_vols,1)+1;
            nend = size(tracer_frames,1);
            
            %% Iteratively realign and sum frames
            for zz=nstart:nend,
                % Coregister nth frame to summed weighted frames 1 through n-1
                ref_vol = ref_vol;
                src_vol = [pet_dir tracer_frames((size(current_vols,1)+1),:)];
                x = spm_coreg(ref_vol,src_vol,...
                    struct('cost_fun','nmi'));
                spm_get_space(src_vol,spm_matrix(x)\spm_get_space(src_vol));
                src_ref = {ref_vol;src_vol};
                spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
                % Sum and weight frames 1 through n
                vols_array{zz} = [pet_dir 'r' tracer_frames(zz,:)]; current_vols = strvcat(vols_array); [~,cols] = size(vols_array);
                first_vol = deblank(current_vols(1,:)); last_vol = deblank(current_vols(size(current_vols,1),:));
                vo_name = [pet_dir 'Summed\' sub '_PET_Raw-' pet_name '_frs0' first_vol(end-7:end-6) '-0' last_vol(end-7:end-6) '.img'];
                exp_num = [exp_num '+(i' num2str(zz) '*' num2str(cell2mat(raw(cols+1,2))) ')'];
                exp_den = [exp_den '+' num2str(cell2mat(raw(cols+1,2)))];
                exp = ['(' exp_num ')/(' exp_den ')'];
                ref_vol = spm_imcalc_ui(current_vols,vo_name,exp);
                ref_vol = [ref_vol ',1'];
                clearvars src_vol exp
            end
            
            %% Make copies of frames 1-8 with "r" prefix
            tracer_files = dir(pet_dir);
            tracer_files = {tracer_files(~[tracer_files.isdir]).name};
            tracer_files = regexprep(tracer_files, 'r(.*)_fr(.*).(.*)', '');
            tracer_files = deblank(str2mat(tracer_files(~cellfun('isempty', tracer_files))));
            for zz=1:size(tracer_files,1),
                current_tfile = [pet_dir tracer_files(zz,:)];
                if str2num(current_tfile(end-6:end-4))<=8,
                    current_rfile = [pet_dir 'r' tracer_files(zz,:)];
                    copyfile(current_tfile,current_rfile);
                end
            end
            clear tracer_frames framen vols_array current_vols exp_num exp_den tracer_files current_rfile current_tfile ref_vol vo_name first_vol last_vol pet_dir
        else
            for zz=1:1:size(tracer_frames,1),
                vols_array{zz,1} = [pet_dir tracer_frames(zz,:)];
            end
            
            current_vols = vols_array;
            spm_jobman('initcfg');
            load vwi_PET_realign;
            matlabbatch{1}.spm.spatial.realign.estwrite.data = {current_vols};
            spm_jobman('run', matlabbatch);
            clear('matlabbatch');
        end
    end
end
clc
end