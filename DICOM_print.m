function DICOM_print()
%
%        Semi-Quantitative PET Analysis
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: DICOM_print()
%
%        Example directories for :
%        FDG:
%
%        It is suggested to start FAP using either of the following
%        commands:
%        >> fap
%        >> fap(sub)
%% Ensure SPM8 path has been added, define home directory %%%%%%%%%%%%%%%%
%                                                                        %
% Code to remove/add SPM paths developed by K-lab:                       %
% http://www.nemotos.net/?p=21                                           %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pth] = fileparts(which('spa'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

%% Define dirs and set SPM8 path
while true
    try spm_rmpath;
    catch break;
    end
end
addpath(spm8_path);
clc

%% Prompt for Directory to process and define all subdirectories.
uiwait(msgbox('Please select directory you would like to analyze.','SPA'));
proc_dir = uigetdir(home_dir, 'Select directory you would like to analyze..');


msg = ('Please select DICOM File...');
[DICOM_file,status] = spm_select(1:1,'any', msg ,[],proc_dir,'.*');
[pathstr, name, ext, versn] = fileparts(DICOM_file);
name = [pathstr '\' name ext];

if isdicom(name) == 1
    info = dicominfo(name)
else
    while isdicom(name) == 0
        msg = ('Please select DICOM File...');
        [DICOM_file,status] = spm_select(1:1,'any', msg ,[],anal_dir,'.*');
        [pathstr, name, ext, versn] = fileparts(DICOM_file);
    end
end

end