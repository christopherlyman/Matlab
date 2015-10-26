function bp2dvr()
%
%   Converts BP PET images into DVR by adding 1.0 to all BP images.
%%
clear all
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));



msg = ('Please select directory containing BP images:');
bp_dir = uigetdir(home_dir,msg);

msg = ('Please select output directory for DVR images:');
dvr_dir = uigetdir(bp_dir,msg);


while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc

spm_get_defaults('cmdline',true);

bpdir = dir(bp_dir);
sizebpdir = size(bpdir,1);

for ii=1:sizebpdir,
    isdir = bpdir(ii).isdir;
    if isdir == 0,
        fullname = [bp_dir '\' bpdir(ii).name];
        [pathstr, name, ext] = fileparts(fullname);
        if strcmp(ext,'.img')==1,
            current_vol = [fullname ',1'];
            vol_out = [dvr_dir '\' name ext];
            exp = 'i1+1.0';
            spm_imcalc_ui(current_vol,vol_out,exp);
        elseif strcmp(ext,'.nii')==1,
            current_vol = [fullname ',1'];
            vol_out = [dvr_dir '\' name ext];
            exp = 'i1+1.0';
            spm_imcalc_ui(current_vol,vol_out,exp);
        end
        clear pathstr name ext fullname
    end
end

disp('DONE!');

end