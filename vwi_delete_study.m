function vwi_delete_study
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

[Selection,ok] = listdlg('PromptString','Select Study to delete:',...
    'SelectionMode','single','ListSize',[160 200],'Name','VWI','ListString',studies);
while isempty(Selection)
    return,
end

delete_name = studies{Selection};

check_question = questdlg(['Are you sure you want to delete the study ' delete_name '?'], ...
    'VWI', ...
    'Yes','No','No');
% Handle response
switch check_question
    case 'Yes'
        disp('Deleting selected study...');
        Answer = 1;
    case 'No'
        Answer = 0;
end

if Answer == 1,
    studies(Selection) = [];

    textfile = [pth '\Studies\Studies.txt'];
    fid=fopen(textfile,'wt');
    fprintf(fid,'%s\n',studies{:,:});
    fclose(fid);
    
    delete([pth '\Studies\' delete_name '.xlsx']);
    
end

end

