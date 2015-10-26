function [scan_dir] = get_datadir(sub,tracer_name,tracer_time,start_dir,silent)
%
%        Kinetic Modeling Pipeline
%        get_datadir
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Chrisotpher H. Lyman, Clifford Workman
%
%        Usage: get_datadir
%
%        This function stores scan directories.

%% Declare required variables, if not already declared
if nargin < 3,
    [pth] = fileparts(which('spa'));
    [~,~,raw]=xlsread([pth '\spa_ini.xlsx'],'Dirs and Paths'); % This extracts the subject numbers and directories from the batch file
    dirs_paths = raw; clear raw;
    start_dir = cell2mat(dirs_paths(find(strcmp(dirs_paths,'Home directory')>0),2));
end

%% Get scan directory
uiwait(msgbox(['Please select ' tracer_time tracer_name ' directory.'],'Semi-Quan'));
scan_dir = uigetdir(start_dir,['Select ' tracer_time tracer_name ' directory.']);
% if findstr(sub, scan_dir) & findstr(tracer_name, scan_dir);  % Checks if subject number and tracer name are in baseline path
%     disp(['Subject number found in path, looks like ' tracer_time tracer_name ' directory.']);
% elseif strcmp(silent, 'yes'); disp(['Subject number not found in directory, or does not look like ' tracer_time tracer_name ' directory. Continuing anyway.']);
% else
%     check_dir = questdlg(['Subject number not found in path, or does not look like ' tracer_time tracer_name ' directory. Continue?'], ...
%                         'FDG Automated Pipeline', 'Yes', 'Change Dir', 'Abort', 'Abort');
%     switch check_dir
%         case 'Yes'
%             disp(['Subject number not found in directory, or does not look like ' tracer_time tracer_name ' directory. Continuing anyway.']);
%         case 'Change Dir'
%             scan_dir = uigetdir(start_dir,['Select ' tracer_time tracer_name ' directory.']);
%             uiwait(msgbox('Warning: I did not check your work this time.','Warning message','warn'));
%         case 'Abort'
%             disp(['Directory for ' tracer_time tracer_name ' incorrect. Terminating.']);
%             return
%     end
% end
end