function vwi_dynamic_safe()
%        Dynamic PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman and Clifford Workman
%
%        Usage: vwi_dynamic;
%
%        sub: subject number
%        MR_dir: directory containing subject's original MRI scan
%        dasb1_dir: directory containing subject's original baseline DASB
%        scan
%        pib1_dir: directory containing subject's original baseline PIB scan
%        dasb2_dir: directory containing subject's original follow-up DASB
%        scan (if it exists)
%        pib2_dir: directory containging subject's original follow-up PIB
%        scan (if it exists)
%
%        Example directories for 2004:
%        MRI: ~\2004\06-15-09_MRI\MR\NIfTI_02_03_12\6459781_701_MRI_7mmAX_20090615\
%        PIB: ~\2004\06-18-09_PET\PIB\
%        Baseline DASB: ~\2004\06-19-09_PET\DASB\
%        Follow-up DASB: ~\2004\08-10-09_PET\DASB\
%
%        It is suggested to start VWI using either of the following
%        commands: vwi
%
%
%
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

%% Prompt for subject number and validity checks
Study_Sub;
waitfor(Study_Sub);
sub = evalin('base','sub');
study = evalin('base','study');

%% Read Study Protocol
[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;
study_dir = studyprotocol{1,2};
sub_dir = [study_dir '\Dynamic\' sub];
if exist(sub_dir,'dir') == 0;
    mkdir(sub_dir);
end

%% Check processing status for specified subject
if exist([sub_dir '\' sub '_processing-status.txt'],'file') == 0;
    fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
    fwrite(fid,'0');
    fclose('all');
    proc_step = 0;
else
    fid = fopen([sub_dir '\' sub '_processing-status.txt']);
    proc_step = textread([sub_dir '\' sub '_processing-status.txt']);
    fclose('all');
    if proc_step == 1;
        check_proc = questdlg('Looks like frame-by-frame realignment is done. Have you aligned the PET and MR data to the AC and checked laterality?', ...
            'Dynamic', 'Yes', 'No', 'Start over!', 'Start over!');
        switch check_proc
            case 'Yes'
                disp('Frame-by-frame realignement done, data re-oriented to AC, and laterality checked. Preparing for PET2PET and MR2PET coregistration/segmentation.');
            case 'No'
                disp('Can''t move forward until data are re-oriented to AC and laterality is checked.');
                return
            case 'Start over!'
                fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
                fwrite(fid,'0');
                fclose('all');
                proc_step = 0;
        end
    elseif proc_step == 2;
        check_proc = questdlg('Looks like coregistration and segmentation are done. Have you drawn the VOI for the cerebellar gray matter?', ...
            'Dynamic', 'Yes', 'No', 'More Options', 'More Options');
        switch check_proc
            case 'Yes'
                disp('PET2PET and MR2PET coregistration and segmentation done. Preparing to mask gray matter VOI and generate TACs.');
            case 'No'
                disp('Can''t move forward until there''s a VOI for the cerebellar gray matter.');
                return
            case 'More Options'
                more_opts = questdlg('Looks like coregistration and segmentation are done. Have you drawn the VOI for the cerebellar gray matter?', ...
                    'Dynamic', 'Redo coreg/seg', 'Start over!', 'Start over!');
                switch more_opts
                    case 'Redo coreg/seg'
                        fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
                        fwrite(fid,'1');
                        fclose('all');
                        proc_step = 1;
                    case 'Start over!'
                        fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
                        fwrite(fid,'0');
                        fclose('all');
                        proc_step = 0;
                end
        end
    elseif proc_step == 3;
        check_proc = questdlg(['TACs appear to have been generated for participant ' sub '. Please send this data to Dr. Yun Zhou to generate parametric images.'], ...
            'Dynamic', 'Okay', 'More Options', 'More Options');
        switch check_proc
            case 'Okay'
                disp(['TACs appear to have been generated for participant ' sub '. Please send this data to Dr. Yun Zhou to generate parametric images.']);
            case 'More Options'
                more_opts = questdlg(['TACs appear to have been generated for participant ' sub '. Please send this data to Dr. Yun Zhou to generate parametric images.'], ...
                    'Dynamic', 'Redo TACs', 'Redo coreg/seg', 'Start over!', 'Start over!');
                switch more_opts
                    case 'Redo TACs'
                        fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
                        fwrite(fid,'2');
                        fclose('all');
                        proc_step = 2;
                    case 'Redo coreg/seg'
                        fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
                        fwrite(fid,'1');
                        fclose('all');
                        proc_step = 1;
                    case 'Start over!'
                        fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
                        fwrite(fid,'0');
                        fclose('all');
                        proc_step = 0;
                end
        end
    end
end

%% PROCESSING STEP ONE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Prompt to select subject's MRI file and how many pet scans per tracer
if proc_step == 0,
    sizeprotocol = size(studyprotocol,2)-2;
    for ii=1:sizeprotocol,
        MRlist{ii,1} = studyprotocol{1,ii+2};
        MRlist{ii,2} = studyprotocol{2,ii+2};
        MRlistdlg{ii,1} = studyprotocol{1,ii+2};
    end
    if sizeprotocol > 1,
        [Selection,ok] = listdlg('PromptString','Select which MR sequence to use:',...
            'SelectionMode','single','ListSize',[160 300],'Name','ROI','ListString',MRlistdlg);
        while isempty(Selection)
            uiwait(msgbox('Error: You must select at least 1 MR sequence.','Error message','error'));
            [Selection,ok] = listdlg('PromptString','Select which MR sequence to use:',...
                'SelectionMode','single','ListSize',[160 300],'Name','ROI','ListString',MRlistdlg);
        end
        MRtype(1,1) = MRlist(Selection,1);
        MRtype(1,2) = MRlist(Selection,2);
    else
        MRtype = MRlist;
    end
    
    %% Prompt to selection number of MR scans
    msg = (['How many ' MRtype{1,1} ' scans:']);
    box_title = 'Dynamic';
    num_lines = 1;
    default = {num2str(MRtype{1,2})};
    MRnum = inputdlg(msg,box_title,num_lines,default);
    clear msg
    mrint = round(str2double(MRnum{1}));
    while isnan(mrint)
        msg = ('A number must be entered:');
        uiwait(msgbox(msg,'Dynamic'));
        MRnum = inputdlg(msg,box_title,num_lines,default);
        mrint = round(str2double(MRnum{1}));
        clear msg
    end
    MRtype(1,2) = MRnum;
    textfile = [sub_dir '\' sub '_MR-Scans.txt'];
    fid=fopen(textfile,'wt');
    fprintf(fid,'%s\t%s',MRtype{:,:});
    fclose(fid);
    
    source_dir = study_dir;
    
    for jj=1:str2double(MRnum),
        msg1 = (['Please select the ' MRtype{1,1} ' #']);
        msg2 = (' image file.');
        msg = sprintf('%s%d%s',msg1,jj,msg2);
        MR_dir = spm_select(1:1,'image', msg ,[],source_dir,'\.(nii|img)$');
        clear msg msg1 msg2
        [pathstr, name, ext] = fileparts(MR_dir);
        source_dir = pathstr;
        if strcmp(ext,'.nii,1') == 1,
            MRext = '.nii';
            MR_Simg = [pathstr '\' name MRext];
        else
            MRext = '.img';
            MRhdr = '.hdr';
            MR_Simg = [pathstr '\' name MRext];
            MR_Shdr = [pathstr '\' name MRhdr];
        end
        if str2double(MRnum) > 1,
            MRtemp = '_';
            MRnumber  = sprintf('%s%d',MRtemp,jj);
        else
            MRnumber = '';
        end
        
        mri_pdir = [sub_dir '\' MRtype{1,1} MRnumber '\']; % Create MRI processing directory
        if exist(mri_pdir,'dir') == 0 % Check if MRI directory exists, create
            disp('Creating MRI processing directory ...');
            mkdir(mri_pdir);
        else disp('MRI directory already exists.');
        end
        
        MR_Iname = [sub '_MR-' MRtype{1,1} MRnumber MRext]; % Check if MRI exists, copy
        MR_Pimg = [mri_pdir MR_Iname];
        if exist(MR_Pimg,'file') ~= 0;
            mri_exists = questdlg('MRI already exist. Overwrite?', ...
                'Dynamic', 'Yes', 'No', 'No');
            switch mri_exists
                case 'Yes'
                    delete(MR_Pimg);
                    disp('Copying MRI ...');
                    if strcmp(MRext,'.nii') == 1,
                        copyfile(MR_Simg, MR_Pimg);
                    else
                        copyfile(MR_Simg, MR_Pimg);
                        
                        MR_Hname = [sub '_MR-' MRtype{1,1} MRnumber MRhdr]; %% can add date here
                        MR_Phdr = [mri_pdir MR_Hname];
                        copyfile(MR_Shdr,MR_Phdr);
                    end
                case 'No'
                    disp('MRI not copied.');
            end
        else
            disp('Copying MRI ...');
            copyfile(MR_Simg, MR_Pimg);
        end
    end
    clear MR_dir ext sizeprotocol
    
    
    %% prompt to select how many scans for each study tracer
    sizeprotocol = size(studyprotocol,1)-1;
    for jj=1:sizeprotocol,
        box1 = ('How many ');
        box2 = studyprotocol{jj+1,1};
        box3 = (' scans:');
        box = {sprintf('%s%s%s',box1,box2,box3)};
        box_title = 'Dynamic';
        num_lines = 1;
        default = {num2str(studyprotocol{jj+1,2})};
        TracerNum = inputdlg(box,box_title,num_lines,default);
        
        if isempty(TracerNum),
            return,
        end;
        scans(jj,1) = cellstr(box2);
        scans(jj,2) = cellstr(TracerNum{1});
        eval(sprintf('TracerNum_%d = TracerNum;',jj));
    end
    clear box1 box2 box3 box
    pettemp = pathstr;
    
    textfile = [sub_dir '\' sub '_PET-Scans.txt'];
    fid=fopen(textfile,'wt');
    
    [rows,cols]=size(scans);
    
    for ii=1:rows
        fprintf(fid,'%s\t%s\n',scans{ii,:});
    end
    fclose(fid);
    
    sizeprotocol = size(scans,1);
    
    %% Prompt to select subject's PET folders
    for jj=1:sizeprotocol,
        TracerNum = eval(sprintf('TracerNum_%d',jj));
        if str2double(TracerNum)>1,
            for ii=1:str2double(TracerNum);
                msg1 = ('Please select ');
                msg2 = ('''s ');
                msg3 = studyprotocol{jj+1,1};
                msg4 = (' ');
                msg5 = (' folder');
                msg = sprintf('%s%s%s%s%s%d%s',msg1,sub,msg2,msg3,msg4,ii,msg5);
                uiwait(msgbox(msg,'Dynamic'));
                petdir = uigetdir(source_dir,msg);
                eval(sprintf('tracer_%d_dir_%d = petdir;',jj,ii));
                source_dir = petdir;
                clear msg msg1 msg2 msg3 msg4 msg5 msg
            end
        else
            for ii=1:str2double(TracerNum);
                msg1 = ('Please select ');
                msg2 = ('''s ');
                msg3 = studyprotocol{jj+1,1};
                msg4 = (' folder');
                msg = sprintf('%s%s%s%s%s%s',msg1,sub,msg2,msg3,msg4);
                uiwait(msgbox(msg,'Dynamic'));
                petdir = uigetdir(source_dir,msg);
                eval(sprintf('tracer_%d_dir_%d = petdir;',jj,ii));
                source_dir = petdir;
                clear msg msg1 msg2 msg3 msg4 msg
            end
        end
    end
%     for jj=1:sizeprotocol,
%         TracerNum = eval(sprintf('TracerNum_%d',jj));
%         if str2double(TracerNum)>1,
%             for ii=1:str2double(TracerNum);
%                 msg1 = (['Please select the ' studyprotocol{jj+1,1} ' #']);
%                 msg2 = (' image file.');
%                 msg = sprintf('%s%d%s',msg1,jj,msg2);
%                 petdir = spm_select(1,'any', msg ,[],source_dir,'\.*.v');
%                 eval(sprintf('tracer_%d_dir_%d = petdir;',jj,ii));
%                 [petpath,~,~]=fileparts(petdir);
%                 source_dir = petpath;
%                 clear msg msg1 msg2
%             end
%         else
%             for ii=1:str2double(TracerNum);
%                 msg1 = ('Please select ');
%                 msg2 = ('''s ');
%                 msg3 = studyprotocol{jj+1,1};
%                 msg4 = (' ECAT file:');
%                 msg = sprintf('%s%s%s%s%s%s',msg1,sub,msg2,msg3,msg4);
%                 petdir = spm_select(1,'any', msg ,[],source_dir,'\.*.v');
%                 eval(sprintf('tracer_%d_dir_%d = petdir;',jj,ii));
%                 [petpath,~,~]=fileparts(petdir);
%                 source_dir = petpath;
%                 niftitest = dir([petpath,'*.nii']);
%                 
%                 clear msg msg1 msg2 msg3 msg4 msg
%             end
%         end
%     end
    
    
    
    %% Make PET directory, copy frames, remove axial planes, convert to nCi
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
    
    for ii=1:sizeprotocol,
        Tracer_name = studyprotocol{ii+1,1};
        TracerNum = eval(sprintf('TracerNum_%d',ii));
        for jj=1:str2double(TracerNum{1});
            if str2double(TracerNum{1}) > 1,
                pet_name = sprintf('%s%s%d', Tracer_name, '_', jj);
                pet_dir = [sub_dir '\' pet_name '\'];
            else
                pet_name = Tracer_name;
                pet_dir = [sub_dir '\' pet_name '\'];
            end
            
            PET_source = eval(sprintf('tracer_%d_dir_%d',ii,jj)); % Check if PET files exist, copy
            Spet_dir = [PET_source '\results\ecat2ana\'];
            
            if exist(pet_dir,'dir') == 0 % Check if PET directory exists, create
                disp('Creating PET processing directory ...');
                mkdir(pet_dir);
                Spet_name = dir(Spet_dir);
                Spetsize = size(Spet_name,1);
                for zz=3:Spetsize,
                    [pathstr, name, ext] = fileparts([Spet_dir Spet_name(zz).name]);
                    pet_in = [pathstr '\' name ext];
                    strtext = findstr(name,'frame');
                    if isempty(strtext)==0,
                        if str2double(name(58:end))<10,
                            name = ['fr00' name(58:end)];
                            pet_out = [pet_dir sub '_PET_Raw-' pet_name '_' name ext]; %% can add date here
                        else
                            name = ['fr0' name(58:end)];
                            pet_out = [pet_dir sub '_PET_Raw-' pet_name '_' name ext]; %% can add date here
                        end
                    else
                        pet_out = [pet_dir sub '_PET_Raw-' pet_name '_' name(end-4:end) ext]; %% can add date here
                    end
                    copyfile(pet_in,pet_out);
                end
            else disp('PET directory already exists.');
                msg = [Tracer_name ' already exists. Overwrite?'];
                pet_exists = questdlg(msg, ...
                    'Dynamic', 'Yes', 'No', 'No');
                switch pet_exists
                    case 'Yes'
                        delete(pet_dir);
                        mkdir(pet_dir);
                        disp(['Copying ' Tracer_name ' ...']);
                        Spet_name = dir(Spet_dir);
                        Spetsize = size(Spet_name,1);
                        for zz=3:Spetsize,
                            [pathstr, name, ext] = fileparts([Spet_dir Spet_name(zz).name]);
                            pet_in = [pathstr '\' name ext];
                            strtext = findstr(name,'frame');
                            if isempty(strtext)==0,
                                if str2double(name(58:end))<10,
                                    name = ['fr00' name(58:end)];
                                    pet_out = [pet_dir sub '_PET_Raw-' pet_name '_' name ext]; %% can add date here
                                else
                                    name = ['fr0' name(58:end)];
                                    pet_out = [pet_dir sub '_PET_Raw-' pet_name '_' name ext]; %% can add date here
                                end
                            else
                                pet_out = [pet_dir sub '_PET_Raw-' pet_name '_' name(end-4:end) ext]; %% can add date here
                            end
                            copyfile(pet_in,pet_out);
                        end
                        break
                    case 'No'
                        disp([Tracer_name ' not copied.']);
                        break
                end
            end
            
            pet_files = dir(pet_dir);
            
            %% Reduce each frame from 207 to 150 axial slices, convert from Bq to nCi
            pet_files = {pet_files(~[pet_files.isdir]).name};
            pet_files = regexprep(pet_files, '(.*).hdr', '');
            pet_files = deblank(str2mat(pet_files(~cellfun('isempty', pet_files))));
            affine_pars = [-1.2188         0         0          160.0000
                0              1.2188    0           -195.0000
                0              0         1.2188      -50.0000
                0              0         0           1.0000];
            for zz=1:size(pet_files(:,1),1),
                frame_name = [pet_dir pet_files(zz,:)];
                read_pet = spm_vol(frame_name);
                conv_pet = (1/(37))*(spm_read_vols(read_pet));
                %         conv_pet = conv_pet(:,:,5:154);  %Original 150 frames
                conv_pet = conv_pet(:,:,1:150); %Standard
%                 conv_pet = conv_pet(:,:,20:169); %Unique 150 frames for subject MCI2030, MCI2033, MCI2034, MCI2035
                read_pet.mat = affine_pars;
                read_pet.dim(1,1:3) = [256 256 150];
                read_pet.fname = [pet_dir pet_files(zz,:)];
                spm_write_vol(read_pet,conv_pet);
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%  REMOVE THIS for KMP!!!!!!!!
    
    %% Frame-by-Frame Realignment
    for ii=1:sizeprotocol,
        Tracer_name = studyprotocol{ii+1,1};
        TracerNum = eval(sprintf('TracerNum_%d',ii));
        for jj=1:str2double(TracerNum{1}),
            if str2double(TracerNum{1}) > 1,
                pet_name = sprintf('%s%s%d', Tracer_name, '_', jj);
                pet_dir = [sub_dir '\' pet_name '\'];
            else
                pet_name = Tracer_name;
                pet_dir = [sub_dir '\' pet_name '\'];
            end
            if exist([pet_dir 'Summed\'],'dir') == 0;
                disp('Creating directory for summed PET images.');
                mkdir([pet_dir 'Summed\']);
            end
        end
    end
    vwi_fxf_realignment(sub,study);
    
    %% Store processing status and stop Dynamic
    fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
    fwrite(fid,'1');
    fclose('all');
    msgbox('Frame-by-frame realignment has finished. Please align PET and MR data to the AC and check laterality. Then, restart VWI.','Status message');
    disp('DONE!');
end

% PROCESSING STEP TWO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if proc_step == 1
    %% Declare required variables, coregister and segment scans, create VOIs
    dyn_coreg_seg(sub,study);
    clc
    %% Store processing status and stop VWI
    fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
    fwrite(fid,'2');
    fclose('all');
    msgbox('Coregistration and segmentation of MR and PET data is complete. Please draw cerebellar gray matter VOI. Then, restart Dynamic.','Status message');
    disp('DONE!');
end

%% PROCESSING STEP THREE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if proc_step == 2
    %% Generate cerebellum and Region TACs
    vwi_generate_cerebTAC(sub,study);
    generate_vwiTACs(sub,study);
    
    %% Store processing status and stop KMP
    fid = fopen([sub_dir '\' sub '_processing-status.txt'],'w');
    fwrite(fid,'3');
    fclose('all');
    
    clc
    msgbox('TACs have been generated. Please send to Dr. Yun Zhou to generate parametric images.','Status message');
    disp('DONE!');
end
clear('all');

disp('DONE!');

end