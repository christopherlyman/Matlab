function mni_roi()
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: get_roivalue(proc_dir)
%
%        proc_dir: directory in which subdirectories labeled by participant
%        contain parametric images prefixed with "h" to signify the headers
%        for these images have been corrected.
%
%        This module overlays the automated KMP VOIs on parametric images
%        and generates descriptive statistics for the voxels within the VOI
%        (mean, max, min, standard deviation, and the size of the VOI).
%        Spreadsheets containing these data will be outputted to the
%        directory specified in the variable "proc_dir."

%% Get directory with PET images, sort into separate directories
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
clear msg;
while isempty(base_image) == 1,
    msg = ('Please select base Image(s):');
    base_image = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
    clear msg;
end

basesize = size(base_image,1);

msg = ('Please select Template Image:');
template_image = spm_select(1:1,'image', msg ,[],proc_dir,'\.(img|nii)$');
clear msg;
while isempty(template_image) == 1,
    msg = ('Please select Template Image:');
    template_image = spm_select(1:1,'image', msg ,[],proc_dir,'\.(img|nii)$');
    clear msg;
end



for ii=1:1:basesize,
    base_hdr = spm_vol(base_image(ii,:));
    base_img = spm_read_vols(base_hdr);
    [basepath,basename,baseext] = fileparts(base_hdr.fname);
    template_hdr = spm_vol(template_image);
    template_img = spm_read_vols(template_hdr);
    [temppath,tempname,tempext] = fileparts(template_hdr.fname);
    dim_test = template_hdr.dim == base_hdr.dim;
    if sum(dim_test)~=3,
        resliceflags = struct('interp',1,'mask',1,'mean',0,'which',1,'wrap',[0 0 0]',...
            'prefix','r');
        spm_reslice(template_image,resliceflags);
        clear template_hdr template_img template_image
        template_image = [temppath '\r' tempname tempext];
        template_hdr = spm_vol(template_image);
        template_img = spm_read_vols(template_hdr);
    end
    
    emptyCell = cell(49,8);
    emptyCell{1,1} = ('Name');
    emptyCell{1,2} = ('Mean');
    emptyCell{1,3} = ('Max');
    emptyCell{1,4} = ('Min');
    emptyCell{1,5} = ('Min Pos');
    emptyCell{1,6} = ('St. Dev');
    emptyCell{1,7} = ('Negative Voxels');
    emptyCell{1,8} = ('Total Voxels');
    
    for jj=1:1:48;
        %% Third, create mask image
        mask_img = zeros(base_hdr.dim(1:3));
        BA = find(template_img(:)==jj);
        if isempty(BA) == 0,
            mask_img(BA) = base_img(BA);
            mask_name = sprintf('%s%d', 'BrodmannArea_', jj);
            mask_hdr = base_hdr;
            mask_hdr.fname = [basepath '\' mask_name baseext];
            %         spm_write_vol(mask_hdr,mask_img);
            nvox = size(BA,1);
            
%             %%Histogram
msg = ('Please select Image:');
Vin = spm_vol(spm_select(1:1,'image', msg ,[],proc_dir,'\.(img|nii)$'));
[Y,XYZ] = spm_read_vols(Vin);
[n, x] = histvol(Vin, 100);
figure;
bar(x,n);
            
            
            
            disp(['Name: ' mask_name]);
            Imgs_mean = sum(sum(sum(mask_img)))/nvox; disp(['Mean: ' num2str(Imgs_mean)]);
            Imgs_max = max(mask_img(:)); disp(['Max: ' num2str(Imgs_max)]);
            Imgs_min = min(mask_img(:)); disp(['Min: ' num2str(Imgs_min)]);
            mask_min = mask_img(mask_img>0); mask_neg = min(mask_img(:)); mask_pos_min = min(mask_min); disp(['Min Pos: ' num2str(mask_pos_min)]);
            Imgs_stdev = std(mask_img(:)); disp(['SD: ' num2str(Imgs_stdev)]);
            Neg_vox = numel(find(mask_img(:)<0)); disp(['Negative voxels: ' num2str(Neg_vox)]);
            Imgs_size = nvox; disp(['Total Voxels: ' num2str(Imgs_size)]);
            disp('----------------------------------------');
            
            emptyCell(jj+1,1) = {mask_name};
            emptyCell(jj+1,2) = num2cell(Imgs_mean);
            emptyCell(jj+1,3) = num2cell(Imgs_max);
            emptyCell(jj+1,4) = num2cell(Imgs_min);
            emptyCell(jj+1,5) = num2cell(mask_pos_min);
            emptyCell(jj+1,6) = num2cell(Imgs_stdev);
            emptyCell(jj+1,7) = num2cell(Neg_vox);
            emptyCell(jj+1,8) = num2cell(Imgs_size);
            
            
            roi_voxels = find(mask_img(:)>0);
            masked_pet = base_img;
            
            inc = ((max(base_img(:))-min(base_img(:)))/64); %Original
            
            masked_pet(roi_voxels) = max(base_img(:))+inc;
            
            %         masked_pet(vox_pos) = max(base_img(:))+max(base_img(:));
            
            %         for m = 1:size(roi_voxels,1), %Old way to index...SLOW!!!
            %             masked_test(roi_voxels(m)) = max(base_img(:))+inc;
            %         end
            
            scrsz = get(0, 'MonitorPositions');
            
            [xyzcor(:,1) xyzcor(:,2) xyzcor(:,3)] = ind2sub(size(template_img), roi_voxels);
            x = xyzcor(:,3);
            MINaxial = min(abs(x));
            MAXaxial = max(abs(x));
            ROIvol = MAXaxial - MINaxial;
            
            number = ROIvol/10;
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
                current_slice = MINaxial-extra;
                if current_slice < 1,
                    current_slice = 1;
                end
            end
            slices_inc = 1;
            
            hf = figure('name',mask_name,'NumberTitle','off','units','pixels','position',[0 0 scrsz(3)/2 scrsz(4)/2]); movegui(hf,'center');
            %         colormap([jet;[1 0 0]]);
            %         colormap([gray;jet(64)]);
            colormap([gray(64);[1 0 0]]);
            for m=1:1:num_planes,
                h(m) = subplot(integ+1,10,m);
                subp = get(h(m),'Position');
                if m == 1,
                    left = .5/(integ+1);
                    bottom = 1-(.5/(integ-1));
                    height = 1 / integ;
                    set(h(m),'Position',[.13 subp(2) .075 .2]);
                else
                    left = left+1.0;
                    set(h(m),'Position',[subp(1) subp(2) .075 .2]); % [left bottom width height]
                end
                ipet = imagesc(imrotate(masked_pet(:,:,current_slice),90)); axis off
                %             ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(abs(base_img(:))) max(base_img(:))]);
                ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(masked_pet(:)) max(masked_pet(:))]);
                current_slice = current_slice+slices_inc;
                hold all
            end
            
            pout = char([basepath '\' basename '-' mask_name '.tif']);
            
            print(hf, '-dtiff', pout);
            close(hf);
            clear roi_voxels xyzcor mask_img BA
        end
    end
    xlxname = ([basename '.xlsx']);
    sheet = 'Brodmann_Areas';
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite([basepath '\' xlxname],emptyCell(:,:),sheet);
    
    excelFilePath = [basepath '\' xlxname];
    sheetName = 'Sheet';
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath));
    
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
    
end

disp('DONE!');

end