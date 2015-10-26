[pth] = fileparts(which('spa'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

% uiwait(msgbox('Please select the directory to process the data.','SPA'));
% proc_dir = uigetdir(home_dir, 'Select the directory to process the ROI analysis...');

while true
    try spm_rmpath;
    catch break;
    end
end
addpath(spm8_path);
clc

spm_orthviews('image',spm_get(1,'*.img','Select background image'));
spm_orthviews('addimage',1,spm_get(1,'*.img','select blobs image'));


% P1 = spm_get(1,'*','Specify background image');
% P2 = spm_get(1,'*','Specify overlay image');
% 
% % msg = ('Please select background image:');
% % P1 = spm_select(1:1,'image', msg ,[],proc_dir,'\.(nii|img)$');
% % clear msg;
% % 
% % [pathstr, name, ext] = fileparts(P1);
% % 
% % msg = ('Please select overlay:');
% % P2 = spm_select(1:1,'image', msg ,[],pathstr,'\.(nii|img)$');
% % clear msg;
% 
% % Clear graphics window..
% spm_clf
% 
% % Display background image..
% h = spm_orthviews('Image', P1,[0.05 0.05 0.9 0.9]);
% 
% % Display blobs in red.  Use [0 1 0] for green, [0 0 1] for blue
% % [0.6 0 0.8] for purple etc..
% spm_orthviews('AddColouredImage', h, P2,[gray;jet(64)]);
% 
% % Update the display..
% spm_orthviews('Redraw');

% SURF PLOT: (example for plane 30)

pl    = 30; % plane 30
fname = spm_get(1,'*.img','Name of t image');
V     = spm_vol(fname);
M     = spm_matrix([1:101,1:126,1:101]);
img   = spm_slice_vol(V,M,V.dim(1:2),1);

isosurface(img);


results_dir = ('Z:\Hopkins-data\GD_(NA_00021615)\SPM8_Analyses\DASB\KMP\2-SampT\DEP-vs-NC_DASB-DVR_BL_s4_s3TEMP_2-SampT\No_2004_2017_1014');

msg = ('Please select SPM T-map:');
results = spm_select(1:1,'image', msg ,[],results_dir,'\.(nii|img)$');
resultsVol = spm_read_vols(spm_vol(results));

temp_dir = ('Z:\Other\Imaging-stuff\Software\MatLab\r2010a\spm8\templates\PET.nii');

temp = spm_read_vols(spm_vol(temp_dir));



patch(isosurface(Vol,max(Vol(:)) /3),'FaceColor',[1 0 0],'facealpha',0.7,'EdgeColor','none','facelighting','phong');
view(3); rotate3d; camlight(0,70); daspect([1,1,1]);
axis vis3d off tight;
