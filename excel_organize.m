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

proc_dir = ('Z:\External\YunZhou\!Data\SRTM_LRSC_Sr7Sf1_without-threshold\Sr7');

dir_proc = dir([proc_dir,'\ROI-Analysis\']);

emptyCell = cell(78,24);
emptyCell{1,1} = 'Name';
emptyCell{1,2} = 'CERB_input-func';
emptyCell{1,3} = 'Amygdala';
emptyCell{1,4} = 'Anterior-Cingulum';
emptyCell{1,5} = 'Caudate';
emptyCell{1,6} = 'CentrumSemiovale';
emptyCell{1,7} = 'Cerebellum';
emptyCell{1,8} = 'Frontal';
emptyCell{1,9} = 'Fusiform';
emptyCell{1,10} = 'Hippocampus';
emptyCell{1,11} = 'Insula';
emptyCell{1,12} = 'Midbrain';
emptyCell{1,13} = 'Occipital';
emptyCell{1,14} = 'Pallidum';
emptyCell{1,15} = 'ParaHippocampal';
emptyCell{1,16} = 'Parietal';
emptyCell{1,17} = 'Pons';
emptyCell{1,18} = 'Postcentral';
emptyCell{1,19} = 'Precentral';
emptyCell{1,20} = 'Precuneus-Posterior-Cingulum';
emptyCell{1,21} = 'Putamen';
emptyCell{1,22} = 'Temporal';
emptyCell{1,23} = 'Thalamus';
emptyCell{1,24} = 'Thalamus_Eroded';

count = 1;

for ii=3:1:size(dir_proc,1),
    working_dir = [proc_dir '\ROI-Analysis\' dir_proc(ii).name];
    dasb_sheet = dir([working_dir, '\*DASB*_DVR.xlsx']);
    if isempty(dasb_sheet) == 0,
        for gg=1:1:size(dasb_sheet,1),
            [~,~,raw]=xlsread([working_dir '\' dasb_sheet(gg).name],'ROI');
            data_names = raw(:,1);
            emptyCell{count+1,1} = dasb_sheet(gg).name;
            for jj=2:1:size(emptyCell,2),
                roi_name = cell2mat(emptyCell(1,jj));
                data_names = raw(:,1);
                match = strfind(data_names,roi_name);
                strings = ~cellfun('isempty', match);
                strings_match = raw(strings,2);
                if isempty(strings_match) == 0,
                    emptyCell(count+1,jj) = strings_match(1);
                end
            end
            count = count+1;
        end
    else
        emptyCell{count+1,1} = dir_proc(ii).name;
        count = count+1;
    end
end

xlxname = ('DASB_ROI-Analysis.xlsx');
sheet = 'ROI-Analysis';
warning('off','MATLAB:xlswrite:AddSheet');
xlswrite([proc_dir '\' xlxname],emptyCell(:,:),sheet);

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