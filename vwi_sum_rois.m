function vwi_sum_rois(vdir)
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: sum_rois(vdir)
%
%        vdir: single participant's directory containing unilateral VOIs.
%
%        Script to sum bilateral VOIs. Creates a subdirectory within the
%        participant's VOI directory (~\Summed\) in which the summed VOIs
%        are placed. Example below:
%
%        If you select this directory:
%        ~\Processing\1001\MPRAGE\SPA_VOIs_MRes\
%
%        ... bilateral VOIs will be outputted into this directory:
%        ~\Processing\1001\MPRAGE\SPA_VOIs_MRes\Summed\*.nii

%% Set directory if not previously specified
if nargin < 1,
    [pth] = fileparts(which('spa'));
    home_dir = char(textread([pth '\home_dir.txt'],'%s'));
    vdir = uigetdir(home_dir,'Select directory with participant ROIs.');
    if vdir == 0
        return
    end
end
clearvars -except vdir
voi_fnames = dir(vdir);
voi_fnames = {voi_fnames(~[voi_fnames.isdir]).name};
voi_fnames = regexprep(voi_fnames, '(.*)Non(.*)Mask(.*)','');
voi_fnames = regexprep(voi_fnames, '(.*)Pons(.*)','');
voi_fnames = regexprep(voi_fnames, '(.*)Lobe(.*)','');
voi_fnames = regexprep(voi_fnames, '(.*)BA(.*)','');
voi_fnames = str2mat(voi_fnames(~cellfun('isempty', voi_fnames)));
[rows,~] = size(voi_fnames);
if exist([vdir '\Summed\'],'dir') == 0, mkdir([vdir '\Summed\']); end

%% Creating an array of VOIs
done_regions = [];
for i=1:rows,
    voi_fname = deblank(voi_fnames(i,:));
    [token,remain] = strtok(deblank(voi_fnames(i,:)), '_'); voi_region = deblank(strtok(remain(2:end), '_'));
    if isempty(cell2mat(strfind(done_regions,voi_region))),
        calc_array{1,:} = [vdir '\' deblank(voi_fnames(i,:)) ',1'];
        for j=1:rows,
            if strfind(voi_fnames(j,:),voi_region) & isempty(strfind(voi_fnames(j,:),voi_fname)),
                calc_array = [calc_array;[vdir '\' deblank(voi_fnames(j,:)) ',1']];
            end
        end
        exp = [];
        if size(calc_array,1) > 1,
            for j=1:size(calc_array),
                if isempty(exp); exp = ['i' num2str(j)];
                else exp = [exp '+i' num2str(j)]; end
            end;
        end
        exp = ['(' exp ')>0'];
        voi_out = [vdir '\Summed\' token '_' voi_region '.nii'];
        bilateral_region = spm_imcalc_ui(calc_array,voi_out,exp);
%         if strfind(voi_region,'Thalamus'),
%             voi_info = spm_vol(bilateral_region);
%             voi = spm_read_vols(voi_info);
%             voi_info.fname = [bilateral_region(1,1:end-4) '_Eroded.nii'];
%             eroded_voi = spm_erode(voi);
%             spm_write_vol(voi_info,eroded_voi);
%         end
        if isempty(done_regions), done_regions = {voi_region};
        else done_regions = [done_regions;voi_region]; end
    end
    clearvars -except vdir voi_fnames rows done_regions
end

% Copy pons into summed directory
pons_fname = dir([vdir '\*Pons*.*']);
pons_size = size(pons_fname,1);
if pons_size > 0,
    pons_newdir = [vdir '\Summed\' char(pons_fname.name(1:end-9)) '.nii'];
    pons_fname = [vdir '\' char(pons_fname.name)];
    copyfile(pons_fname,pons_newdir);
end

Lobe_fname = dir([vdir '\*Lobe_GM.nii']);
Lobe_size = size(Lobe_fname,1);
for i = 1:1:Lobe_size,
    Lobe_newdir = [vdir '\Summed\' char(Lobe_fname(i).name)];
    Lobe_olddir = [vdir '\' char(Lobe_fname(i).name)];
    copyfile(Lobe_olddir,Lobe_newdir);
end

BA_fname = dir([vdir '\*_BA.nii']);
BA_size = size(BA_fname,1);
for i = 1:1:BA_size,
    BA_newdir = [vdir '\Summed\' char(BA_fname(i).name)];
    BA_olddir = [vdir '\' char(BA_fname(i).name)];
    copyfile(BA_olddir,BA_newdir);
end

% Copy CerGM VOI into CerGM directory
% cd(vdir); cd('../');
% if exist([pwd '\CerGM_VOI\']) == 0; % Create directory to store cerebellar GM VOI
%     disp('Creating directory to store cerebellar gray matter VOI.');
%     mkdir([pwd '\CerGM_VOI\']);
% end
cergm_fname = dir([vdir '\Summed\*MR.nii']);
cergm_size = size(cergm_fname,1);
if cergm_size > 0,
    cergm_newdir = [vdir '\Summed\' char(cergm_fname.name(1:end-6)) 'Cerebellar-GM.nii'];
    cergm_fname = [vdir '\Summed\' char(cergm_fname.name)];
    movefile(cergm_fname,cergm_newdir);   
end

end