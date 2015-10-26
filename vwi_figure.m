function spa_figure()
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman and Clifford Workman
%
%        Usage: spa_figure;
%
%       First, you will be prompted to select the "\Processing" directory
%       created during spa_coreg_seg. E.g.) Z:\TEST\MCI\Processing\
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
%          spa_coreg_seg).
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

%% Define Dirs and set SPM8 path
[pth] = fileparts(which('spa'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

uiwait(msgbox('Please select the directory to process the data.','SPA'));
proc_dir = uigetdir(home_dir, 'Select the directory to process the ROI analysis...');

while true
    try spm_rmpath;
    catch break;
    end
end
addpath(spm8_path);
clc

%% Prompt to select ROI
msg = ('Please select image to analyze:');
data = spm_select(1:1,'image', msg ,[],proc_dir,'\.(nii|img)$');
clear msg;

%% Prompt to select background or template image
msg = ('Please select ROI:');
ROI = spm_select(1:1,'image', msg ,[],proc_dir,'\.(nii|img)$');
clear msg;

%% Copy Images into processing directory
roi_dir = [proc_dir '\ROI'];
mkdir(roi_dir);

[pathstr, name, ext] = fileparts(data(1,:));
stringext = strfind(ext,'.img');
if isempty(stringext)
    ext = ('.nii');
    dataHOME = [pathstr '\' name ext];
    dataimg = [roi_dir '\' name ext];
    copyfile(dataHOME,dataimg,'f');
else
    ext = ('.img');
    hdr = ('.hdr');
    dataHOME = [pathstr '\' name ext];
    dataimg = [roi_dir '\' name ext];
    copyfile(dataHOME,dataimg,'f');
    hdrHOME = [pathstr '\' name hdr];
    datahdr = [roi_dir '\' name hdr];
    copyfile(hdrHOME,datahdr,'f');
end

[pathstr, name, ext] = fileparts(ROI(1,:));
stringext = strfind(ext,'.img');
if isempty(stringext)
    ext = ('.nii');
    roiHOME = [pathstr '\' name ext];
    roiimg = [roi_dir '\' name ext];
    copyfile(roiHOME,roiimg,'f');
else
    ext = ('.img');
    hdr = ('.hdr');
    roiHOME = [pathstr '\' name ext];
    roiimg = [roi_dir '\' name ext];
    copyfile(roiHOME,roiimg,'f');
    roihdrHOME = [pathstr '\' name hdr];
    roihdr = [roi_dir '\' name hdr];
    copyfile(roihdrHOME,roihdr,'f');
end

%% Reslice background into overlay space
src_ref{1,:} = [dataimg ',1'];
src_ref{2,:} = [roiimg ',1'];
spm_reslice(src_ref, struct('mask',0,'mean',0,'interp',7,'which',1));

%% Turn overlay into binary mask
[pathstr, name, ext] = fileparts(roiimg(1,:));
roi_in = [pathstr '\r' name ext ',1'];
roi_out = [pathstr '\r' name ext ',1'];
exp = 'i1>0';
spm_imcalc_ui(roi_in,roi_out,exp);
roi_img = roi_out;

%% First, load the PET scan of interest
data_vol = spm_vol(dataimg);
data_read = spm_read_vols(data_vol);

%% Second, load each VOI
roi_vol = spm_vol(roi_img);
roi_read = spm_read_vols(roi_vol);
nvox = sum(sum(sum(roi_read)));
roi_avg = data_read.*roi_read;

[~, name, ext] = fileparts(roiHOME(1,:));
region = name;

vox_names = find(roi_avg>0);
vox_size = size(vox_names,1);
if vox_size > 0,
    for j=1:1:vox_size;
        vox_name = vox_names(j);
        vox_val(j,1) = roi_avg(vox_name);
    end
    roi_mean = (sum(sum(sum(roi_avg)))/nvox); disp(['Region: ' region]);disp(['Average: ' num2str(roi_mean)]);
    roi_max = max(roi_avg(:)); disp(['Max: ' num2str(roi_max)]);
    roi_min = min(abs(vox_val(:))); disp(['Min: ' num2str(roi_min)]);
    roi_neg = min(roi_avg(:)); disp(['Neg: ' num2str(roi_neg)]);
    roi_stdev = std(roi_avg(:)); disp(['St Dev: ' num2str(roi_stdev)]);
    roi_size = numel(find(roi_avg(:))); disp(['Total voxels: ' num2str(roi_size)]);
    disp('----------------------------------------');
    
    
    % Store data for export to excel
    
    emptyCell{1,1} = ('Region');
    emptyCell{1,2} = ('Average');
    emptyCell{1,3} = ('Maximum');
    emptyCell{1,4} = ('Minimum');
    emptyCell{1,5} = ('Negative');
    emptyCell{1,6} = ('St Dev');
    emptyCell{1,7} = ('Num Voxels');
    
    emptyCell(2,1) = {region};
    emptyCell(2,2) = num2cell(roi_mean);
    emptyCell(2,3) = num2cell(roi_max);
    emptyCell(2,4) = num2cell(roi_min);
    emptyCell(2,5) = num2cell(roi_neg);
    emptyCell(2,6) = num2cell(roi_stdev);
    emptyCell(2,7) = num2cell(roi_size);
    
    
end
size_pet = size(data_read,3);
roi_voxels = find(roi_read(:)>0);
masked_pet = data_read;

inc = ((max(data_read(:))-min(data_read(:)))/64); %Original

masked_pet(vox_names) = max(data_read(:))+inc;

scrsz = get(0, 'MonitorPositions');

[xyzcor(:,1) xyzcor(:,2) xyzcor(:,3)] = ind2sub(size(roi_read), roi_voxels);
x = xyzcor(:,3);
MINaxial = min(abs(x));
MAXaxial = max(abs(x));
ROIvol = MAXaxial - MINaxial;

number = ROIvol/10;
integ = floor(number);
fract = number-integ;
last = fract*10;
extra = 10-last;
extra = extra/2;
if extra == 5,
    num_planes = integ*10;
    current_slice = MINaxial;
    integ = integ-1;
else
    extra = floor(extra);
    num_planes = (integ+1)*10;
    current_slice = MINaxial-extra;
end
slices_inc = 1;

hf = figure('name',region,'NumberTitle','off','units','pixels','position',[0 0 scrsz(3)/2 scrsz(4)/2]); movegui(hf,'center');
%         colormap([jet;[1 0 0]]);
%         colormap([gray;jet(64)]);
colormap([gray(64);[1 0 0]]);
for m=1:1:num_planes,
    h(m) = subplot(integ+1,10,m);
    subp = get(h(m),'Position');
    if m == 1,
        set(h(m),'Position',[.13 subp(2) .075 .2]);
    else
        set(h(m),'Position',[subp(1) subp(2) .075 .2]); % [left bottom width height]
    end
    ipet = imagesc(imrotate(masked_pet(:,:,current_slice),90)); axis off
    %             ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(abs(data_read(:))) max(data_read(:))]);
    ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(masked_pet(:)) max(masked_pet(:))]);
    current_slice = current_slice+slices_inc;
    hold all
end
if exist([proc_dir, '\ROI\ROI_Placement\'],'dir') == 0, mkdir([proc_dir, '\ROI\ROI_Placement\']); end
pout = char([proc_dir, '\ROI\ROI_Placement\' deblank(region) '.tif']);

print(hf, '-dtiff', pout);


% xlxname = [region '.xlsx'];
% sheet = deblank(region);
% xlswrite([proc_dir '\' xlxname],emptyCell(:,:),sheet);
textfile = [proc_dir '\' region '.txt'];
fid = fopen(textfile, 'wt');
fprintf(fid, '%s\t%s\n%s\t%s\n%s\t%s\n%s\t%s\n%s\t%s\n%s\t%s\n%s\t%s\n%', emptyCell{:,:});
fclose(fid);



%% Delete unused sheets
% excelFilePath = [proc_dir '\' xlxname];
% sheetName = 'Sheet';
% objExcel = actxserver('Excel.Application');
% objExcel.Workbooks.Open(fullfile(excelFilePath));
% 
% objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
% objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
% objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
% 
% objExcel.ActiveWorkbook.Save;
% objExcel.ActiveWorkbook.Close;
% objExcel.Quit;
% objExcel.delete;

end