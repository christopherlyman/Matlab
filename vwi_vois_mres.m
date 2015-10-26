function vwi_vois_mres(sub,study,Answer)
%
%       vwi_vois_mres(sub,study,Answer)
%        Kinetic Modeling Pipeline
%        VWI VOIs module (restricted VOIs)
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman
%
%        Usage: vwi_vois_mres(sub,base_dir,sub)
%
%        sub:subject number
%        base_dir: the directory where data for this study is processed
%        sub: subject number, prefixed with "MCI" where required (leave
%        variable out if no prefix is required)
%
%        This software provides an automated method for generating VOIs
%        that can be overlayed on PET data collected in Dr. Gwenn Smith's
%        lab. Results are outputted to a subdirectory of the MPRAGE folder
%        titled "VWI_VOIs_MRes." Example:
%        ~\1001\MPRAGE\VWI_VOIs_MRes\
%
%        This function also implicitly calls "sum_vois." Type "help
%        sum_vois" in the MATLAB command window for more information.
%
%        ----------------------------- Steps -----------------------------
%        1) Transform VOIs from MNI to participant's native space using
%           normalization parameters derived during MR segmentation (module
%           coreg_seg).
%        2) Reslice VOIs to PET space.
%        3) Create copies of VOIs and dilate. Mask original VOIs with
%           dilated copies. This excludes areas in which voxels might
%           overlap across VOIs. Then, larger VOIs are eroded a bit more.
%        4) Create non-gray matter masks, denoise the masks, and then
%           remove non-gray matter voxels from gray-matter VOIs.
%        5) Create non-white matter mask, denoise the mask, and then
%           remove non-white matter voxels from white-matter VOI.
%        6) Apply a cluster threshold (k >= 100) to remove noise from VOIs
%           larger than 100 voxels.
%        7) Make masks of whole regions by summing subregion masks.

%% Declare required variables, if not already declared
if exist('sub','var') == 0,
    Study_Sub;
    waitfor(Study_Sub);
    sub = evalin('base','sub');
    study = evalin('base','study');
end

%% Identify tracer and frames
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

Answer = 1;

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

