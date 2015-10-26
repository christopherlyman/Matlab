function vwi_TAC()


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

msg = ('Please select base Image(s):');
base_image = spm_select(inf,'image', msg ,[],home_dir,'\.(img|nii)$');

clear msg;
while isempty(base_image) == 1,
    msg = ('Please select base Image:');
    base_image = spm_select(1:1,'image', msg ,[],home_dir,'\.(img|nii)$');
    clear msg;
end

[pathstr, name, ~] = fileparts(base_image(1,:));

msg = ('Please select ROI Image:');
roi_image = spm_select(1:1,'image', msg ,[],pathstr,'\.(img|nii)$');
clear msg;
while isempty(roi_image) == 1,
    msg = ('Please select ROI Image:');
    roi_image = spm_select(1:1,'image', msg ,[],pathstr,'\.(img|nii)$');
    clear msg;
end

prot_err = questdlg(['Would you like to select a protocol to go with the base images?'], ...
    'VWI', 'Yes', 'No', 'No');
switch prot_err
    case 'Yes'
        [FileName,PathName] = uigetfile([pth '\Tracers\protocols\*.xlsx'],'Select protocol:');
    case 'No'
        return
end

[ROIpath, ROIname, ROIext] = fileparts(roi_image);

roi_vol = spm_vol(roi_image);
thresh_roi = (spm_read_vols(roi_vol)>0.5);
nvox = sum(sum(sum(thresh_roi)));

while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc

[mpro,dur,tm,wt,num_frames,tac] = set_mpro(PathName,FileName);
if isempty(mpro), disp('No protocol file specified. Terminating.'); return; end


%% First, load the Base scan of interest
num_images = size(base_image,1);
for kk=1:num_images % Kinetic modeling magic
    base = base_image(kk,:);
    base_vol = spm_vol(base);
    read_base = spm_read_vols(base_vol);
    tac(kk,2)= sum(sum(sum(read_base.*thresh_roi)));
    clear base base_vol read_base
end

h = figure; % Generates outputs
tac(:,2)=tac(:,2)/nvox;
plot(tm,tac(:,2),'o');
pout = [ROIpath '\' name '_TAC_Fig.tif'];
print(h, '-dtiff', pout);
close(h);
fout = [ROIpath '\' name '_TAC.xls'];
xlswrite(fout,tac);

disp('DONE!');

    function [mpro,dur,tm,wt,num_frames,tac] = set_mpro(PathName,FileName)
        mpro = xlsread([PathName FileName],'protocol');
        dur = mpro(:,2); % Stores values from column 2
        tm = mpro(:,4); % Stores values from column 4
        if max(dur) > 60 % Converts to minutes depending on how "dur" column is stored in spreadsheet
            dur = dur/60;
        end
        wt = diag(sqrt(dur/sum(dur))); % Stores the square roots of "given time" divided by "total time" through a diagonal matrix
        num_frames = max(size(dur));
        tac = cell2mat({tm, zeros(num_frames,1)}); % Creates "tac" array with columns "tm" by zeroes
    end

end