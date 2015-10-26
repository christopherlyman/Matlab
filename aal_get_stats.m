function aal_get_stats()
%
%        Static PET Analysis Pipeline
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher H. Lyman, Clifford Workman, and Dr.
%        Kentaro Hirao
%
%        Usage: get_roivals(sub_dir)
%
%        sub_dir: directory in which sub_directories labeled by participant
%        contain parametric images prefixed with "h" to signify the headers
%        for these images have been corrected.
%
%        This module overlays the automated KMP VOIs on parametric images
%        and generates descriptive statistics for the voxels within the VOI
%        (mean, max, min, standard deviation, and the size of the VOI).
%        Spreadsheets containing these data will be outputted to the
%        directory specified in the variable "sub_dir."


%% default dirs
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

%% Loop to iterate through participant's pimage folder

if exist('proc_dir','var'),
    proc_dir = proc_dir;
else
    proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');
end


if exist('base_pet','var'),
    base_pet = base_pet;
else
    msg = ('Please select base PET image(s):');
    base_pet = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
    
    
    clear msg;
    while isempty(base_pet) == 1,
        msg = ('Please select base PET image(s):');
        base_pet = spm_select(Inf,'image', msg ,[],proc_dir,'\.(img|nii)$');
        clear msg;
    end
end

pimgs_size = size(base_pet,1);

roi_dir = [proc_dir '\ROI\'];
aal_roi_dir = dir([roi_dir, '*_Brain-Mask.nii']);
sub_aal_rois = {aal_roi_dir.name};
sub_aal_rois = str2mat(sub_aal_rois);

roisize = size(sub_aal_rois,1);

for ii=1:1:pimgs_size,
    emptyCell = cell(roisize+1,7);
    roi_val = cell(8,1);
    emptyCell{1,1} = ('Name');
    emptyCell{1,2} = ('Mean');
    emptyCell{1,3} = ('Max');
    emptyCell{1,4} = ('Global Min');
    emptyCell{1,5} = ('Min Positive Number');
    emptyCell{1,6} = ('St. Dev');
    emptyCell{1,7} = ('Negative Voxels');
    emptyCell{1,8} = ('Total Voxels');
    
    [~,petname,~]=fileparts(base_pet(ii,:));
    disp(petname);
    roi_placement = [roi_dir '\ROI-Placement'];
    pet_tiff_dir = [roi_placement '\' petname];
    if exist(pet_tiff_dir,'dir') == 0;
        mkdir(pet_tiff_dir);
    end
    
    for jj=1:1:roisize,
        %% First, load the Base scan of interest
        [~,roiname,~] = fileparts([roi_dir '\' deblank(sub_aal_rois(jj,:))]);
        roiname = roiname(size(sub,2)+2:end);
        roiname = roiname(1:end-11);
        
        pet_vol = spm_vol(base_pet(ii,:));
        pet_read = spm_read_vols(pet_vol);
        
        %% Second, load each ROI
        roi_image = [roi_dir '\' deblank(sub_aal_rois(jj,:)) ',1'];
        roi_vol = spm_vol(roi_image);
        roi_read = spm_read_vols(roi_vol);
        
        nvox = round(sum(sum(sum(roi_read))));
        roi_avg = pet_read.*roi_read;
        
        
        
        Imgs_mean = sum(sum(sum(roi_avg)))/nvox;
        Imgs_max = max(roi_avg(:));
        Imgs_min = min(roi_avg(:));
        %         find_min = find(roi_avg(:)>0); original
        find_min = roi_avg(:)>0;
        Pos_min_val = roi_avg(find_min);
        Pos_min = min(Pos_min_val);
        Imgs_stdev = std(roi_avg(:));
        Neg_vox = numel(find(roi_avg(:)<0));
        Imgs_size = nvox;
        roi_val{1,1} = ['Name: ' roiname];
        roi_val{2,1} = ['Mean: ' num2str(Imgs_mean)];
        roi_val{3,1} = ['Max: ' num2str(Imgs_max)];
        roi_val{4,1} = ['Global Min: ' num2str(Imgs_min)];
        roi_val{5,1} = ['Minimum Positive Number: ' num2str(Pos_min)];
        roi_val{6,1} = ['SD: ' num2str(Imgs_stdev)];
        roi_val{7,1} = ['Count Negative voxels: ' num2str(Neg_vox)];
        roi_val{8,1} = ['Count Total Voxels: ' num2str(Imgs_size)];
        roi_val{9,1} = '----------------------------------------';
        disp(roi_val);
        
        emptyCell(jj+1,1) = {roiname};
        if nvox == 0,
            emptyCell{jj+1,2} = ('NaN');
            emptyCell{jj+1,3} = ('NaN');
            emptyCell{jj+1,4} = ('NaN');
            emptyCell{jj+1,5} = ('NaN');
            emptyCell{jj+1,6} = ('NaN');
            emptyCell{jj+1,7} = ('NaN');
            emptyCell(jj+1,8) = num2cell(Imgs_size);
        else
            emptyCell(jj+1,2) = num2cell(Imgs_mean);
            emptyCell(jj+1,3) = num2cell(Imgs_max);
            emptyCell(jj+1,4) = num2cell(Imgs_min);
            emptyCell(jj+1,5) = num2cell(Pos_min);
            emptyCell(jj+1,6) = num2cell(Imgs_stdev);
            emptyCell(jj+1,7) = num2cell(Neg_vox);
            emptyCell(jj+1,8) = num2cell(Imgs_size);
        end
        
        roi_voxels = find(roi_read(:)>0);
        masked_pet = pet_read;
        
        inc = ((max(pet_read(:))-min(pet_read(:)))/64); %Original
        
        masked_pet(roi_voxels) = max(pet_read(:))+inc;
        
        scrsz = get(0, 'MonitorPositions');
        
        [xyzcor(:,1) xyzcor(:,2) xyzcor(:,3)] = ind2sub(size(roi_read), roi_voxels);
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
            if (current_slice+num_planes)>MAXaxial,
                minus = (current_slice+num_planes)-MAXaxial;
                num_planes = num_planes-minus;
            end
        end
        
        if (current_slice+num_planes)>MAXaxial,
            minus = (current_slice+num_planes)-MAXaxial;
            num_planes = num_planes-minus;
        end
        slices_inc = 1;
        
        hf = figure('NumberTitle','off','units','pixels','position',[0 0 scrsz(3)/2 scrsz(4)/2]); movegui(hf,'southwest');
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
            %             ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(abs(pet_read(:))) max(pet_read(:))]);
            ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(masked_pet(:)) max(masked_pet(:))]);
            current_slice = current_slice+slices_inc;
            hold all
        end
        
        pout = char([pet_tiff_dir '\' roiname '.tif']);
        
        print(hf, '-dtiff', pout);
        close(hf);
        clear roi_read roi_voxels xyzcor
        
    end
    
    xlxname = ([sub '_AAL_rois.xlsx']);
    
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite([proc_dir '\' xlxname],emptyCell(:,:),petname);
end

excelFilePath = [proc_dir '\' xlxname];
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



clc

disp('DONE!');

end