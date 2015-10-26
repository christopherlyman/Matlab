function Freesurfer_roi_val()
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

% proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');
proc_dir = ['Z:\02_Analyses\FreeSurfer'];

dir_proc = dir(proc_dir);
for kk = length(dir_proc):-1:1
    % remove folders starting with .
    fname = dir_proc(kk).name;
    if fname(1) == '.'
        dir_proc(kk) = [ ];
    end
    if fname(1) == '!'
        dir_proc(kk) = [ ];
    end
    if ~dir_proc(kk).isdir
        dir_proc(kk) = [ ];
        continue
    end
end

sublist = cell(size(dir_proc,1),1);

for kk = 1:1:size(dir_proc,1),
    sublist{kk,:} = [dir_proc(kk).name];
end

[subSelection,sok] = listdlg('PromptString','Select Subject(s) to Process:',...
    'SelectionMode','multiple','ListSize',[200 500],'Name','VWI','ListString',sublist);
while isempty(subSelection)
    uiwait(msgbox('Error: You must select at least one Subject to Process.','Error message','error'));
    [subSelection,sok] = listdlg('PromptString','Select Subject(s) to Process:',...
        'SelectionMode','multiple','ListSize',[200 500],'Name','VWI','ListString',sublist);
end

sub = sublist(subSelection);
sublength = sub;

[~,~,masterMean]=xlsread([proc_dir '\Master_FreeSurfer-ROIs.xlsx'],'MEAN');
[~,~,masterVoxels]=xlsread([proc_dir '\Master_FreeSurfer-ROIs.xlsx'],'VOXELS');
[~,~,masterMax]=xlsread([proc_dir '\Master_FreeSurfer-ROIs.xlsx'],'MAX');
[~,~,masterMin]=xlsread([proc_dir '\Master_FreeSurfer-ROIs.xlsx'],'MIN');
[~,~,masterSD]=xlsread([proc_dir '\Master_FreeSurfer-ROIs.xlsx'],'SD');
[~,~,masterNeg]=xlsread([proc_dir '\Master_FreeSurfer-ROIs.xlsx'],'NEG');


for gg = 1:1:size(sub,1),
    sub_dir = [proc_dir '\' str2mat(sub(gg))];
    pet_dir = dir([sub_dir, '\*_DVR*.img']);
    pet_images = {pet_dir.name};
    pet_images = str2mat(pet_images);
    
    for hh=1:size(pet_images,1)
        base_image(hh,1) = {[sub_dir '\' deblank(pet_images(hh,:))]};
    end;
    
    basesize = size(base_image,1);
    
    cort_roi = dir([sub_dir '\NIfTI\Cortical', '\*_Bi_*.nii']);
    cort_images = {cort_roi.name};
    cort_images = str2mat(cort_images);
    
    for hh=1:size(cort_images,1)
        roi_image(hh,1) = {[sub_dir '\NIfTI\Cortical\' deblank(cort_images(hh,:))]};
    end;
    cortsize = size(roi_image,1);
    
    subcort_roi = dir([sub_dir '\NIfTI\Subcortical', '\*_Bi_*.nii']);
    subcort_images = {subcort_roi.name};
    subcort_images = str2mat(subcort_images);
    
    for hh=1:size(subcort_images,1)
        roi_image(hh+cortsize,1) = {[sub_dir '\NIfTI\Subcortical\' deblank(subcort_images(hh,:))]};
    end;
    
    roisize = size(roi_image,1);
    
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
        [basepath,basename,~] = fileparts(base_image{ii});
        ID = basename
        emptyCell_mean{ii+1,1} = ID;
        emptyCell_voxels{ii+1,1} = ID;
        emptyCell_max{ii+1,1} = ID;
        emptyCell_min{ii+1,1} = ID;
        emptyCell_SD{ii+1,1} = ID;
        emptyCell_neg{ii+1,1} = ID;
        
        for jj=1:1:roisize,
            
            [~,roiname,~] = fileparts(roi_image{jj});
            %% First, load the Base scan of interest
            read_base = spm_vol(base_image{ii});
            conv_base = spm_read_vols(read_base);
            
            %% Second, load each ROI
            read_roi = spm_vol(roi_image{jj});
            conv_roi = spm_read_vols(read_roi);
            
            nvox = round(sum(sum(sum(conv_roi))));
            roi_avg = conv_base.*conv_roi;
            
            
            
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
            
        end
     
    end
    
    masterMean = [masterMean; emptyCell_mean(2:end,:)];
    masterVoxels = [masterVoxels; emptyCell_voxels(2:end,:)];
    masterMax = [masterMax; emptyCell_max(2:end,:)];
    masterMin = [masterMin; emptyCell_min(2:end,:)];
    masterSD = [masterSD; emptyCell_SD(2:end,:)];
    masterNeg = [masterNeg; emptyCell_neg(2:end,:)];
    
    clear emptyCell_mean emptyCell_voxels emptyCell_max emptyCell_min ...
        emptyCell_SD emptyCell_neg roi_image pet_dir pet_images ... 
        base_image cort_roi subcort_roi cort_images subcort_images ...
        sub_dir cortsize roisize basesize
    
end

% MaterFile = [proc_dir '\' sub 'ROI-Master.xlsx'];
MaterFile = [proc_dir '\Master_FreeSurfer-ROIs.xlsx'];
if exist(MaterFile, 'file') == 0
    sheet = 'MEAN';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,masterMean,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'MEAN';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,masterMean,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'VOXELS';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,masterVoxels,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'VOXELS';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,masterVoxels,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'MAX';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,masterMax,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'MAX';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,masterMax,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'MIN';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,masterMin,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'MIN';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,masterMin,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'SD';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,masterSD,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'SD';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,masterSD,sheet);
    waitfor(excel);
end

if exist(MaterFile, 'file') == 0
    sheet = 'NEG';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(MaterFile,masterNeg,sheet);
    
    excelFilePath = [MaterFile];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    %     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
else
    
    sheet = 'NEG';
    warning('off','MATLAB:xlswrite:AddSheet');
    excel = xlswrite(MaterFile,masterNeg,sheet);
    waitfor(excel);
end





disp('DONE!');

end