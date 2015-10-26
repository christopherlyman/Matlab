function Hammers-Atlas()


clear all
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

Hammers_Atlas = {'Temporal Lobe',...
    'Hippocampus',...
    'Amygdala',...
    'Anterior temporal lobe medial part',...
    'Anterior temporal lobe, lateral part',...
    'Parahippocampal and ambient gyri',...
    'Superior temporal gyrus, posterior part',...
    'Middle and inferior temporal gyrus',...
    'Fusiform gyrus',...
    'Posterior temporal lobe',...
    'Superior temporal gyrus, anterior part',...
    'Posterior Fossa',...
    'Cerebellum',...
    'Brainstem',...
    'Insula and Cingulate gyri',...
    'Insula',...
    'Cingulate gyrus, anterior part',...
    'Cingulate gyurs, posterior part',...
    'Frontal Lobe',...
    'Middle frontal gyrus',...
    'Precentral gyrus',...
    'Straight gyrus',...
    'Anterior orbital gyrus',...
    'Inferior frontal gyrus',...
    'Superior frontal gyrus',...
    'Medial orbital gyrus',...
    'Lateral orbital gyrus',...
    'Posterior orbital gyrus',...
    'Subgenual frontal cortex',...
    'Subcallosal area',...
    'Pre-subgenual frontal cortex',...
    'Occipital Lobe',...
    'Lingual gyrus',...
    'Cuneus',...
    'Lateral remainder of occipital lobe',...
    'Parietal Lobe',...
    'Postcentral gyrus',...
    'Superior parietal gyrus',...
    'Inferiolateral remainder of parietal lobe',...
    'Central Structures',...
    'Caudate nucleus',...
    'Nucleus accumbens',...
    'Putamen',...
    'Thalamus',...
    'Pallidum',...
    'Corpus callosum',...
    'Substantia nigra',...
    'Ventricles',...
    'Lateral ventricle (excluding temporal horn)',...
    'Lateral ventricle, temporal horn',...
    'Third ventricle';}

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

study = evalin('base','study');
[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;

study_question = questdlg('What type of PET studies?', ...
    'VWI', ...
    'Static','Dynamic','Static');
% Handle response
switch study_question
    case 'Static'
        Answer = 1;
        study_dir = [studyprotocol{1,2} '\03_Pre-Processing'];
    case 'Dynamic'
        Answer = 2;
        study_dir = [studyprotocol{1,2} '\Dynamic'];
end


if exist('sub','var'),
    sub = evalin('base','sub');
    sublength{:,:} = sub;
    sub = sublength;
else
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
        'SelectionMode','multiple','ListSize',[200 500],'Name','VWI','ListString',Hammers_Atlas(:));
    while isempty(subSelection)
        uiwait(msgbox('Error: You must select at least one Select Subject to Process.','Error message','error'));
        [subSelection,sok] = listdlg('PromptString','Select Subject(s) to Process:',...
            'SelectionMode','multiple','ListSize',[200 500],'Name','VWI','ListString',Hammers_Atlas(:));
    end
    
    sub = sublist(subSelection);
    sublength = sub;
end