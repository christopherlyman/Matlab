function roistat()
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: get_roivals(proc_dir)
%
%        proc_dir: directory in which subdirectories labeled by participant
%        contain parametric images prefixed with "h" to signify the headers
%        for these images have been corrected.
%
%        This module overlays the automated KMP VOIs on parametric images
%        and generates descriptive statistics for the voxels within the VOI
%        (mean, max, min, standard deviation, and the size of the VOI).
%        Spreadsheets containing these data will be outputted to the
%        directory specified in the variable "proc_dir."

%% Get directory with parametric images, sort into separate directories

[pth] = fileparts(which('spa'));
cd(pth);
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

while true
    try spm_rmpath;
    catch break;
    end
end
addpath(spm8_path);
clc

subdir = uigetdir(home_dir,'Select directory containing PET image.');
cd(subdir);
subdir = spm_get();
roidir = spm_get();

        
%% First, load the PET scan of interest
read_pet = spm_vol(subdir);
conv_pet = spm_read_vols(read_pet);
        
%% Second, load each VOI
roi_hdr = spm_vol(roidir);
roi_img = spm_read_vols(roi_hdr);

%% Get statistics
nvox = sum(sum(sum(roi_img)));
roi_avg = conv_pet.*roi_img;

vox_names = find(roi_avg>0);
vox_size = size(vox_names,1);
for j=1:1:vox_size;
    vox_name = vox_names(j);
    vox_val(j,1) = roi_avg(vox_name);
end
roi_mean = (sum(sum(sum(roi_avg)))/nvox); disp(['Average: ' num2str(roi_mean)]);
roi_max = max(roi_avg(:)); disp(['Max: ' num2str(roi_max)]);
roi_min = min(abs(vox_val(:))); disp(['Min: ' num2str(roi_min)]);
roi_neg = min(roi_avg(:)); disp(['Neg: ' num2str(roi_neg)]);
roi_stdev = std(roi_avg(:)); disp(['St Dev: ' num2str(roi_stdev)]);
roi_size = numel(find(roi_avg(:))); disp(['Total voxels: ' num2str(roi_size)]);
disp('----------------------------------------');

end