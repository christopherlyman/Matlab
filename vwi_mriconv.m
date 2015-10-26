function data_conv = mriconv()
%
%        mriconvert
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman
%
%        Usage: mriconv
%
%        In the directory selector that appears, choose the directory
%        containing the DICOM files to be converted. This launches
%        MRIConvert within MATLAB. The resulting NIfTI files will be moved
%        to a NIfTI subdirectory within the DICOM directory. Example below:
%
%        If you select this directory:
%        ~\1001\05-21-09_MRI\MR\
%
%        ... it will generate the following outputs:
%        ~\1001\05-21-09_MRI\MR\NIfTI_02-02-12\*\*.nii
%        ... where the date appended to the folder is today's date.

%% Select DICOM series for MRIConvert
[pth] = fileparts(which('spa'));
[~,~,raw]=xlsread([pth '\spa_ini.xlsx'],'Dirs and Paths');
dirs_paths = raw; clear raw;
home_dir = cell2mat(dirs_paths(find(strcmp(dirs_paths,'Home directory')>0),2));

nifti_series = [odir];
dicom_series = [wdir];
mriconvert = '"C:\Program Files (x86)\MRIconvert\mcverter"';
outdir = [dicom_series 'temp'];
outdir_mcvert = [outdir];
data_conv = system([mriconvert ' /o ' outdir_mcvert ' /f nifti /x /n --nii /u ' dicom_series]);

dir_date = datevec(date); 
yy = num2str(dir_date(1,1)); 
mm = num2str(dir_date(1,2)); 
dd = num2str(dir_date(1,3)); 
if str2num(mm) < 10, 
    mm = ['0' mm]; 
end; 
if str2num(dd) < 10,
    dd = ['0' dd];
end;
yy = yy(1,end-1:end);
dir_date = [mm '-' dd '-' yy];
rename = dir([dicom_series 'temp']);
movefile([dicom_series 'temp\' rename(3).name],[odir 'NIfTI_' dir_date '\']);
rmdir([dicom_series 'temp']);
end