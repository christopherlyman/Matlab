function imgs_stats()


clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

%% Define Dirs and set SPM8 path
proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

while true
    try spm_rmpath;
    catch
        break;
    end
end

addpath(spm8_path,'-frozen');

clc

spm_get_defaults('cmdline',true);

prompt = {'Enter Name for data:'};
dlg_title = 'VWI';
num_lines = 1;
def = {''};
dataname = inputdlg(prompt,dlg_title,num_lines,def);
data_name = dataname{1};


msg = (['Please select ' data_name ' images']);
Imgs = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');
clear msg;
Imgsrows = size(Imgs,1);

emptyCell = cell(Imgsrows,7);
emptyCell{1,1} = ('Name');
emptyCell{1,2} = ('Mean');
emptyCell{1,3} = ('Max');
emptyCell{1,4} = ('Min');
emptyCell{1,5} = ('St. Dev');
emptyCell{1,6} = ('Total Voxels');
emptyCell{1,7} = ('Negative Voxels');


for ii=1:1:Imgsrows,
    [~, name, ext] = fileparts(Imgs(ii,:));
    read_Imgs = spm_vol(Imgs(ii,:));
    Imgs_vol = spm_read_vols(read_Imgs);
    
    disp(['Name: ' name]);
    Imgs_mean = mean(Imgs_vol(:)); disp(['Mean: ' num2str(Imgs_mean)]);
    Imgs_max = max(Imgs_vol(:)); disp(['Max: ' num2str(Imgs_max)]);
    Imgs_min = min(Imgs_vol(:)); disp(['Min: ' num2str(Imgs_min)]);
    Imgs_stdev = std(Imgs_vol(:)); disp(['SD: ' num2str(Imgs_stdev)]);
    Imgs_val = numel(find(Imgs_vol(:))); Imgs_zero = numel(find(Imgs_vol(:)==0));
    Imgs_size = Imgs_val+Imgs_zero; disp(['Count Total Voxels: ' num2str(Imgs_size)]);
    Neg_vox = numel(find(Imgs_vol(:)<0)); disp(['Count Negative voxels: ' num2str(Neg_vox)]);
    disp('----------------------------------------');
    
    emptyCell(ii+1,1) = {name};
    emptyCell(ii+1,2) = num2cell(Imgs_mean);
    emptyCell(ii+1,3) = num2cell(Imgs_max);
    emptyCell(ii+1,4) = num2cell(Imgs_min);
    emptyCell(ii+1,5) = num2cell(Imgs_stdev);
    emptyCell(ii+1,6) = num2cell(Imgs_size);
    emptyCell(ii+1,7) = num2cell(Neg_vox);
end

xlxname = ([data_name '_descript-stats.xlsx']);
sheet = data_name;
warning('off','MATLAB:xlswrite:AddSheet');
xlswrite([proc_dir '\' xlxname],emptyCell(:,:),sheet);


%% Delete unused sheets
excelFilePath = [proc_dir '\' xlxname];
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

disp('DONE!');

end