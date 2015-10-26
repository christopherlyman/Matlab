function combine_ROIs()
%
%
%
%% Ensure SPM8 path has been added, define home directory %%%%%%%%%%%%%%%%
%                                                                        %
% Code to remove/add SPM paths developed by K-lab:                       %
% http://www.nemotos.net/?p=21                                           %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));


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

%% Prompt for prcessing directory subject number and validity checks

% proc_dir = uigetdir(home_dir, 'Select the subject''s direcotry..');
proc_dir = [Z:\02_Analyses\FreeSurfer];

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

for ii = 1:1:size(sub,1),
    working_dir = [proc_dir '\' str2mat(sub(ii))];
    pet_dir = dir([working_dir, '\*_DVR*.img']);
    
    pet_images = {pet_dir.name};
    pet_images = str2mat(pet_images);
    
    for jj=1:size(pet_images,1)
        base_images(jj,1) = {[working_dir '\' deblank(pet_images(jj,:)) ',1']};
    end;
    
    for jj = 1:1:size(base_images,1),
        [basepath,basename,~] = fileparts(base_image(ii,:));

    ID = basename
    emptyCell_mean{ii+1,1} = ID;
    emptyCell_voxels{ii+1,1} = ID;
    emptyCell_max{ii+1,1} = ID;
    emptyCell_min{ii+1,1} = ID;
    emptyCell_SD{ii+1,1} = ID;
    emptyCell_neg{ii+1,1} = ID;
    
    for jj=1:1:roisize,
        [~,roiname,~] = fileparts(roi_image(jj,:));
        %% First, load the Base scan of interest
        read_base = spm_vol(base_image(ii,:));
        conv_base = spm_read_vols(read_base);
        
        %% Second, load each ROI
        read_roi = spm_vol(roi_image(jj,:));
        conv_roi = spm_read_vols(read_roi);  
        
        nvox = sum(sum(sum(conv_roi)));
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
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
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
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
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
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
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
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
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
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
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
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
%     objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
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
    
end

disp('Done!');

end
