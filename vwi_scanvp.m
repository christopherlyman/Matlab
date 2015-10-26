function spa_scanvp(dirs_paths, proc_SUV, spm8_path, silent, stdy, sub, stu_sub, scans_available)
%
%        FDG Automated Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: spa(sub,MR_dir)
%
%        sub: subject number
%        MR_dir: directory containing subject's original MRI scan
%        
%
%        Example directories for :
%        FDG: 
%
%        It is suggested to start SPA using either of the following
%        commands:
%        >> spa
%        >> spa(sub)
%
%        The remaining variables are intended for batch processing.
%        Type "help spa_batch" to learn more. Additional information about
%        the processing steps utilized in SPA can be found by typing
%        "help" followed by the name of the module in question into the
%        MATLAB console.

%% Ensure SPM8 path has been added, define home directory %%%%%%%%%%%%%%%%
%                                                                        %
% Code to remove/add SPM paths developed by K-lab:                       %
% http://www.nemotos.net/?p=21                                           %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pth] = fileparts(which('spa'));
[~,~,raw]=xlsread([pth '\spa_ini.xlsx'],'Dirs and Paths'); % This extracts directories from the batch file
dirs_paths = raw; clear raw;
home_dir = cell2mat(dirs_paths(strcmp(dirs_paths,'Home directory')>0,2));
proc_ScanVP = cell2mat(dirs_paths(strcmp(dirs_paths,'Process ScanVP')>0,2));
spm8_path = dirs_paths(strcmp(dirs_paths,'SPM8 path')>0,2);
while true
   try spm_rmpath; 
   catch break; 
   end
end
addpath(cell2mat(spm8_path));
clc

scanvp;
clc

cd (proc_ScanVP);

