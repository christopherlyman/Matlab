function TracNam = vwi_tracer()
%
%        Kinetic Modeling Pipeline
%        Coregistration and Segmentation Module
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman
%
%        Usage: spa_coreg_seg(sub_stu,mprage_pdir,dasb1_pdir,pib_pdir,dasb2_pdir)
%
%        sub_stu: subject number, prefixed with "MCI" where required
%        mprage_pdir: MPRAGE processing directory
%        dasb1_pdir: baseline DASB processing directory
%        pib_pdir: PIB processing directory
%        dasb2_pdir: follow-up DASB processing directory
%
%        This module coregisters the MPRAGE, PIB, and follow-up DASB (if
%        they exist) to the baseline DASB scan. Alternatively, if the DASB
%        is missing, the MR is coregistered to the PIB. The reference images
%        used for coregistration are the summed image frames 1-30 for DASBs
%        and summed image frames 1-16 for PIB. If the DASB reference is
%        missing, this software will pick the last summed image available.
%        If the PIB reference is missing, it will pick the image closest to
%        and greater than summed image frames 1-16 (for example, summed
%        image frames 1-17). After coregistration, the MPRAGE is segmented
%        into gray matter, white matter, and CSF, and normalization
%        parameters to MNI space are derived.
%
%        This function also implicitly calls "kmp_vois_mres." Type
%        "help kmp_vois_mres" in the MATLAB command window for more information.
%
%        This module is meant to be used with KMP. If using as a
%        standalone module, please note that any missing scans should be
%        specified as is done in the following example: dasb1_pdir = '';

%% Declare required variables, if not already declared
[pth] = fileparts(which('vwi'));
studies = [pth '\Tracers\Tracers.txt'];
fid = fopen(studies, 'r');
Tracers = textscan(fid, '%s%s','Whitespace','\t');
fclose(fid);
Tracer_names = Tracers{1};
Tracer_refnum = Tracers{2};
NumOfTracers = size(Tracers{1},1);


box1 = {'Enter a Tracer Name:', 'Enter the Standard Number of Frames:'};
box_title = 'VWI';
num_lines = 1;
default = {'',''};
TracNamNum = inputdlg(box1,box_title,num_lines,default);
TracNumint = round(str2double(TracNamNum{2}));
while isnan(TracNumint) || isempty(TracNamNum{1}) == 1 || TracNumint < 0,
    msg = ('The Tracer Name or the Number of Frames was not entered correctly:');
    uiwait(errordlg(msg,'VWI'));
    TracNamNum = inputdlg(box1,box_title,num_lines,default);
    TracNumint = round(str2double(TracNamNum{2}));
    clear msg
end
clear box1 default
if isempty(TracNamNum{1}) == 0 || isempty(TracNamNum{2}) == 0;
    TracNam = TracNamNum{1};
    FramNum = TracNamNum{2};
end

if str2double(FramNum) > 1,
    box1 = {'Enter the Reference Frame Number:'};
    num_lines = 1;
    default = {''};
    RefNum = inputdlg(box1,box_title,num_lines,default);
    Refint = round(str2double(RefNum{1}));
    while isnan(Refint)
        msg = ('A number must be entered:');
        uiwait(errordlg(msg,'VWI'));
        RefNum = inputdlg(box1,box_title,num_lines,default);
        Refint = round(str2double(RefNum{1}));
        clear msg
    end
    int = ~mod(str2double(RefNum{1}),1);
    while isnan(Refint)|| Refint > TracNumint || Refint < 0 || int == 0,
        msg = ('The Reference number must be a positive interger within the Total number of frames:');
        uiwait(errordlg(msg,'VWI'));
        RefNum = inputdlg(box1,box_title,num_lines,default);
        Refint = round(str2double(RefNum{1}));
        int = ~mod(str2double(RefNum{1}),1);
        clear msg
    end
end

framsize = str2double(FramNum);
AcquisInfo = cell(framsize+1,4);
for jj = 1:1:str2double(FramNum),
    if jj == 1,
        AcquisInfo{jj,1} = ('frame');
        AcquisInfo{jj,2} = ('acquisition');
        AcquisInfo{jj,3} = ('frame start');
        AcquisInfo{jj,4} = ('mid-time');
    end
    msg1 = ('Enter the acquisition time in minutes for frame # ');
    msg = sprintf('%s%d',msg1,jj);
    num_lines = 1;
    subinfo = inputdlg(msg,box_title,num_lines);
    subinfoint = round(str2double(subinfo{1}));
    while isnan(subinfoint) || subinfoint < 0,
        msg2 = ('A positive number must be entered:');
        uiwait(errordlg(msg2,'VWI'));
        subinfo = inputdlg(msg,box_title,num_lines);
        subinfoint = round(str2double(subinfo{1}));
        clear msg2
    end
        
    AcquisInfo{jj+1,1} = jj;
    AcquisInfo{jj+1,2} = str2double(subinfo);
    if jj == 1,
        AcquisInfo{jj+1,3} = str2double('0');
        AcquisInfo{jj+1,4} = AcquisInfo{jj+1,2}/2;
    else
        AcquisInfo{jj+1,3} = sum(reshape([AcquisInfo{2:jj+1,2}],[],1,1))-AcquisInfo{jj+1,2};
        AcquisInfo{jj+1,4} = AcquisInfo{jj+1,2}/2+AcquisInfo{jj+1,3};
    end
end
xlxname = [TracNam '.xlsx'];
xlswrite([pth '\Tracers\protocols\' xlxname],AcquisInfo,'protocol');

excelFilePath = [pth '\Tracers\protocols\' xlxname];
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

Tracer_names{NumOfTracers+1,1} = TracNam;
Tracer_refnum{NumOfTracers+1,1} = RefNum{1};
TracersText(:,1) = cellstr(Tracer_names);
TracersText(:,2) = cellstr(Tracer_refnum);
textfile = [pth '\Tracers\Tracers.txt'];
fid=fopen(textfile,'wt');

for ii=1:NumOfTracers+1
    fprintf(fid,'%s\t%s\n',TracersText{ii,:});
end

fclose(fid);

clc
disp('DONE!');

end