function AAL_rois(sub,proc_dir,base_pet)
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman and Clifford Workman
%
%        Usage: vwi_rois;
%
%       First, you will be prompted to select the "\Processing" directory
%       created during vwi_coreg_seg. E.g.) Z:\TEST\MCI\Processing\
%       Click the folder named "Processing" and click "OK".
%
%       Second, you will be prompted to enter a study name (e.g. MCI) and
%       the number of subjects to be analyzed. This is the total number of
%       subjects you wish to analyize for the study name you entered.
%
%       Third, you will be prompted to enter the name of each subject.
%       E.g.) 2005
%       Fourth, you will be prompted to select each subject's Processing
%       directory. E.g.) Z:\TEST\MCI\Processing\MCI-2005
%
%       The program will run through the following steps:
%       ----------------------------- Steps -----------------------------
%       1) Transform ROIs from MNI to participant's native space using
%          normalization parameters derived during MR segmentation (module
%          vwi_coreg_seg).
%       2) Reslice ROIs to subject space.
%       3) Create copies of ROIs and dilate. Mask original ROIs with
%          dilated copies. This excludes areas in which voxels might
%          overlap across ROIs. Then, larger ROIs are eroded a bit more.
%       4) Create non-gray matter masks, denoise the masks, and then
%          remove non-gray matter voxels from gray-matter ROIs.
%       5) Create non-white matter mask, denoise the mask, and then
%          remove non-white matter voxels from white-matter VOI.
%       6) Apply a cluster threshold (k >= 100) to remove noise from ROIs
%          larger than 100 voxels.
%       7) Make masks of whole regions by summing subregion masks.
%       8) Run get_roivals.m to get statistics and print to spreadsheet in
%          subject directory.

%% Ensure SPM8 path has been added, define home directory %%%%%%%%%%%%%%%%
%                                                                        %
% Code to remove/add SPM paths developed by K-lab:                       %
% http://www.nemotos.net/?p=21                                           %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc
spm_get_defaults('cmdline',true);


if exist('sub','var'),
    sub = sub;
else,
    prompt = {'Enter subject number:'};
    dlg_title = 'AAL rois';
    num_lines = 1;
    sub = inputdlg(prompt,dlg_title,num_lines);
    sub = sub{1};
end


if exist('proc_dir','var'),
    proc_dir = proc_dir;
else
    proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');
end


if exist('base_pet','var'),
    base_pet = base_pet;
else
    msg = ('Please select base PET image(s):');
    base_pet = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
    
    
    clear msg;
    while isempty(base_pet) == 1,
        msg = ('Please select base PET image(s):');
        base_pet = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
        clear msg;
    end
end

[~,basePETname,basePEText] = fileparts(base_pet(1,:));

roi_atlas_home = deblank([pth '\aal.nii']);
roi_atlas = deblank([proc_dir '\aal.nii']);
copyfile(roi_atlas_home,roi_atlas);

