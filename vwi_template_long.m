function vwi_template_long()
%
%       Static PET Analysis Pipeline
%       Copyright (C) 2013 Johns Hopkins University
%       Software by Christopher H. Lyman and Clifford Workman
%
%       Usage: vwi_template;
%
%       First, you will be prompted to select a processing directory. The
%       templates will end up in this directory. It is recommended that
%       you select a directory that is conveniently located near where
%       your source and reference images are located because when you are
%       prompted to select your source and reference images it defaults to
%       this directory.
%
%       Second, you will be prompted to select your reference images. The
%       reference images are the image type of your final template. Please
%       select all subjects you wish to analyze. e.g.) Depressed and Normal
%       controls.
%
%       Third, you will be prompted to select your source images. These are
%       the images which can be spatially normalized to an SPM template
%       image. These images must be coregistered to the reference image
%       first. Also, select the reference images in the same subject order
%       as you selected for the reference images.
%
%       Fourth, you will be prompted to select an SPM template. Select the
%       template that best matches your source images. e.g.) If your source
%       images are MPRAGEs or SPGRs then select the T1 SPM template.
%
%       The program will run through the following steps:
%       ----------------------------- Steps -----------------------------
%       1) The source images are spatially normalized to the SPM template
%          and the reference images are the images to write.
%       2) The warped (spatially-normalized) references images are
%          realigned to the mean and a mean image is resliced.
%       3) The resliced mean reference image is then smoothed by both a 3
%          mm and 6 mm FWHM gaussian kernel and prefixed s3_* and s6_*
%          respectively.

%% Declare required variables, if not already declared
clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));
spm8_template = [spm8_path '\templates'];

%% Define Dirs and set SPM8 path
uiwait(msgbox('Please select the directory to process the data.','VWI'));
proc_dir = uigetdir(home_dir, 'Select the directory to process the data..');

while true
    try spm_rmpath;
    catch
        break;
    end
end

addpath(spm8_path,'-frozen');

clc

spm_get_defaults('cmdline',true);

%% Prompt to select scans that you wish to make a template
msg = ('Please select reference images');
Reference = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');
clear msg;
Refrows = size(Reference,1);

%% Prompt to select scans that will be used to Normalize to Template Space
msg = ('Please select Source images');
Source = spm_select(Inf,'image', msg ,[],proc_dir,'\.(nii|img)$');
clear msg;
Sourows = size(Source,1);

coreg_question = questdlg('Are the Source Images coregistered to the Reference images?', ...
    'VWI', ...
    'Yes','No','No');
% Handle response
switch coreg_question
    case 'Yes'
        Answer = 1;
    case 'No'
        uiwait(msgbox('Please coregister the Source images to the Reference image before continuing.','VWI'));
        disp('Please coregister the Source images to the Reference image before continuing.')
        Answer = 2;
end

order_question = questdlg('Were the Source and Reference images selected in the same file order?', ...
    'VWI', ...
    'Yes','No','No');
% Handle response
switch order_question
    case 'Yes'
        Answer = 1;
    case 'No'
        uiwait(msgbox('Please rerun vwi_template selecting the Source and Reference images in the same order.','VWI'));
        disp('Please rerun vwi_template selecting the Source and Reference images in the same order.')
        Answer = 2;
end

if Refrows ~= Sourows,
    uiwait(msgbox('Reference and Source Images do not match. Please check before continuing.','VWI'));
    disp('Reference and Source Images do not match. Please check before continuing.');
    Answer = 2;
    check = questdlg('It was noticed that the number of Source and Reference images selected do not match. Continue?', ...
        'VWI', ...
        'Yes','No','No');
    % Handle response
    switch check
        case 'Yes'
            Answer = 1;
        case 'No'
            uiwait(msgbox('Reference and Source Images do not match. Please check before continuing.','VWI'));
            disp('Reference and Source Images do not match. Please check before continuing.')
            Answer = 2;
    end
end

Norm_question = questdlg('Would you like the Reference images normalized to the new Template?', ...
    'VWI', ...
    'Yes','No','No');
% Handle response
switch Norm_question
    case 'Yes'
        Norm_Answer = 1;
    case 'No'
        Norm_Answer = 2;
end

