function DICOM_hdr()
%
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman and Clifford Workman
%
%        Usage: DICOM_hdr;
%
%       You will be prompted to select a directory to process. This
%       program will sort through this directory and any subdirectories
%       looking for DICOM files. When it finds DICOM files it will read the
%       DICOM header information using Matlab's dicominfo function and
%       print an excel file with useful information and place it in that
%       directory under the name DICOM.xlsx.
%
%
%% Ensure SPM8 path has been added, define home directory %%%%%%%%%%%%%%%%
%                                                                        %
% Code to remove/add SPM paths developed by K-lab:                       %
% http://www.nemotos.net/?p=21                                           %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));

%% Prompt for Directory to process and define all subdirectories.
uiwait(msgbox('Please select directory you would like to analyze.','VWI'));
proc_dir = uigetdir(home_dir, 'Select directory you would like to analyze..');
allSubFolders = genpath(proc_dir);
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

%% Get DICOM header info
tic; % Start Timer.
for j = 1:1:listOfFoldercols, %Loop through subfolders
    count = [num2str(j), ' of ', num2str(listOfFoldercols), ' Folders'];
    disp(count);
    list = ls(listOfFolderNames{j}); %list folder contents
    pwd = listOfFolderNames{j};
    listrows = size(list,1);
    IM_rows = (listrows - 2);
    emptyCell = cell(IM_rows,26);
    struct = dir(listOfFolderNames{j});
    h=waitbar(0,'Processing...DICOM information.'); % Progress bar
    for k = 3:1:listrows; %Loop through folder contents
        isdir = struct(k).isdir;
        if isdir == 0,
            name = struct(k).name;
            name = [pwd '\' name];
            if isdicom(name) == 1,
                info = dicominfo(name); %Matlab function that reads DICOM headers
                %info = spm_dicom_headers(name); SPM8's version of dicominfo
                %function. Problem with dates and times.
                if isfield(info,'Filename') == 1,
                    Filename = info.Filename;
                    [~, name, ext] = fileparts(Filename(1,:));
                    emptyCell{k-1,1} = name;
                end
                if isfield(info,'StudyDate') == 1,
                    StudyDate = info.StudyDate;
                    emptyCell{k-1,2} = StudyDate;
                end
                if isfield(info,'Modality') == 1,
                    Modality = info.Modality;
                    emptyCell{k-1,3} = Modality;
                end
                if isfield(info,'SeriesDescription') == 1,
                    SeriesDescription = info.SeriesDescription;
                    emptyCell{k-1,4} = SeriesDescription;
                end
                if isfield(info,'ImagesInAcquisition') == 1,
                    NumberofSlices = info.ImagesInAcquisition;
                    emptyCell{k-1,5} = NumberofSlices;
                elseif isfield(info,'NumberOfSlices') == 1,
                    NumberOfSlices = info.NumberOfSlices;
                    emptyCell{k-1,5} = NumberOfSlices;
                end
                if isfield(info,'Width') == 1,
                    Width = info.Width;
                    emptyCell{k-1,6} = Width;
                end
                if isfield(info,'Height') == 1,
                    Height = info.Height;
                    emptyCell{k-1,7} = Height;
                end
                if isfield(info,'Manufacturer') == 1,
                    Manufacturer = info.Manufacturer;
                    emptyCell{k-1,8} = Manufacturer;
                end
                if isfield(info,'SliceThickness') == 1,
                    Xaxis = info.SliceThickness;
                    emptyCell{k-1,9} = Xaxis;
                end
                if isfield(info,'PixelSpacing') == 1,
                    YZaxis = [info.PixelSpacing];
                    Yaxis = YZaxis(1);
                    Zaxis = YZaxis(2);
                    emptyCell{k-1,10} = Yaxis;
                    emptyCell{k-1,11} = Zaxis;
                end
                if isfield(info,'RadiopharmaceuticalInformationSequence') == 1,
                    Rad_struct = info.RadiopharmaceuticalInformationSequence;
                    Rad_switch = struct2cell(Rad_struct);
                    Rad_cell = Rad_switch{1};
                    if isfield(Rad_cell, 'RadionuclideTotalDose');
                        Rad_Dose = Rad_cell.RadionuclideTotalDose;
                        emptyCell{k-1,13} = Rad_Dose;
                        eval(sprintf('Rad_Dose%d = Rad_Dose;', j));
                    end
                    if isfield(Rad_cell, 'Radiopharmaceutical');
                        Rad_Pharm = Rad_cell.Radiopharmaceutical;
                        if strcmp(char(Rad_Pharm), 'Fluorodeoxyglucose')
                            Rad_Pharm = ('FDG');
                        end
                        emptyCell{k-1,11} = Rad_Pharm;
                        eval(sprintf('Rad_Pharm%d = Rad_Pharm;', j));
                    elseif isfield(info, 'MagneticFieldStrength') == 1,
                        MagFieldStrength = info.MagneticFieldStrength;
                        emptyCell{k-1,12} = MagFieldStrength;
                    end
                    if isfield(Rad_cell, 'RadiopharmaceuticalStartTime');
                        RadStartTime = Rad_cell.RadiopharmaceuticalStartTime;
                        emptyCell{k-1,15} = RadStartTime;
                        eval(sprintf('RadStartTime%d = RadStartTime;', j));
                    end
                end
                if isfield(info,'Units') == 1,
                    Units = info.Units;
                    emptyCell{k-1,14} = Units;
                end
                if isfield(info,'ActualFrameDuration') == 1,
                    FrameDuration = info.ActualFrameDuration;
                    emptyCell{k-1,16} = FrameDuration;
                end
                if isfield(info,'AcquisitionTime') == 1,
                    AcquisitionTime = info.AcquisitionTime;
                    emptyCell{k-1,17} = AcquisitionTime;
                end
                if isfield(info,'RescaleSlope') == 1,
                    RescaleSlope = info.RescaleSlope;
                    emptyCell{k-1,18} = RescaleSlope;
                end
                if isfield(info,'RescaleIntercept') == 1,
                    RescaleIntercept = info.RescaleIntercept;
                    emptyCell{k-1,19} = RescaleIntercept;
                end
                if isfield(info,'PatientAge') == 1,
                    PatientAge = info.PatientAge;
                    emptyCell{k-1,20} = PatientAge;
                end
                if isfield(info,'PatientWeight') == 1,
                    PatientWeight = info.PatientWeight;
                    emptyCell{k-1,21} = PatientWeight;
                end
                if isfield(info,'PatientSex') == 1,
                    PatientSex = info.PatientSex;
                    emptyCell{k-1,22} = PatientSex;
                end
                if isfield(info,'PatientSize') == 1,
                    Height = info.PatientSize;
                    emptyCell{k-1,23} = Height;
                end
                if isfield(info,'ReconstructionMethod') == 1,
                    ReconstructionMethod = info.ReconstructionMethod;
                    emptyCell{k-1,24} = ReconstructionMethod;
                end
                if isfield(info,'EchoTime') == 1,
                    EchoTime = info.EchoTime;
                    emptyCell{k-1,25} = EchoTime;
                end
                if isfield(info,'RepetitionTime') == 1,
                    RepetitionTime = info.RepetitionTime;
                    emptyCell{k-1,26} = RepetitionTime;
                end
                waitbar(k/listrows);
            end
        end
    end
    eval(sprintf('emptyCell%d = emptyCell;', j));
    IDX = find(~cellfun('isempty', emptyCell));
    D = size(IDX,1);
    if D ~= 0,
        for ii = 2:1:size(IDX,2);
            X = emptyCell(ii);
            if isempty(X) == 1,
                emptyCell(ii,:) = [];
            end
        end
        emptyCell{1,1} = ('Filename');
        emptyCell{1,2} = ('Study Date');
        emptyCell{1,3} = ('Modality');
        emptyCell{1,4} = ('Description');
        emptyCell{1,5} = ('Number of Slices');
        emptyCell{1,6} = ('Scan Width');
        emptyCell{1,7} = ('Scan Height');
        emptyCell{1,8} = ('Manufacturer');
        emptyCell{1,9} = ('X-axis');
        emptyCell{1,10} = ('Y-axis');
        emptyCell{1,11} = ('Z-axis');
        emptyCell{1,12} = ('Field Strength');
        emptyCell{1,13} = ('Dose');
        emptyCell{1,14} = ('Units');
        emptyCell{1,15} = ('Rad Start Time');
        emptyCell{1,16} = ('Frame Duration');
        emptyCell{1,17} = ('Acquisition Time');
        emptyCell{1,18} = ('Rescale Slope');
        emptyCell{1,19} = ('Rescale Intercept');
        emptyCell{1,20} = ('Patient Age');
        emptyCell{1,21} = ('Patient Weight');
        emptyCell{1,22} = ('Patient Sex');
        emptyCell{1,23} = ('Patient Height');
        emptyCell{1,24} = ('Reconstruction Method');
        emptyCell{1,25} = ('EchoTime');
        emptyCell{1,26} = ('RepetitionTime');
        
        %             textfile = [pwd '\DICOM.txt'];
        %             fid = fopen(textfile, 'wt');
        %             fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', emptyCell{:,:});
        %             fclose(fid);
        [x]=xlswrite([pwd '\DICOM.xlsx'],emptyCell(:,:));
    end
close(h)    
end

clc

toc
disp('DONE!');

end