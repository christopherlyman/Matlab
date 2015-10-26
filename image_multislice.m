clear all
[pth] = fileparts(which('vwi'));
% home_dir = 'Z:\Hopkins-data\AD-DBS\!Sites\02_Hopkins\Raw-Data\02-010\NIfTI\PET_2';
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

% image_dir = spm_select(Inf,'image', msg ,[],home_dir,'\.(nii|img)$');

image_dir = 'Z:\Hopkins-data\AD-DBS\!Sites\02_Hopkins\Raw-Data\02-010\NIfTI\PET_2\FNMI-02-010_PET-FDG_M1_fr-1.nii,1';

read_image = spm_vol(image_dir);
load_image = spm_read_vols(read_image);

region = 'FNMI-02-010_PET-FDG_M1_multislice';

scrsz = get(0, 'MonitorPositions');

number = (size(load_image,3)/10);
integ = floor(number);
fract = number-integ;
last = fract*10;
extra = 10-last;
extra = extra/2;
if extra == 5,
    num_planes = integ*10;
    current_slice = MINaxial;
    integ = integ-1;
else
    extra = floor(extra);
    num_planes = (integ+1)*10;
    current_slice = 23;
    if current_slice < 1,
        current_slice = 1;
    end
end

num_planes = 20;
slices_inc = 1;

hf = figure('name',region,'NumberTitle','off','units','pixels','position',[0 0 scrsz(3)/2 scrsz(4)/2]); movegui(hf,'center');
colormap(jet);

for m=1:1:num_planes,
    h(m) = subplot(5,5,m);
    subp = get(h(m),'Position');
    if m == 1,
        left = .5/(4);
        bottom = 1-(.5/(4));
        height = 1 / 5;
        set(h(m),'Position',[.13 subp(2) .11 .2]);
    else
        left = left+1.0;
        set(h(m),'Position',[subp(1) subp(2) .11 .2]); % [left bottom width height]
    end
    ipet = imagesc(imrotate(load_image(:,:,current_slice),90)); axis off
    %             ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(abs(conv_pet(:))) max(conv_pet(:))]);
    ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(load_image(:)) max(load_image(:))]);
    current_slice = current_slice+slices_inc;
    hold all
end

pout = char(['Z:\Hopkins-data\AD-DBS\!Sites\02_Hopkins\Raw-Data\02-010\NIfTI\PET_2\' deblank(region) '.tif']);

print(hf, '-dtiff', pout);
close(hf);