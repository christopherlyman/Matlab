function DICOM_organize(anal_dir, emptyCell, struct, Filename, Modality, SeriesDescription, NumberofSlices, Rad_Dose, Rad_Pharm, StudyDate, PatientSex, PatientAge, PatientWeight)
%
%        Semi-Quantitative PET Analysis
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: fap(sub,MR_dir)
%
%        sub: subject number
%        MR_dir: directory containing subject's original MRI scan
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
cd(pth);
home_dir = char(textread([pth '\home_dir.txt'],'%s'));

%% Define dirs and set SPM8 path
% spm8_path = dirs_paths(strcmp(dirs_paths,'SPM8 path')>0,2);
% while true
%     try spm_rmpath;
%     catch
%         break;
%     end
% end
% addpath(cell2mat(spm8_path));
% clc

%% Prompt for Directory to process and define all subdirectories.

stdysub = get_stdysub;
stdy = stdysub{1};
subnum = stdysub{2};

uiwait(msgbox('Please select directory you would like to analyze.','SPA'));
anal_dir = uigetdir(home_dir, 'Select directory you would like to analyze..');
allSubFolders = genpath(anal_dir);
remain = allSubFolders;
listOfFolderNames = {};
while true,
    [singleSubFolder, remain] = strtok(remain, ';');
    if isempty(singleSubFolder),
        break;
    end
    listOfFolderNames = [listOfFolderNames singleSubFolder];
end
listOfFoldercols = size(listOfFolderNames,2);

DICOM_dir = [anal_dir '\' stdy '-' subnum];
if exist(DICOM_dir) == 0, mkdir(DICOM_dir);
end

%% Get DICOM header info
tic; % Start Timer.
for j = 1:1:listOfFoldercols, %Loop through subfolders
    count = [num2str(j), ' of ', num2str(listOfFoldercols), ' Folders'];
    disp(count);
    list = ls(listOfFolderNames{j}); %list folder contents
    cd (listOfFolderNames{j});
    pwd = listOfFolderNames{j};
    listrows = size(list,1);
    listcols = size(list,2);
    IM_rows = (listrows - 2);
    emptyCell = cell(IM_rows,1);
    struct = dir(listOfFolderNames{j});
    %     h=waitbar(0,'Processing...DICOM information.'); % Progress bar
    for k = 3:1:listrows; %Loop through folder contents
        isdir = struct(k).isdir;
        if isdir == 0,
            name = struct(k).name;
            if isdicom(name) == 1,
                info = dicominfo(name); %Matlab function that reads DICOM headers
                %info = spm_dicom_headers(name); SPM8's version of dicominfo
                %function. Problem with dates and times.
                if isfield(info,'Filename') == 1,
                    Filename = info.Filename;
                    emptyCell{k-2,1} = Filename;
                end
                %                 if isfield(info,'StudyDate') == 1,
                %                     StudyDate = info.StudyDate;
                %                     emptyCell{k-2,2} = StudyDate;
                %                 end
                %                 if isfield(info,'Modality') == 1,
                %                     Modality = info.Modality;
                %                     emptyCell{k-2,3} = Modality;
                %                 end
                %                 if isfield(info,'SeriesDescription') == 1,
                %                     SeriesDescription = info.SeriesDescription;
                %                     emptyCell{k-2,4} = SeriesDescription;
                %                 end
                %                 waitbar(k/listrows);
            end
        end
    end
    empties = find(cellfun(@isempty,emptyCell)); % identify the empty cells
    emptyCell(empties) = [];                     % remove the empty cells
    if size(emptyCell,1) == 0 || size(emptyCell,2) == 0,
        cell_size = 0;
    else
        cell_size = size(emptyCell,1);
    end
    fullCell = cell(cell_size,4);
    for k = 1:1:cell_size; %Loop through folder contents
        name = emptyCell{k};
        info = dicominfo(name); %Matlab function that reads DICOM headers
        %info = spm_dicom_headers(name); SPM8's version of dicominfo
        %function. Problem with dates and times.
        if isfield(info,'Filename') == 1,
            Filename = info.Filename;
            fullCell{k,1} = Filename;
        end
        if isfield(info,'StudyDate') == 1,
            StudyDate = info.StudyDate;
            fullCell{k,2} = StudyDate;
            stdyDa = regexprep(StudyDate,'[^\w'']','');
        end
        if isfield(info,'Modality') == 1,
            Modality = info.Modality;
            fullCell{k,3} = Modality;
            Mod = regexprep(Modality,'[^\w'']','');
            Mod_dir = [DICOM_dir '\' Mod];
            if exist(Mod_dir) == 0,
                mkdir(Mod_dir);
            end
        else
            Mod_dir = [DICOM_dir '\Unknown'];
        end
        if isfield(info,'SeriesDescription') == 1,
            SeriesDescription = info.SeriesDescription;
            fullCell{k,4} = SeriesDescription;
            SeriesDes = regexprep(SeriesDescription,'[^\w'']','');
        end
        
        if isfield(info,'Modality') == 0,
            if isfield(info,'StudyDate') == 1,
                Mod_dir = [DICOM_dir '\' stdyDa];
                if exist(Mod_dir) == 0,
                    mkdir(Mod_dir);
                end
            else
                if isfield(info,'SeriesDescription') == 1,
                    Mod_dir = [DICOM_dir '\' SeriesDes];
                    if exist(Mod_dir) == 0,
                        mkdir(Mod_dir);
                    end
                end
                if exist(Mod_dir) == 0;
                    Mod_dir = [DICOM_dir '\Unknown'];
                    mkdir(Mod_dir);
                end
            end
        end
        if isfield(info,'Modality') == 1 && isfield(info,'StudyDate') == 1,
            Scan_dir = [Mod_dir '\' stdyDa];
            if exist(Scan_dir) == 0,
                mkdir(Scan_dir);
            end
        elseif isfield(info,'Modality') == 1 && isfield(info,'SeriesDescription') == 1,
            Scan_dir = [Mod_dir '\' SeriesDes];
            if exist(Scan_dir) == 0,
                mkdir(Scan_dir);
            end
        else
            Scan_dir = [Mod_dir '\Unknown'];
            mkdir(Scan_dir);
        end
        
        if isfield(info,'SeriesDescription') == 1,
            Ser_dir = [Scan_dir '\' SeriesDes];
            if exist(Ser_dir) == 0,
                mkdir(Ser_dir);
            end
        else
            Ser_dir = [Scan_dir '\Unknown'];
            mkdir(Ser_dir);
        end
        
        DICOM_orig = [pwd '\' Filename];
        DICOM_new = [Ser_dir '\' Filename];
        copyfile(DICOM_orig,DICOM_new);
        
        clear Mod_dir Scan_dir Ser_dir
        
        %                 waitbar(k/listrows);
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    % Need to create folders with series descirption and copy DICOM data
    % into folders.
    
    eval(sprintf('fullCell%d = fullCell;', j));
    
%     close(h)
end
clc

toc
disp('DONE!');

end