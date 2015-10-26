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

for ii = 1:1:size(sub,1),
    working_dir = [proc_dir '\' str2mat(sub(ii)) '\NIfTI\Cortical\'];
    roi_dir = dir([working_dir, '*Bi_pars*']);
    
    vwi_rois = {roi_dir.name};
    vwi_rois = str2mat(vwi_rois);
    
    for jj=1:size(vwi_rois,1)
        input_rois(jj,1) = {[working_dir deblank(vwi_rois(jj,:)) ',1']};
    end;
    
    exp = '((i1>0)+(i2>0)+(i3>0))>0';
    
    output_roi = [working_dir str2mat(sub(ii)) '_Bi_inferiorfrontal.nii'];
    
    spm_imcalc_ui(input_rois,output_roi,exp);
    
    clear input_rois output_roi roi_dir working_dir exp
    
    working_dir = [proc_dir '\' str2mat(sub(ii)) '\NIfTI\Cortical\'];
    roi_dir = dir([working_dir, '*Bi_*anteriorcingulate*']);
    
    vwi_rois = {roi_dir.name};
    vwi_rois = str2mat(vwi_rois);
    
    for jj=1:size(vwi_rois,1)
        input_rois(jj,1) = {[working_dir deblank(vwi_rois(jj,:)) ',1']};
    end;
    
    exp = '((i1>0)+(i2>0))>0';
    
    output_roi = [working_dir str2mat(sub(ii)) '_Bi_anteriorcingulate.nii'];
    
    spm_imcalc_ui(input_rois,output_roi,exp);
    
    clear input_rois output_roi roi_dir working_dir exp
    
    working_dir = [proc_dir '\' str2mat(sub(ii)) '\NIfTI\Cortical\'];
    roi_dir = dir([working_dir, '*Bi_*orbitofrontal*']);
    
    vwi_rois = {roi_dir.name};
    vwi_rois = str2mat(vwi_rois);
    
    for jj=1:size(vwi_rois,1)
        input_rois(jj,1) = {[working_dir deblank(vwi_rois(jj,:)) ',1']};
    end;
    
    exp = '((i1>0)+(i2>0))>0';
    
    output_roi = [working_dir str2mat(sub(ii)) '_Bi_orbitofrontal.nii'];
    
    spm_imcalc_ui(input_rois,output_roi,exp);
    
    clear input_rois output_roi roi_dir working_dir exp    
    
    working_dir = [proc_dir '\' str2mat(sub(ii)) '\NIfTI\Cortical\'];
    roi_dir = dir([working_dir, '*Bi_*middlefrontal*']);
    
    vwi_rois = {roi_dir.name};
    vwi_rois = str2mat(vwi_rois);
    
    for jj=1:size(vwi_rois,1)
        input_rois(jj,1) = {[working_dir deblank(vwi_rois(jj,:)) ',1']};
    end;
    
    exp = '((i1>0)+(i2>0))>0';
    
    output_roi = [working_dir str2mat(sub(ii)) '_Bi_middlefrontal.nii'];
    
    spm_imcalc_ui(input_rois,output_roi,exp);
    
    clear input_rois output_roi roi_dir working_dir exp    
    
end

disp('Done!');

end
