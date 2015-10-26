function vwi_get_roivals(sub_dir,sub,study,Answer)
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

%% Get directory with PET images, sort into separate directories
if exist('sub','var') == 0,
    Study_Sub;
    waitfor(Study_Sub);
    study = evalin('base','study');
    sub = evalin('base','sub');
   

    [~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
    studyprotocol = raw;
    clear raw;
    
    study_question = questdlg('What type of PET studies?', ...
        'VWI', ...
        'Static','Dynamic','Static');
    % Handle response
    switch study_question
        case 'Static'
            Answer = 1;
            study_dir = [studyprotocol{1,2} '\03_Pre-Processing'];
        case 'Dynamic'
            Answer = 2;
            study_dir = [studyprotocol{1,2} '\Dynamic'];
    end
    
    sub_dir = [study_dir '\' sub];
end

if Answer == 1,
    %%% FOR FDG Studies:
    dir_sub = dir(sub_dir);
    for kk = length(dir_sub):-1:1
        % remove folders starting with .
        fname = dir_sub(kk).name;
        if fname(1) == '.'
            dir_sub(kk) = [ ];
        end
        if fname(1) == '!'
            dir_sub(kk) = [ ];
        end
        if ~dir_sub(kk).isdir
            dir_sub(kk) = [ ];
            continue
        end
        if fname(1) == 'ROI'
            dir_sub(kk) = [ ];
        end
    end
    
    Count = 1;
    for jj=1:1:size(dir_sub,1),
        FDG_dir = [sub_dir '\' dir_sub(jj).name];
        dir_FDG = dir([FDG_dir,'\r*.nii']);
        for gg = 1:1:size(dir_FDG,1),
            PET_list{Count,1} = [FDG_dir '\' dir_FDG(gg).name ',1'];
            Count= Count+1;
        end
    end
    
    pimgs_size = size(PET_list,1);
    
    ROIdir = [sub_dir '\ROI\Summed'];
    
    ROIimgs = dir([ROIdir,'\*.nii']);
    roisize = size(ROIimgs,1);
    
    roi_placement = [sub_dir '\ROI\ROI-Placement'];
    
elseif Answer == 2,
    %%% FOR PET Studies: should change the parametric_dir variable to be
    %%% more flexible.
    parametric_dir = [home_dir '\' study '\Parametric\!Data\DVR'];
    Count = 1;
    dir_PET = dir([parametric_dir,'\' sub '*.img']);
    for gg = 1:1:size(dir_PET,1),
        PET_list{gg,1} = [parametric_dir '\' dir_PET(gg).name ',1'];
        Count= Count+1;
    end
    
    
    pimgs_size = size(PET_list,1);
    
    ROIdir = [sub_dir '\MPRAGE\VWI_VOIs_MRes\Summed'];
    
    ROIimgs = dir([ROIdir,'\*.nii']);
    roisize = size(ROIimgs,1);
    
    roi_placement = [sub_dir '\MPRAGE\VWI_VOIs_MRes\ROI-Placement'];
    
end

%% Loop to iterate through each participant's pimage folder

while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc
spm_get_defaults('cmdline',true);

for ii=1:1:pimgs_size,
    emptyCell = cell(roisize+1,7);
    roi_val = cell(8,1);
    emptyCell{1,1} = ('Name');
    emptyCell{1,2} = ('Mean');
    emptyCell{1,3} = ('Max');
    emptyCell{1,4} = ('Min');
    emptyCell{1,5} = ('St. Dev');
    emptyCell{1,6} = ('Negative Voxels');
    emptyCell{1,7} = ('Total Voxels');
    
    [~,petname,~]=fileparts(PET_list{ii,:});
    
    pet_tiff_dir = [roi_placement '\' petname];
    if exist(pet_tiff_dir,'dir') == 0;
        mkdir(pet_tiff_dir);
    end
    
    for jj=1:1:roisize,
        %% First, load the Base scan of interest
        [~,roiname,~] = fileparts([ROIdir '\' ROIimgs(jj).name]);
        roiname = roiname(size(sub,2)+2:end);
        
        read_base = spm_vol(PET_list{ii,:});
        conv_base = spm_read_vols(read_base);
        
        %% Second, load each ROI
        roi_image = [ROIdir '\' ROIimgs(jj).name ',1'];
        read_roi = spm_vol(roi_image);
        conv_roi = spm_read_vols(read_roi);
        
        nvox = sum(sum(sum(conv_roi)));
        roi_avg = conv_base.*conv_roi;
        
        
        
        Imgs_mean = sum(sum(sum(roi_avg)))/nvox;
        Imgs_max = max(roi_avg(:));
        Imgs_min = min(roi_avg(:));
        Imgs_stdev = std(roi_avg(:));
        Imgs_val = numel(find(roi_avg(:))); Imgs_zero = numel(find(roi_avg(:)==0));
        Neg_vox = numel(find(roi_avg(:)<0));
        Imgs_size = nvox;
        roi_val{1,1} = ['Name: ' roiname];
        roi_val{2,1} = ['Mean: ' num2str(Imgs_mean)];
        roi_val{3,1} = ['Max: ' num2str(Imgs_max)];
        roi_val{4,1} = ['Min: ' num2str(Imgs_min)];
        roi_val{5,1} = ['SD: ' num2str(Imgs_stdev)];
        roi_val{6,1} = ['Count Negative voxels: ' num2str(Neg_vox)];
        roi_val{7,1} = ['Count Total Voxels: ' num2str(Imgs_size)];
        roi_val{8,1} = '----------------------------------------';
        disp(roi_val);
        
        emptyCell(jj+1,1) = {roiname};
        emptyCell(jj+1,2) = num2cell(Imgs_mean);
        emptyCell(jj+1,3) = num2cell(Imgs_max);
        emptyCell(jj+1,4) = num2cell(Imgs_min);
        emptyCell(jj+1,5) = num2cell(Imgs_stdev);
        emptyCell(jj+1,6) = num2cell(Neg_vox);
        emptyCell(jj+1,7) = num2cell(Imgs_size);
        
        
        size_pet = size(conv_base,3);
        roi_voxels = find(conv_roi(:)>0);
        masked_pet = conv_base;
        
        inc = ((max(conv_base(:))-min(conv_base(:)))/64); %Original
        
        masked_pet(roi_voxels) = max(conv_base(:))+inc;
        
        %         masked_pet(vox_pos) = max(conv_base(:))+max(conv_base(:));
        
        %         for m = 1:size(roi_voxels,1), %Old way to index...SLOW!!!
        %             masked_test(roi_voxels(m)) = max(conv_base(:))+inc;
        %         end
        
        scrsz = get(0, 'MonitorPositions');
        
        [xyzcor(:,1) xyzcor(:,2) xyzcor(:,3)] = ind2sub(size(conv_roi), roi_voxels);
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
        
        hf = figure('NumberTitle','off','units','pixels','position',[0 0 scrsz(3)/2 scrsz(4)/2]); movegui(hf,'center');
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
            %             ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(abs(conv_base(:))) max(conv_base(:))]);
            ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(masked_pet(:)) max(masked_pet(:))]);
            current_slice = current_slice+slices_inc;
            hold all
        end
        
        pout = char([pet_tiff_dir '\' roiname '.tif']);
        
        print(hf, '-dtiff', pout);
        close(hf);
        clear conv_roi roi_voxels xyzcor
        
        %         textfile = [basepath '\' basename '-' roiname '.txt'];
        %         fid=fopen(textfile,'wt');
        %
        %
        %         [rows,cols]=size(emptyCell);
        %
        %         for gg=1:rows
        %             fprintf(fid,'%s\n',emptyCell{gg,:});
        %         end
        %         fclose(fid);
    end
    
    if Answer ==1,
        petnamefinal = petname;
    else
        petbreak = strfind(petname,'_');
        petbreakmin = petbreak(1)+1;
        if petbreak(3)-petbreak(2)==2,
            petbreakmax = petbreak(3)-1;
        else
            petbreakmax = petbreak(2)-1;
        end
        
        petnamefinal = petname(petbreakmin:petbreakmax);
    end
    
    xlxname = ([sub '_ROI-Analysis.xlsx']);
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite([sub_dir '\' xlxname],emptyCell(:,:),petnamefinal);
    
    clear petbreak petbreakmin petbreakmax petnamefinal
end
%
% excelFilePath = [sub_dir '\' xlxname];
% sheetName = 'Sheet';
% objExcel = actxserver('Excel.Application');
% objExcel.Workbooks.Open(fullfile(excelFilePath));
%
% objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
% objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
% objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
%
% objExcel.ActiveWorkbook.Save;
% objExcel.ActiveWorkbook.Close;
% objExcel.Quit;
% objExcel.delete;
%
% clc

disp('DONE!');

end