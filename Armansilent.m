function DICOMinfo = Armansilent(OutFileName,petdir,sub_dir,pet_name)

list = ls(petdir);
struct1 = dir(petdir);
listsize1 = size(list);
listlength1 = listsize1(1);
struct = struct1(3:listlength1,:);
listsize = size(struct);
listlength = listsize(1);
DICOM_names = {};

for zz = 1:1:listlength;
    isdir = struct(zz).isdir;
    if isdir == 0,
        name = [petdir '\' struct(zz).name];
        filename = struct(zz).name;
        if isdicom(name) == 1,
            DICOM_size = size(DICOM_names,1)+1;
            DICOM_names{DICOM_size,1} = filename;
            info = dicominfo(name);
            Y = dicomread(info);
            DICOM_names{DICOM_size,2} = mat2str(info.FrameReferenceTime);
        end
    end
end

clear list struct1 listsize1 listlength1 struct listsize listlength

sortDICOM = sortrows(DICOM_names,2);
Framemin = min(str2double(sortDICOM(:,2)));

framereftimes{1,1} = mat2str(Framemin);
temp{1,1} = mat2str(Framemin);
for zz=1:DICOM_size,
    if strcmp(mat2str(temp{1,1}),mat2str(sortDICOM{zz,2}))
        continue
    else
        temp{1,1} = sortDICOM{zz,2};
        framerefsize = size(framereftimes,1);
        framereftimes{framerefsize+1,1} = sortDICOM{zz,2};
    end
end
        
howmanyframes = size(framereftimes,1);
for zz=1:howmanyframes,
    frame_name = {};
    frametime = framereftimes{zz,1};
    for gg=1:DICOM_size,
        if strcmp(frametime,sortDICOM{gg,2}),
            framesize = size(frame_name,1);
            frame_name{framesize+1,1} = sortDICOM{gg,1};
        end
    end
    eval(sprintf('frame_name_%d = frame_name;',zz));
    clear frame_name
end
        

if howmanyframes > 1,
    for zz=1:howmanyframes;
        S(zz,1) = mat2str(zz);
    end
    msgprompt = {['Frame number for ' pet_name]};
    [Selection,ok] = listdlg('PromptString',msgprompt,...
        'SelectionMode','single','ListString',S);
else
    Selection = 1;
end

frames = 1;

DICOM_files_names = eval(sprintf('frame_name_%d',Selection));
name = [petdir '\' DICOM_files_names{1}];
info = dicominfo(name);
Y = dicomread(info);

DICOMinfo = cell(1,6);
if isfield(info,'RadiopharmaceuticalInformationSequence') == 1,
    Rad_struct = info.RadiopharmaceuticalInformationSequence;
    Rad_switch = struct2cell(Rad_struct);
    Rad_cell = Rad_switch{1};
    if isfield(Rad_cell, 'RadionuclideTotalDose') == 1,
        Dose = Rad_cell.RadionuclideTotalDose;
        DICOMinfo{1,1} = Dose;
    end
    if isfield(Rad_cell, 'RadiopharmaceuticalStartTime');
        StartTime = Rad_cell.RadiopharmaceuticalStartTime;
        DICOMinfo{1,2} = StartTime;
    end
end
if isfield(info,'Units') == 1,
    Units = info.Units;
    DICOMinfo{1,3} = Units;
end
if isfield(info,'ActualFrameDuration') == 1,
    FrameDuration = info.ActualFrameDuration;
    DICOMinfo{1,4} = FrameDuration;
end
if isfield(info,'AcquisitionTime') == 1,
    AcquiTime = info.AcquisitionTime;
    DICOMinfo{1,5} = AcquiTime;
end

if isfield(info,'PatientWeight') == 1,
    PatientWeight = info.PatientWeight;
    DICOMinfo{1,6} = PatientWeight;
end

if isfield(info,'PatientSex') == 1,
    PatientSex = info.PatientSex;
    DICOMinfo{1,7} = PatientSex;
end

xdim = info.Rows;
ydim = info.Columns;
zdim = info.NumberOfSlices;
z_width = info.SliceThickness;

x_width=info.PixelSpacing(1);
y_width=info.PixelSpacing(2);

image=zeros(xdim,ydim,zdim,frames);
image_final=zeros(xdim,ydim,zdim,frames);

baddata = 0;
Totalfiles = (frames*zdim);
check = Totalfiles/DICOM_size;
if check ~= 1,
    if check == 2,
        frames = 1;
    else
        uiwait(msgbox('The number of files does not match. Please check that you have all the DICOM data.','VWI'));
        baddata = 1;
    end
end


if baddata ~= 1,
    for frame=1:frames
        if frame == 1,
            for zz=1:zdim   % Bottom to top
                slice_number = zz+(frame-1)*zdim
                
                name = DICOM_files_names{zz}
                fullname = [petdir '\' DICOM_files_names{zz}];
                if isdicom(fullname) == 1,
                    
                    info=dicominfo(sprintf('%s',fullname));
                    Y = dicomread(info);
                    
                    image(:,:,zz,frame)=flipud(rot90((double(Y))*info.RescaleSlope+info.RescaleIntercept,1));
                    
                    SliceLocation(zz,frame)=info.SliceLocation;
                    AcquisitionTime(zz,frame)=str2num(info.AcquisitionTime);
                    FrameReferenceTime(zz,frame)=info.FrameReferenceTime;
                end
                
            end
        else
            for zz=zdim+1:1:listlength   % Bottom to top
                slice_number = zz
                
                name = DICOM_files_names{zz}
                fullname = [petdir '\' DICOM_files_names{zz}];
                if isdicom(fullname) == 1,
                    
                    info=dicominfo(sprintf('%s',fullname));
                    Y = dicomread(info);
                    
                    % We do rotation and flipping to correspond to Vinci DICOM images
                    image(:,:,zz-zdim,frame)=flipud(rot90((double(Y))*info.RescaleSlope+info.RescaleIntercept,1));
                    
                    SliceLocation(zz-zdim,frame)=info.SliceLocation;
                    AcquisitionTime(zz-zdim,frame)=str2num(info.AcquisitionTime);
                    FrameReferenceTime(zz-zdim,frame)=info.FrameReferenceTime;
                end
                
            end
        end
    end

    
    
    SliceThickness=double(info.SliceThickness);
    % SliceLocation;
    min_SliceLocation=min(min(SliceLocation));
    
    % Map to appropriate slice number
    for frame=1:frames;
        hold=round((SliceLocation(:,frame)-min_SliceLocation)/SliceThickness)+1;
        SliceLocationMap(:,frame)=double(zdim)-hold+1;
    end
    
    for zz=1:zdim;
        [hold I]=sort(FrameReferenceTime(zz,:));
        frame_map(zz,:)=I;
    end
    
    
    % Sorts planes; also switches axis direction to correspond to Vinci
    % DICOM images
    for frame=1:frames;
        for zz=1:zdim;   % Bottom to top
            image_final(:,:,SliceLocationMap(zz,frame),frame)=image(:,:,zz,frame_map(zz,frame));
        end
    end
    
    
    for frame=1:frames;
        for zz=1:zdim;   % Bottom to top
            image_final2(:,:,zdim-zz+1,frame)=flipud(fliplr(image_final(:,:,zz,frame)));
        end
    end
    
    % Puts origin at center of FOV by taking half the X,Y,Z dimensions.
    X = xdim/2;
    Y = ydim/2;
    Z = zdim/2;
    origin = [X Y Z];
    
    % Saving each dynamic frames into a separate NIFTI file
    for frame=1:frames;
        nifti_image=make_nii(image_final2(:,:,:,frame),[x_width y_width z_width],[origin],16);
        nifti_image.hdr.dime.datatype=16;
        nifti_image.hdr.dime.bitpix=16;
        if frames > 1,
            output_filename=sprintf('%s/%s%s%d%s',sub_dir,OutFileName,'_fr-', frame, '.nii');
        else
            output_filename=sprintf('%s/%s%s',sub_dir,OutFileName,'.nii');
        end
        save_nii(nifti_image,output_filename);
    end
    clc
end