aal_mni_dir = [proc_dir '\aal-mni\'];
roi_dir = [proc_dir '\ROI\'];

mkdir(aal_mni_dir);
mkdir(roi_dir);

% GM_temp_home = [pth '\Grey.nii'];
% GM_temp = [aal_mni_dir '\Grey.nii'];
% copyfile(GM_temp_home,GM_temp);

Brain_temp_home = [pth '\Brain.nii'];
Brain_temp = [aal_mni_dir '\Brain.nii'];
copyfile(Brain_temp_home,Brain_temp);

[~,~,raw]=xlsread([pth '\AAL-Atlas.xlsx'],'ROIs');
AAL_rois = raw; clear raw;

roi_vol = spm_vol(roi_atlas(1,:));
roi_read = spm_read_vols(roi_vol);
roi_header = roi_vol;

disp('Creating AAL ROIs...');

for ii=1:1:size(AAL_rois,1),
    roiname = AAL_rois{ii,1};
    roinum = AAL_rois{ii,2};
    %     roi_voxels = find(roi_read(:)==roinum);
    roi_voxels = roi_read(:)==roinum;
    
    roi_backup = roi_read;
    roi_backup(:,:,:)= 0;
    roi_backup(roi_voxels) = 1;
    roi_name = [aal_mni_dir '\' roiname '.nii'];
    roi_header.fname = roi_name;
    spm_write_vol(roi_header,roi_backup);
    clear roi_backup roiname roinum roi_voxels
    
end


spm_jobman('initcfg');

disp('Inverse Spatial Normalization of MNI space ROIs...');

%% Generate ROIs: The subject's MRI must have the inverse spatial...
%  normalization parameters file (*_seg_inv_sn.mat). %%%%
inv_mat = dir([proc_dir, '\*inv_sn.mat']);
mat_name = inv_mat.name;
mat_name = [proc_dir '\' mat_name];
aal_roi_names = dir([aal_mni_dir, '\*.nii']);
aal_roi_names = {aal_roi_names.name};
aal_roi_names = str2mat(aal_roi_names);
aal_size = size(aal_roi_names,1);
roi_array = cell(aal_size,1);
for jj=1:aal_size
    roi_array(jj,1) = {[aal_mni_dir deblank(aal_roi_names(jj,:)) ',1']};
end;
matlabbatch{1}.spm.spatial.normalise.write.subj.matname = {mat_name};
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = roi_array;
matlabbatch{1}.spm.spatial.normalise.write.roptions.preserve = 0;
matlabbatch{1}.spm.spatial.normalise.write.roptions.bb = [-100 -150 -100
    100  100  100];
matlabbatch{1}.spm.spatial.normalise.write.roptions.vox = [2 2 2];
matlabbatch{1}.spm.spatial.normalise.write.roptions.interp = 1;
matlabbatch{1}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.normalise.write.roptions.prefix = [sub '_'];
spm_jobman('run', matlabbatch);
clear('matlabbatch');

ROI_MNI_name = [aal_mni_dir sub];
movefile([ROI_MNI_name '*.nii'], roi_dir);
rmdir(aal_mni_dir,'s'); % Delete MNI ROIs

clear roi_array aal_size


%% Reslice ROIs to PET space

disp('reslicing subject space ROIs...');

tissue_dir = dir([proc_dir '\c*.nii']);
tissue_names = {tissue_dir.name};
tissue_names = str2mat(tissue_names);

for ii=1:1:size(tissue_names,1),
    movefile([proc_dir '\' tissue_names(ii,:)], roi_dir);
end

aal_roi_dir = dir([roi_dir,'*.nii']);
sub_aal_rois = {aal_roi_dir.name};
sub_aal_rois = str2mat(sub_aal_rois);

aal_size = size(sub_aal_rois,1);

for jj=1:aal_size
    roi_array(jj,1) = {[roi_dir deblank(sub_aal_rois(jj,:)) ',1']};
end;

% Reslice ROIs to PET space
PET_name = [basePETname basePEText];

for zz=1:size(sub_aal_rois) % Reslice and threshold ROIs
    aal_rois_rname = [roi_dir 'r' aal_roi_dir(zz,:).name];
    vwi_rois_name = [roi_dir aal_roi_dir(zz,:).name];
    src_ref = {deblank([proc_dir '\' PET_name ',1']),deblank([roi_dir str2mat(aal_roi_dir(zz,:).name) ',1'])};
    spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
    roi_name = [roi_dir str2mat(aal_roi_dir(zz,:).name)];
    delete(roi_name);
    movefile(aal_rois_rname,vwi_rois_name);
    clear roi_name aal_rois_rname vwi_rois_name
end

movefile([roi_dir '\' sub '_Brain.nii'],[proc_dir '\' sub '_Brain.nii']);

% movefile([roi_dir '\' sub '_Grey.nii'],[proc_dir '\' sub '_Grey.nii']);

for ii=1:1:size(tissue_names,1),
    movefile([roi_dir '\' tissue_names(ii,:)], proc_dir);
end

clear roi_array
aal_roi_dir = dir([roi_dir,'*.nii']);
sub_aal_rois = {aal_roi_dir.name};
sub_aal_rois = str2mat(sub_aal_rois);

aal_size = size(sub_aal_rois,1);

for jj=1:aal_size
    roi_array(jj,1) = {[roi_dir deblank(sub_aal_rois(jj,:)) ',1']};
end;

disp('Creating Binary AAL ROIs...');

% Threshold binary ROIs.
for zz=1:size(sub_aal_rois,1) % Reslice and threshold ROIs
    current_vols = [roi_dir str2mat(aal_roi_dir(zz,:).name)];
    vo_name = [roi_dir aal_roi_dir(zz,:).name];
    exp = 'i1>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
end



%% Dilate ROIs
if exist([proc_dir '\ROI\dilated\'],'dir') == 0,
    mkdir([proc_dir '\ROI\dilated\']);
end

disp('Copying ROIs into Dilation folder...');
for jj=1:size(sub_aal_rois),
    copyfile([proc_dir '\ROI\' deblank(sub_aal_rois(jj,:))],[proc_dir '\ROI\dilated\']);
end

disp('Dilating ROIs...');

roi_fnames = dir([proc_dir, '\ROI\dilated\']);
roi_fnames = {roi_fnames(~[roi_fnames.isdir]).name};
roi_fnames = char(rot90(roi_fnames)); %Replaces strvcat
roi_fnames = flipud(roi_fnames); %Replaces strvcat
[rows,~] = size(roi_fnames);
for zz=1:rows,
    this_roi = [proc_dir '\ROI\dilated\' deblank(roi_fnames(zz,:))];
    roi_hdr = spm_vol(this_roi);
    roi = spm_read_vols(roi_hdr);
    dilated_roi = spm_dilate(roi);
    spm_write_vol(roi_hdr,dilated_roi);
end


%% Subtract dilation masks from ROIs

disp('Subtrating dilation masks from ROIs...');

exp = []; % Define expression for ImCalc
for zz=2:aal_size,
    if isempty(exp);
        exp = ['i' num2str(zz)];
    else exp = [exp '+i' num2str(zz)];
    end
end;

exp = ['(i1-(' exp '))>0'];
for zz=1:aal_size,
    calc_array(1,1) = {[proc_dir '\ROI\dilated\' deblank(sub_aal_rois(zz,:)) ',1']};
    counter = 2;
    for gg=1:aal_size,
        if zz~=gg, calc_array(counter,1) = {[proc_dir '\ROI\dilated\' deblank(sub_aal_rois(gg,:)) ',1']};
            counter=counter+1;
        end
    end;
    sub_aal_rois_out = [proc_dir '\ROI\' deblank(sub_aal_rois(zz,:))];
    spm_imcalc_ui(calc_array,sub_aal_rois_out,exp);
end
clear calc_array

rmdir([proc_dir '\ROI\dilated\'],'s'); % Delete dilation masks


%% Create non-gray and non-white matter masks

disp('Creating tissue masks...');

GM_dir = dir([proc_dir, '\c1*.nii']);
GM_name = GM_dir.name;
CSF_dir = dir([proc_dir, '\c3*.nii']);
CSF_name = CSF_dir.name;
Brain_temp = dir([proc_dir, '\' sub '_Brain.nii']);
% Brain_temp = dir([proc_dir, '\' sub '_Grey.nii']);
Brain_temp = Brain_temp.name;



MRI_vol = spm_vol([proc_dir '\' GM_name]);
MRI_read = spm_read_vols(MRI_vol);
MRI_read(:,:,:)= 1;
MRI_positive = [proc_dir '\positive.nii'];
MRI_vol.fname = MRI_positive;
spm_write_vol(MRI_vol,MRI_read);

current_vols = str2mat([proc_dir '\' GM_name ',1'],...
    [proc_dir '\' Brain_temp ',1']);
Brain_temp_inverted = [proc_dir '\' sub '_Brain_temp_inverted.nii'];
exp = '((i1>0)-(i2>.2))>0';
spm_imcalc_ui(current_vols,Brain_temp_inverted,exp);
Brain_temp_inverted_name = [sub '_Brain_temp_inverted.nii'];

current_vols = str2mat([proc_dir '\' GM_name ',1'],...
    [proc_dir '\' Brain_temp_inverted_name ',1']);
GM_clean = [proc_dir '\' sub '_GM_clean.nii'];
exp = '((i1>0)-(i2>0))>0';
spm_imcalc_ui(current_vols,GM_clean,exp);
GM_clean_name = [sub '_GM_clean.nii'];

current_vols = str2mat([proc_dir '\' GM_clean_name],...
    [proc_dir '\' CSF_name ',1']);
GM_CSF_clean = [proc_dir '\' sub '_GM-CSF_clean.nii'];
exp = '((i1>0) - (i2>.4))>0';
spm_imcalc_ui(current_vols,GM_CSF_clean,exp);
GM_CSF_clean_name = [sub '_GM-CSF_clean.nii'];

current_vols = str2mat(MRI_positive,...
    [proc_dir '\' GM_CSF_clean_name ',1']);
Brain_mask = [proc_dir '\' sub '_Brain-Mask.nii'];
exp = '((i1>0)-(i2>0))>0';
spm_imcalc_ui(current_vols,Brain_mask,exp);
Brain_mask_name = [sub '_Brain-Mask.nii'];


%Clean segment partitions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                        %
% Chris Rorden's adaptation of John Ashburner's script to clean segment  %
% partitions.                                                            %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Cleaning Segmented Partitions...');


roi_mask = Brain_mask_name;

wi = spm_vol([proc_dir '\' roi_mask]);
w = spm_read_vols(wi)*255;
b = w;
kx=[0.75 1 0.75]; % Build a 3x3x3 seperable smoothing kernel
ky=[0.75 1 0.75];
kz=[0.75 1 0.75];
sm=sum(kron(kron(kz,ky),kx))^(1/3);
kx=kx/sm; ky=ky/sm; kz=kz/sm;
th1 = 0.2;
niter = 32;
spm_progress_bar('Init',niter,'Cleaning tissue masks (x4)','Iterations completed');
for gg=1:niter,
    if gg>2, th=th1; else th=0.6; end; % Dilate after two iterations of erosion.
    for jj=1:size(b,3),
        wp = double(w(:,:,jj));
        bp = double(b(:,:,jj))/255;
        bp = (bp>th).*(wp);
        b(:,:,jj) = uint8(round(bp));
    end;
    spm_conv_vol(b,b,kx,ky,kz,-[1 1 1]);
    spm_progress_bar('Set',gg);
end;
th = 0.05;
for hh=1:size(b,3),
    wp = double(w(:,:,hh))/255;
    bp = double(b(:,:,hh))/255;
    bp = ((bp>th).*(wp))>th;
    w(:,:,hh) = uint8(round(255*wp.*bp));
end;
spm_progress_bar('Clear');
[pth,nam,ext]=fileparts(wi.fname);
wi.fname = fullfile(pth,[nam, ext]);
spm_write_vol(wi,w/255);



%% Subtract tissue masks from ROIs

disp('Subtracting Tissue Masks from ROIs...');

current_mask = [proc_dir '\' Brain_mask_name ',1'];
rows = size(sub_aal_rois,1);

[~,mask_name,~] = fileparts(current_mask);
[~,Mremain] = strtok(deblank(mask_name), '_');
Mask_type = deblank(strtok(Mremain(2:end), '_'));



for zz=1:rows,
%     size_check = spm_read_vols(spm_vol([roi_dir sub_aal_rois(zz,:)]));
    roi_fname = deblank(sub_aal_rois(zz,:));
%     [~,remain] = strtok(deblank(roi_fname), '_');
%     roi_region = deblank(strtok(remain(2:end), '_'));
    disp([roi_fname '  masking  ' Mask_type ' ...']);
    current_vols = strvcat({str2mat(roi_array(zz)), current_mask});
    [~,nam,ext] = fileparts(aal_roi_dir(zz,:).name);
    vo_name = [roi_dir nam '_' Mask_type ext];
    exp = '(i1 - i2)>.99';
    spm_imcalc_ui(current_vols,vo_name,exp);
    clear size_check current_vols vo_name exp nam ext
end


% Threshold ROIs to k >= 100 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                        %
% Martin Pyka's adaptation of John Ashburner's script to apply extent    %
% thresholds: http://spm.martinpyka.de/?p=29                             %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Thresholding ROIs...');
j = 50;
%     j = 75;
%     j = 50;

current_mask = ('Brain-Mask');
masked_roi_dir = dir([roi_dir,'*' deblank(current_mask) '.nii']);
masked_roi_name = {masked_roi_dir.name};
masked_roi_name = str2mat(masked_roi_name);

for hh = 1:size(masked_roi_dir,1),
    size_check = spm_read_vols(spm_vol([roi_dir '\' masked_roi_name(hh,:)]));
    %         if size(find(size_check>0),1) > 75
    if size(find(size_check>0),1) > 100
        %             if size(find(size_check>0),1) > 50
        hdr = spm_vol([roi_dir '\' masked_roi_name(hh,:)]);
        image = spm_read_vols(hdr);
        indices = find(image>0);
        [x, y, z] = ind2sub(size(image), indices);
        XYZ = [x y z];
        A     = spm_clusters(XYZ');
        Q     = [];
        for mm = 1:max(A)
            d = find(A == mm);
            if length(d) >= j; Q = [Q d]; end
        end
        XYZ   = XYZ(Q,:);
        result = zeros(size(image));
        inds = sub2ind(size(image), XYZ(:,1), XYZ(:,2), XYZ(:,3));
        result(inds) = image(inds);
        spm_write_vol(hdr,result);
    end
end


%% Get ROI values and print to spreadsheet.

aal_get_roivals(proc_dir,sub,base_pet);


close all;
clear,clc;
disp('DONE!');

end