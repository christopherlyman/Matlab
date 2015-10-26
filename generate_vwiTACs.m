function generate_vwiTACs(sub,study)
%
%        Kinetic Modeling Pipeline
%        TAC module for VWI VOIs
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman
%
%        Usage: generate_vwiTACs(sub,dasb1_pdir,pib1_pdir,dasb2_pdir)
%
%        sub: subject number, prefixed with "MCI" where required
%        dasb1_pdir: baseline DASB processing directory
%        pib1_pdir: PIB processing directory
%        dasb2_pdir: follow-up DASB processing directory
%        pib2_pdir: follow-up PIB processing directory
%
%        This module generates time activity curves for dynamic PET scans
%        using the automated VWI VOIs. The TACs will be outputted to the
%        subdirectory "VWI_MRes_TACs" within a given processing directory.
%
%        TACs are generated only for regions specified in the
%        "vwi_TAC_regions.xlsx" spreadsheet. The regions named in this
%        spreadsheet must conform directly to the naming convention used by
%        VWI. (For example, since the centrum semiovale is written as
%        "CentrumSemiovale" in the VOI filename, it must be specified
%        indentically in the vwi_TAC_regions spreadsheet.
%
%        This module is meant to be used with VWI. If using as a
%        standalone module, please note that any missing scans should be
%        specified as is done in the following example: dasb1_pdir = '';

%% Declare required variables, if not already declared
if exist('sub','var') == 0,
    Study_Sub;
    waitfor(Study_Sub);
    sub = evalin('base','sub');
    study = evalin('base','study');
end

[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));


%% Define Dirs and set SPM8 path
while true
    try, spm_rmpath;
    catch
        break;
    end
end
addpath(spm8_path,'-frozen');
clc

spm_get_defaults('cmdline',true);

