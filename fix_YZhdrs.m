function fix_YZhdrs(pimdir,home_dir)
%
%        Kinetic Modeling Pipeline
%        fix_phdrs
%        Copyright (C) 2014 Johns Hopkins University
%        Software by Christopher Lyman & Clifford Workman
%
%        Usage: fix_YZhdrs(pimdir)
%
%        pimdir: directory containing parametric images manually renamed to
%        replace participant names with subject numbers.
%
%        Script to fix headers for parametric images returned from Yun
%        Zhou's software. The software assumes you've manually renamed the
%        image and header files (ex: to "1001_PIB_srtmLRSC_DVR.img").
%        Since this is fairly simple to do manually, I didn't want to spend
%        the time coding a function to do this automatically. For an example
%        of how a directory inputted into "fix_phdrs" should look, check
%        here:
%        ~\Processed_Images\PET_Data\Processing\Parametric_Images_Backup\
%
%        After the data are renamed, this script will sort the images into
%        separate directories and then fix the headers, prefixing the new
%        files with an "h" and removing "raw" from the file names.

%% Get directory with parametric images
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

proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

uncorrect_dir = uigetdir(proc_dir, 'Select the directory containing uncorrected header images..');

dynamic_dir = uigetdir(proc_dir, 'Select the directory containing dynamic frame images..');


msg = ('Please select YZ''s uncorrected header images.');
uncorrected = spm_select(Inf,'image', msg ,[],uncorrect_dir,'\.(nii|img)$');
clear msg;


msg = ('Please select any resliced dynamic frame image for each uncorrected header image and in the same order.');
dynamic = spm_select(Inf,'image', msg ,[],dynamic_dir,'\.(nii|img)$');
clear msg;




%% Fix PIB headers
if isempty(pib_pimgs) == 0,
    read_orig = spm_vol(orig_pibimgs);
    for j=1:size(pib_pimgs,1),
        current_vol = [pimdir sub_array(i,:) '\' deblank(pib_pimgs(j,:)) ',1'];
        read_pet = spm_vol(current_vol);
        conv_pet = spm_read_vols(read_pet);
        read_pet.mat = read_orig.mat;
        read_pet.fname = [pimdir sub_array(i,:) '\h' deblank(pib_pimgs(j,:))];
        spm_write_vol(read_pet,conv_pet);
    end
    clear read_orig current_vol read_pet
end

%% Fix DASB headers
% Read from original data
for j=1:2,
    if j==1,
        orig_dasbimgs = orig_dasb1imgs;
        dasb_pimgs = dasb1_pimgs;
    elseif j==2,
        orig_dasbimgs = orig_dasb2imgs;
        dasb_pimgs = dasb2_pimgs;
    end
    if isempty(dasb1_pimgs), break; end
    read_orig = spm_vol(orig_dasbimgs);
    for k=1:size(dasb_pimgs,1),
        current_vol = [pimdir sub_array(i,:) '\' deblank(dasb_pimgs(k,:)) ',1'];
        read_pet = spm_vol(current_vol);
        conv_pet = spm_read_vols(read_pet);
        read_pet.mat = read_orig.mat;
        if strfind(pimdir,'MCI'), read_pet.fname = [pimdir sub_array(i,:) '\h' deblank(dasb_pimgs(k,1:8)) deblank(dasb_pimgs(k,end-20:end))];
        elseif isempty(dasb2_pimgs), read_pet.fname = [pimdir sub_array(i,:) '\h' deblank(dasb_pimgs(k,1:5)) deblank(dasb_pimgs(k,end-20:end))];
        else read_pet.fname = [pimdir sub_array(i,:) '\h' deblank(dasb_pimgs(k,1:5)) deblank(dasb_pimgs(k,end-23:end))]; end
        spm_write_vol(read_pet,conv_pet);
    end
    clear read_orig current_vol read_pet
    if isempty(dasb2_pimgs), break; end
end
end
disp('DONE!');
end