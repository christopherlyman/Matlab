function [FDG_dir,MRI_dir] = get_RAWdir(sub,stdy,FDGnum,MRInum,home_dir)
%
%        FDG Automated Pipeline
%        get_RAWdir
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Christopher Lyman, Cliff Workman, & Dr. Kentaro Hirao
%
%        Usage: [FDG1_dir,IM_dir] = get_RAWdir(sub);
%
%        sub: subject number
%
%        This function stores the MR and Image directories for a given
%        participant. To get both directories, type:
%        >> [FDG1_dir,IM_dir] = get_RAWdir(sub);
%        For FDG1_dir only, type: >> get_RAWdir(sub);
%        For IM_dir only, type: >> [~,IM_dir] = get_RAWdir(sub);

%% Declare required variables, if not already declared
if nargin < 1, sub = get_stdysub; end
[pth] = fileparts(which('spa'));
[~,~,raw]=xlsread([pth '\spa_ini.xlsx'],'Dirs and Paths');
dirs_paths = raw; clear raw;
home_dir = cell2mat(dirs_paths(find(strcmp(dirs_paths,'Home directory')>0),2));


%% Get MR
if MRInum > 0,
    for i = 1:1:MRInum;
        msg1 = ('Please select MRI number ');
        msg2 = (' raw DICOM data');
        msg = [sprintf('%s%d%s', msg1,i,msg2)]
        MRI_prefix = ('MRI_');
        MRI_name = [sprintf('%s%d',MRI_prefix,i)]
        uiwait(msgbox(msg,'SPA'));
        MRI_dir = uigetdir(proc_SUV,'Select MRI raw DICOM directory.');
        eval(sprintf('MRI_%d = MRI_dir;',i));
    end
end
%% Get FDG
if FDGnum > 0,
    for i = 1:1:FDGnum;
        msg1 = ('Please select FDG number ');
        msg2 = (' raw DICOM data');
        msg = [sprintf('%s%d%s', msg1,i,msg2)]
        FDG_prefix = ('FDG_');
        FDG_name = [sprintf('%s%d',FDG_prefix,i)]
        uiwait(msgbox(msg,'SPA'));
        FDG_dir = uigetdir(proc_SUV,'Select FDG raw DICOM directory.');
        eval(sprintf('FDG_%d = FDG_dir;',i));
    end
end