[~,~,raw]=xlsread([pth '\Studies\' study '.xlsx'],'Study-Protocol');
studyprotocol = raw;
clear raw;
study_dir = studyprotocol{1,2};
sub_dir = [study_dir '\Dynamic\' sub];

textfile = [sub_dir '\' sub '_MR-Scans.txt'];
fid = fopen(textfile);
mri_scans = textscan(fid,'%s%s','Whitespace','\t');
fclose(fid);
mr_name = cell2mat(mri_scans{1});
mr_num = cell2mat(mri_scans{2});

textfile = [sub_dir '\' sub '_PET-Scans.txt'];
fid = fopen(textfile);
pet_scans = textscan(fid,'%s%s','Whitespace','\t');
fclose(fid);
pet_names = pet_scans{1};
pet_num = pet_scans{2};


%% Decide for which regions TACs will be generated
[pth] = fileparts(which('vwi')); % Declare required variables
[~,~,raw] = xlsread([pth '\vwi_regions.xlsx'],'Regions'); % Store names of regions for which we need TACs
all_regions = strtrim(sprintf('%s ' ,raw{:}));

%% Prepare for creating TACs

for jj=1:1 %str2double(mr_num)
    if str2double(mr_num)>1
        mrtype = sprintf('%s%s%d', mr_name, '_',jj);
    else
        mrtype = mr_name;
    end
    mr_dir = [sub_dir '\' mrtype '\']; % Declare processing directories
    
    % Create an output directory for TACs
    if exist([study_dir '\Dynamic\!Region_TACs\' sub '\'],'dir') == 0
        mkdir([study_dir '\Dynamic\!Region_TACs\' sub '\']);
        outdir = [study_dir '\Dynamic\!Region_TACs\' sub '\'];
    else
        outdir = [study_dir '\Dynamic\!Region_TACs\' sub '\'];
    end
    
    % Make a list of all VOIs in the directory, excluding those for which we don't need TACs
    vwi_vois = dir([mr_dir 'VWI_VOIs_MRes\Summed\*.nii']);
    vwi_vois = {vwi_vois.name};
    these_regions = str2mat(vwi_vois);
    for ii = 1:size(these_regions),
        this_region = deblank(these_regions(ii,:));
        [tok,remain] = strtok(deblank(this_region), [sub '_']); this_region = deblank(strtok(tok(1:end-4), '_'));
        if isempty(strfind(all_regions,this_region)), vwi_vois{1,ii} = ''; end
    end
    vwi_vois = deblank(str2mat(vwi_vois(~cellfun('isempty', vwi_vois))));
    
    
    
    for ii=1:size(pet_names,1),
        Tracer_name = pet_names{ii,1};
        for zz=1:str2double(pet_num{ii,1});
            if str2double(pet_num{ii,1}) > 1,
                pet_name = sprintf('%s%s%d', Tracer_name, '_', zz);
                pet_dir = [sub_dir '\' pet_name '\'];
            else
                pet_name = Tracer_name;
                pet_dir = [sub_dir '\' pet_name '\'];
            end
            
            
            tracer_frames = dir([pet_dir, 'r*']); % Create array of SPM-ready img files
            tracer_frames = {tracer_frames(~[tracer_frames.isdir]).name};
            tracer_frames = regexprep(tracer_frames, '.img', '.img,1');
            tracer_frames = regexprep(tracer_frames, '(.*).hdr', '');
            tracer_frames = deblank(str2mat(tracer_frames(~cellfun('isempty', tracer_frames))));
            
            [pathstr] = fileparts(which('vwi'));
            FileName = [Tracer_name '.xlsx'];
            PathName = [pathstr '\Tracers\protocols\'];
            [~,~,raw]=xlsread([PathName FileName],'protocol');
            Protocolsize = size(raw,1)-1;
            if size(tracer_frames,1) == Protocolsize,
                disp('Found appropriate tracer protocol');
            else
                disp('No appropriate tracer protocol found');
                %                 prot_err = questdlg(['Unexpected number of frames in ' pet_name ' directory.'], ...
%                 prot_err = questdlg(['Found in pet_num loop.'], ...
%                     'VWI', 'Select alternate protocol file', 'Abort', 'Abort');
%                 switch prot_err
%                     case 'Select alternate protocol file'
%                         [FileName,PathName] = uigetfile([pathstr '\Tracers\protocols\*.xlsx'],'Select protocol file for fxf realignment.');
%                         if FileName == 0,
%                             disp('No protocol file specified. Terminating.');
%                             return
%                         end
%                         [~,~,raw]=xlsread([PathName FileName],'protocol');
%                     case 'Abort'
%                         disp('Unexpected number of frames for fxf realignment. Terminating.');
%                         return
%                 end
            end
            
            for kk=1:size(vwi_vois,1),
                vwi_voi = deblank(vwi_vois(kk,:)); % Stores VOI
                [~, ~, voiext] = fileparts([mr_dir 'VWI_VOIs_MRes\Summed\' vwi_voi]);
                [tok,~] = strtok(deblank(vwi_voi), sub);
                tokext = strfind(tok,voiext);
                voi_region = deblank(tok(2:tokext-1));
                
                %                 voi_region = deblank(strtok(tok(1:end-4), '_'));
                vwi_voi = [mr_dir 'VWI_VOIs_MRes\Summed\' deblank(vwi_vois(kk,:))];
                read_voi = spm_vol(deblank(vwi_voi));
                thresh_voi = (spm_read_vols(read_voi)>0.5);
                nvox = sum(sum(sum(thresh_voi)));
                
                % Get the name of the region
                current_pet_dir = pet_dir;
                
                tracer = ['_' pet_name '_']; tracer_err = pet_name;
                [mpro] = set_mpro(pathstr,current_pet_dir,sub,tracer_err);
                if isempty(mpro), disp('No protocol file specified. Terminating.'); return; end
                [dur,tm,wt,num_frames,tac] = set_tacvars(mpro);
                disp(['Generating ' voi_region ' TAC for subject ' sub '''s ' pet_name ' scan.']);
                
                
                
                list_frames = dir([pet_dir 'r*.img']);
                tracer_frames = [];
                for gg=1:num_frames
                    frame_names = list_frames(gg).name;
                    if isempty(tracer_frames); tracer_frames = frame_names;
                    else tracer_frames = [tracer_frames;frame_names]; end
                end
                
                for gg=1:num_frames % Kinetic modeling magic
                    fpet = [pet_dir deblank(tracer_frames(gg,:))];
                    read_pet = spm_vol(fpet);
                    conv_pet = spm_read_vols(read_pet);
                    tac(gg,2)= sum(sum(sum(conv_pet.*thresh_voi)));
                    clear fpet read_pet conv_pet
                end
                
                h = figure; % Generates outputs
                tac(:,2)=tac(:,2)/nvox;
                plot(tm,tac(:,2),'o');
                if exist ([outdir sub tracer voi_region '_TAC_Fig.tif'],'file'),
                    pout = [outdir sub tracer voi_region '_Eroded_TAC_Fig.tif'];
                else pout = [outdir sub tracer voi_region '_TAC_Fig.tif']; end
                print(h, '-dtiff', pout);
                close(h);
                if exist ([outdir sub tracer voi_region '_TAC.xls'],'file'),
                    fout = [outdir sub tracer voi_region '_Eroded_TAC.xls'];
                else fout = [outdir sub tracer voi_region '_TAC.xls']; end
                xlswrite(fout,tac);
            end
            clear read_voi list_frames tracer_frames Protocolsize
        end
    end
    
end

%% Figure out which protocol file to use
    function [mpro] = set_mpro(pathstr,pet_dir,sub,tracer_err)
        pdir_contents = dir([pet_dir 'r*.img']);
        % if size(strvcat({pdir_contents.name}),1) ~= 30, % Reads protocol spreadsheet
        if size(strvcat({pdir_contents.name}),1) ~= Protocolsize, % Reads protocol spreadsheet
            prot_err = questdlg(['Unexpected number of frames in ' sub '''s ' tracer_err ' processing directory. What do?'], ...
                'VWI', 'Select alternate protocol file', 'Abort', 'Abort');
            switch prot_err
                case 'Select alternate protocol file'
                    [FileName,PathName] = uigetfile([pathstr '\Tracers\protocols\alternate_protocols\*.xlsx'],'Select protocol file for generating TACs.');
                    if FileName == 0,
                        mpro = []; dur = []; tm = []; wt = []; num_frames = []; tac = [];
                        return
                    else mpro = xlsread([PathName '\' FileName]);
                    end
                case 'Abort'
                    mpro = []; dur = []; tm = []; wt = []; num_frames = []; tac = [];
                    return
            end
        else mpro = xlsread([pathstr '\Tracers\protocols\' Tracer_name '.xlsx'],'protocol'); end
    end

%% Set other TAC vars
    function [dur,tm,wt,num_frames,tac] = set_tacvars(mpro)
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