if Answer == 1,
    
    %% Prompt to select SPM Template type for Source Images
    msg = ('Please select Template for Source Images');
    Template = spm_select(1:1,'image', msg ,[],spm8_template,'\.(nii)$');
    clear msg;
    
    %% Prompt to change amount of smoothing applied to the templates
    prompt = {'Enter Template Name:','Enter 1st template FWHM smoothing value (mm):','Enter 2nd template FWHM smoothing value (mm):'};
    dlg_title = 'VWI';
    num_lines = 1;
    def = {'','3',''};
    smoothing = inputdlg(prompt,dlg_title,num_lines,def);
    TempName = smoothing{1};
    sTemp1 = smoothing{2};
    sTemp2 = smoothing{3};
    
    
    %% Create Template Directory
    Temp_dir = [proc_dir '\Template'];
    if exist(Temp_dir,'dir') == 0;
        mkdir(Temp_dir);
    end
    
    %% Copy Source and Reference Images to the Template Directory
    for ii = 1:1:Refrows
        [pathstr, name, ext] = fileparts(Reference(ii,:));
        stringext = strfind(ext,'.img');
        if isempty(stringext)
            ext = ('.nii');
            Refimgs = [pathstr '\' name ext];
            Tempimgs = [Temp_dir '\' name ext];
            copyfile(Refimgs,Tempimgs,'f');
        else
            ext = ('.img');
            hdr = ('.hdr');
            Refimgs = [pathstr '\' name ext];
            Tempimgs = [Temp_dir '\' name ext];
            copyfile(Refimgs,Tempimgs,'f');
            Refhdr = [pathstr '\' name hdr];
            Temphdr = [Temp_dir '\' name hdr];
            copyfile(Refhdr,Temphdr,'f');
        end
        clear pathstr name ext Tempimgs Refimgs stringext Temphdr Refhdr
    end
    
    for ii = 1:1:Sourows
        [pathstr, name, ext] = fileparts(Source(ii,:));
        stringext = strfind(ext,'.img');
        if isempty(stringext)
            ext = ('.nii');
            Sourimgs = [pathstr '\' name ext];
            Tempimgs = [Temp_dir '\' name ext];
            copyfile(Sourimgs,Tempimgs,'f');
        else
            ext = ('.img');
            hdr = ('.hdr');
            Sourimgs = [pathstr '\' name ext];
            Tempimgs = [Temp_dir '\' name ext];
            copyfile(Sourimgs,Tempimgs,'f');
            Sourhdr = [pathstr '\' name hdr];
            Temphdr = [Temp_dir '\' name hdr];
            copyfile(Sourhdr,Temphdr,'f');
        end
        clear pathstr name ext Tempimgs Sourimgs stringext Temphdr Sourhdr
    end
    
    %% Spatially Normalize Source Images to Template Space
    spm_jobman('initcfg');
    load NormalizeTemplate;
    
    Ref_array = cell(Sourows,1);
    for ii = 1:1:Sourows
        [~, name, ext] = fileparts(Source(ii,:));
        Sourimg = deblank([Temp_dir '\' name ext]);
        [~, name, ext] = fileparts(Reference(ii,:));
        Refimg = deblank([Temp_dir '\' name ext]);
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {Sourimg};
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {Refimg};
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {Template};
        %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
        Norm = spm_jobman('run',matlabbatch);
        Ref_array(ii,1) = {[Temp_dir '\w' name ext]};
    end


    
    %% Realign Normalized Reference images to a mean and smooth
    clear matlabbatch
    load RealignTemplate;
    
    st1 = str2double(sTemp1);
    st2 = str2double(sTemp2);
    
    if isempty(sTemp1) == 1 && isempty(sTemp2) == 1;
        newmatlabbatch{1,1} = matlabbatch{1,1};
        clear matlabbatch
        matlabbatch = newmatlabbatch;
        clear newmatlabbatch
        Temps = 1;
    end
    if isempty(sTemp1) == 0 && isempty(sTemp2) == 1;
        newmatlabbatch{1,1} = matlabbatch{1,1};
        newmatlabbatch{1,2} = matlabbatch{1,2};
        clear matlabbatch
        matlabbatch = newmatlabbatch;
        clear newmatlabbatch
        st1 = str2double(sTemp1);
        prefix1 = ['s' sTemp1 '_'];
        matlabbatch{1,2}.spm.spatial.smooth.fwhm = [st1,st1,st1];
        matlabbatch{1,2}.spm.spatial.smooth.prefix = prefix1;
        Temps = 2;
    end
    if isempty(sTemp1) == 1 && isempty(sTemp2) == 0;
        newmatlabbatch{1,1} = matlabbatch{1,1};
        newmatlabbatch{1,2} = matlabbatch{1,3};
        clear matlabbatch
        matlabbatch = newmatlabbatch;
        clear newmatlabbatch
        st1 = str2double(sTemp1);
        prefix1 = ['s' sTemp1 '_'];
        matlabbatch{1,2}.spm.spatial.smooth.fwhm = [st1,st1,st1];
        matlabbatch{1,2}.spm.spatial.smooth.prefix = prefix1;
        Temps = 2;
    end
    if isempty(sTemp1) == 0 && isempty(sTemp2) == 0;
        st1 = str2double(sTemp1);
        st2 = str2double(sTemp2);
        matlabbatch{1,2}.spm.spatial.smooth.fwhm = [st1,st1,st1];
        matlabbatch{1,3}.spm.spatial.smooth.fwhm = [st2,st2,st2];
        prefix1 = ['s' sTemp1 '_'];
        prefix2 = ['s' sTemp2 '_'];
        matlabbatch{1,2}.spm.spatial.smooth.prefix = prefix1;
        matlabbatch{1,3}.spm.spatial.smooth.prefix = prefix2;
        Temps = 3;
    end
    
    matlabbatch{1}.spm.spatial.realign.estwrite.data = {Ref_array};
    Realign = spm_jobman('run',matlabbatch);
    
    if Temps == 3,
        prefix1 = ['\' prefix1];
        Temp1_file = dir([Temp_dir, prefix1 '*']);
        prefix2 = ['\' prefix2];
        Temp2_file = dir([Temp_dir, prefix2 '*']);
        
        temp1size = size(Temp1_file,1);
        if temp1size > 1
            Temp_name = Temp1_file.name;
            [~, name, ~] = fileparts(Temp_name);
            Temp_start_img = [Temp_dir '\' name '.img'];
            Temp_start_hdr = [Temp_dir '\' name '.hdr'];
            Temp1_final_img = [proc_dir prefix1 TempName '_Template.img'];
            Temp1_final_hdr = [proc_dir prefix1 TempName '_Template.hdr'];
            copyfile(Temp_start_img,Temp1_final_img,'f');
            copyfile(Temp_start_hdr,Temp1_final_hdr,'f');
        else
            Temp_name = Temp1_file.name;
            [~, name, ext] = fileparts(Temp_name);
            Temp_start = [Temp_dir '\' name ext];
            Temp1_final_img = [proc_dir prefix1 TempName '_Template.nii'];
            copyfile(Temp_start,Temp1_final_img,'f');
        end
        
        temp2size = size(Temp2_file,1);
        if temp2size > 1
            Temp_name = Temp2_file.name;
            [~, name, ~] = fileparts(Temp_name);
            Temp_start_img = [Temp_dir '\' name '.img'];
            Temp_start_hdr = [Temp_dir '\' name '.hdr'];
            Temp2_final_img = [proc_dir prefix2 TempName '_Template.img'];
            Temp2_final_hdr = [proc_dir prefix2 TempName '_Template.hdr'];
            copyfile(Temp_start_img,Temp2_final_img,'f');
            copyfile(Temp_start_hdr,Temp2_final_hdr,'f');
        else
            Temp_name = Temp2_file.name;
            [~, name, ext] = fileparts(Temp_name);
            Temp_start = [Temp_dir '\' name ext];
            Temp2_final_img = [proc_dir prefix2 TempName '_Template.nii'];
            copyfile(Temp_start,Temp2_final_img,'f');
        end
    end
    
    if Temps == 2,
        prefix1 = ['\' prefix1];
        Temp1_file = dir([Temp_dir, prefix1 '*']);
        
        
        temp1size = size(Temp1_file,1);
        if temp1size > 1
            Temp_name = Temp1_file.name;
            [~, name, ~] = fileparts(Temp_name);
            Temp_start_img = [Temp_dir '\' name '.img'];
            Temp_start_hdr = [Temp_dir '\' name '.hdr'];
            Temp1_final_img = [proc_dir prefix1 TempName '_Template.img'];
            Temp1_final_hdr = [proc_dir prefix1 TempName '_Template.hdr'];
            copyfile(Temp_start_img,Temp1_final_img,'f');
            copyfile(Temp_start_hdr,Temp1_final_hdr,'f');
        else
            Temp_name = Temp1_file.name;
            [~, name, ext] = fileparts(Temp_name);
            Temp_start = [Temp_dir '\' name ext];
            Temp1_final_img = [proc_dir prefix1 TempName '_Template.nii'];
            copyfile(Temp_start,Temp1_final_img,'f');
        end
    end
    
    mean_file = dir([Temp_dir, '\mean*']);
    meansize = size(mean_file,1);
    if meansize > 1
        mean_name = mean_file.name;
        [~, name, ~] = fileparts(mean_name);
        Temp_start_img = [Temp_dir '\' name '.img'];
        Temp_start_hdr = [Temp_dir '\' name '.hdr'];
        mean_final_img = [proc_dir '\mean_' TempName '_Template.img'];
        mean_final_hdr = [proc_dir '\mean_' TempName '_Template.hdr'];
        copyfile(Temp_start_img,mean_final_img,'f');
        copyfile(Temp_start_hdr,mean_final_hdr,'f');
    else
        mean_name = mean_file.name;
        [~, name, ext] = fileparts(mean_name);
        Temp_start = [Temp_dir '\' name ext];
        mean_final_img = [proc_dir '\mean_' TempName '_Template.nii'];
        copyfile(Temp_start,mean_final_img,'f');
    end
    
    %     rmdir(Temp_dir,'s'); % Delete template directory
    
    
    if Norm_Answer == 1,
        %% Normalize Reference images to the new templates
        clear matlabbatch
        load NormalizeTemplate;
        
        Norm_dir = [proc_dir '\Normalize'];
        if exist(Norm_dir,'dir') == 0;
            mkdir(Norm_dir);
        end
        
        Ref1_array = cell(Refrows,1);
        Mean_array = cell(Refrows,1);
        
        Mean_dir = [Norm_dir '\Mean_Template'];
        if exist(Mean_dir,'dir') == 0;
            mkdir(Mean_dir);
        end
        
        if Temps == 3,
            Norm1_dir = [Norm_dir prefix1 'Template'];
            if exist(Norm1_dir,'dir') == 0;
                mkdir(Norm1_dir);
            end
            Norm2_dir = [Norm_dir prefix2 'Template'];
            if exist(Norm2_dir,'dir') == 0;
                mkdir(Norm2_dir);
            end
            
            for ii = 1:1:Refrows
                [pathstr, name, ext] = fileparts(Reference(ii,:));
                stringext = strfind(ext,'.img');
                if isempty(stringext)
                    ext = ('.nii');
                    Refimgs = [pathstr '\' name ext];
                    Normimgs = [Norm1_dir '\' name ext];
                    copyfile(Refimgs,Normimgs,'f');
                    Ref1_array(ii,1) = {[Norm1_dir '\' name ext ',1']};
                else
                    ext = ('.img');
                    hdr = ('.hdr');
                    Refimgs = [pathstr '\' name ext];
                    Normimgs = [Norm1_dir '\' name ext];
                    copyfile(Refimgs,Normimgs,'f');
                    Refhdr = [pathstr '\' name hdr];
                    Normhdr = [Norm1_dir '\' name hdr];
                    copyfile(Refhdr,Normhdr,'f');
                    Ref1_array(ii,1) = {[Norm1_dir '\' name ext ',1']};
                end
                Temp1 = [Temp1_final_img ',1'];
                matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = Ref1_array(ii,1);
                matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = Ref1_array(ii,1);
                matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {Temp1};
                %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
                Norm = spm_jobman('run',matlabbatch);
                Ref1_array(ii,1) = {[Norm1_dir '\w' name ext]};
                clear pathstr name ext Normimgs Refimgs stringext Normhdr Refhdr
            end
            
            Ref2_array = cell(Refrows,1);
            
            for ii = 1:1:Refrows
                [pathstr, name, ext] = fileparts(Reference(ii,:));
                stringext = strfind(ext,'.img');
                if isempty(stringext)
                    ext = ('.nii');
                    Refimgs = [pathstr '\' name ext];
                    Normimgs = [Norm2_dir '\' name ext];
                    copyfile(Refimgs,Normimgs,'f');
                    Ref2_array(ii,1) = {[Norm2_dir '\' name ext ',1']};
                else
                    ext = ('.img');
                    hdr = ('.hdr');
                    Refimgs = [pathstr '\' name ext];
                    Normimgs = [Norm2_dir '\' name ext];
                    copyfile(Refimgs,Normimgs,'f');
                    Refhdr = [pathstr '\' name hdr];
                    Normhdr = [Norm2_dir '\' name hdr];
                    copyfile(Refhdr,Normhdr,'f');
                    Ref2_array(ii,1) = {[Norm2_dir '\' name ext ',1']};
                end
                Temp2 = [Temp2_final_img ',1'];
                matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = Ref2_array(ii,1);
                matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = Ref2_array(ii,1);
                matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {Temp2};
                %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
                Norm = spm_jobman('run',matlabbatch);
                Ref2_array(ii,1) = {[Norm2_dir '\w' name ext]};
                clear pathstr name ext Normimgs Refimgs stringext Normhdr Refhdr
            end
        end
        
        if Temps == 2,
            
            Norm1_dir = [Norm_dir prefix1 'Template'];
            if exist(Norm1_dir,'dir') == 0;
                mkdir(Norm1_dir);
            end
            
            for ii = 1:1:Refrows
                [pathstr, name, ext] = fileparts(Reference(ii,:));
                stringext = strfind(ext,'.img');
                if isempty(stringext)
                    ext = ('.nii');
                    Refimgs = [pathstr '\' name ext];
                    Normimgs = [Norm1_dir '\' name ext];
                    copyfile(Refimgs,Normimgs,'f');
                    Ref1_array(ii,1) = {[Norm1_dir '\' name ext ',1']};
                else
                    ext = ('.img');
                    hdr = ('.hdr');
                    Refimgs = [pathstr '\' name ext];
                    Normimgs = [Norm1_dir '\' name ext];
                    copyfile(Refimgs,Normimgs,'f');
                    Refhdr = [pathstr '\' name hdr];
                    Normhdr = [Norm1_dir '\' name hdr];
                    copyfile(Refhdr,Normhdr,'f');
                    Ref1_array(ii,1) = {[Norm1_dir '\' name ext ',1']};
                end
                Temp1 = [Temp1_final_img ',1'];
                matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = Ref1_array(ii,1);
                matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = Ref1_array(ii,1);
                matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {Temp1};
                %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
                Norm = spm_jobman('run',matlabbatch);
                Ref1_array(ii,1) = {[Norm1_dir '\w' name ext]};
                clear pathstr name ext Normimgs Refimgs stringext Normhdr Refhdr
            end
        end
        
        for ii = 1:1:Refrows
            [pathstr, name, ext] = fileparts(Reference(ii,:));
            stringext = strfind(ext,'.img');
            if isempty(stringext)
                ext = ('.nii');
                Refimgs = [pathstr '\' name ext];
                Normimgs = [Mean_dir '\' name ext];
                copyfile(Refimgs,Normimgs,'f');
                Mean_array(ii,1) = {[Mean_dir '\' name ext ',1']};
            else
                ext = ('.img');
                hdr = ('.hdr');
                Refimgs = [pathstr '\' name ext];
                Normimgs = [Mean_dir '\' name ext];
                copyfile(Refimgs,Normimgs,'f');
                Refhdr = [pathstr '\' name hdr];
                Normhdr = [Mean_dir '\' name hdr];
                copyfile(Refhdr,Normhdr,'f');
                Mean_array(ii,1) = {[Mean_dir '\' name ext ',1']};
            end
            mean = [mean_final_img ',1'];
            matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = Mean_array(ii,1);
            matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = Mean_array(ii,1);
            matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {mean};
            %     matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = {100}; % maybe?
            Norm = spm_jobman('run',matlabbatch);
            Mean_array(ii,1) = {[Mean_dir '\w' name ext]};
            clear pathstr name ext Normimgs Refimgs stringext Normhdr Refhdr
        end
        
        
        %% Smooth Normalized Reference Images
        
        clear matlabbatch
        load Smooth;
        
        Smooth_dir = [proc_dir '\Smoothed\'];
        if exist(Smooth_dir,'dir') == 0;
            mkdir(Smooth_dir);
        end
        
        SmoothM_dir = [Smooth_dir '\Mean_Template'];
        if exist(SmoothM_dir,'dir') == 0;
            mkdir(SmoothM_dir);
        end
        
        if Temps == 3,
            Smooth1_dir = [Smooth_dir prefix1 'Template'];
            if exist(Smooth1_dir,'dir') == 0;
                mkdir(Smooth1_dir);
            end
            Smooth2_dir = [Smooth_dir prefix2 'Template'];
            if exist(Smooth2_dir,'dir') == 0;
                mkdir(Smooth2_dir);
            end
            
            prefix = 's4';
            matlabbatch{1}.spm.spatial.smooth.data = Ref1_array;
            matlabbatch{1}.spm.spatial.smooth.prefix = prefix;
            Smooth = spm_jobman('run',matlabbatch);
            
            for ii = 1:1:Refrows
                [pathstr, name, ext] = fileparts(Ref1_array{ii,:});
                stringext = strfind(ext,'.img');
                if isempty(stringext)
                    ext = ('.nii');
                    Refimgs = [pathstr '\s4' name ext];
                    Smoothimgs = [Smooth1_dir '\s4' name ext];
                    movefile(Refimgs,Smoothimgs);
                else
                    ext = ('.img');
                    hdr = ('.hdr');
                    Refimgs = [pathstr '\s4' name ext];
                    Smoothimgs = [Smooth1_dir '\s4' name ext];
                    movefile(Refimgs,Smoothimgs);
                    Refhdr = [pathstr '\s4' name hdr];
                    Smoothhdr = [Smooth1_dir '\s4' name hdr];
                    movefile(Refhdr,Smoothhdr);
                end
            end
            
            prefix = 's4';
            matlabbatch{1}.spm.spatial.smooth.data = Ref2_array;
            matlabbatch{1}.spm.spatial.smooth.prefix = prefix;
            Smooth = spm_jobman('run',matlabbatch);
            
            for ii = 1:1:Refrows
                [pathstr, name, ext] = fileparts(Ref2_array{ii,:});
                stringext = strfind(ext,'.img');
                if isempty(stringext)
                    ext = ('.nii');
                    Refimgs = [pathstr '\s4' name ext];
                    Smoothimgs = [Smooth2_dir '\s4' name ext];
                    movefile(Refimgs,Smoothimgs);
                else
                    ext = ('.img');
                    hdr = ('.hdr');
                    Refimgs = [pathstr '\s4' name ext];
                    Smoothimgs = [Smooth2_dir '\s4' name ext];
                    movefile(Refimgs,Smoothimgs);
                    Refhdr = [pathstr '\s4' name hdr];
                    Smoothhdr = [Smooth2_dir '\s4' name hdr];
                    movefile(Refhdr,Smoothhdr);
                end
            end
        end
        
        if Temps == 2,
            
            Smooth1_dir = [Smooth_dir prefix1 'Template'];
            if exist(Smooth1_dir,'dir') == 0;
                mkdir(Smooth1_dir);
            end
            prefix = 's4';
            matlabbatch{1}.spm.spatial.smooth.data = Ref1_array;
            matlabbatch{1}.spm.spatial.smooth.prefix = prefix;
            Smooth = spm_jobman('run',matlabbatch);
            
            for ii = 1:1:Refrows
                [pathstr, name, ext] = fileparts(Ref1_array{ii,:});
                stringext = strfind(ext,'.img');
                if isempty(stringext)
                    ext = ('.nii');
                    Refimgs = [pathstr '\s4' name ext];
                    Smoothimgs = [SmoothM_dir '\s4' name ext];
                    movefile(Refimgs,Smoothimgs);
                else
                    ext = ('.img');
                    hdr = ('.hdr');
                    Refimgs = [pathstr '\s4' name ext];
                    Smoothimgs = [SmoothM_dir '\s4' name ext];
                    movefile(Refimgs,Smoothimgs);
                    Refhdr = [pathstr '\s4' name hdr];
                    Smoothhdr = [SmoothM_dir '\s4' name hdr];
                    movefile(Refhdr,Smoothhdr);
                end
            end
        end
        
        prefix = 's4';
        matlabbatch{1}.spm.spatial.smooth.data = Mean_array;
        matlabbatch{1}.spm.spatial.smooth.prefix = prefix;
        Smooth = spm_jobman('run',matlabbatch);
        
        for ii = 1:1:Refrows
            [pathstr, name, ext] = fileparts(Mean_array{ii,:});
            stringext = strfind(ext,'.img');
            if isempty(stringext)
                ext = ('.nii');
                Refimgs = [pathstr '\s4' name ext];
                Smoothimgs = [SmoothM_dir '\s4' name ext];
                movefile(Refimgs,Smoothimgs);
            else
                ext = ('.img');
                hdr = ('.hdr');
                Refimgs = [pathstr '\s4' name ext];
                Smoothimgs = [SmoothM_dir '\s4' name ext];
                movefile(Refimgs,Smoothimgs);
                Refhdr = [pathstr '\s4' name hdr];
                Smoothhdr = [SmoothM_dir '\s4' name hdr];
                movefile(Refhdr,Smoothhdr);
            end
        end
        
        %     rmdir(Norm_dir,'s'); % Delete template directory
    end
end

clc
close all;

disp('DONE!');

end