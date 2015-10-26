function vwi_suv()
%
%        FDG Automated Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: vwi(sub,MR_dir)
%
%        sub: subject number
%        MR_dir: directory containing subject's original MRI scan
%
%
%        Example directories for :
%        FDG:
%
%        It is suggested to start VWI using either of the following
%        commands:
%        >> vwi
%        >> vwi(sub)
%
%        The remaining variables are intended for batch processing.
%        Type "help vwi_batch" to learn more. Additional information about
%        the processing steps utilized in VWI can be found by typing
%        "help" followed by the name of the module in question into the
%        MATLAB console.

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

%% Prompt for subject number and validity checks
Study_Sub;
waitfor(Study_Sub);
sub = evalin('base','sub');
study = evalin('base','study');

%% Read Study Protocol
[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;
study_dir = studyprotocol{1,2};
sub_dir = [study_dir '\01_SUV\' sub];
ManACdir = [study_dir '\02_Manual-AC\' sub];
ProcessingDir = [study_dir '\02_Manual-AC\'];

if exist(sub_dir,'dir') == 0;
    mkdir(sub_dir);
end
if exist(ManACdir,'dir') == 0;
    mkdir(ManACdir);
end
if exist(ProcessingDir,'dir') == 0;
    mkdir(ProcessingDir);
end

%% prompt to select how many scans for each study tracer
sizeprotocol = size(studyprotocol,1)-1;
for jj=1:sizeprotocol,
    scanlist = cell(studyprotocol{jj+1,2}+1,1);
    for ii=1:1:studyprotocol{jj+1,2},
        scanlist{ii,1} = [studyprotocol{jj+1,1} '-' sprintf('%d',ii)];
    end
    scanlist{studyprotocol{jj+1,2}+1} = 'None';
    [scanSelection,sok] = listdlg('PromptString','Select scans:',...
        'SelectionMode','multiple','ListSize',[160 300],'Name','SUV','ListString',scanlist);
    while isempty(scanSelection)
        uiwait(msgbox('Error: You must select at least one scan.','Error message','error'));
        [scanSelection,sok] = listdlg('PromptString','Select which SUV Calucation:',...
            'SelectionMode','multiple','ListSize',[160 300],'Name','SUV','ListString',scanlist);
    end
    eval(sprintf('scanSelection_%d = scanSelection;',jj));
end

MRprotocol = size(studyprotocol,2)-2;
MRlist = cell(MRprotocol+1,1);
for jj=1:MRprotocol,
    MRlist{jj,1} = [studyprotocol{1,2+jj}];
end
MRlist{MRprotocol+1} = 'None';
[mrSelection,MRok] = listdlg('PromptString','Select scans:',...
    'SelectionMode','single','ListSize',[160 300],'Name','SUV','ListString',MRlist);
while isempty(mrSelection)
    uiwait(msgbox('Error: You must select at least one scan.','Error message','error'));
    [mrSelection,MRok] = listdlg('PromptString','Select which SUV Calucation:',...
        'SelectionMode','single','ListSize',[160 300],'Name','SUV','ListString',MRlist);
end
eval(sprintf('mrSelection_%d = mrSelection;',jj));
eval(sprintf('MRlist_%d = MRlist;',jj));

msg = ['Please select the Baseline ' MRlist{mrSelection} ' scan:'];
MR_scan = spm_select(1:1,'image', msg ,[],home_dir,'\.(nii|img)$');
[mrpath,mrname,mrext] = fileparts(MR_scan);

%% Prompt to select subject's PET folders
% sizeprotocol = size(scans,1);
pettemp = mrpath;

for jj=1:sizeprotocol,
    scanSelection = eval(sprintf('scanSelection_%d',jj));
    for ii=1:size(scanSelection,2);
        if strcmp('None',scanlist{scanSelection(ii)})==1,
        else
            msg1 = ('Please select ');
            msg2 = ('''s ');
            msg3 = scanlist{scanSelection(ii)};
            msg4 = (' ');
            msg5 = (' folder:');
            msg = sprintf('%s%s%s%s%s%s',msg1,sub,msg2,msg3,msg4,msg5);
            uiwait(msgbox(msg,'SUV'));
            petdir = uigetdir(pettemp,msg);
            eval(sprintf('tracer_%d_dir_%d = petdir;',jj,ii));
            pettemp = petdir;
        end
    end
end
clear msg msg1 msg2 msg3 msg4 msg5 msg

%% Prompt to select type of SUV calculation
S = {'Body Weight (BW)','Body Surface Area (BSA)','Lean Body Mass (LBM)','Body Mass Index (BMI)','All SUVs'};
[Selection,ok] = listdlg('PromptString','Select which SUV Calucation:',...
    'SelectionMode','single','ListSize',[160 300],'Name','SUV','ListString',S);
while isempty(Selection)
    uiwait(msgbox('Error: You must select SUV Calculation to use.','Error message','error'));
    [Selection,ok] = listdlg('PromptString','Select which SUV Calucation:',...
        'SelectionMode','single','ListSize',[160 300],'Name','SUV','ListString',S);
end


%%%%%%%%%%%%%%%%%%%%%% FIX FROM HERE!

%% Find out what type of data is being used
for jj=1:sizeprotocol,
    Tracer_name = studyprotocol{jj+1,1};
    scanSelection = eval(sprintf('scanSelection_%d',jj));
    for ii=1:1:size(scanSelection,2),
        checker = 1;
        petdir = eval(sprintf('tracer_%d_dir_%d',jj,ii));
        petstruct = dir(petdir);
        pet_name = scanlist{scanSelection(ii)};
        imdur = [sub_dir '\' pet_name];
        if exist(imdur,'dir') == 0;
            mkdir(imdur);
        end
        ACdur = [ManACdir '\' pet_name];
        if exist(ACdur,'dir') == 0;
            mkdir(ACdur);
        end
        for kk=1:size(petstruct,1),
            if checker == 1,
                isdir = petstruct(kk).isdir;
                if isdir == 0,
                    fullname = [petdir '\' petstruct(kk).name];
                    [pathstr, name, ext] = fileparts(fullname);
                    filename = petstruct(kk).name;
                    DICOM_info = cell(1,7);
                    if isdicom(fullname) == 1,
                        OutFileName = [sub '_PET_' pet_name];
                        DICOM_info = Armansilent(OutFileName,petdir,imdur,pet_name);
                        petimg = [imdur '\' OutFileName '.nii'];
                        ACpetimg = [ACdur '\' OutFileName '.nii'];
                        copyfile(petimg,ACpetimg)
                        eval(sprintf('DICOM_info_%d_%d = DICOM_info;',jj,ii));
                        checker = 2;
                    elseif strfind(ext,'.nii') == 1,
                        imagecheck = dir([petdir,'\*.nii']);
                        sizecheck = size(imagecheck,1);
                        if sizecheck > 1,
                            msg = (['Please select ' sub '''s appropriate ' pet_name ' file:']);
                            fullname = spm_select(1:1,'image', msg ,[],petdir,'.(nii|img)$');
                            clear msg
                            [pathstr, name, ext] = fileparts(fullname);
                            if strfind(ext,'.nii') == 1,
                                ext = '.nii';
                                Spetimg = [pathstr '\' name ext];
                                petimg = [imdur '\' name ext];
                                ACpetimg = [ACdur '\' name ext];
                                copyfile(Spetimg,ACpetimg)
                                copyfile(Spetimg,petimg)
                                eval(sprintf('DICOM_info_%d_%d = DICOM_info;',jj,ii));
                                checker = 2;
                            else
                                ext = '.img';
                                Spetimg = [pathstr '\' name ext];
                                Spethdr = [pathstr '\' name '.hdr'];
                                petimg = [imdur '\' name ext];
                                pethdr = [imdur '\' name '.hdr'];
                                ACpetimg = [ACdur '\' name '.hdr'];
                                ACpethdr = [ACdur '\' name '.hdr'];
                                copyfile(Spetimg,ACpetimg)
                                copyfile(Spethdr,ACpethdr)
                                copyfile(Spetimg,petimg)
                                copyfile(Spethdr,pethdr)
                                eval(sprintf('DICOM_info_%d_%d = DICOM_info;',jj,ii));
                                checker = 2;
                            end
                        else
                            ext = '.nii';
                            Spetimg = [pathstr '\' name ext];
                            petimg = [imdur '\' name ext];
                            ACpetimg = [ACdur '\' name ext];
                            copyfile(Spetimg,ACpetimg)
                            copyfile(Spetimg,petimg)
                            eval(sprintf('DICOM_info_%d_%d = DICOM_info;',jj,ii));
                            checker = 2;
                        end
                    elseif strfind(ext,'.img') == 1,
                        imagecheck = dir([petdir,'\*.img']);
                        sizecheck = size(imagecheck,1);
                        if sizecheck > 1,
                            msg = (['Please select ' sub '''s appropriate ' pet_name ' file:']);
                            fullname = spm_select(1:1,'image', msg ,[],petdir,'.(nii|img)$');
                            clear msg
                            [pathstr, name, ext] = fileparts(fullname);
                            if strfind(ext,'.nii') == 1,
                                ext = '.nii';
                                Spetimg = [pathstr '\' name ext];
                                petimg = [imdur '\' name ext];
                                ACpetimg = [ACdur '\' name ext];
                                copyfile(Spetimg,ACpetimg)
                                copyfile(Spetimg,petimg)
                                eval(sprintf('DICOM_info_%d_%d = DICOM_info;',jj,ii));
                                checker = 2;
                            else
                                ext = '.img';
                                Spetimg = [pathstr '\' name ext];
                                Spethdr = [pathstr '\' name '.hdr'];
                                petimg = [imdur '\' name ext];
                                pethdr = [imdur '\' name '.hdr'];
                                ACpetimg = [ACdur '\' name '.hdr'];
                                ACpethdr = [ACdur '\' name '.hdr'];
                                copyfile(Spetimg,ACpetimg)
                                copyfile(Spethdr,ACpethdr)
                                copyfile(Spetimg,petimg)
                                copyfile(Spethdr,pethdr)
                                eval(sprintf('DICOM_info_%d_%d = DICOM_info;',jj,ii));
                                checker = 2;
                            end
                            ext = '.img';
                            Spetimg = [pathstr '\' name ext];
                            Spethdr = [pathstr '\' name '.hdr'];
                            petimg = [imdur '\' name ext];
                            pethdr = [imdur '\' name '.hdr'];
                            ACpetimg = [ACdur '\' name '.hdr'];
                            ACpethdr = [ACdur '\' name '.hdr'];
                            copyfile(Spetimg,ACpetimg)
                            copyfile(Spethdr,ACpethdr)
                            copyfile(Spetimg,petimg)
                            copyfile(Spethdr,pethdr)
                            eval(sprintf('DICOM_info_%d_%d = DICOM_info;',jj,ii));
                            checker = 2;
                        end
                    end
                end
            end
        end
    end
end


%% Prompt to enter Dose injected and BMI
height = '';
sexchange = '';

for jj=1:sizeprotocol,
    Tracer_name = studyprotocol{jj+1,1};
    scanSelection = eval(sprintf('scanSelection_%d',jj));
    for ii=1:size(scanSelection,2);
        pet_name = scanlist{scanSelection(ii)};
        Dosedefault = cell(1,5);
        if exist('DICOM_info','var')==0,
            DICOM_info = cell(1,7);
        else
            DICOM_info = eval(sprintf('DICOM_info_%d_%d',jj,ii));
        end
        dose = DICOM_info{1,1};
        units = DICOM_info{1,3};
        
        if isempty(units) == 0,
            if strcmp('BQML',units) || strcmp('bqml',units),
                Dosedefault{1,2} = mat2str(dose/1000000);
            else
                Dosedefault{1,2} = '';
            end
        else
            Dosedefault{1,2} = '';
        end
        
        injectionTime = DICOM_info{1,2};
        if isempty(injectionTime) == 0,
            injhr = injectionTime(1:2);
            injmin = injectionTime(3:4);
            injsec = injectionTime(5:6);
            if size(injectionTime,2) > 7,
                if str2double(injectionTime(8))>=5
                    injsec = mat2str(str2double(injsec)+1);
                    if str2double(injsec)<10,
                        injsec = ['0' injsec];
                    elseif str2double(emmsec) == 60,
                        injmin = mat2str(str2double(injmin)+1);
                        if str2double(injmin)<10,
                            injmin = ['0' injmin];
                        end
                        injsec = '00';
                        if str2double(injmin) == 60,
                            injhr = mat2str(str2double(injhr)+1);
                            if str2double(injhr)<10,
                                injhr = ['0' injhr];
                            end
                            injmin = '00';
                        end
                    end
                end
            end
            Dosedefault{1,3} = [injhr ':' injmin ':' injsec];
        else
            Dosedefault{1,3} = '';
        end
        emmissionTime = DICOM_info{1,5};
        if isempty(emmissionTime) == 0,
            emmhr = emmissionTime(1:2);
            emmmin = emmissionTime(3:4);
            emmsec = emmissionTime(5:6);
            
            if size(emmissionTime,2) > 7,
                if str2double(emmissionTime(8))>=5
                    emmsec = mat2str(str2double(emmsec)+1);
                    if str2double(emmsec)<10,
                        emmsec = ['0' emmsec];
                    elseif str2double(emmsec) == 60,
                        emmmin = mat2str(str2double(emmmin)+1);
                        if str2double(emmmin)<10,
                            emmmin = ['0' emmmin];
                        end
                        emmsec = '00';
                        if str2double(emmmin) == 60,
                            emmhr = mat2str(str2double(emmhr)+1);
                            if str2double(emmhr)<10,
                                emmhr = ['0' emmhr];
                            end
                            emmmin = '00';
                        end
                    end
                end
            end
            Dosedefault{1,4} = [emmhr ':' emmmin ':' emmsec];
        else
            Dosedefault{1,4} = '';
        end
        
        framDur = DICOM_info{1,4};
        if isempty(framDur) == 0,
            framDur = mat2str(framDur*.000016666666666667);
            framMin = framDur(1:2);
            framSec = framDur(4:5);
            framSec = mat2str(str2double(framSec)*60);
            if str2double(framSec) == 0,
                framSec = ('000');
            end
            framMS = framSec(3);
            framSec = framSec(1:2);
            if str2double(framMS)>=5
                framSec = mat2str(str2double(framSec)+1);
                if str2dboule(framSec) == 1,
                    framSec = '01';
                elseif str2double(framSec) == 60,
                    framMin = mat2str(str2double(framMin)+1);
                    framSec = '00';
                end
            end
            Dosedefault{1,5} = [framMin ':' framSec];
        else
            Dosedefault{1,5} = '';
        end
        
        if isempty(framDur) == 0 && isempty(emmissionTime) == 0 && isempty(injectionTime) == 0 && isempty(units) == 0,
            injhr = str2double(Dosedefault{1,3}(1:2));
            injmin = str2double(Dosedefault{1,3}(4:5));
            injsec = str2double(Dosedefault{1,3}(7:8));
            emmhr = str2double(Dosedefault{1,4}(1:2));
            emmmin = str2double(Dosedefault{1,4}(4:5));
            emmsec = str2double(Dosedefault{1,4}(7:8));
            DeltaT = ((emmsec + emmmin * 60 + emmhr * 3600)-(injsec + injmin * 60 + injhr * 3600));
            DOSEemmission = ((str2double(Dosedefault{1,2}))/exp((0.693*(DeltaT/60))/109.8));
            Dosedefault{1,1} = mat2str(DOSEemmission);
        else
            Dosedefault{1,1} = '';
        end
        
        
        DOSEprompt = {'Enter Decay corrected Dose at Emission Start Time(MBq):','or Enter Injected Dose (MBq):',...
            'and Enter Injection Time (hh:mm:ss)','and Enter Emission Start Time (hh:mm:ss)',...
            'and Enter frame duration (min):'};
        msgDose = ['Enter Does information for ' pet_name ' :'];
        msg = pet_name;
        dlg_title = msg;
        num_lines = 1;
        uiwait(msgbox(msgDose,'SUV'));
        DOSEinputs = inputdlg(DOSEprompt,dlg_title,num_lines,Dosedefault);
        if isempty(DOSEinputs{1,1}) == 1,
            while isempty(DOSEinputs{1,1}) == 1 && isempty(DOSEinputs{2,1}) == 1 || isempty(DOSEinputs{3,1}) == 1 || isempty(DOSEinputs{4,1}) == 1 || isempty(DOSEinputs{5,1}) == 1
                msgwarndose = 'Either the Decay corrected dose at emmission start time must be entered or the Injected Dose and Injection Time and Emission Start Time and Frame Durration must be entered.';
                uiwait(msgbox(msgwarndose,'SUV'));
                DOSEinputs = inputdlg(DOSEprompt,dlg_title,num_lines,Dosedefault);
            end
        end
        eval(sprintf('DOSEinputs_%d_%d = DOSEinputs;',jj,ii));
        clear DOSEinputs Dosedefault
        
        
        SUVprompt = {'and Enter Weight (kg):','Enter Height (cm):','and Enter Gender (M/F):','Enter BMI:','Enter BSA:','Enter LBM:'};
        SUVdefault = cell(1,6);
        weight = DICOM_info{1,6};
        if isempty(weight) == 0,
            SUVdefault{1,1} = mat2str(weight);
        else
            SUVdefault{1,1} = '';
        end
        SUVdefault{1,2} = height;
        sex = DICOM_info{1,7};
        if isempty(sex) == 0,
            SUVdefault{1,3} = sex;
        else
            SUVdefault{1,3} = sexchange;
        end
        SUVdefault{1,4} = '';
        SUVdefault{1,5} = '';
        SUVdefault{1,6} = '';
                
        msgSUV = ['Enter SUV information for ' pet_name ' :'];
        dlg_title = pet_name;
        num_lines = 1;
        uiwait(msgbox(msgSUV,'SUV'));
        SUVinputs = inputdlg(SUVprompt,dlg_title,num_lines,SUVdefault);
        
         
        if Selection == 1,
            while isempty(SUVinputs{1,1}) == 1,
                msgwarnSUV = 'Weight must be entered.';
                uiwait(msgbox(msgwarnSUV,'SUV'));
                SUVinputs = inputdlg(SUVprompt,dlg_title,num_lines,SUVdefault);
            end
        elseif Selection == 2,
            while isempty(SUVinputs{1,1}) == 1 && isempty(SUVinputs{2,1}) == 1 || isempty(SUVinputs{5,1}) == 1
                msgwarnSUV = 'Either a Height and Weight is entered or the BSA.';
                uiwait(msgbox(msgwarnSUV,'SUV'));
                SUVinputs = inputdlg(SUVprompt,dlg_title,num_lines,SUVdefault);
            end
            height = SUVinputs{2,1};
        elseif Selection == 3,
            while isempty(SUVinputs{1,1}) == 1 && isempty(SUVinputs{2,1}) == 1 && isempty(SUVinputs{3,1}) == 1 || isempty(SUVinputs{6,1}) == 1
                msgwarnSUV = 'Either a Height, Weight, and Gender is entered or the LBM.';
                uiwait(msgbox(msgwarnSUV,'SUV'));
                SUVinputs = inputdlg(SUVprompt,dlg_title,num_lines,SUVdefault);
            end
            height = SUVinputs{2,1};
            sexchange = SUVinputs{3,1};
        elseif Selection == 4,
            while isempty(SUVinputs{1,1}) == 1 && isempty(SUVinputs{2,1}) == 1 || isempty(SUVinputs{4,1}) == 1
                msgwarnSUV = 'Either a Height and Weight is entered or the BMI.';
                uiwait(msgbox(msgwarnSUV,'SUV'));
                SUVinputs = inputdlg(SUVprompt,dlg_title,num_lines,SUVdefault);
            end
            height = SUVinputs{2,1};
        elseif Selection == 5,
            while isempty(SUVinputs{1,1}) == 1 && isempty(SUVinputs{2,1}) == 1 && isempty(SUVinputs{3,1}) == 1 || isempty(SUVinputs{1,1}) == 1 && isempty(SUVinputs{4,1}) == 1 && isempty(SUVinputs{5,1}) == 1 && isempty(SUVinputs{6,1}) == 1
                msgwarnSUV = 'Either a Height, Weight, and Gender is entered or the Weight, BSA, LBM, and BMI.';
                uiwait(msgbox(msgwarnSUV,'SUV'));
                SUVinputs = inputdlg(SUVprompt,dlg_title,num_lines,SUVdefault);
            end
            height = SUVinputs{2,1};
            sexchange = SUVinputs{3,1};
        end
        
        eval(sprintf('SUVinputs_%d_%d = SUVinputs;',jj,ii));
        clear SUVdefault SUVinputs
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Calculate SUV


%% SUV equation
for jj=1:sizeprotocol,
    Tracer_name = studyprotocol{jj+1,1};
    scanSelection = eval(sprintf('scanSelection_%d',jj));
    for ii=1:size(scanSelection,2);
        pet_name = scanlist{scanSelection(ii)};
        pet_dir = [sub_dir '\' pet_name];
        petstruct = dir(pet_dir);
        petstruct = {petstruct(~[petstruct.isdir]).name};
        
        ManACPETdir = [ManACdir '\' pet_name];
        if exist(ManACPETdir,'dir') == 0;
            mkdir(ManACPETdir);
        end
        
        pet_file = [pet_dir '\' petstruct{1}];
        [pathstr, name, ext] = fileparts(pet_file);
        
        if Selection == 1,
            if strcmp(ext,'.hdr')
                ext = '.img';
            end
            SUVname = [pathstr '\' name '_SUV-BW' ext];
        elseif Selection == 2,
            if strcmp(ext,'.hdr')
                ext = '.img';
            end
            SUVname = [pathstr '\' name '_SUV-BSA' ext];
        elseif Selection == 3,
            if strcmp(ext,'.hdr')
                ext = '.img';
            end
            SUVname = [pathstr '\' name '_SUV-LBM' ext];
        elseif Selection == 4,
            if strcmp(ext,'.hdr')
                ext = '.img';
            end
            SUVname = [pathstr '\' name '_SUV-BMI' ext];
        elseif Selection == 5,
            if strcmp(ext,'.hdr')
                ext = '.img';
            end
            namebw = [pathstr '\' name '_SUV-BW' ext];
            namebsa = [pathstr '\' name '_SUV-BSA' ext];
            namelbm = [pathstr '\' name '_SUV-LBM' ext];
            namebmi = [pathstr '\' name '_SUV-BMI' ext];
        end
        
        SUVinputs = eval(sprintf('SUVinputs_%d_%d',jj,ii));
        DOSEinputs = eval(sprintf('DOSEinputs_%d_%d',jj,ii));
        
        if Selection == 1,
            SUV = (str2double(SUVinputs{1,1})*1000);
        elseif Selection == 2,
            if isempty(SUVinputs{4,1}) == 1,
                SUV = (((str2double(SUVinputs{1,1})^0.425)*(((str2double(SUVinputs{2,1}))^0.725)*0.007184))*10000);
            else
                SUV = (str2double(SUVinputs{4,1}));
            end
        elseif Selection == 3,
            if isempty(SUVinputs{5,1}) == 1,
                gender = SUVinputs{3,1};
                if isempty(strfind(gender,'F')) == 1
                    SUV = (((1.07*str2double(SUVinputs{1,1}))-(148*((str2double(SUVinputs{1,1})/str2double(SUVinputs{2,1}))^2)))*1000);
                elseif isempty(strfind(gender,'f')) == 1
                    SUV = (((1.07*str2double(SUVinputs{1,1}))-(148*((str2double(SUVinputs{1,1})/str2double(SUVinputs{2,1}))^2)))*1000);
                else
                    SUV = (((1.10*str2double(SUVinputs{1,1}))-(128*((str2double(SUVinputs{1,1})/str2double(SUVinputs{2,1}))^2)))*1000);
                end
            else
                SUV = (str2double(SUVinputs{5,1})*1000);
            end
        elseif Selection == 4,
            if isempty(SUVinputs{6,1}) == 1,
                SUV = ((str2double(SUVinputs{1,1})/(((str2double(SUVinputs{2,1}))*0.01)^2))*1000);
                % SUV = (str2double(SUVinputs{3,1})/((str2double(SUVinputs{2,1}))*0.01)*(str2double(SUVinputs{2,1})*0.01));
            else
                SUV = (str2double(SUVinputs{6,1})*1000);
            end
        elseif Selection == 5,
            SUVbw = (str2double(SUVinputs{1,1})*1000);
            if isempty(SUVinputs{4,1}) == 1,
                SUVbsa = (((str2double(SUVinputs{1,1})^0.425)*(((str2double(SUVinputs{2,1}))^0.725)*0.007184))*10000);
            else
                SUVbsa = (str2double(SUVinputs{4,1}));
            end
            if isempty(SUVinputs{5,1}) == 1,
                gender = SUVinputs{3,1};
                if isempty(strfind(gender,'F')) == 1
                    SUVlbm = (((1.07*str2double(SUVinputs{1,1}))-(148*((str2double(SUVinputs{1,1})/str2double(SUVinputs{2,1}))^2)))*1000);
                elseif isempty(strfind(gender,'f')) == 1
                    SUVlbm = (((1.07*str2double(SUVinputs{1,1}))-(148*((str2double(SUVinputs{1,1})/str2double(SUVinputs{2,1}))^2)))*1000);
                else
                    SUVlbm = (((1.10*str2double(SUVinputs{1,1}))-(128*((str2double(SUVinputs{1,1})/str2double(SUVinputs{2,1}))^2)))*1000);
                end
            else
                SUVlbm = (str2double(SUVinputs{5,1})*1000);
            end
            if isempty(SUVinputs{6,1}) == 1,
                SUVbmi = ((str2double(SUVinputs{1,1})/(((str2double(SUVinputs{2,1}))*0.01)^2))*1000);
                % SUV = (str2double(SUVinputs{3,1})/((str2double(SUVinputs{2,1}))*0.01)*(str2double(SUVinputs{2,1})*0.01));
            else
                SUVbmi = (str2double(SUVinputs{6,1})*1000);
            end
        end
        
        
        
        if isempty(DOSEinputs{1,1}) == 1,
            %             strinjhr = strfind(DOSEinputs{3,1},':');
            %             if strinjhr(1)==2,
            %                 injhr = ['0' DOSEinputs{3,1}(1:1)];
            %                 injhr = str2double(injhr);
            %             elseif strinjhr(1)==3,
            injhr = str2double(DOSEinputs{3,1}(1:2));
            injmin = str2double(DOSEinputs{3,1}(4:5));
            injsec = str2double(DOSEinputs{3,1}(7:8));
            emmhr = str2double(DOSEinputs{4,1}(1:2));
            emmmin = str2double(DOSEinputs{4,1}(4:5));
            emmsec = str2double(DOSEinputs{4,1}(7:8));
            DeltaT = (emmsec + emmmin * 60 + emmhr * 3600)-(injsec + injmin * 60 + injhr * 3600);
            DOSEemmission = ((str2double(DOSEinputs{2,1}))/exp((0.693*(DeltaT/60))/109.8));
        else
            DOSEemmission = str2double(DOSEinputs{1,1});
        end
                
        if Selection == 5,
            SUVequbw = ['(i1*0.000001)/(' mat2str(DOSEemmission) '/' mat2str(SUVbw) ')'];
            SUVequbsa = ['(i1*0.000001)/(' mat2str(DOSEemmission) '/' mat2str(SUVbsa) ')'];
            SUVequlbm = ['(i1*0.000001)/(' mat2str(DOSEemmission) '/' mat2str(SUVlbm) ')'];
            SUVequbmi = ['(i1*0.000001)/(' mat2str(DOSEemmission) '/' mat2str(SUVbmi) ')'];
            BW_calc = spm_imcalc_ui(pet_file,namebw,SUVequbw);
            BSA_calc = spm_imcalc_ui(pet_file,namebsa,SUVequbsa);
            LBM_calc = spm_imcalc_ui(pet_file,namelbm,SUVequlbm);
            BMI_calc = spm_imcalc_ui(pet_file,namebmi,SUVequbmi);
            
            textfile = [pathstr '\' sub '_PET_' pet_name '_SUV-BW-equation.txt'];
            fid=fopen(textfile,'wt');
            fprintf(fid,'%s',SUVequbw);
            fclose(fid);
            textfile = [pathstr '\' sub '_PET_' pet_name '_SUV-BSA-equation.txt'];
            fid=fopen(textfile,'wt');
            fprintf(fid,'%s',SUVequbsa);
            fclose(fid);
            textfile = [pathstr '\' sub '_PET_' pet_name '_SUV-LBM-equation.txt'];
            fid=fopen(textfile,'wt');
            fprintf(fid,'%s',SUVequlbm);
            fclose(fid);
            textfile = [pathstr '\' sub '_PET_' pet_name '_SUV-BMI-equation.txt'];
            fid=fopen(textfile,'wt');
            fprintf(fid,'%s',SUVequbmi);
            fclose(fid);
            
            [suvPath,suv_Name,suvExt] = fileparts(namebw);
            if strcmp(suvExt,'.img') == 1,
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                SUVhdrout = [ManACdir '\' pet_name '\' suv_Name '.hdr'];
                SUVhdrin = [suvPath '\' suv_Name '.hdr'];
                copyfile(namebw,SUVimgout,'f');
                copyfile(SUVhdrin,SUVhdrout,'f');
            else
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                copyfile(namebw,SUVimgout,'f');
            end
            clear suvPath suv_Name suvExt
            
            [suvPath,suv_Name,suvExt] = fileparts(namebsa);
            if strcmp(suvExt,'.img') == 1,
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                SUVhdrout = [ManACdir '\' pet_name '\' suv_Name '.hdr'];
                SUVhdrin = [suvPath '\' suv_Name '.hdr'];
                copyfile(namebsa,SUVimgout,'f');
                copyfile(SUVhdrin,SUVhdrout,'f');
            else
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                copyfile(namebsa,SUVimgout,'f');
            end
            clear suvPath suv_Name suvExt
            
            [suvPath,suv_Name,suvExt] = fileparts(namelbm);
            if strcmp(suvExt,'.img') == 1,
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                SUVhdrout = [ManACdir '\' pet_name '\' suv_Name '.hdr'];
                SUVhdrin = [suvPath '\' suv_Name '.hdr'];
                copyfile(namelbm,SUVimgout,'f');
                copyfile(SUVhdrin,SUVhdrout,'f');
            else
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                copyfile(namelbm,SUVimgout,'f');
            end
            clear suvPath suv_Name suvExt
            
            [suvPath,suv_Name,suvExt] = fileparts(namebmi);
            if strcmp(suvExt,'.img') == 1,
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                SUVhdrout = [ManACdir '\' pet_name '\' suv_Name '.hdr'];
                SUVhdrin = [suvPath '\' suv_Name '.hdr'];
                copyfile(namebmi,SUVimgout,'f');
                copyfile(SUVhdrin,SUVhdrout,'f');
            else
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                copyfile(namebmi,SUVimgout,'f');
            end
            clear suvPath suv_Name suvExt
            
        else
            SUVequ = ['(i1*0.000001)/(' mat2str(DOSEemmission) '/' mat2str(SUV) ')'];
            SUV_calc = spm_imcalc_ui(pet_file,SUVname,SUVequ);
            
            suv_type = regexprep(S(Selection),'[^\w'']','');
            
            textfile = [pathstr '\' sub '_PET_' pet_name '_SUV-' suv_type '-equation.txt'];
            fid=fopen(textfile,'wt');
            fprintf(fid,'%s',SUVequ);
            fclose(fid);
            
            
            [suvPath,suv_Name,suvExt] = fileparts(SUVname);
            if strcmp(suvExt,'.img') == 1,
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                SUVhdrout = [ManACdir '\' pet_name '\' suv_Name '.hdr'];
                SUVhdrin = [suvPath '\' suv_Name '.hdr'];
                copyfile(SUVname,SUVimgout,'f');
                copyfile(SUVhdrin,SUVhdrout,'f');
            else
                SUVimgout = [ManACdir '\' pet_name '\' suv_Name ext];
                copyfile(SUVname,SUVimgout,'f');
            end
            
        end
        %         (60*str2double(DOSEinputs{5,1}(1:2)))+str2double(DOSEinputs{5,1}(
        %         4:5)) % Equation for converting frame durration to seconds to be
        %         added to the DeltaT so that a 2nd frame can be decay corrected.
        
    end
end



if strcmp(mrext,'.img,1')==1,
    inputimg = [mrpath '\' mrname '.img'];
    inputhdr = [mrpath '\' mrname '.hdr'];
    outputimg = [ManACdir '\' mrname '.img'];
    outputhdr = [ManACdir '\' mrname '.hdr'];
    copyfile(inputimg,outputimg,'f');
    copyfile(inputhdr,outputhdr,'f');
else
    inputimg = [mrpath '\' mrname '.nii'];
    outputimg = [ManACdir '\' sub '_MR-' MRlist{mrSelection} '-1.nii'];
    copyfile(inputimg,outputimg,'f');
end

clc
disp('DONE!');

end