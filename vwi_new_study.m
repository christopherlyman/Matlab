function [study] = vwi_new_stud()
%
%        Voxel-Wise Institute
%        vwi_new_stud
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher Henry Lyman
%
%        Usage: vwi_new_stud
%
%        This function prompts to select from list of study names
%        previously provided or allows for new study to be added.

%% List previous study names
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
studies = cell(textread([pth '\Studies\Studies.txt'],'%s'));
NumOfStudies = size(studies,1);


% box1 = {'Enter a Study Name:''Enter study prefix'};
box1 = {'Enter a Study Name:'};
box_title = 'VWI';
num_lines = 1;
default = {''};
NewStudyName = inputdlg(box1,box_title,num_lines,default);
if isempty(NewStudyName),
    return,
end;

studies{NumOfStudies+1,1} = NewStudyName{1};
textfile = [pth '\Studies\Studies.txt'];
fid=fopen(textfile,'wt');

for ii=1:NumOfStudies+1
    fprintf(fid,'%s\n',studies{ii,:});
end

fclose(fid);

study = NewStudyName{1};
% prefix = NewStudyName{2};

proc_dir_question = questdlg('Would you like to select an alternate study processing directory?', ...
    'VWI', ...
    'Yes','No','No');
% Handle response
switch proc_dir_question
    case 'Yes'
        uiwait(msgbox('Please select the processing directory for this study.','VWI'));
        proc_dir = uigetdir(home_dir, 'Select the Processing directory...');
        while isempty(proc_dir)
            uiwait(msgbox('Error: You must select a processing directory','Error message','error'));
            proc_dir = uigetdir(home_dir, 'Select the Processing directory...');
        end
    case 'No'
        proc_dir = (['Z:\Hopkins-data\VWI\' study]);
end

if exist(proc_dir,'dir') == 0;
    mkdir(proc_dir);
end



% TracerText = cell(textread([pth '\Tracers\Tracers.txt'],'%s'));
text = [pth '\Tracers\Tracers.txt'];
fid = fopen(text);
TracerText = textscan(fid,'%s%s','Whitespace','\t');

TracerList = TracerText{:,1};

TracerListSize = size(TracerText{1},1);

TracerList{TracerListSize+1,1} = 'New Tracer';


[Selection,ok] = listdlg('PromptString','Select which Tracers for this Study:',...
    'SelectionMode','multiple','ListSize',[160 300],'Name','VWI','ListString',TracerList);
while isempty(Selection)
    uiwait(msgbox('Error: You must select at least 1 Tracer.','Error message','error'));
    [Selection,ok] = listdlg('PromptString','Select which Tracers for this Study:',...
        'SelectionMode','multiple','ListSize',[160 300],'Name','VWI','ListString',TracerList);
end



ListSize = size(Selection,2);

for ii=1:ListSize,
    if strcmp(TracerList(Selection(ii)),TracerList(TracerListSize+1,1)),
        TracNam = vwi_tracer;
        TracerList{Selection(ii)} = TracNam;
    end
end

for ii=1:ListSize
    TracerName = TracerList(Selection(ii));
    box = ['Enter the number of scans for ' TracerName{1} ':'];
    box1 = {box};
    box_title = 'VWI';
    num_lines = 1;
    default = {'1'};
    TracNum = inputdlg(box1,box_title,num_lines,default);
    if isempty(TracNum),
        return,
    end;
    
    StudyTracers{ii+1,1} = TracerName{1};
    StudyTracers{ii+1,2} = TracNum{1};
end

mriList = cell(textread([pth '\Tracers\MRIs.txt'],'%s'));

mriListSize = size(mriList,1);

mriList{mriListSize+1,1} = 'New Sequence';


[Selection,ok] = listdlg('PromptString','Select which Tracers for this Study:',...
    'SelectionMode','multiple','ListSize',[160 300],'Name','VWI','ListString',mriList);
while isempty(Selection)
    uiwait(msgbox('Error: You must select at least 1 Tracer.','Error message','error'));
    [Selection,ok] = listdlg('PromptString','Select which Tracers for this Study:',...
        'SelectionMode','multiple','ListSize',[160 300],'Name','VWI','ListString',mriList);
end



ListSize = size(Selection,2);

for ii=1:ListSize,
    if strcmp(mriList(Selection(ii)),mriList(mriListSize+1,1)),
        TracNam = vwi_MRsequence;
        mriList{Selection(ii)} = mrNam;
    end
end


for ii=1:ListSize
    mriName = mriList(Selection(ii));
    box = ['Enter the number of scans for ' mriName{1} ':'];
    box1 = {box};
    box_title = 'VWI';
    num_lines = 1;
    default = {'1'};
    mriNum = inputdlg(box1,box_title,num_lines,default);
    mriint = round(str2double(mriNum{1}));
    while isnan(mriint)
        msg = ('A number must be entered:');
        uiwait(msgbox(msg,'VWI'));
        mriNum = inputdlg(box,box_title,num_lines,default);
        mriint = round(str2double(mriNum{1}));
        clear msg
    end
    
    StudyTracers{1,ii+2} = mriName{1};
    StudyTracers{2,ii+2} = mriNum{1};
end


StudyTracers{1,1} = study;
StudyTracers{1,2} = proc_dir;

xlxname = [study '.xlsx'];
xlswrite([pth '\Studies\' xlxname],StudyTracers,'Study-Protocol');
excelFilePath = [pth '\Studies\' xlxname];
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

clc

disp('New Study Added');

end