% 
% %% Ask whether to run silently
% if exist('silent', 'var') == 0
%     silent = 'no';
% %     % To enable individual "silent mode", uncomment the following:
% %     error_check = questdlg('Run with or without error checking (i.e., error messages that pause the software)?', ...
% %                            'FDG Automated Pipeline', 'With error checking', 'Without', 'Without');
% %     switch error_check
% %         case 'Without'
% %             error_dblcheck = questdlg('Please confirm that you want to run SPA without error checking.', ...
% %                                       'FDG Automated Pipeline', 'With error checking', 'Without', 'Without');
% %             switch error_dblcheck    
% %                 case 'Without'
% %                     disp('Running SPA without error checking. Please review the processed data carefully.');
% %                     silent = 'yes';
% %                 case 'With error checking'
% %                     disp('Running SPA with error checking.');
% %                     silent = 'no';
% %             end
% %         case 'With error checking'
% %             disp('Running SPA with error checking.');
% %             silent = 'no';
% %     end
% end
% 
% %% Prompt for study and subject number
% stdysub = get_stdysub;
% stdy = stdysub{1};
% sub = stdysub{2};
% clear stdysub;
% stu_sub = [stdy '_' sub];
% 
% %% Prompt to select scans
% sel_scans;
% waitfor(sel_scans);
% scans_available = evalin('base','scans_available');
% [FDG1_dir,IM_dir] = get_RAWdir(sub,stdy,home_dir); if isempty(IM_dir), return; end
% 
% %% Check processing status for specified subject
% if exist([IM_dir '\' stu_sub '\' stu_sub '_processing-status.txt']) == 0;
%     fid = fopen([IM_dir '\' stu_sub '\' stu_sub '_processing-status.txt'],'w');
%     fwrite(fid,'0');
%     fclose('all');
% else
%     proc_step = textread([IM_dir '\' stu_sub '\' stu_sub '_processing-status.txt']);
%     fclose('all');
%     if strcmp(silent, 'yes') && proc_step == 1;
%         disp('SUV calculation done. Please manually align FDG and MR images to AC.');
%     elseif proc_step == 1;
%         check_proc = questdlg('The SUV calculation is complete. Have you manually aligned the FDG SUV and MR images to the AC?', ...
%             'SUV Pipeline', 'Yes', 'No', 'Recalculate SUV', 'Recalculate SUV');
%         switch check_proc
%             case 'Yes'
%                 disp('SUV calculation is complete and the PET SUV and MR images have been manually aligned to the AC. Preparing to align MR to PET and MR segmentation.');
%             case 'No'
%                 disp('Can''t move forward until PET and MR are manually aligned to the AC');
%                 return
%             case 'Recalculate SUV'
%                 fid = fopen([IM_dir '\' stu_sub '\' stu_sub '_processing-status.txt'],'w');
%                 fwrite(fid,'0');
%                 fclose('all');
%         end
%     elseif strcmp(silent, 'yes') && proc_step == 2;
%         disp('Coregistration of the MR to the PET and MR segmentation is complete.');
%     elseif proc_step == 2;
%         check_proc = questdlg('Coregistration of the MR to the PET and MR segmentation is complete. Would you like the skull strip the FDG images?', ...
%             'SUV pipeline', 'Yes', 'No', 'More Options', 'More Options');
%         switch check_proc
%             case 'Yes'
%                 disp('Coregistration of the MR to the PET and MR segmentation is complete. Preparing to skull strip FDG images.');
%             case 'No'
%                 disp('Preparing to realign and normalize.');
%                 return
%             case 'More Options'
%                 more_opts = questdlg('Coregistration of the MR to the PET and MR segmentation is complete. Would you like the skull strip the FDG images?', ...
%                     'SUV pipeline', 'Redo Coreg/Segment', 'Start over!', 'Start over!');
%                 switch more_opts
%                     case 'Redo Coreg/Segment'
%                         fid = fopen([IM_dir '\' stu_sub '\' stu_sub '_processing-status.txt'],'w');
%                         fwrite(fid,'1');
%                         fclose('all');
%                     case 'Start over!'
%                         fid = fopen([IM_dir '\' stu_sub '\' stu_sub '_processing-status.txt'],'w');
%                         fwrite(fid,'0');
%                         fclose('all');
%                 end
%         end
%     end
% end
% 
% %% PROCESSING STEP ONE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % Get Follow-up FDG directory
% if exist('FDG2_dir', 'var') == 0 && strcmp(scans_available(2),'yes');
%     tracer_time = 'Follow-up ';
%     tracer_name = 'FDG';
%     if isempty(FDG1_dir) == 0, start_dir = FDG1_dir;
%     else start_dir = FDG1_dir; end
%     [scan_dir] = get_datadir(sub,tracer_name,tracer_time,start_dir,silent);
%     FDG2_dir = scan_dir; clear scan_dir;
% else FDG2_dir = ''; clear FDG2_dir
% end
% 
% % Get additional follow-up FDG directory
% if exist('FDG3_dir', 'var') == 0 && strcmp(scans_available(3),'yes');
%     tracer_time = 'Additional follow-up ';
%     tracer_name = 'FDG';
%     if isempty(FDG2_dir) == 0, start_dir = FDG2_dir;
%     elseif isempty(FDG1_dir) == 0, start_dir = FDG1_dir;
%     else start_dir = FDG1_dir; 
%     end
%     [scan_dir] = get_datadir(sub,tracer_name,tracer_time,start_dir,silent);
%     FDG3_dir = scan_dir; clear scan_dir;
% else FDG3_dir = ''; clear FDG3_dir
% end
% 
% % Get Baseline MRI directory
% if exist('MR1_dir', 'var') == 0 && strcmp(scans_available(4),'yes'),
%     tracer_time = 'baseline ';
%     tracer_name = 'MRI';
%     start_dir = FDG1_dir;
%     [scan_dir] = get_datadir(sub,tracer_name,tracer_time,start_dir,silent);
%     MR1_dir = scan_dir; clear scan_dir;
% else MR1_dir = ''; clear MR1_dir
% end
% 
% % Get Follow-up MRI directory
% if exist('MR2_dir', 'var') == 0 && strcmp(scans_available(5),'yes');
%     tracer_time = 'Follow-up ';
%     tracer_name = 'MRI';
%     if isempty(MR1_dir) == 0, start_dir = MR1_dir;
%     else start_dir = MR1_dir; end
%     [scan_dir] = get_datadir(sub,tracer_name,tracer_time,start_dir,silent);
%     MR2_dir = scan_dir; clear scan_dir;
% else MR2_dir = ''; clear MR2_dir
% end
% 
% %% Get Dose Injected and BMI values
% prompt = {'Enter Dose Injected (MBq):','Enter BMI:'};
% dlg_title = 'FDG (Baseline or Single scan)';
% num_lines = 1;
% FDG1DoseBMI = inputdlg(prompt,dlg_title,num_lines);
% 
% if exist('FDG2_dir', 'var') ~= 0 && strcmp(scans_available(2),'yes');
% prompt = {'Enter Dose Injected (MBq):','Enter BMI:'};
% dlg_title = 'Follow-up FDG Scan';
% num_lines = 1;
% FDG2DoseBMI = inputdlg(prompt,dlg_title,num_lines);
% end
%  
% % Get additional follow-up FDG directory
% if exist('FDG3_dir', 'var') ~= 0 && strcmp(scans_available(3),'yes');
% prompt = {'Enter Dose Injected (MBq):','Enter BMI:'};
% dlg_title = 'Additional Follow-up FDG Scan';
% num_lines = 1;
% FDG3DoseBMI = inputdlg(prompt,dlg_title,num_lines);
% end
% clear dlg_title;
% clear num_lines
% clear prompt
% 
% %% Make DICOM directory and copy DICOM
% DICOM_pdir = [IM_dir '\' stu_sub '\DICOM\']; % Create DICOM processing directory
% sub_pdir = [IM_dir '\' stu_sub '\']; % Create NIfTI processing directories
% 
% %% Make baseline FDG directory, copy DICOM files
% if strcmp(scans_available(1),'yes'),
%     if strcmp(scans_available(2),'no'), % Create FDG processing directory
%         FDG1_pdir = [DICOM_pdir 'FDG\'];
%         FDG1_ndir = [sub_pdir 'FDG\'];
%         FDG1_rename = [stu_sub '_FDG-PET.nii'];
%     else FDG1_pdir = [DICOM_pdir 'FDG_BL\'];
%          FDG1_ndir = [sub_pdir 'FDG_BL\'];
%          FDG1_rename = [stu_sub '_FDG-PET_BL.nii'];
%     end
%     if exist(FDG1_pdir) == 0; % Check if FDG directory exists, create
%         disp('Creating baseline FDG PET processing directory ...');
%         mkdir(FDG1_pdir);
%         mkdir(FDG1_ndir);
%         disp('Copying FDG PET ...');
%         copyfile(FDG1_dir, FDG1_pdir);
%         wdir = FDG1_pdir;
%         odir = FDG1_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting FDG PET DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         FDG1_name = dir('*.nii');
%         FDG1_name = FDG1_name(1).name;
%         movefile(FDG1_name, FDG1_rename);
%         disp('Finished converting FDG PET DICOM to NIfTI ...');
%     else disp('Baseline FDG PET directory already exists.'); 
%         disp('Copying FDG PET ...');
%         copyfile(FDG1_dir, FDG1_pdir);
%         wdir = FDG1_pdir;
%         odir = FDG1_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting FDG PET DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         FDG1_name = dir('*.nii');
%         FDG1_name = FDG1_name(1).name;
%         movefile(FDG1_name, FDG1_rename);
%         disp('Finished converting FDG PET DICOM to NIfTI ...');
%     end
% end
% 
% %% Make FDG follow-up directory and copy files
% if strcmp(scans_available(2),'yes'),
%     FDG2_pdir = [DICOM_pdir 'FDG_FU\']; % Create FDG Follow-up processing directory
%     FDG2_ndir = [sub_pdir 'FDG_FU\'];
%     FDG2_rename = [stu_sub '_FDG-PET_FU.nii'];
% 
%     if exist(FDG2_pdir) == 0; % Check if FDG Follow-up directory exists, create
%         disp('Creating FDG Follow-up processing directory ...');
%         mkdir(FDG2_pdir);
%         mkdir(FDG2_ndir);
%         disp('Copying FDG Follow-up PET ...');
%         copyfile(FDG2_dir, FDG2_pdir);
%         wdir = FDG2_pdir;
%         odir = FDG2_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting FDG Follow-up DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         FDG2_name = dir('*.nii');
%         FDG2_name = FDG2_name(1).name;
%         movefile(FDG2_name, FDG2_rename);
%         disp('Finished converting FDG Follow-up DICOM to NIfTI ...');
%     else disp('FDG Follow-up directory already exists.'); 
%         disp('Copying FDG Follow-up PET ...');
%         copyfile(FDG2_dir, FDG2_pdir);
%         wdir = FDG2_pdir;
%         odir = FDG2_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting FDG Follow-up DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         FDG2_name = dir('*.nii');
%         FDG2_name = FDG2_name(1).name;
%         movefile(FDG2_name, FDG2_rename);
%         disp('Finished converting FDG Follow-up DICOM to NIfTI ...');
%     end
% end
% 
% % Make additional follow-up FDG directory and copy frames
% if strcmp(scans_available(3),'yes'),
%     FDG3_pdir = [DICOM_pdir 'FDG_FU_2\']; % Create additional follow-up FDG processing directory
%     FDG3_ndir = [sub_pdir 'FDG_FU_2\'];
%     FDG3_rename = [stu_sub '_FDG-PET_FU_2.nii'];
%     if exist(FDG3_pdir) == 0; % Check if additional follow-up FDG directory exists, create
%         disp('Creating Additional follow-up FDG processing directory ...');
%         mkdir(FDG3_pdir);
%         mkdir(FDG3_ndir);
%         disp('Copying Additional FDG Follow-up PET ...');
%         copyfile(FDG3_dir, FDG3_pdir);
%         wdir = FDG3_pdir;
%         odir = FDG3_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting Additional FDG Follow-up PET DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         FDG3_name = dir('*.nii');
%         FDG3_name = FDG3_name(1).name;
%         movefile(FDG3_name, FDG3_rename);
%         disp('Finished converting Additional FDG Follow-up PET DICOM to NIfTI ...');
%     else disp('Additional follow-up FDG directory already exists.'); 
%         disp('Copying Additional FDG Follow-up PET ...');
%         copyfile(FDG3_dir, FDG3_pdir);
%         wdir = FDG3_pdir;
%         odir = FDG3_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting Additional FDG Follow-up PET DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         FDG3_name = dir('*.nii');
%         FDG3_name = FDG3_name(1).name;
%         movefile(FDG3_name, FDG3_rename);
%         disp('Finished converting Additional FDG Follow-up PET DICOM to NIfTI ...');
%     end
% end
% 
% %% Make Baseline MRI directory, copy DICOM files
% if strcmp(scans_available(4),'yes'),
%     if strcmp(scans_available(5),'no'), % Create MRI processing directory
%         MR1_pdir = [DICOM_pdir 'MRI\'];
%         MR1_ndir = [sub_pdir 'MRI\'];
%         MR1_rename = [stu_sub '_MRI.nii'];
%     else MR1_pdir = [DICOM_pdir 'MRI_BL\'];
%          MR1_ndir = [sub_pdir 'MRI_BL\'];
%          MR1_rename = [stu_sub '_MRI_BL.nii'];
%     end
%     if exist(MR1_pdir) == 0; % Check if MRI directory exists, create
%         disp('Creating baseline MRI processing directory ...');
%         mkdir(MR1_pdir);
%         mkdir(MR1_ndir);
%         disp('Copying MRI ...');
%         copyfile(MR1_dir, MR1_pdir);
%         wdir = MR1_pdir;
%         odir = MR1_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting MRI DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         MR1_name = dir('*.nii');
%         MR1_name = MR1_name(1).name;
%         movefile(MR1_name, MR1_rename);
%         disp('Finished converting MRI DICOM to NIfTI ...');
%     else disp('Baseline MRI directory already exists.'); 
%         disp('Copying MRI ...');
%         copyfile(MR1_dir, MR1_pdir);
%         wdir = MR1_pdir;
%         odir = MR1_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting MRI DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         MR1_name = dir('*.nii');
%         MR1_name = MR1_name(1).name;
%         movefile(MR1_name, MR1_rename);
%         disp('Finished converting MRI DICOM to NIfTI ...');
%     end
% end
% 
% % Make MRI Follow-up directory and copy frames
% if strcmp(scans_available(5),'yes'),
%     MR2_pdir = [DICOM_pdir 'MRI_FU\']; % Create follow-up MRI processing directory
%     MR2_ndir = [sub_pdir 'MRI_FU\'];
%     MR2_rename = [stu_sub '_MRI_FU.nii'];
% 
%     if exist(MR2_pdir) == 0; % Check if follow-up MRI directory exists, create
%         disp('Creating Follow-up MRI processing directory ...');
%         mkdir(MR2_pdir);
%         mkdir(MR2_ndir);
%         disp('Copying MRI Follow-up ...');
%         copyfile(MR2_dir, MR2_pdir);
%         wdir = MR2_pdir;
%         odir = MR2_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting Follow-up MRI DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         MR2_name = dir('*.nii');
%         MR2_name = MR2_name(1).name;
%         movefile(MR2_name, MR2_rename);
%         disp('Finished converting Follow-up MRI DICOM to NIfTI ...');
%     else disp('Follow-up MRI directory already exists.'); 
%         disp('Copying MRI Follow-up ...');
%         copyfile(MR2_dir, MR2_pdir);
%         wdir = MR2_pdir;
%         odir = MR2_ndir;
%         dicom_series = wdir;
%         mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
%         outdir = [dicom_series 'temp'];
%         outdir_mcvert = outdir;
%         disp('Converting Follow-up MRI DICOM to NIfTI ...');
%         data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);
%         allSubFolders = genpath(wdir);
%         remain = allSubFolders;
%         listOfFolderNames = {};
%         while true,
%             [singleSubFolder, remain] = strtok(remain, ';');
%             if isempty(singleSubFolder), 
%                 break; 
%             end
%         listOfFolderNames = [listOfFolderNames singleSubFolder];
%         end
%         for k = 1 : length(listOfFolderNames)
%             filePattern = [listOfFolderNames{k}, '\*.nii'];
%         end
%         NiiFolder = listOfFolderNames{k};
%         cd (NiiFolder);
%         copyfile('*.nii', odir);
%         cd (odir);
%         MR2_name = dir('*.nii');
%         MR2_name = MR2_name(1).name;
%         movefile(MR2_name, MR2_rename);
%         disp('Finished converting Follow-up MRI DICOM to NIfTI ...');
%     end
% end
% clear wdir
% clear odir
% clear nifti_series
% clear dicom_series
% clear outdir
% clear outdir_mcvert
% clear data_conv
% clear rename
% clear listOfFolderNames
% clear NiiFolder
% clear allSubFolders
% clear filePattern
% clear remain
% clear FDG1_name
% clear FDG2_name
% clear FDG3_name
% clear MR1_name
% clear MR2_name
% clear singleSubFolder
% clear mriconvert
% clear tracer_name
% clear tracer_time
% clear k
% 
% %% Store processing status and stop SPA
% fid = fopen([IM_dir '\' stu_sub '\' stu_sub '_processing-status.txt'],'w');
% fwrite(fid,'1');
% fclose('all');
% disp('All raw DICOM data has been converted to NIfTI. Now starting SUV calculation.');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %   Calculate SUV
% 
% 
% %% PROCESSING STEP TWO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if strcmp(scans_available(1),'yes'),
%     if strcmp(scans_available(2),'no'),
%         NIfTI_FILE = strcat(FDG1_ndir, FDG1_rename);
%         SUV_FDG1 = [stu_sub '_FDG_SUV.nii'];
%         SUV_FILE = strcat(FDG1_ndir, SUV_FDG1);
%     else
%         NIfTI_FILE = strcat(FDG1_ndir, FDG1_rename);
%         SUV_FDG1 = [stu_sub '_FDG_BL_SUV.nii'];
%         SUV_FILE = strcat(FDG1_ndir, SUV_FDG1);
%     end
%     dose = FDG1DoseBMI{1};
%     bmi = FDG1DoseBMI{2};
%     equ = ['(i1*.001)/(' dose '/' bmi ')'];
%     n = size(NIfTI_FILE,1);
%     for file_num = 1:n
%         FILE = deblank(NIfTI_FILE(file_num,:));
%         FILES = cell(1);
%         FILES{1} = FILE ;
%         P= char(FILES);
%     end
%     %  FORMAT Q = spm_imcalc_ui(P,Q,f,flags,Xtra_vars...)
%     SUV_calc = spm_imcalc_ui(P,SUV_FILE,equ);
% end
% 
% if strcmp(scans_available(2),'yes'),
%     NIfTI_FILE = strcat(FDG2_ndir, FDG2_rename);
%     SUV_FDG2 = [stu_sub '_FDG_FU_SUV.nii'];
%     SUV_FILE = strcat(FDG2_ndir, SUV_FDG2);
%     dose = FDG2DoseBMI{1};
%     bmi = FDG2DoseBMI{2};
%     equ = ['(i1*.001)/(' dose '/' bmi ')'];
%     n = size(NIfTI_FILE,1);
%     for file_num = 1:n
%         FILE = deblank(NIfTI_FILE(file_num,:));
%         FILES = cell(1);
%         FILES{1} = FILE ;
%         P= char(FILES);
%     end
%     %  FORMAT Q = spm_imcalc_ui(P,Q,f,flags,Xtra_vars...)
%     SUV_calc = spm_imcalc_ui(P,SUV_FILE,equ);
% end
% 
% if strcmp(scans_available(3),'yes'),
%     NIfTI_FILE = strcat(FDG3_ndir, FDG3_rename);
%     SUV_FDG3 = [stu_sub '_FDG_FU-2_SUV.nii'];
%     SUV_FILE = strcat(FDG3_ndir, SUV_FDG3);
%     dose = FDG3DoseBMI{1};
%     bmi = FDG3DoseBMI{2};
%     equ = ['(i1*.001)/(' dose '/' bmi ')'];
%     n = size(NIfTI_FILE,1);
%     for file_num = 1:n
%         FILE = deblank(NIfTI_FILE(file_num,:));
%         FILES = cell(1);
%         FILES{1} = FILE ;
%         P= char(FILES);
%     end
%     %  FORMAT Q = spm_imcalc_ui(P,Q,f,flags,Xtra_vars...)
%     SUV_calc = spm_imcalc_ui(P,SUV_FILE,equ);
% end
% 
% %% Store processing status and stop SPA
% fid = fopen([IM_dir '\' stu_sub '\' stu_sub '_processing-status.txt'],'w');
% fwrite(fid,'2');
% fclose('all');
% disp('SUV Calculation(s) DONE!');
% uiwait(msgbox('DONE!','FDG Automated Pipeline'));
% 
% %% PROCESSING STEP THREE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % if proc_step == 2
% 
% cd (proc_SUV);
% clear, clc
end