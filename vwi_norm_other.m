function vwi_norm_other()

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

msg = 'Please select source image(s)';
source_dir = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');

msg = 'Please select images to normalize';
norm_dir = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');

%% Prompt to select SPM Template type for Source Images
msg = ('Please select Template that matches source images:');
Template = spm_select(1:1,'image', msg ,[],spm8_template,'\.(nii|img)$');
clear msg;

Sdir = [proc_dir '\Source'];
Ndir = [proc_dir '\Other'];
if exist(Sdir,'dir') == 0;
    mkdir(Sdir);
end

if exist(Ndir,'dir') == 0;
    mkdir(Ndir);
end

Source_vol = cell(size(source_dir,1),1);

for ii=1:size(source_dir,1),
    [pathstr, name, ext] = fileparts(source_dir(ii,:));
    stringext = strfind(ext,'.img');
    if isempty(stringext)
        ext = ('.nii');
        imgs = [pathstr '\' name ext];
        Simgs = [Sdir '\' name ext];
        copyfile(imgs,Simgs,'f');
        clear imgs 
    else
        ext = ('.img');
        hdr = ('.hdr');
        imgs = [pathstr '\' name ext];
        Simgs = [Sdir '\' name ext];
        copyfile(imgs,Simgs,'f');
        filehdr = [pathstr '\' name hdr];
        Shdr = [Sdir '\' name hdr];
        copyfile(filehdr,Shdr,'f');
        clear imgs hdr Shdr hdr
    end
    Source_vol{ii,:} = Simgs;
    clear pathstr name ext Simgs
end

Norm_vol = cell(size(norm_dir,1),1);

for ii=1:size(norm_dir,1),
    [pathstr, name, ext] = fileparts(norm_dir(ii,:));
    stringext = strfind(ext,'.img');
    if isempty(stringext)
        ext = ('.nii');
        imgs = [pathstr '\' name ext];
        Nimgs = [Ndir '\' name ext];
        copyfile(imgs,Nimgs,'f');
        clear imgs 
    else
        ext = ('.img');
        hdr = ('.hdr');
        imgs = [pathstr '\' name ext];
        Nimgs = [Ndir '\' name ext];
        copyfile(imgs,Nimgs,'f');
        filehdr = [pathstr '\' name hdr];
        Nhdr = [Ndir '\' name hdr];
        copyfile(filehdr,Nhdr,'f');
        clear imgs hdr Nhdr hdr
    end
    Norm_vol{ii,:} = Nimgs;
    clear pathstr name ext
end

spm_jobman('initcfg');
load([pth '\norm.mat']);

for ii=1:size(source_dir,1),
    [Spath,Sname,Sext] = fileparts(Source_vol{ii});
    Sourceimg = [Spath '\' Sname Sext ',1'];
    if Sname(5) == '_',
        ID = Sname(1:4);
    else
        ID = Sname(1:7);
    end
    count = 1;
    for jj = 1:size(norm_dir,1),
        [Normpath,Normname,Normext] = fileparts(Norm_vol{jj});
        if Normname(5) == '_',
            filename = Normname(1:4);
        else
            filename = Normname(1:7);
        end
        if strcmp(filename,ID),
            Normimgs{count,1} = [Normpath '\' Normname Normext ',1'];
            count = (count+1);
        end
        clear Normpath Normname Normext
    end
    Norm_imgs = Normimgs(~cellfun('isempty',Normimgs));
    clear ID Spath Sname Sext count
           
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {Sourceimg};
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = (Norm_imgs);
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {Template};
    %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
    Norm = spm_jobman('run',matlabbatch);
    clear Norm_imgs Normimgs
end

Normalized_data = dir([Ndir, '\w*']);
Normalized_size = size(Normalized_data,1);

for ii=1:1:Normalized_size,
    [~, name, ext] = fileparts(Normalized_data(ii).name);
    imgs = [Ndir '\' name ext];
    Wimgs = [proc_dir '\' name ext];
    movefile(imgs,Wimgs,'f');
    clear imgs Wimgs name ext
end

disp('DONE!');

end