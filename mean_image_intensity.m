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


msg = ('Please select Image(s) to display:');
display_image = spm_select(Inf,'image', msg ,[],pwd,'\.(img|nii)$');


for ii=1:1:size(display_image,1),
    V = spm_vol(display_image(ii,:));
    Y = spm_read_vols(V);
    Ymean = squeeze(mean(mean(Y,1),2));
    figure_name = sprintf('Image Number: %d', ii);
    hf = figure('Name',figure_name);
    imagesc(Ymean);
    ylabel('Slice#');
    xlabel('Volume#');
    
    pause(1);
    close(hf);
end

disp('DONE!');