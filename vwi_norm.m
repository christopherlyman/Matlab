function vwi_norm()

clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));
spm8_template = [spm8_path '\templates'];

while true
    try spm_rmpath;
    catch
        break;
    end
end

addpath(spm8_path,'-frozen');

clc

spm_get_defaults('cmdline',true);

%% Define Dirs and set SPM8 path
uiwait(msgbox('Please select the directory to process the data.','VWI'));
proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

msg = 'Please select image(s) to normalize';
Reference_data = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');

msg = 'Please select source images';
Source_data = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');

%% Prompt to select SPM Template type for Source Images
msg = ('Please select Template that matches source images:');
Template = spm_select(1:1,'image', msg ,[],spm8_template,'\.(nii|img)$');
clear msg;

Norm_dir = [proc_dir '\Norm\'];
if exist(Norm_dir,'dir') == 0;
    mkdir(Norm_dir);
end
Source_dir = [Norm_dir '\Source\'];
Reference_dir = [Norm_dir '\Reference\'];
if exist(Source_dir,'dir') == 0;
    mkdir(Source_dir);
end

if exist(Reference_dir,'dir') == 0;
    mkdir(Reference_dir);
end

norm_vol = cell(size(Reference_data,1),1);

for ii=1:size(Reference_data,1),
    [pathstr, name, ext] = fileparts(Reference_data(ii,:));
    stringext = strfind(ext,'.img');
    if isempty(stringext)
        ext = ('.nii');
        imgs = [pathstr '\' name ext];
        Nimgs = [Reference_dir '\' name ext];
        copyfile(imgs,Nimgs,'f');
        clear imgs 
    else
        ext = ('.img');
        hdr = ('.hdr');
        imgs = [pathstr '\' name ext];
        Nimgs = [Reference_dir '\' name ext];
        copyfile(imgs,Nimgs,'f');
        filehdr = [pathstr '\' name hdr];
        Nhdr = [Reference_dir '\' name hdr];
        copyfile(filehdr,Nhdr,'f');
        clear imgs hdr Nhdr hdr
    end
    norm_vol{ii,:} = Nimgs;
    clear pathstr name ext
end

for ii=1:size(Source_data,1),
    [pathstr, name, ext] = fileparts(Source_data(ii,:));
    stringext = strfind(ext,'.img');
    if isempty(stringext)
        ext = ('.nii');
        imgs = [pathstr '\' name ext];
        Nimgs = [Source_dir '\' name ext];
        copyfile(imgs,Nimgs,'f');
        clear imgs 
    else
        ext = ('.img');
        hdr = ('.hdr');
        imgs = [pathstr '\' name ext];
        Nimgs = [Source_dir '\' name ext];
        copyfile(imgs,Nimgs,'f');
        filehdr = [pathstr '\' name hdr];
        Nhdr = [Source_dir '\' name hdr];
        copyfile(filehdr,Nhdr,'f');
        clear imgs hdr Nhdr hdr
    end
    source_vol{ii,:} = Nimgs;
    clear pathstr name ext
end

spm_jobman('initcfg');
load([pth '\norm.mat'])

for ii=1:size(norm_vol,1),
    Normimg = deblank([norm_vol{ii} ',1']);
    Sourceimg = deblank([source_vol{ii} ',1']);
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {Sourceimg};
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {Normimg};
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {Template};
    %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
    Norm = spm_jobman('run',matlabbatch);
end

Normalized_data = dir([Reference_dir, '\w*']);
Normalized_size = size(Normalized_data,1);

for ii=1:1:Normalized_size,
    [~, name, ext] = fileparts(Normalized_data(ii).name);
    imgs = [Reference_dir '\' name ext];
    Wimgs = [Norm_dir '\' name ext];
    movefile(imgs,Wimgs,'f');
    clear imgs Wimgs pathstr name ext
end

disp('DONE!');

end