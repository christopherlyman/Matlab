function Arman_automated(DICOM_proc,OutFileName,out_pdir)


cd (DICOM_proc);
list = ls(DICOM_proc);
struct1 = dir(DICOM_proc);
listsize1 = size(list);
listlength1 = listsize1(1);
struct = struct1(3:listlength1,:);
listsize = size(struct);
listlength = listsize(1);
clear struct1;
clear listsize1;
clear listlength1;

cell1 = struct2cell(struct);
cell2 = cell1(1,:);
cell = cell2.';
clear cell1;
clear cell2;

for k = 1:1:listlength;
    isdir = struct(k).isdir;
    if isdir == 0,
        name = struct(k).name;
        if isdicom(name) == 1,
            info = dicominfo(name);
            Y = dicomread(info);
            
            if isfield(info,'NumberOfTimeSlices') == 1,
                frames = info.NumberOfTimeSlices;
            else
                frames = 1;
            end
            
            xdim = info.Rows;
            ydim = info.Columns;
            zdim = info.NumberOfSlices;
            z_width = info.SliceThickness;
            x_width=info.PixelSpacing(1);
            y_width=info.PixelSpacing(2);
            image=zeros(xdim,ydim,zdim,frames);
            image_final=zeros(xdim,ydim,zdim,frames);
            
            break
        else
            return
        end
    end
end


for frame=1:frames;
    if frame == 1,
        for j=1:zdim;   % Bottom to top
            slice_number = j+(frame-1)*zdim;
            isdir = struct(j).isdir;
            if isdir == 0,
                name = struct(j).name;
                if isdicom(name) == 1,
                    info=dicominfo(sprintf('%s',name));
                    Y = dicomread(info);
                    image(:,:,j,frame)=flipud(rot90((double(Y))*info.RescaleSlope+info.RescaleIntercept,1));
                    SliceLocation(j,frame)=info.SliceLocation;
                    AcquisitionTime(j,frame)=str2num(info.AcquisitionTime);
                    FrameReferenceTime(j,frame)=info.FrameReferenceTime;
                end
            end
            
        end
    else
        for j=zdim+1:1:listlength;  % Bottom to top
            slice_number = j;
            isdir = struct(j).isdir;
            if isdir == 0,
                name = struct(j).name;
                if isdicom(name) == 1,
                    info=dicominfo(sprintf('%s',name));
                    Y = dicomread(info);
                    image(:,:,j-zdim,frame)=flipud(rot90((double(Y))*info.RescaleSlope+info.RescaleIntercept,1));
                    SliceLocation(j-zdim,frame)=info.SliceLocation;
                    AcquisitionTime(j-zdim,frame)=str2num(info.AcquisitionTime);
                    FrameReferenceTime(j-zdim,frame)=info.FrameReferenceTime;
                end
            end
            
        end
    end
end


SliceThickness=double(info.SliceThickness);
min_SliceLocation=min(min(SliceLocation));


% Map to appropriate slice number
for frame=1:frames;
    hold=round((SliceLocation(:,frame)-min_SliceLocation)/SliceThickness)+1;
    SliceLocationMap(:,frame)=double(zdim)-hold+1;
end

for j=1:zdim;
    [hold I]=sort(FrameReferenceTime(j,:));
    frame_map(j,:)=I;
end


% Sorts planes; also switches axid direction to correspond to Vinci DICOM images
for frame=1:frames;
    for j=1:zdim;   % Bottom to top
        image_final(:,:,SliceLocationMap(j,frame),frame)=image(:,:,j,frame_map(j,frame));
    end
end

for frame=1:frames;
    for j=1:zdim;   % Bottom to top
        image_final2(:,:,zdim-j+1,frame)=flipud(fliplr(image_final(:,:,j,frame)));
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
        output_filename=sprintf('%s/%s%s%d%s',out_pdir,OutFileName,'_fr-', frame, '.nii');
    else
        output_filename=sprintf('%s/%s%s',out_pdir,OutFileName,'.nii');
    end
    save_nii(nifti_image,output_filename);
end


clc
