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

proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

msg = ('Please select base Image(s):');
base_image = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');

read_base = spm_vol(base_image(1,:));
conv_base = spm_read_vols(read_base);

Imgs_mean = mean(conv_base(:));
thresh_mean = mean(conv_base(:))/8;
Imgs_thresh = find(conv_base(:)>thresh_mean);
final_mean = mean(conv_base(Imgs_thresh));
disp(final_mean);



