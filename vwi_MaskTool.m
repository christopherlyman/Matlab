function spa_MaskTool()
%
%       Static PET Analysis Pipeline
%       Copyright (C) 2013 Johns Hopkins University
%       Software by Christopher H. Lyman and Clifford Workman
%
%       Usage: spa_template;
%       
%       First, you will be prompted to select a processing directory. The
%       templates will end up in this directory. It is recommended that 
%       you select a directory that is conveniently located near where 
%       your source and reference images are located because when you are 
%       prompted to select your source and reference images it defaults to
%       this directory.
%
%       Second, you will be prompted to select your reference images. The
%       reference images are the image type of your final template. Please
%       select all subjects you wish to analyze. e.g.) Depressed and Normal
%       controls.
%
%       Third, you will be prompted to select your source images. These are
%       the images which can be spatially normalized to an SPM template
%       image. These images must be coregistered to the reference image
%       first. Also, select the reference images in the same subject order
%       as you selected for the reference images.
%
%       Fourth, you will be prompted to select an SPM template. Select the 
%       template that best matches your source images. e.g.) If your source
%       images are MPRAGEs or SPGRs then select the T1 SPM template. 
%
%       The program will run through the following steps:
%       ----------------------------- Steps -----------------------------
%       1) The source images are spatially normalized to the SPM template
%          and the reference images are the images to write.
%       2) The warped (spatially-normalized) references images are
%          realigned to the mean and a mean image is resliced.
%       3) The resliced mean reference image is then smoothed by both a 3
%          mm and 6 mm FWHM gaussian kernel and prefixed s3_* and s6_*
%          respectively.

%% Declare required variables, if not already declared
clear global;
clear classes
[pth] = fileparts(which('spa'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));
spm8_template = [spm8_path '\templates'];

%% Define Dirs and set SPM8 path
uiwait(msgbox('Please select the directory to process the data.','SPA'));
proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

while true
    try spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc

%% Prompt to select scans that you wish to make a template
msg = ('Please select GM tissue image');
GMim = spm_select(Inf,'image', msg ,[],proc_dir,'^c1');
clear msg;
Tissuerows = size(GMim,1);

%% Prompt to select scans that will be used to Normalize to Template Space
msg = ('Please select WM tissue image');
WMim = spm_select(Inf,'image', msg ,[],proc_dir,'^c2');
clear msg;


msg = ('Please select CSF tissue image');
CSFim = spm_select(Inf,'image', msg ,[],proc_dir,'^c3');
clear msg;


%% Create Template Directory
mask_dir = [proc_dir '\Brain-Mask'];
mkdir(mask_dir);

%% Look through IMcalc
for ii = 1:1:Tissuerows
    Imarray{1,1} = deblank(GMim(ii,:));
    Imarray{2,1} = deblank(WMim(ii,:));
    Imarray{3,1} = deblank(CSFim(ii,:));
    subdir = [sprintf('subdir_%d',ii)];
    mask = [sprintf('%s%d%s','Brain-Mask_',ii,'.nii')];
    mkcalcout = [mask_dir '\' subdir];
    mkdir(mkcalcout);
    Imcalcout = [mkcalcout '\' mask];
    mask = [sprintf('%s%d%s','PET-MASK_',ii,'.nii')];
    exp = ('((i1>0)+(i2>0)+(i3>.5))>0');
    spm_imcalc_ui(Imarray,Imcalcout,exp);
end


clc
close all;

disp('SPA Template DONE!');

end