function AAL()
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


% roi_image = [pth '\aal_DARTEL.nii']; %% DARTEL space ROI
roi_image = [proc_dir '\raal.nii']; %% Original AAL space ROI

[~,~,raw]=xlsread([pth '\AAL-Atlas.xlsx'],'ROIs');
AAL_rois = raw; clear raw;




emptyCell_mean = cell(basesize+1,size(AAL_rois,1)+1);
emptyCell_mean{1,1} = ('Name');

emptyCell_voxels = cell(basesize+1,size(AAL_rois,1)+1);
emptyCell_voxels{1,1} = ('Name');

emptyCell_max = cell(basesize+1,size(AAL_rois,1)+1);
emptyCell_max{1,1} = ('Name');

emptyCell_min = cell(basesize+1,size(AAL_rois,1)+1);
emptyCell_min{1,1} = ('Name');

emptyCell_SD = cell(basesize+1,size(AAL_rois,1)+1);
emptyCell_SD{1,1} = ('Name');

emptyCell_neg = cell(basesize+1,size(AAL_rois,1)+1);
emptyCell_neg{1,1} = ('Name');

for ii=1:1:basesize,
    [basepath,basename,~] = fileparts(base_image(ii,:));
    %     if basename(9) == '_',
    %         ID = basename(3:8);
    %     else
    %         ID = basename(1:7);
    %     end
    ID = basename
    emptyCell_mean{ii+1,1} = ID;
    emptyCell_voxels{ii+1,1} = ID;
    emptyCell_max{ii+1,1} = ID;
    emptyCell_min{ii+1,1} = ID;
    emptyCell_SD{ii+1,1} = ID;
    emptyCell_neg{ii+1,1} = ID;
    %% First, load the Base scan of interest
    base_vol = spm_vol(base_image(ii,:));
    base_read = spm_read_vols(base_vol);
    
    %% Second, load each ROI
    roi_vol = spm_vol(roi_image(1,:));
    roi_read = spm_read_vols(roi_vol);
    roi_header = roi_vol;
    
    for jj=1:1:size(AAL_rois,1),
        roiname = AAL_rois{jj,1};
        roinum = AAL_rois{jj,2};
        
        roi_voxels = find(roi_read(:)==roinum);
        roi_data = base_read(roi_voxels);
        
        
        %% write individual ROIs as binary masks NIfTI files:
        base_backup = base_read;
        base_backup(:,:,:)= 0;
        base_backup(roi_voxels) = 1;
        roi_name = [proc_dir '\' roiname '.nii'];
        roi_header.fname = roi_name;
        spm_write_vol(roi_header,base_backup);
        clear base_backup
        
        
        nvox = size(roi_data,1);
        
        Imgs_mean = sum(roi_data)/nvox;
        Imgs_max = max(roi_data(:));
        Imgs_min = min(roi_data(:));
        Imgs_stdev = std(roi_data(:));
        Imgs_val = numel(find(roi_data(:))); Imgs_zero = numel(find(roi_data(:)==0));
        Neg_vox = numel(find(roi_data(:)<0));
        Imgs_size = nvox;
        roi_val{1,1} = ['Name: ' roiname];
        roi_val{2,1} = ['Mean: ' num2str(Imgs_mean)];
        roi_val{3,1} = ['Max: ' num2str(Imgs_max)];
        roi_val{4,1} = ['Min: ' num2str(Imgs_min)];
        roi_val{5,1} = ['SD: ' num2str(Imgs_stdev)];
        roi_val{6,1} = ['Count Negative voxels: ' num2str(Neg_vox)];
        roi_val{7,1} = ['Count Total Voxels: ' num2str(Imgs_size)];
        roi_val{8,1} = '----------------------------------------';
        disp(roi_val);
        
        emptyCell_mean{1,jj+1} = (roiname);
        emptyCell_mean{ii+1,jj+1} = (Imgs_mean);

        emptyCell_voxels{1,jj+1} = (roiname);
        emptyCell_voxels{ii+1,jj+1} = (Imgs_size);
        
        emptyCell_max{1,jj+1} = (roiname);
        emptyCell_max{ii+1,jj+1} = (Imgs_max);
        
        emptyCell_min{1,jj+1} = (roiname);
        emptyCell_min{ii+1,jj+1} = (Imgs_min);
        
        emptyCell_SD{1,jj+1} = (roiname);
        emptyCell_SD{ii+1,jj+1} = (Imgs_stdev);
        
        emptyCell_neg{1,jj+1} = (roiname);
        emptyCell_neg{ii+1,jj+1} = (Neg_vox);
        
        clear roi_data nvox
        
    end
    
    
    %     [~,~,initial_array] = xlsread(MaterFile,sheet);
    %     initial_array(ii+1,:)= emptyCell_mean(2,:);
    %
    
    
end

MaterFile = [proc_dir '\ROI-Master.xlsx'];
if exist(MaterFile, 'file') == 0
    sheet = 'Mean';
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
    
    sheet = 'Mean';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_mean,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'Voxels';
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
    
    sheet = 'Voxels';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_voxels,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'Max';
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
    
    sheet = 'Max';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_max,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'Min';
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
    
    sheet = 'Min';
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
    sheet = 'Neg';
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
    
    sheet = 'Neg';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,emptyCell_neg,sheet);
    waitfor(excel);
end


disp('DONE!');

end