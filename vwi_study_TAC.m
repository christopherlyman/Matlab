function vwi_study_TAC()


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
study_dir = [studyprotocol{1,2} '\Dynamic'];

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

for ii=1:1:size(sublength,1),
    sub = sublength{ii,:};
    sub_dir = [study_dir '\' sub];
    disp(['Subject: ' sub]);
    
    textfile = [sub_dir '\' sub '_MR-Scans.txt'];
    fid = fopen(textfile);
    mri_scans = textscan(fid,'%s%s','Whitespace','\t');
    fclose(fid);
    mr_name = cell2mat(mri_scans{1});
    mr_num = cell2mat(mri_scans{2});
    
    if str2double(mr_num) > 1,
        MRI_dir = [sub_dir '\' mr_name '_1'];
    else
        MRI_dir = [sub_dir '\' mr_name];
    end
    
    textfile = [sub_dir '\' sub '_PET-Scans.txt'];
    fid = fopen(textfile);
    pet_scans = textscan(fid,'%s%s','Whitespace','\t');
    fclose(fid);
    pet_names = pet_scans{1};
    pet_num = pet_scans{2};
    
    for kk = length(pet_names):-1:1
        % remove folders starting with .
        if strfind(pet_names{kk},'O-') == 1,
            pet_names{kk} = [ ];
        end
    end
    pet_names = pet_names(~cellfun('isempty',pet_names));
    
    CERBroi = [MRI_dir '\CerGM_VOI\r' sub '_CERB_input-function.nii'];
    
    dirMRI = dir([MRI_dir, '\r*.nii']);
    MRI_name = dirMRI.name;
    seg_dir = [MRI_dir '\Segment'];
    GM_dir = dir([seg_dir, 'p1*.nii']);
    if size(GM_dir,1) == 0,
        GM_dir = dir([seg_dir, '\c1*.nii']);
    end
    GM_name = GM_dir.name;
    WM_dir = dir([seg_dir, '\p2*.nii']);
    if size(WM_dir,1) == 0,
        WM_dir = dir([seg_dir, '\c2*.nii']);
    end
    WM_name = WM_dir.name;
    CSF_dir = dir([seg_dir, '\p3*.nii']);
    if size(CSF_dir,1) == 0,
        CSF_dir = dir([seg_dir, '\c3*.nii']);
    end
    CSF_name = CSF_dir.name;
    
    current_vols = str2mat([MRI_dir '\' MRI_name ',1'],...
        [seg_dir '\' GM_name ',1']);
    vo_name = [seg_dir '\' sub '_Non-GM-Mask.nii']; % CerGM VOI mask
    exp = '((i1>0)-(i2>.8))>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
    seg_roi_75 = [sub '_Non-GM-Mask.nii'];
    clear current_vols vo_name exp
    
    current_vols = str2mat([MRI_dir '\CerGM_VOI\r' sub '_CERB_input-function.nii,1'],...
        [seg_dir '\' sub '_Non-GM-Mask.nii,1']);
    vo_name = [MRI_dir '\CerGM_VOI\r' sub 'GM-masked_CERB_input-function.nii'];
    exp = '((i1>0)-(i2>.3))>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
    CERBseg = vo_name;
    
    for jj=1:size(pet_names,1),
        Tracer_name = pet_names{jj,1};
        for gg=1:str2double(pet_num{jj,1})
            if str2double(pet_num{jj,1}) > 1,
                pet_name = sprintf('%s%s%d', Tracer_name, '_', gg);
            else
                pet_name = [Tracer_name];
            end
            
            tracer_frames = dir([sub_dir '\' pet_name, '\r*']); % Create array of SPM-ready img files
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
                %                 prot_err = questdlg(['Unexpected number of frames in ' pet_name ' directory.'], ...
                prot_err = questdlg(['Inappropriate number of frames for ' sub ' ' pet_name '.'], ...
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
            
            
            roi_vol = spm_vol(CERBseg);
            thresh_roi = (spm_read_vols(roi_vol)>0.5);
            nvox = sum(sum(sum(thresh_roi)));
            
            [mpro,dur,tm,wt,num_frames,tac] = set_mpro(PathName,FileName);
            if isempty(mpro), disp('No protocol file specified. Terminating.'); return; end
            
            
            
            %% First, load the Base scan of interest
            num_images = size(tracer_frames,1);
            for kk=1:num_images % Kinetic modeling magic
                base = [sub_dir '\' pet_name '\' tracer_frames(kk,:)];
                base_vol = spm_vol(base);
                read_base = spm_read_vols(base_vol);
                tac(kk,2)= sum(sum(sum(read_base.*thresh_roi)));
                clear base base_vol read_base
            end
            
            h = figure; % Generates outputs
            tac(:,2)=tac(:,2)/nvox;
            plot(tm,tac(:,2),'o');
            pout = [MRI_dir '\CerGM_VOI\' sub '_' pet_name '_TAC_Fig.tif'];
            print(h, '-dtiff', pout);
            close(h);
            fout = [MRI_dir '\CerGM_VOI\' sub '_' pet_name '_TAC.xls'];
            xlswrite(fout,tac);
            
        end
    end
end

disp('DONE!');

    function [mpro,dur,tm,wt,num_frames,tac] = set_mpro(PathName,FileName)
        mpro = xlsread([PathName FileName],'protocol');
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


