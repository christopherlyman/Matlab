%% HOW TO FIND A VOXEL THAT MATCHES A GIVEN MM COORDINATE SET!!!!!

clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc
spm_get_defaults('cmdline',true);

msg = ('Please select base Image(s):');
base_image = spm_select(Inf,'image', msg ,[],pwd,'\.(img|nii)$');

clear msg;
while isempty(base_image) == 1,
    msg = ('Please select base Image(s):');
    base_image = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
    clear msg;
end

prompt = {'X:','Y:','Z:'}; % x,y,z coordinates for your target voxel
dlg_title = 'Enter SPM coordinates:';
num_lines = 1;
coords = inputdlg(prompt,dlg_title,num_lines);
targ_coords = [str2double(coords{1});str2double(coords{2});str2double(coords{3})];

% do this once for your first subject, just to get the target voxel indices
V = spm_vol(base_image(1,:));
[Y,XYZmm] = spm_read_vols(V);
% targ_coords = [0 0 0]'; % x,y,z coordinates for your target voxel
targ_mtx = repmat(targ_coords,1,size(XYZmm,2));

idx = find(sum(round(XYZmm) == targ_mtx,1)==3);

targ_voxels = XYZmm(1:3,idx);

% Y01(targ_voxels);
% Y01(targ_voxels,1);
% Y02(targ_voxels,2);
nsub = size(base_image,1);
vox_values = nan(1,nsub);
for k=1:nsub
   V = spm_vol(base_image(k,:)); % PET file for subject k
   Y = spm_read_vols(V);

   vox_values(k) = Y(idx);
   
end % for k=1:nsub

str2double(coords)'
vox_values'

