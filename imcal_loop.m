clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

while true
    try spm_rmpath;
    catch
        break;
    end
end

addpath(spm8_path,'-frozen');

clc

spm_get_defaults('cmdline',true);

proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

msg = 'Please select files to calculate:';
imscan = spm_select(inf,'image', msg ,[],proc_dir,'\.(nii|img)$');

prompt = {'Enter full equation including "i1" for the image:'};
dlg_title = 'VWI';
num_lines = 1;
def = {''};
smoothing = inputdlg(prompt,dlg_title,num_lines,def);
equation = smoothing{1};

calc_dir = [proc_dir '\ImCalc'];

if exist(calc_dir,'dir') == 0;
    mkdir(calc_dir);
end

for ii = 1:1:size(imscan,1),
    [path,name,ext]=fileparts(imscan(ii,:));
    input = [path '\' name ext];
    output = [calc_dir '\' name ext];
    exp = equation;
    spm_imcalc_ui(input,output,exp);
    clear output input exp
end

clc

disp('DONE!');