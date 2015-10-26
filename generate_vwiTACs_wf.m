function generate_vwiTACs_wf(sub,study)
%
%        Kinetic Modeling Pipeline
%        TAC module for KMP VOIs
%        Copyright (C) 2012 Johns Hopkins University
%        Software by Cliff Workman
%
%        Usage: generate_kmpTACs_wf(sub_stu,dasb1_pdir,pib_pdir,dasb2_pdir)
%
%        sub_stu: subject number, prefixed with "MCI" where required
%        dasb1_pdir: baseline DASB processing directory
%        pib_pdir: PIB processing directory
%        dasb2_pdir: follow-up DASB processing directory
%
%        This module generates time activity curves for dynamic PET scans
%        using the automated KMP VOIs. The TACs will be outputted to the
%        subdirectory "KMP_MRes_TACs" within a given processing directory.
%
%        TACs are generated only for regions specified in the
%        "kmp_TAC_regions.xlsx" spreadsheet. The regions named in this
%        spreadsheet must conform directly to the naming convention used by
%        KMP. (For example, since the centrum semiovale is written as
%        "CentrumSemiovale" in the VOI filename, it must be specified
%        indentically in the kmp_TAC_regions spreadsheet.
%
%        This module is meant to be used with KMP. If using as a
%        standalone module, please note that any missing scans should be
%        specified as is done in the following example: dasb1_pdir = '';

%% Declare required variables, if not already declared
[pth] = fileparts(which('kmp'));
[~,~,raw]=xlsread([pth '\kmp_ini.xlsx'],'Dirs and Paths');
dirs_paths = raw; clear raw;
home_dir = cell2mat(dirs_paths(find(strcmp(dirs_paths,'Home directory')>0),2));
if nargin < 1,
    % Prompt for subject number and validity checks
    sub = get_subnum;
    [~,base_dir] = get_basedir(sub,home_dir); if isempty(base_dir), return; end
    if findstr('MCI_AD_(NA_00026190-34091)', base_dir); sub_stu = ['MCI' sub]; % Determine study
    else sub_stu = sub;
    end
    % Declare required variables, reslice cerebellar GM VOI to resliced MPRAGE
    mprage_pdir = [base_dir sub '\MPRAGE\']; % Declare processing directories
    pib_pdir = [base_dir sub '\PIB\'];
    if exist([base_dir sub '\PIB\'],'dir'),
        pib_pdir = [base_dir sub '\PIB\'];
    else pib_pdir = '';
    end
    if exist([base_dir sub '\DASB_BL\'],'dir') & exist([base_dir sub '\DASB_FU\'],'dir'),
        disp('mistake is here 2');
        dasb1_pdir = [base_dir sub '\DASB_BL\'];
        dasb2_pdir = [base_dir sub '\DASB_FU\'];
    elseif exist([base_dir sub '\DASB\'],'dir'),
        disp('mistake is here 2');
        dasb1_pdir = [base_dir sub '\DASB\'];
        dasb2_pdir = '';
    else
        dasb1_pdir = '';
        dasb2_pdir = '';
    end
end

%% Decide for which regions TACs will be generated
[pth] = fileparts(which('kmp')); % Declare required variables
[~,~,raw] = xlsread([pth '\kmp_TAC_regions.xlsx'],'Regions'); % Store names of regions for which we need TACs
all_regions = strtrim(sprintf('%s ' ,raw{:}));

%% Desginate reference images
if isempty(dasb1_pdir) == 0, % First, Baseline DASB
    dasb1_frames = dir([dasb1_pdir '\Summed\*.img']);
    dasb1_frames = flipdim(strvcat({dasb1_frames.name}),1);
    dasb1_ref = deblank(dasb1_frames(1,:)); dasb1_ref = ['fr' dasb1_ref(1,end-6:end-4)];
end; clear dasb1_frames;

if isempty(pib_pdir) == 0, % Second, PIB
    pib_frames = dir([pib_pdir '\Summed\*.img']);
    pib_frames = strvcat({pib_frames.name});
    for i=1:size(pib_frames,1),
        current_frame = deblank(pib_frames(i,:));
        pib_nums{i,1} = str2num(current_frame(end-6:end-4));
        pib_nums{i,1} = cell2mat(pib_nums(i,1))-16;
        pib_nums{i,2} = current_frame;
    end
    for i=1:size(pib_frames,1),
        if cell2mat(pib_nums((size(pib_frames,1)+1-i),1))<0,
            pib_nums((size(pib_frames,1)+1-i),:) = [];
        end
    end
    pib_ref = deblank(cell2mat(pib_nums(1,2))); pib_ref = ['fr' pib_ref(1,end-6:end-4)];
end; clear pib_frames;

if isempty(dasb2_pdir) == 0, % First, Baseline DASB
    dasb2_frames = dir([dasb2_pdir '\Summed\*.img']);
    dasb2_frames = flipdim(strvcat({dasb2_frames.name}),1);
    dasb2_ref = deblank(dasb2_frames(1,:)); dasb2_ref = ['fr' dasb2_ref(1,end-6:end-4)];
end; clear dasb2_frames;

%% Prepare for creating TACs
if isempty(dasb1_pdir) == 0 & isempty(pib_pdir) == 0 & isempty(dasb2_pdir) == 0,
    tracer_pdir = str2mat(dasb1_pdir, pib_pdir, dasb2_pdir);
elseif isempty(dasb1_pdir) == 0 & isempty(pib_pdir) == 0 & isempty(dasb2_pdir),
    tracer_pdir = str2mat(dasb1_pdir, pib_pdir);
elseif isempty(dasb1_pdir) == 0 & isempty(pib_pdir) & isempty(dasb2_pdir),
    tracer_pdir = str2mat(dasb1_pdir);
elseif isempty(pib_pdir) == 0 & isempty(dasb1_pdir) & isempty(dasb2_pdir),
    tracer_pdir = str2mat(pib_pdir);
end
num_dirs = size(tracer_pdir,1);

% Create an output directory for TACs
if findstr(sub_stu, 'MCI') & exist([home_dir 'MCI_AD_(NA_00026190-34091)\Processed_Images\PET_Data\Processing\KMP_MRes_TACs\' sub_stu '\'],'dir') == 0
    base_dir = [home_dir 'MCI_AD_(NA_00026190-34091)\Processed_Images\PET_Data\Processing\'];
    mkdir([home_dir 'MCI_AD_(NA_00026190-34091)\Processed_Images\PET_Data\Processing\KMP_MRes_TACs\' sub_stu '\']);
elseif isempty(findstr(sub_stu, 'MCI')) & exist([home_dir 'GD_(NA_00021615)\Processed_Images\PET_Data\Processing\KMP_MRes_TACs\' sub_stu '\'],'dir') == 0
    base_dir = [home_dir 'GD_(NA_00021615)\Processed_Images\PET_Data\Processing\'];
    mkdir([home_dir 'GD_(NA_00021615)\Processed_Images\PET_Data\Processing\KMP_MRes_TACs\' sub_stu '\']);
elseif findstr(sub_stu, 'MCI')
    base_dir = [home_dir 'MCI_AD_(NA_00026190-34091)\Processed_Images\PET_Data\Processing\'];
    disp('Directory for outputting KMP TACs already exists.');
else
    base_dir = [home_dir 'GD_(NA_00021615)\Processed_Images\PET_Data\Processing\'];
    disp('Directory for outputting KMP TACs already exists.');
end
outdir = [base_dir 'KMP_MRes_TACs\' sub_stu '\'];

% Make a list of all VOIs in the directory, excluding those for which we don't need TACs
cd([base_dir sub '\MPRAGE\KMP_VOIs_MRes\Summed\']);
kmp_vois = dir([base_dir sub '\MPRAGE\KMP_VOIs_MRes\Summed\*.nii']);
kmp_vois = {kmp_vois.name};
these_regions = str2mat(kmp_vois);
for i = 1:size(these_regions),
    this_region = deblank(these_regions(i,:));
    [~,remain] = strtok(deblank(this_region), '_'); this_region = deblank(strtok(remain(2:end-4), '_'));
    if isempty(strfind(all_regions,this_region)), kmp_vois{1,i} = ''; end
end
kmp_vois = deblank(str2mat(kmp_vois(~cellfun('isempty', kmp_vois))));

mpro_dasb1 = []; mpro_dasb2 = []; mpro_pib = [];
for i=1:size(kmp_vois,1),
    cd([base_dir sub '\MPRAGE\KMP_VOIs_MRes\Summed\']);
    kmp_voi = deblank(kmp_vois(i,:)); % Stores VOI
    [~,remain] = strtok(deblank(kmp_voi), '_'); voi_region = deblank(strtok(remain(2:end-4), '_'));

    read_voi = spm_vol(deblank(kmp_voi));
    thresh_voi = (spm_read_vols(read_voi)>0.5);
    nvox = sum(sum(sum(thresh_voi)));

    % Get the name of the region
    for j=1:num_dirs,
        current_tracer_pdir = deblank(tracer_pdir(j,:));
        if findstr('DASB_BL', tracer_pdir(j,:));
            tracer = 'DASB-BL'; tracer_err = 'BL DASB';
            if isempty(mpro_dasb1),
                [mpro] = set_mpro(pth,current_tracer_pdir,sub_stu,tracer_err);
                mpro_dasb1 = mpro;
            else clear mpro; mpro = mpro_dasb1; end
            if isempty(mpro), disp('No protocol file specified. Terminating.'); return; end
            [dur,tm,wt,num_frames,tac] = set_tacvars(mpro);
            disp(['Generating ' voi_region ' TAC for subject ' sub_stu '''s baseline DASB scan.']);
        elseif findstr('DASB_FU', tracer_pdir(j,:));
            tracer = 'DASB-FU'; tracer_err = 'FU DASB';
            if isempty(mpro_dasb2),
                [mpro] = set_mpro(pth,current_tracer_pdir,sub_stu,tracer_err);
                mpro_dasb2 = mpro;
            else clear mpro; mpro = mpro_dasb2; end
            if isempty(mpro), disp('No protocol file specified. Terminating.'); return; end
            [dur,tm,wt,num_frames,tac] = set_tacvars(mpro);
            disp(['Generating ' voi_region ' TAC for subject ' sub_stu '''s follow-up DASB scan.']);
        elseif findstr('DASB',tracer_pdir(j,:));
            tracer = 'DASB'; tracer_err = 'DASB';
            if isempty(mpro_dasb1),
                [mpro] = set_mpro(pth,current_tracer_pdir,sub_stu,tracer_err);
                mpro_dasb1 = mpro;
            else clear mpro; mpro = mpro_dasb1; end
            if isempty(mpro), disp('No protocol file specified. Terminating.'); return; end
            [dur,tm,wt,num_frames,tac] = set_tacvars(mpro);
            disp(['Generating ' voi_region ' TAC for subject ' sub_stu '''s DASB scan.']);
        elseif findstr('PIB', tracer_pdir(j,:));
            tracer = 'PIB'; tracer_err = tracer;
            if isempty(mpro_pib),
                [mpro] = set_mpro(pth,current_tracer_pdir,sub_stu,tracer_err);
                mpro_pib = mpro;
            else clear mpro; mpro = mpro_pib; end
            if isempty(mpro), disp('No protocol file specified. Terminating.'); return; end
            [dur,tm,wt,num_frames,tac] = set_tacvars(mpro);
            disp(['Generating ' voi_region ' TAC for subject ' sub_stu '''s PIB scan.']);
        end

        cd(deblank(tracer_pdir(j,:))); % CDs to ith directory, stores names of tracer frames
        list_frames = dir('r*.img');
        tracer_frames = [];
        for k=1:num_frames
            frame_names = list_frames(k).name;
            if isempty(tracer_frames); tracer_frames = frame_names;
            else tracer_frames = [tracer_frames;frame_names]; end
        end

        for k=1:num_frames % Kinetic modeling magic
            fpet = deblank(tracer_frames(k,:));
            read_pet = spm_vol(fpet);
            conv_pet = spm_read_vols(read_pet);
            tac(k,2)= sum(sum(sum(conv_pet.*thresh_voi)));
            if strcmp(tracer,'DASB_BL') | strcmp(tracer,'DASB'),
                if strcmp(deblank(tracer_frames(k,end-8:end-4)), dasb1_ref),
                    gen_voifig(thresh_voi,conv_pet,sub_stu,tracer,voi_region,outdir);
                end
            elseif strcmp(tracer,'PIB'),
                if strcmp(deblank(tracer_frames(k,end-8:end-4)), pib_ref),
                    gen_voifig(thresh_voi,conv_pet,sub_stu,tracer,voi_region,outdir);
                end
            elseif strcmp(tracer,'DASB_FU'),
                if strcmp(deblank(tracer_frames(k,end-8:end-4)), dasb2_ref),
                    gen_voifig(thresh_voi,conv_pet,sub_stu,tracer,voi_region,outdir);
                end
            end
            clear fpet read_pet conv_pet
        end
        
        h = figure; % Generates outputs
        tac(:,2)=tac(:,2)/nvox;
        plot(tm,tac(:,2),'o');
        if exist ([outdir sub_stu '_' tracer '_' voi_region '_TAC_Fig.tif'],'file'),
            pout = [outdir sub_stu '_' tracer '_' voi_region '_Eroded_TAC_Fig.tif'];
        else pout = [outdir sub_stu '_' tracer '_' voi_region '_TAC_Fig.tif']; end
        print(h, '-dtiff', pout);
        close(h);
        if exist ([outdir sub_stu '_' tracer '_' voi_region '_TAC.xls'],'file'),
            fout = [outdir sub_stu '_' tracer '_' voi_region '_Eroded_TAC.xls'];
        else fout = [outdir sub_stu '_' tracer '_' voi_region '_TAC.xls']; end
        xlswrite(fout,tac);
    end
    clear read_voi thresh_voi
end

%% Figure out which protocol file to use
function [mpro] = set_mpro(pth,tracer_pdir,sub_stu,tracer_err)
pdir_contents = dir([tracer_pdir '\r*.img']);
if size(strvcat({pdir_contents.name}),1) ~= 30, % Reads protocol spreadsheet
    prot_err = questdlg(['Unexpected number of frames in ' sub_stu '''s ' tracer_err ' processing directory. What do?'], ...
                         'Kinetic Modeling', 'Select alternate protocol file', 'Abort', 'Abort');
    switch prot_err
        case 'Select alternate protocol file'
            [FileName,PathName] = uigetfile([pth '\protocols\*.xlsx'],'Select protocol file for generating TACs.');
            if FileName == 0,
                mpro = []; dur = []; tm = []; wt = []; num_frames = []; tac = [];
                return
            else mpro = xlsread([PathName '\' FileName]);
            end
        case 'Abort'
            mpro = []; dur = []; tm = []; wt = []; num_frames = []; tac = [];
            return
    end
else mpro = xlsread([pth '\protocols\standard.xlsx'],'protocol'); end
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

%% Display the VOIs on representative PET frames
function gen_voifig(thresh_voi,conv_pet,sub_stu,tracer,voi_region,outdir)
voi_voxels = find(thresh_voi(:)>0);
masked_pet = conv_pet;
inc = ((max(conv_pet(:))-min(conv_pet(:)))/64);
for l = 1:size(voi_voxels,1),
    masked_pet(voi_voxels(l)) = max(conv_pet(:))+inc;
end
scrsz = get(0, 'MonitorPositions');
num_planes = 30; slices_inc = size(masked_pet); slices_inc = (slices_inc(3)/num_planes);
current_slice = 1;
hf = figure('units','pixels','position',[0 0 scrsz(3) scrsz(4)]); movegui(hf,'center');
colormap([gray(64);[1 0 0]]);
for l=1:num_planes,
    h(l) = subplot(3,10,l);
    subp = get(h(l),'Position'); set(h(l),'Position',[subp(1) subp(2) .075 .2]);
    ipet = imagesc(imrotate(masked_pet(:,:,current_slice),90)); axis off
    ax = findobj(gcf,'Type','axes'); set(ax,'CLim', [min(conv_pet(:)) max(conv_pet(:))]);
    if current_slice == 1, current_slice = 5;
    else current_slice = current_slice+slices_inc; end
    hold all
end
if exist([outdir 'VOI_Placement\' tracer '\'],'dir') == 0, mkdir([outdir 'VOI_Placement\' tracer '\']); end
if exist([outdir 'VOI_Placement\' tracer '\' sub_stu '_' tracer '_' voi_region '.tif'],'file'),
    pout = char([outdir 'VOI_Placement\' tracer '\' sub_stu '_' tracer '_' voi_region '_Eroded.tif']);
else pout = char([outdir 'VOI_Placement\' tracer '\' sub_stu '_' tracer '_' voi_region '.tif']); end
print(hf, '-dtiff', pout);
close(hf);
end
end