function roi_val_mask()
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: get_roivalue(proc_dir)
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

%% Get directory with PET images, sort into separate directories
clear global;
clear classes;
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

% prompt = {'Enter subject number:'};
% dlg_title = 'AAL rois';
% num_lines = 1;
% sub = inputdlg(prompt,dlg_title,num_lines);
% sub = sub{1};

proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

msg = ('Please select base Image(s):');
base_image = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');

clear msg;
while isempty(base_image) == 1,
    msg = ('Please select base Image(s):');
    base_image = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
    clear msg;
end

basesize = size(base_image,1);
[basepath,~,~] = fileparts(base_image(1,:));

msg = ('Please select ROI Image(s):');
roi_image = spm_select(Inf,'image', msg ,[],basepath,'\.(img|nii)$');
clear msg;
while isempty(roi_image) == 1,
    msg = ('Please select ROI Image(s):');
    roi_image = spm_select(Inf,'image', msg ,[],basepath,'\.(img|nii)$');
    clear msg;
end

roisize = size(roi_image,1);



% cerb_dir = ('Z:\External\YunZhou\!Data\SRTM_LRSC_Sr7Sf1_with-threshold\KMP_Coregistration_for_ROI-Analysis');


emptyCell_mean = cell(basesize+1,roisize+1);
emptyCell_mean{1,1} = ('Name');

emptyCell_voxels = cell(basesize+1,roisize+1);
emptyCell_voxels{1,1} = ('Name');

emptyCell_max = cell(basesize+1,roisize+1);
emptyCell_max{1,1} = ('Name');

emptyCell_min = cell(basesize+1,roisize+1);
emptyCell_min{1,1} = ('Name');

emptyCell_SD = cell(basesize+1,roisize+1);
emptyCell_SD{1,1} = ('Name');

emptyCell_neg = cell(basesize+1,roisize+1);
emptyCell_neg{1,1} = ('Name');


for ii=1:1:basesize,
    [basepath,basename,~] = fileparts(base_image(ii,:));
    
    ID = basename
    emptyCell_mean{ii+1,1} = ID;
    emptyCell_voxels{ii+1,1} = ID;
    emptyCell_max{ii+1,1} = ID;
    emptyCell_min{ii+1,1} = ID;
    emptyCell_SD{ii+1,1} = ID;
    emptyCell_neg{ii+1,1} = ID;
    
    
    
    [~,roiname,~] = fileparts(roi_image(ii,:));
    %% First, load the Base scan of interest
    read_base = spm_vol(base_image(ii,:));
    conv_base = spm_read_vols(read_base);
    
    %% Second, load each ROI
    read_roi = spm_vol(roi_image(ii,:));
    conv_roi = spm_read_vols(read_roi);
    
    roi_thresh = find(conv_roi(:)>0.4);
    
    roi_backup = conv_roi;
    roi_backup(:,:,:)= 0;
    roi_backup(roi_thresh) = 1;
    roi_name = [proc_dir '\' roiname '_Mask.nii'];
    read_roi.fname = roi_name;
    spm_write_vol(read_roi,roi_backup);
    
    nvox = sum(sum(sum(roi_backup)));
    roi_avg = conv_base.*roi_backup;
    
    
    
    Imgs_mean = sum(sum(sum(roi_avg)))/nvox;
    Imgs_max = max(roi_avg(:));
    Imgs_min = min(roi_avg(:));
    find_min = find(roi_avg(:)>0);
    Pos_min_val = roi_avg(find_min);
    Pos_min = min(Pos_min_val);
    Imgs_stdev = std(roi_avg(:));
    Imgs_val = numel(find(roi_avg(:))); Imgs_zero = numel(find(roi_avg(:)==0));
    Neg_vox = numel(find(roi_avg(:)<0));
    Imgs_size = nvox;
    roi_val{1,1} = ['Name: ' roiname];
    roi_val{2,1} = ['Mean: ' num2str(Imgs_mean)];
    roi_val{3,1} = ['Max: ' num2str(Imgs_max)];
    roi_val{4,1} = ['Global Min: ' num2str(Imgs_min)];
    roi_val{5,1} = ['Minimum Positive Number: ' num2str(Pos_min)];
    roi_val{6,1} = ['SD: ' num2str(Imgs_stdev)];
    roi_val{7,1} = ['Count Negative voxels: ' num2str(Neg_vox)];
    roi_val{8,1} = ['Count Total Voxels: ' num2str(Imgs_size)];
    roi_val{9,1} = '----------------------------------------';
    disp(roi_val);
    
    emptyCell_mean{1,ii+1} = (roiname);
    emptyCell_mean{ii+1,ii+1} = (Imgs_mean);
    
    emptyCell_voxels{1,ii+1} = (roiname);
    emptyCell_voxels{ii+1,ii+1} = (Imgs_size);
    
    emptyCell_max{1,ii+1} = (roiname);
    emptyCell_max{ii+1,ii+1} = (Imgs_max);
    
    emptyCell_min{1,ii+1} = (roiname);
    emptyCell_min{ii+1,ii+1} = (Imgs_min);
    
    emptyCell_SD{1,ii+1} = (roiname);
    emptyCell_SD{ii+1,ii+1} = (Imgs_stdev);
    
    emptyCell_neg{1,ii+1} = (roiname);
    emptyCell_neg{ii+1,ii+1} = (Neg_vox);
    
    
    
    
    %     [~,~,initial_array] = xlsread(MaterFile,sheet);
    %     initial_array(ii+1,:)= emptyCell(2,:);
    %
    
    
end

% MaterFile = [proc_dir '\' sub 'ROI-Master.xlsx'];
MaterFile = [proc_dir '\ROI-Master.xlsx'];
if exist(MaterFile, 'file') == 0
    sheet = 'MEAN';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,emptyCell_mean,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'MEAN';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_mean,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'VOXELS';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,emptyCell_voxels,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'VOXELS';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_voxels,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'MAX';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,emptyCell_max,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'MAX';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_max,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'MIN';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,emptyCell_min,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'MIN';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_min,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'SD';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,emptyCell_SD,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'SD';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_SD,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'NEG';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,emptyCell_neg,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'NEG';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_neg,sheet);
    waitfor(excel);
end



disp('DONE!');

end