function vwi_coreg()

clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

while true
    try spm_rmpath;
    catch
        break;
    end
end

addpath(spm8_path,'-frozen');

clc

spm_get_defaults('cmdline',true);

%% Define Dirs and set SPM8 path
proc_dir = ('Z:\External\YunZhou\!Data\SRTM_LRSC_Sr7Sf1_with-threshold\KMP_Coregistration_for_ROI-Analysis\test');

msg = 'Please select image(s) to normalize';
pet_data = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');

lld_dir = ('Z:\Hopkins-data\GD_(NA_00021615)\Processed_Images\PET_Data\Processing');
mci_dir = ('Z:\Hopkins-data\MCI_AD_(NA_00026190-34091)\Processed_Images\PET_Data\Processing');

%% Prompt to select SPM Template type for Source Images

pet_size = size(pet_data,1);
pet_vol = cell(pet_size,1);


for ii=1:1:pet_size,
    [pathstr, name, ext] = fileparts(pet_data(ii,:));
    if name(5) == '_',
        if strcmp(name(19:20),'BL'),
            sub = [name(1:4) '_BL'];
        elseif strcmp(name(19:20),'FU'),
            sub = [name(1:4) '_FU'];
        else
            sub = name(1:4);
        end
    else
        sub = name(1:7);
    end
    
    sub_dir = [proc_dir '\' sub];
    if exist(sub_dir,'dir') == 0;
        mkdir(sub_dir);
    end
    
    stringext = strfind(ext,'.img');
    if isempty(stringext)
        ext = ('.nii');
        imgs = [pathstr '\' name ext];
        petimgs = [sub_dir '\' name ext];
        copyfile(imgs,petimgs,'f');
        clear imgs
    else
        ext = ('.img');
        hdr = ('.hdr');
        imgs = [pathstr '\' name ext];
        petimgs = [sub_dir '\' name ext];
        copyfile(imgs,petimgs,'f');
        filehdr = [pathstr '\' name hdr];
        pethdr = [sub_dir '\' name hdr];
        copyfile(filehdr,pethdr,'f');
        clear imgs hdr filehdr pethdr
    end
    pet_vol{ii,:} = petimgs;
    clear pathstr name ext petimgs
end

for ii=1:size(pet_vol,1)
    [~, name, ext] = fileparts(pet_vol{ii});
    if name(5) == '_',
        if strcmp(name(19:20),'BL'),
            sub = [name(1:4) '_BL'];
            sub_name = name(1:4);
            sub_dir = [proc_dir '\' sub];
            mr_dir = [lld_dir '\' sub_name '\MPRAGE\'];
            roi_dir = [lld_dir '\' sub_name '\MPRAGE\KMP_VOIs_MRes\Summed\'];
        elseif strcmp(name(19:20),'FU'),
            sub = [name(1:4) '_FU'];
            sub_name = name(1:4);
            sub_dir = [proc_dir '\' sub];
            mr_dir = [lld_dir '\' sub_name '\MPRAGE\'];
            roi_dir = [lld_dir '\' sub_name '\MPRAGE\KMP_VOIs_MRes\Summed\'];
        else
            sub = name(1:4);
            sub_name = name(1:4);
            sub_dir = [proc_dir '\' sub];
            mr_dir = [lld_dir '\' sub_name '\MPRAGE\'];
            roi_dir = [lld_dir '\' sub_name '\MPRAGE\KMP_VOIs_MRes\Summed\'];
        end
    else
        sub = name(1:7);
        sub_name = name(1:7);
        mci_name = name(4:7);
        sub_dir = [proc_dir '\' sub];
        mr_dir = [mci_dir '\' mci_name '\MPRAGE\'];
        roi_dir = [mci_dir '\' mci_name '\MPRAGE\KMP_VOIs_MRes\Summed\'];
    end
    
    mr_data = [mr_dir 'r' sub_name '_MR_MPRAGE.nii'];
    coreg_mr = [sub_dir '\' sub_name '_MR_MPRAGE.nii'];
    copyfile(mr_data,coreg_mr,'f');
    
    other_dir = [sub_dir '\Other\'];
    if exist(other_dir,'dir') == 0;
        mkdir(other_dir);
    end
    
    dir_roi = dir([roi_dir, '\*.nii']);
    roi_size = size(dir_roi,1);  
    
    for jj=1:1:roi_size
        [~, name, ext] = fileparts(dir_roi(jj).name);
        stringext = strfind(ext,'.img');
        if isempty(stringext)
            ext = ('.nii');
            Sroiimgs = [roi_dir '\' name ext];
            roiimgs = [other_dir name ext];
            copyfile(Sroiimgs,roiimgs,'f');
            clear Sroiimgs roiimgs
        else
            ext = ('.img');
            hdr = ('.hdr');
            Sroiimgs = [roi_dir '\' name ext];
            roiimgs = [other_dir name ext];
            copyfile(Sroiimgs,roiimgs,'f');
            Sroihdr = [roi_dir '\' name hdr];
            roihdr = [other_dir name hdr];
            copyfile(Sroihdr,roihdr,'f');
            clear Sroiimgs hdr Sroihdr roihdr roiimgs
        end
        clear  name ext
    end
end

spm_jobman('initcfg');
load([pth '\coreg.mat'])

ref_size = size(pet_vol,1);

for ii=1:1:ref_size,
    Refimg = deblank([pet_vol{ii} ',1']);
    [~, name, ext] = fileparts(Refimg);
    if name(5) == '_',
        if strcmp(name(19:20),'BL'),
            sub = [name(1:4) '_BL'];
            sub_name = name(1:4);
            sub_dir = [proc_dir '\' sub];
            other_dir = [sub_dir '\Other\'];
        elseif strcmp(name(19:20),'FU'),
            sub = [name(1:4) '_FU'];
            sub_name = name(1:4);
            sub_dir = [proc_dir '\' sub];
            other_dir = [sub_dir '\Other\'];
        else
            sub = name(1:4);
            sub_name = name(1:4);
            sub_dir = [proc_dir '\' sub];
            other_dir = [sub_dir '\Other\'];
        end
    else
        sub = name(1:7);
        sub_name = name(1:7);
        sub_dir = [proc_dir '\' sub];
        other_dir = [sub_dir '\Other\'];
    end
    Sourceimg = deblank([sub_dir '\' sub_name '_MR_MPRAGE.nii,1']);
    dir_other = dir([other_dir, '*.nii']);
    other_size = size(dir_other,1);
    other_vol = cell(other_size,1);
    for jj=1:1:other_size,
        other_vol{jj,:} = [other_dir '\' dir_other(jj).name ',1'];
    end
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {Refimg};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {Sourceimg};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = (other_vol);
    %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
    coreg = spm_jobman('run',matlabbatch);
    
    for jj = 1:1:size(other_vol,1),
        [~,name,ext] = fileparts(other_vol{jj,:});
        current_vol = [other_dir 'coreg' name ext];
        vo_name = [other_dir 'coreg' name ext];
        exp = 'i1>0';
        spm_imcalc_ui(current_vol,vo_name,exp);
        clear name ext current_vol vo_name exp
    end
    
end

disp('DONE!');

end