function vwi_sum_vois(sub,study)
%
%        Kinetic Modeling Pipeline
%        sum_vois
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman
%
%        Usage: sum_vois(vdir)
%
%        vdir: single participant's directory containing unilateral VOIs.
%
%        Script to sum bilateral VOIs. Creates a subdirectory within the
%        participant's VOI directory (~\Summed\) in which the summed VOIs
%        are placed. Example below:
%
%        If you select this directory:
%        ~\Processing\1001\MPRAGE\KMP_VOIs_MRes\
%
%        ... bilateral VOIs will be outputted into this directory:
%        ~\Processing\1001\MPRAGE\KMP_VOIs_MRes\Summed\*.nii

%% Set directory if not previously specified
if exist('sub','var') == 0,
    Study_Sub;
    waitfor(Study_Sub);
    sub = evalin('base','sub');
    study = evalin('base','study');
end

%% Identify tracer and frames
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

[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;
study_dir = studyprotocol{1,2};
sub_dir = [study_dir '\Dynamic\' sub];

textfile = [sub_dir '\' sub '_MR-Scans.txt'];
fid = fopen(textfile);
mri_scans = textscan(fid,'%s%s','Whitespace','\t');
fclose(fid);
mr_name = cell2mat(mri_scans{1});
mr_num = cell2mat(mri_scans{2});


if str2double(mr_num)>1
    mrtype = [mr_name '_1'];
else
    mrtype = mr_name;
end
mri_pdir = [sub_dir '\' mrtype '\']; % Declare processing directories

vdir = [mri_pdir 'VWI_VOIs_MRes\'];
voi_fnames = dir(vdir);
voi_fnames = {voi_fnames(~[voi_fnames.isdir]).name};
voi_fnames = regexprep(voi_fnames, '(.*)Non(.*)Mask(.*)','');
voi_fnames = regexprep(voi_fnames, '(.*)Pons(.*)','');
voi_fnames = str2mat(voi_fnames(~cellfun('isempty', voi_fnames)));
[rows,~] = size(voi_fnames);
if exist([vdir 'Summed\'],'dir') == 0, mkdir([vdir 'Summed\']); end

%% Creating an array of VOIs
done_regions = [];
for ii=1:rows,
    voi_fname = deblank(voi_fnames(ii,:));
    voi_name = regexp(deblank(voi_fnames(ii,:)),sub,'split');
    [token,remain] = strtok(deblank(voi_name(2)), ['_']);
    voi_region = token{1};
    %Cliff's script for finding region names but is limited to subject
    %numbers without "_" in the names.
    %[token,remain] = strtok(deblank(voi_fnames(ii,:)), '_'); %
    %voi_region = deblank(strtok(remain(2:end), '_'));
    
    if isempty(cell2mat(strfind(done_regions,voi_region))),
        calc_array{1,:} = [vdir deblank(voi_fnames(ii,:)) ',1'];
        for jj=1:rows,
            if strfind(voi_fnames(jj,:),voi_region) & isempty(strfind(voi_fnames(jj,:),voi_fname)),
                calc_array = [calc_array;[vdir deblank(voi_fnames(jj,:)) ',1']];
            end
        end
        exp = [];
        if size(calc_array,1) > 1,
            for jj=1:size(calc_array),
                if isempty(exp); exp = ['i' num2str(jj)];
                else exp = [exp '+i' num2str(jj)]; end
            end;
        end
        exp = ['(' exp ')>0'];
        voi_out = [vdir 'Summed\' sub '_' voi_region '.nii'];
        bilateral_region = spm_imcalc_ui(calc_array,voi_out,exp);
        if strfind(voi_region,'Thalamus'),
            voi_info = spm_vol(bilateral_region);
            voi = spm_read_vols(voi_info);
            voi_info.fname = [bilateral_region(1,1:end-4) '_Eroded.nii'];
            eroded_voi = spm_erode(voi);
            spm_write_vol(voi_info,eroded_voi);
        end
        if isempty(done_regions), done_regions = {voi_region};
        else done_regions = [done_regions;voi_region]; end
    end
    clearvars -except vdir voi_fnames rows done_regions mri_pdir sub mr_name mr_num
end

% Copy pons into summed directory
pons_fname = dir([vdir '*Pons*.*']);
pons_newdir = [vdir 'Summed\' char(pons_fname.name(1:end-9)) '.nii'];
pons_fname = [vdir char(pons_fname.name)];
copyfile(pons_fname,pons_newdir);

% Copy CerGM VOI into CerGM directory
if exist([mri_pdir 'CerGM_VOI\'],'dir') == 0; % Create directory to store cerebellar GM VOI
    disp('Creating directory to store cerebellar gray matter VOI.');
    mkdir([mri_pdir 'CerGM_VOI\']);
end
cergm_fname = dir([vdir 'Summed\*MR.nii']);
cergm_newdir = [mri_pdir 'CerGM_VOI\' char(cergm_fname.name(1:end-4)) '_CerGM.nii'];
cergm_fname = [vdir 'Summed\' char(cergm_fname.name)];
movefile(cergm_fname,cergm_newdir);


end