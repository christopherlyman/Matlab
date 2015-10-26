function Master_File_static()

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

if exist('sub','var'),
    sub = evalin('base','sub');
else
    sub = 'BATCH';
end
study = evalin('base','study');
[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;

study_dir = [studyprotocol{1,2} '\03_Pre-Processing'];


if strcmp(sub,'BATCH'),
    dir_study = dir(study_dir);
    for kk = length(dir_study):-1:1
        % remove folders starting with .
        fname = dir_study(kk).name;
        if fname(1) == '.'
            dir_study(kk) = [ ];
        end
        if fname(1) == '!'
            dir_study(kk) = [ ];
        end
        if ~dir_study(kk).isdir
            dir_study(kk) = [ ];
            continue
        end
    end
    
    sublist = cell(size(dir_study,1),1);
    for kk = 1:1:size(dir_study,1),
        sublist{kk,:} = [dir_study(kk).name];
    end
    
    [subSelection,sok] = listdlg('PromptString','Select Subject(s) to Process:',...
        'SelectionMode','multiple','ListSize',[200 500],'Name','VWI','ListString',sublist);
    while isempty(subSelection)
        uiwait(msgbox('Error: You must select at least one Select Subject to Process.','Error message','error'));
        [subSelection,sok] = listdlg('PromptString','Select Subject(s) to Process:',...
            'SelectionMode','multiple','ListSize',[200 500],'Name','VWI','ListString',sublist);
    end
    
    sub = sublist(subSelection);
    sublength = sub;
else
    sublength{:,:} = sub;
    sub = sublength;
end

BMImaster = [study_dir '\FNMI_ROI-Stats_BMI-Master.xlsx'];
LBMmaster = [study_dir '\FNMI_ROI-Stats_LBM-Master.xlsx'];
BWmaster = [study_dir '\FNMI_ROI-Stats_BW-Master.xlsx'];
BSAmaster = [study_dir '\FNMI_ROI-Stats_BSA-Master.xlsx'];

for ii=1:1:size(sublength,1),
    sub = sublength{ii,:};
    sub_dir = [study_dir '\' sub];
    sub_filename = dir([sub_dir, '\*.xlsx']);
    
    dir_sub = dir(sub_dir);
    for kk = length(dir_sub):-1:1
        % remove folders starting with .
        fname = dir_sub(kk).name;
        if fname(1) == '.'
            dir_sub(kk) = [ ];
        end
        if fname(1) == '!'
            dir_sub(kk) = [ ];
        end
        if ~dir_sub(kk).isdir
            dir_sub(kk) = [ ];
            continue
        end
        if fname(1) == 'R'
            dir_sub(kk) = [ ];
        end
    end
    
    Count = 1;
    for jj=1:1:size(dir_sub,1),
        PET_dir = [sub_dir '\' dir_sub(jj).name];
        dir_PET = dir([PET_dir,'\r*SUV*.nii']);
        for gg = 1:1:size(dir_PET,1),
            PET_list{Count,1} = [PET_dir '\' dir_PET(gg).name];
            Count= Count+1;
        end
    end
    
    for jj = 1:1:size(PET_list,1),
        [~,sheetname,~]=fileparts(PET_list{jj,:});
        [~,~,raw]=xlsread([sub_dir '\' sub_filename.name],sheetname);
        data = raw(1:end,2);
        clear raw
        
        pet = sheetname(length(sub)+7:end);
        pettemp = strfind(pet,'_');
        pet = pet(1:pettemp-1);
        data{1,1} = [sub '_' pet '_Mean'];
        
        if strfind(sheetname,'BW'),
            master = BWmaster;
            mastersheetname = 'BW-Mean';
        elseif strfind(sheetname,'BMI'),
            master = BMImaster;
            mastersheetname = 'BMI-Mean';
        elseif strfind(sheetname,'BSA'),
            master = BSAmaster;
            mastersheetname = 'BSA-Mean';
        elseif strfind(sheetname,'LBM'),
            master = LBMmaster;
            mastersheetname = 'LBM-Mean';
        end
        
        [~,~,initial_array] = xlsread(master,mastersheetname);
        col_size = size(initial_array,2);
        initial_array(:,col_size+1) = data;
        warning('off','MATLAB:xlswrite:AddSheet');
        excel = xlswrite(master,initial_array,mastersheetname);
        waitfor(excel);
        clear sheetname mastersheetname master col_size initial_array
    end
    clear PET_list dir_sub
end

clc
disp('DONE!');
end