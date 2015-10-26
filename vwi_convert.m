function spa_convert()
%
%        Static PET Analysis Pipeline
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
cd(pth);
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

%% Define Dirs and set SPM8 path
uiwait(msgbox('Please select the directory to process the data.','SPA'));
proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');
while true
    try spm_rmpath;
    catch break;
    end
end
addpath(spm8_path);
clc

%% Prompt for study and number of subjects
stdysubnum = get_stdysubnum;
stdy = stdysubnum{1};
subnum = stdysubnum{2};
for i=1:1:str2double(subnum);
    subinfo = get_subinfo(i);
    sub = subinfo{1};
    MRInum1 = subinfo{2};
    FDGnum1 = subinfo{3};
    MRInum = str2double(MRInum1);
    FDGnum = str2double(FDGnum1);
    stu_sub = [stdy '-' sub];
    eval(sprintf('sub_%d = sub;',i));
    eval(sprintf('MRInum_%d = MRInum;',i));
    eval(sprintf('FDGnum_%d = FDGnum;',i));
    eval(sprintf('stu_sub_%d = stu_sub;',i));
end
clear FDGnum1;
clear stdysub;
clear MRInum1;

%% Prompt to select MRI scans
for i=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',i));
    stu_sub = [stdy '-' sub];
    MRInum = eval(sprintf('MRInum_%d',i));
    if MRInum > 0,
        for k = 1:1:MRInum;
            msg1 = ('Please select the folder which contains the T1 MRI scan number ');
            msg2 = (' for ');
            msg = [sprintf('%s%d%s%s', msg1,k,msg2,stu_sub)];
            MRI_prefix = [stu_sub '_MRI_'];
            MRI_name = [sprintf('%s%d',MRI_prefix,k)];
            uiwait(msgbox(msg,'SPA'));
            MRI_dir = uigetdir(proc_dir,msg);
            eval(sprintf('sub_%d_MRI_%d = MRI_dir;',i,k));
        end
    end
end
%% Prompt to select FDG scans
for i=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',i));
    stu_sub = [stdy '-' sub];
    FDGnum = eval(sprintf('FDGnum_%d',i));
    if FDGnum > 0,
        for k = 1:1:FDGnum;
            msg1 = ('Please select the folder which contains the Attenuated Corrected FDG scan number ');
            msg2 = (' for ');
            msg = [sprintf('%s%d%s%s', msg1,k,msg2,stu_sub)];
            FDG_prefix = [stu_sub '_FDG_'];
            FDG_name = [sprintf('%s%d',FDG_prefix,k)];
            uiwait(msgbox(msg,'SPA'));
            FDG_dir = uigetdir(proc_dir,msg);
            eval(sprintf('sub_%d_FDG_%d = FDG_dir;',i,k));
        end
    end
end
clear msg;
clear msg1;
clear msg2;

sub_pdir = [proc_dir '\' stu_sub]; % Create NIfTI processing directories
FDGname = ('_FDG-PET_');
MRname = ('_MR-MPRAGE_');
scantotal = FDGnum+MRInum;

h=waitbar(0,'Converting FDG DICOM...'); % Progress bar

%% Convert FDG data
for i=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',i));
    stu_sub = [stdy '-' sub];
    FDGnum = eval(sprintf('FDGnum_%d',i));
    if FDGnum > 1,
        for k = 1:1:FDGnum;
            OutFileName = [sprintf('%s%s%d',stu_sub,FDGname,k)];
            DICOM_proc = eval(sprintf('FDG_%d',k));
            currentFDG = (sprintf('FDG_%d',k));
            disp(sprintf('%s%s','Converting ', currentFDG));
            out_pdir = [sub_pdir '\' currentFDG];
            cd(proc_dir);
            mkdir(out_pdir);
            Arman_automated(DICOM_proc,OutFileName,out_pdir);
            waitbar(k/scantotal);
        end
    end
end
close(h)
h=waitbar(0,'Converting MRI DICOM...'); % Progress bar
%% Convert MRI data
for i=1:1:str2double(subnum);
    sub = eval(sprintf('sub_%d',i));
    stu_sub = [stdy '-' sub];
    MRInum = eval(sprintf('MRInum_%d',i));
    if MRInum > 1,
        for k = 1:1:MRInum;
            OutFileName = [sprintf('%s%s%d',stu_sub,MRname,k)];
            DICOM_proc = eval(sprintf('MRI_%d',k));
            currentMRI = (sprintf('MRI_%d',k));
            disp(sprintf('%s%s','Converting ', currentMRI));
            out_pdir = [sub_pdir '\' currentMRI];
            cd(proc_dir);
            mkdir(out_pdir);
            mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
            data_conv = system([mriconvert ' /o ' out_pdir ' /f nifti /x /n --nii /u ' DICOM_proc]);
            waitbar((k+FDGnum)/scantotal);
        end
    end
end

close(h)

clear, clc
close all;

disp('DONE!');

end