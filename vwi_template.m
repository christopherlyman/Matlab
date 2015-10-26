function vwi_template()
%
%       Static PET Analysis Pipeline
%       Copyright (C) 2013 Johns Hopkins University
%       Software by Christopher H. Lyman and Clifford Workman
%
%       Usage: vwi_template;
%
%       First, you will be prompted to select a processing directory. The
%       templates will end up in this directory. It is recommended that
%       you select a directory that is conveniently located near where
%       your Tempimgs and reference images are located because when you are
%       prompted to select your Tempimgs and reference images it defaults to
%       this directory.
%
%       Second, you will be prompted to select your reference images. The
%       reference images are the image type of your final template. Please
%       select all subjects you wish to analyze. e.g.) Depressed and Normal
%       controls.
%
%       Third, you will be prompted to select your Tempimgs images. These are
%       the images which can be spatially normalized to an SPM template
%       image. These images must be coregistered to the reference image
%       first. Also, select the reference images in the same subject order
%       as you selected for the reference images.
%
%       Fourth, you will be prompted to select an SPM template. Select the
%       template that best matches your Tempimgs images. e.g.) If your Tempimgs
%       images are MPRAGEs or SPGRs then select the T1 SPM template.
%
%       The program will run through the following steps:
%       ----------------------------- Steps -----------------------------
%       1) The Tempimgs images are spatially normalized to the SPM template
%          and the reference images are the images to write.
%       2) The warped (spatially-normalized) references images are
%          realigned to the mean and a mean image is resliced.
%       3) The resliced mean reference image is then smoothed by both a 3
%          mm and 6 mm FWHM gaussian kernel and prefixed s3_* and s6_*
%          respectively.

%% Declare required variables, if not already declared
clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));
spm8_template = [spm8_path '\templates'];

%% Define Dirs and set SPM8 path
uiwait(msgbox('Please select the directory to process the data.','VWI'));
proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

while true
    try spm_rmpath;
    catch
        break;
    end
end

addpath(spm8_path,'-frozen');

clc

spm_get_defaults('cmdline',true);


%% Prompt to select scans that will be used to Normalize to Template Space
msg = ('Please select template images');
Tempimgs = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');
clear msg;
Temprows = size(Tempimgs,1);


%% Prompt to select SPM Template type for Tempimgs Images
msg = ('Please select Template to use for Images');
Template = spm_select(1:1,'image', msg ,[],spm8_template,'\.(nii)$');
clear msg;

%% Prompt to change amount of smoothing applied to the templates
prompt = {'Enter Template Name:'};
dlg_title = 'VWI';
num_lines = 1;
def = {''};
smoothing = inputdlg(prompt,dlg_title,num_lines,def);
TempName = smoothing{1};


%% Create Template Directory
date_str = datestr(now,'yyyy-mm-dd');
Temp_dir = [proc_dir '\Template_' date_str];
if exist(Temp_dir,'dir') == 0;
    mkdir(Temp_dir);
end

%% Copy Tempimgs and Reference Images to the Template Directory

for ii = 1:1:Temprows
    [pathstr, name, ext] = fileparts(Tempimgs(ii,:));
    stringext = strfind(ext,'.img');
    if isempty(stringext)
        ext = ('.nii');
        Sourimgs = [pathstr '\' name ext];
        Temp_imgs = [Temp_dir '\' name ext];
        copyfile(Sourimgs,Temp_imgs,'f');
    else
        ext = ('.img');
        hdr = ('.hdr');
        Sourimgs = [pathstr '\' name ext];
        Temp_imgs = [Temp_dir '\' name ext];
        copyfile(Sourimgs,Temp_imgs,'f');
        Sourhdr = [pathstr '\' name hdr];
        Temphdr = [Temp_dir '\' name hdr];
        copyfile(Sourhdr,Temphdr,'f');
    end
    clear pathstr name ext Temp_imgs Sourimgs stringext Temphdr Sourhdr
end

%% Spatially Normalize Tempimgs Images to Template Space
spm_jobman('initcfg');
load NormalizeTemplate;

Ref_array = cell(Temprows,1);
for ii = 1:1:Temprows
    [~, name, ext] = fileparts(Tempimgs(ii,:));
    Temp_imgs = deblank([Temp_dir '\' name ext]);
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {Temp_imgs};
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {Temp_imgs};
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {Template};
    %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
    Norm = spm_jobman('run',matlabbatch);
    Ref_array(ii,1) = {[Temp_dir '\w' name ext]};
    clear name ext Temp_imgs
end
clear matlabbatch

%% Realign Normalized Reference images to a mean and smooth
load Realign;

matlabbatch{1}.spm.spatial.realign.estwrite.data = {Ref_array};
Realign = spm_jobman('run',matlabbatch);


mean_file = dir([Temp_dir, '\mean*']);
meansize = size(mean_file,1);
if meansize > 1
    mean_name = mean_file.name;
    [~, name, ~] = fileparts(mean_name);
    Temp_start_img = [Temp_dir '\' name '.img'];
    Temp_start_hdr = [Temp_dir '\' name '.hdr'];
    mean_final_img = [proc_dir '\mean_' TempName '_Template.img'];
    mean_final_hdr = [proc_dir '\mean_' TempName '_Template.hdr'];
    copyfile(Temp_start_img,mean_final_img,'f');
    copyfile(Temp_start_hdr,mean_final_hdr,'f');
else
    mean_name = mean_file.name;
    [~, name, ext] = fileparts(mean_name);
    Temp_start = [Temp_dir '\' name ext];
    mean_final_img = [proc_dir '\mean_' TempName '_Template.nii'];
    copyfile(Temp_start,mean_final_img,'f');
end

%     rmdir(Temp_dir,'s'); % Delete template directory

clc
close all;

disp('DONE!');

end