[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;
study_dir = studyprotocol{1,2};
sub_dir = [study_dir '\Dynamic\' sub];

textfile = [sub_dir '\' sub '_MR-Scans.txt'];
fid = fopen(textfile);
mri_scans = textscan(fid,'%s%s','Whitespace','\t');
fclose(fid);
mr_name = cell2mat(mri_scans{1});
mr_num = cell2mat(mri_scans{2});

textfile = [sub_dir '\' sub '_PET-Scans.txt'];
fid = fopen(textfile);
pet_scans = textscan(fid,'%s%s','Whitespace','\t');
fclose(fid);

if str2double(mr_num)>1
    mrtype = [mr_name '_1'];
else
    mrtype = mr_name;
end
mri_pdir = [sub_dir '\' mrtype '\']; % Declare processing directories

%% Transform VOIs to participant's native space
[pth] = fileparts(which('vwi')); % Create arrays of SPM-ready img files
vwi_vois = dir([pth '\aal_vois_mres\*.nii']);
vwi_vois = {vwi_vois.name};
vwi_vois = str2mat(vwi_vois);

if exist([mri_pdir 'VWI_VOIs_MRes\'],'dir') == 0;
    mkdir([mri_pdir 'VWI_VOIs_MRes\']);
end

for jj=1:size(vwi_vois)
    voi_input = [pth '\aal_vois_mres\' deblank(vwi_vois(jj,:))];
    voi_output = [mri_pdir 'VWI_VOIs_MRes\' deblank(vwi_vois(jj,:))];
    copyfile(voi_input,voi_output);
    voi_array(jj,1) = {[mri_pdir 'VWI_VOIs_MRes\' deblank(vwi_vois(jj,:)) ',1']};
end

if Answer == 1,
    spm_jobman('initcfg');
    matlabbatch{1}.spm.spatial.normalise.write.subj.matname = {[mri_pdir 'Segment\r' sub '_MR-' mrtype '_seg_inv_sn.mat']};
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = voi_array;
    matlabbatch{1}.spm.spatial.normalise.write.roptions.preserve = 0;
    matlabbatch{1}.spm.spatial.normalise.write.roptions.bb = [-100 -150 -100
        100  100  100];
    matlabbatch{1}.spm.spatial.normalise.write.roptions.vox = [2 2 2];
    matlabbatch{1}.spm.spatial.normalise.write.roptions.interp = 1;
    matlabbatch{1}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.normalise.write.roptions.prefix = [sub '_'];
    spm_jobman('run', matlabbatch);
    clear('matlabbatch');
    
else
    spm_jobman('initcfg');
    matlabbatch{1}.spm.tools.vbm8.tools.defs.field = {[mri_pdir 'Segment\iy_r' sub '_MR-' mrtype '.nii,1']};
    matlabbatch{1}.spm.tools.vbm8.tools.defs.fnames = voi_array;
    spm_jobman('run', matlabbatch);
    clear('matlabbatch');
    
    for jj=1:size(vwi_vois)
        voi_input = [mri_pdir 'VWI_VOIs_MRes\w' deblank(vwi_vois(jj,:))];
        voi_output = [mri_pdir 'VWI_VOIs_MRes\' sub '_' deblank(vwi_vois(jj,:))];
        movefile(voi_input,voi_output);
    end
end

for jj=1:size(voi_array,1),
    delete([mri_pdir 'VWI_VOIs_MRes\' deblank(vwi_vois(jj,:))]);
end

%% Create an array of native space VOIs
vwi_vois_dir = dir([mri_pdir 'VWI_VOIs_MRes\*.nii']);
sub_vwi_vois = {vwi_vois_dir.name};
sub_vwi_vois = str2mat(sub_vwi_vois);
clear voi_array
voi_array = cell(size(sub_vwi_vois,1),1);
for jj=1:size(sub_vwi_vois,1)
    voi_array(jj,1) = {[mri_pdir 'VWI_VOIs_MRes\' deblank(sub_vwi_vois(jj,:)) ',1']};
end;

%% Reslice VOIs to PET space
for jj=1:size(sub_vwi_vois,1) % Reslice and threshold VOIs
    src_ref = {deblank([mri_pdir 'r' sub '_MR-' mrtype '.nii,1']),deblank([mri_pdir 'VWI_VOIs_MRes\' str2mat(vwi_vois_dir(jj,:).name) ',1'])};
    spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
    delete(deblank([mri_pdir 'VWI_VOIs_MRes\' str2mat(vwi_vois_dir(jj,:).name)]));
    movefile([mri_pdir 'VWI_VOIs_MRes\r' vwi_vois_dir(jj,:).name],[mri_pdir 'VWI_VOIs_MRes\' vwi_vois_dir(jj,:).name]);
    current_vols = deblank([mri_pdir 'VWI_VOIs_MRes\' str2mat(vwi_vois_dir(jj,:).name)]);
    vo_name = deblank([mri_pdir 'VWI_VOIs_MRes\' vwi_vois_dir(jj,:).name]);
    exp = 'i1>0';
    spm_imcalc_ui(current_vols,vo_name,exp);
end

%% Dilate VOIs
if exist([mri_pdir 'VWI_VOIs_MRes\dilated\'],'dir') == 0, mkdir([mri_pdir 'VWI_VOIs_MRes\dilated\']); end
for i=1:size(sub_vwi_vois), copyfile([mri_pdir 'VWI_VOIs_MRes\' deblank(sub_vwi_vois(i,:))],[mri_pdir 'VWI_VOIs_MRes\dilated\']); end
voi_fnames = dir([mri_pdir 'VWI_VOIs_MRes\dilated\']);
voi_fnames = {voi_fnames(~[voi_fnames.isdir]).name};
voi_fnames = strvcat(voi_fnames);
[rows,~] = size(voi_fnames);

for ii=1:rows,
    this_voi = deblank([mri_pdir 'VWI_VOIs_MRes\dilated\' voi_fnames(ii,:)]);
    voi_hdr = spm_vol(this_voi);
    voi = spm_read_vols(voi_hdr);
    dilated_voi = spm_dilate(voi);
    spm_write_vol(voi_hdr,dilated_voi);
end

%% Subtract dilation masks from VOIs
exp = []; % Define expression for ImCalc
for ii=2:rows,
    if isempty(exp); exp = ['i' num2str(ii)];
    else exp = [exp '+i' num2str(ii)]; end
end;
exp = ['(i1-(' exp '))>0'];
for ii=1:rows,
    calc_array(1,1) = {[mri_pdir 'VWI_VOIs_MRes\' deblank(voi_fnames(ii,:)) ',1']};
    counter = 2;
    for jj=1:rows,
        if ii~=jj, calc_array(counter,1) = {[mri_pdir 'VWI_VOIs_MRes\dilated\' deblank(voi_fnames(jj,:)) ',1']}; counter=counter+1; end
    end;
    voi_out = [mri_pdir 'VWI_VOIs_MRes\' deblank(voi_fnames(ii,:))];
    spm_imcalc_ui(calc_array,voi_out,exp);
end

rmdir([mri_pdir 'VWI_VOIs_MRes\dilated\'],'s'); % Delete dilation masks

%% Create non-gray and non-white matter masks
if Answer == 1,
    current_vols = str2mat([mri_pdir 'Segment\r' sub '_MR-' mrtype '.nii,1'],...
        [mri_pdir 'Segment\c1r' sub '_MR-' mrtype '.nii,1']);
else
    current_vols = str2mat([mri_pdir 'Segment\r' sub '_MR-' mrtype '.nii,1'],...
        [mri_pdir 'Segment\p1r' sub '_MR-' mrtype '.nii,1']);
end
vo_name = [mri_pdir 'VWI_VOIs_MRes\' sub '_Non-GM-Mask.nii']; % CerGM VOI mask
exp = '((i1>0)-(i2>.75))>0';
voi_mask_75 = spm_imcalc_ui(current_vols,vo_name,exp);

clear vo_name exp % More stringent mask
vo_name = [mri_pdir 'VWI_VOIs_MRes\' sub '_Non-GM-Mask_3.nii'];
exp = '((i1>0)-(i2>.3))>0';
voi_mask_3 = spm_imcalc_ui(current_vols,vo_name,exp);

clear vo_name exp % Least stringent mask
vo_name = [mri_pdir 'VWI_VOIs_MRes\' sub '_Non-GM-Mask_01.nii'];
exp = '((i1>0)-(i2>0.01))>0';
voi_mask_01 = spm_imcalc_ui(current_vols,vo_name,exp);

clear current_vols vo_name exp
if Answer == 1,
    current_vols = str2mat([mri_pdir 'Segment\r' sub '_MR-' mrtype '.nii,1'],...
        [mri_pdir 'Segment\c2r' sub '_MR-' mrtype '.nii,1']);
else
    current_vols = str2mat([mri_pdir 'Segment\r' sub '_MR-' mrtype '.nii,1'],...
        [mri_pdir 'Segment\p2r' sub '_MR-' mrtype '.nii,1']);
end
vo_name = [mri_pdir 'VWI_VOIs_MRes\' sub '_Non-WM-Mask_6.nii']; % White matter mask
exp = '((i1>0)-(i2>.6))>0';
voi_mask_wm = spm_imcalc_ui(current_vols,vo_name,exp);

% Clean segment partitions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                        %
% Chris Rorden's adaptation of John Ashburner's script to clean segment  %
% partitions.                                                            %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:4,
    if ii==1, voi_mask = voi_mask_75; elseif ii==2, voi_mask = voi_mask_3; elseif ii==3, voi_mask = voi_mask_01; elseif ii==4, voi_mask = voi_mask_wm; end
    wi = spm_vol(voi_mask);
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
    for jj=1:niter,
        if jj>2, th=th1; else th=0.6; end; % Dilate after two its of erosion.
        for zz=1:size(b,3),
            wp = double(w(:,:,zz));
            bp = double(b(:,:,zz))/255;
            bp = (bp>th).*(wp);
            b(:,:,zz) = uint8(round(bp));
        end;
        spm_conv_vol(b,b,kx,ky,kz,-[1 1 1]);
        spm_progress_bar('Set',jj);
    end;
    th = 0.05;
    for zz=1:size(b,3),
        wp = double(w(:,:,zz))/255;
        bp = double(b(:,:,zz))/255;
        bp = ((bp>th).*(wp))>th;
        w(:,:,zz) = uint8(round(255*wp.*bp));
    end;
    spm_progress_bar('Clear');
    [pth,nam,ext]=fileparts(wi.fname);
    wi.fname = fullfile(pth,[nam, ext]);
    spm_write_vol(wi,w/255);
end

%% Reslice non-gray and non-white matter masks
for ii=1:4,
    if ii==1, voi_mask = voi_mask_75; elseif ii==2, voi_mask = voi_mask_3; elseif ii==3, voi_mask = voi_mask_01; elseif ii==4, voi_mask = voi_mask_wm; end
    src_ref = {[mri_pdir 'r' sub '_MR-' mrtype '.nii,1'];voi_mask};
    spm_reslice(src_ref, struct('mean',0,'interp',1,'which',1));
    current_vols = str2mat(voi_mask);
    vo_name = voi_mask;
    exp = 'i1>0.5';
    spm_imcalc_ui(current_vols,vo_name,exp);
    delete(voi_mask);
    [pathstr,name,ext]=fileparts(voi_mask);
    rvoi_mask = [pathstr '\r' name ext];
    movefile(rvoi_mask,voi_mask);
end

%% Subtract non-gray matter tissue from VOIs
for ii=1:size(sub_vwi_vois),
    size_check = spm_read_vols(spm_vol([mri_pdir 'VWI_VOIs_MRes\' sub_vwi_vois(ii,:)]));
    voi_fname = deblank([mri_pdir 'VWI_VOIs_MRes\' sub_vwi_vois(ii,:)]);
    [~,remain] = strtok(deblank(voi_fnames(ii,:)), '_'); voi_region = deblank(strtok(remain(2:end), '_'));
    if strcmp(voi_region,'Putamen') == 0 && strcmp(voi_region,'Thalamus') == 0,
        if isempty(strfind(voi_fname(end-8:end-5),'_WM_')),
            disp([voi_fname ' 6']);
            current_vols = strvcat({str2mat(voi_array(ii)), [voi_mask_3 ',1']});
            [pathstr,nam,ext] = fileparts([mri_pdir 'VWI_VOIs_MRes\' vwi_vois_dir(ii,:).name]);
            vo_name = [pathstr '\' nam ext];
            exp = '(i1 - i2)>.99';
            spm_imcalc_ui(current_vols,vo_name,exp);
        elseif isempty(strfind(voi_fname(end-8:end-5),'_WM_')) == 0,
            disp([voi_fname ' WM']);
            current_vols = strvcat({str2mat(voi_array(ii)), [voi_mask_wm ',1']});
            [pathstr,nam,ext] = fileparts([mri_pdir 'VWI_VOIs_MRes\' vwi_vois_dir(ii,:).name]);
            vo_name = [pathstr '\' nam ext];
            exp = '(i1 - i2)>.99';
            spm_imcalc_ui(current_vols,vo_name,exp);
        end
    elseif strcmp(voi_region,'Putamen') || strcmp(voi_region,'Thalamus'),
        disp([voi_fname ' 2']);
        current_vols = strvcat({str2mat(voi_array(ii)), [voi_mask_01 ',1']});
        [pathstr,nam,ext] = fileparts([mri_pdir 'VWI_VOIs_MRes\' vwi_vois_dir(ii,:).name]);
        vo_name = [pathstr '\' nam ext];
        exp = '(i1 - i2)>.99';
        spm_imcalc_ui(current_vols,vo_name,exp);
    end
    clear size_check
end

%% Threshold VOIs to k >= 100 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                        %
% Martin Pyka's adaptation of John Ashburner's script to apply extent    %
% thresholds: http://spm.martinpyka.de/?p=29                             %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
k = 100;
for ii = 1:size(sub_vwi_vois),
    size_check = spm_read_vols(spm_vol([mri_pdir 'VWI_VOIs_MRes\' sub_vwi_vois(ii,:)]));
    if size(find(size_check>0),1) > 100
        hdr = spm_vol([mri_pdir 'VWI_VOIs_MRes\' sub_vwi_vois(ii,:)]);
        image = spm_read_vols(hdr);
        indices = find(image>0);
        [x, y, z] = ind2sub(size(image), indices);
        XYZ = [x y z];
        A     = spm_clusters(XYZ');
        Q     = [];
        for zz = 1:max(A)
            j = find(A == zz);
            if length(j) >= k; Q = [Q j]; end
        end
        XYZ   = XYZ(Q,:);
        result = zeros(size(image));
        inds = sub2ind(size(image), XYZ(:,1), XYZ(:,2), XYZ(:,3));
        result(inds) = image(inds);
        spm_write_vol(hdr,result);
    end
end


%% Sum VOIs
clearvars -except sub study
vwi_sum_vois(sub,study);

end