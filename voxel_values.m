function voxel_values()


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

V=spm_vol(spm_get(Inf,'*.img'));

prompt = {'X:','Y:','Z:'};
dlg_title = 'Coordinates';
num_lines = 1;
coords = inputdlg(prompt,dlg_title,num_lines);
x = str2double(coords{1});
y = str2double(coords{2});
z = str2double(coords{3});

dat = zeros(length(V),1);
for i=1:length(dat),
        dat(i) = spm_sample_vol(V(i),x,y,z,0);
end;

disp(dat);

end