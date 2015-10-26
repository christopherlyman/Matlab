function Thresh_ROI()

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
base_image = spm_select(1:1,'image', msg ,[],proc_dir,'\.(img|nii)$');

[path,name,ext] = fileparts(base_image);

% Step 1: Read Volume
base_vol = spm_read_vols(spm_vol(base_image(1,:)));

box = {'Enter the Threshold percentage value (e.g. top 65% of image values = .65):'};
box_title = 'VWI';
num_lines = 1;
Thresh_percent_value = inputdlg(box,box_title,num_lines);
if isempty(Thresh_percent_value),
    return,
end;

% Step 2: Get Max
Imgs_max = max(base_vol(:));
tthresh = Imgs_max.*str2double(Thresh_percent_value);

suprathresh = base_vol>=tthresh;  


% Step 3:  Write out base_vol_suprathresh as its own image.
V = spm_vol(base_image(1,:));
V.fname = [name '_thresh-' Thresh_percent_value{1} '.img'];
V.private.dat.fname = V.fname;
spm_write_vol(V,suprathresh);


j = 100;
%     j = 75;
%     j = 50;
size_check = suprathresh;
%         if size(find(size_check>0),1) > 75
if size(find(size_check>0),1) > 100
    %             if size(find(size_check>0),1) > 50
    hdr = spm_vol(V);
    image = spm_read_vols(hdr);
    indices = find(image>0);
    [x, y, z] = ind2sub(size(image), indices);
    XYZ = [x y z];
    A     = spm_clusters(XYZ');
    Q     = [];
    for mm = 1:max(A)
        d = find(A == mm);
        if length(d) >= j; Q = [Q d]; end
    end
    XYZ   = XYZ(Q,:);
    result = zeros(size(image));
    inds = sub2ind(size(image), XYZ(:,1), XYZ(:,2), XYZ(:,3));
    result(inds) = image(inds);
    spm_write_vol(hdr,result);
end

disp('DONE!');

end