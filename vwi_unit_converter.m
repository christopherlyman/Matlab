function vwi_unit_converter()


[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));
spm8_path = char(textread([pth '\spm8_path.txt'],'%s'));

while true
    try spm_rmpath;
    catch
        break;
    end
end

addpath(spm8_path,'-frozen');

clc

spm_get_defaults('cmdline',true);

unitlist{1,1} = 'nCi';
unitlist{2,1} = 'uCi';
unitlist{3,1} = 'mCi';
unitlist{4,1} = 'Ci';
unitlist{5,1} = 'Bq';
unitlist{6,1} = 'kBq';
unitlist{7,1} = 'MBq';
unitlist{8,1} = 'GBq';
unitlist{9,1} = 'dpm';
unitlist{10,1} = 'other';

unitable{1,1} = 'nCi';
unitable{1,2} = '1';
unitable{1,3} = '1';
unitable{2,1} = 'uCi';
unitable{2,2} = '1';
unitable{2,3} = '1000';
unitable{3,1} = 'mCi';
unitable{3,2} = '1';
unitable{3,3} = '1000000';
unitable{4,1} = 'Ci';
unitable{4,2} = '1';
unitable{4,3} = '1000000000';
unitable{5,1} = 'Bq';
unitable{5,2} = '2';
unitable{5,3} = '1';
unitable{6,1} = 'kBq';
unitable{6,2} = '2';
unitable{6,3} = '0.001';
unitable{7,1} = 'MBq';
unitable{7,2} = '2';
unitable{7,3} = '0.000001';
unitable{8,1} = 'GBq';
unitable{8,2} = '2';
unitable{8,3} = '0.000000001';
unitable{9,1} = 'dpm';
unitable{9,2} = '2';
unitable{9,3} = '60';


[Inputselection,ok] = listdlg('PromptString','Select the original image units:',...
    'SelectionMode','single','ListSize',[160 300],'Name','Unit Converter','ListString',unitlist);
while isempty(Inputselection)
    uiwait(msgbox('Error: You must select the original image units.','Error message','error'));
    [Inputselection,ok] = listdlg('PromptString','Select original image units:',...
        'SelectionMode','single','ListSize',[160 300],'Name','Unit Converter','ListString',unitlist);
end


[Outputselection,ok] = listdlg('PromptString','Select units to convert to:',...
    'SelectionMode','single','ListSize',[160 300],'Name','Unit Converter','ListString',unitlist);
while isempty(Outputselection)
    uiwait(msgbox('Error: You must select units to convert to.','Error message','error'));
    [Outputselection,ok] = listdlg('PromptString','Select units to convert to:',...
        'SelectionMode','single','ListSize',[160 300],'Name','Unit Converter','ListString',unitlist);
end

if Outputselection ~= 10 && Inputselection ~= 10,
    
    inputclass = unitable(Inputselection,2);
    inputval = unitable(Inputselection,3);
    outputclass = unitable(Outputselection,2);
    outputval = unitable(Outputselection,3);
    
    if str2double(inputclass) == 1 && str2double(outputclass) == 2,
        conv_factor = ['37*' inputval{1} '*' outputval{1}];
    elseif str2double(inputclass) == 2 && str2double(outputclass) == 1,
        conv_factor = ['0.02702702702702703/' inputval{1} '/' outputval{1}];
    elseif str2double(inputclass) == 2 && str2double(outputclass) == 2,
        conv_factor = ['1*' inputval{1} '*' outputval{1}];
    elseif str2double(inputclass) == 1 && str2double(outputclass) == 1,
        conv_factor = ['1/' inputval{1} '/' outputval{1}];
    end
    
    msg = ('Please select original images');
    images = spm_select(Inf,'image', msg ,[],home_dir,'\.(nii|img)$');
    clear msg;
    imrows = size(images,1);
    
    
    for zz=1:imrows % Reslice and threshold ROIs
        vol_in = images(zz,:);
        vol_out = images(zz,:);
        exp = ['(' conv_factor ')*(i1)'];
        spm_imcalc_ui(vol_in,vol_out,exp);
    end
    
else
    box1 = {'Enter a conversion factor Name:'};
    box_title = 'VWI';
    num_lines = 1;
    default = {''};
    input_factor = inputdlg(box1,box_title,num_lines,default);
    conv_int = round(str2double(input_factor{1}));
    while isnan(conv_int)
        msg = ('conversion factor must be a number:');
        uiwait(errordlg(msg,'VWI'));
        input_factor = inputdlg(box1,box_title,num_lines,default);
        conv_int = round(str2double(input_factor{1}));
        clear msg
    end
    conv_factor = input_factor{1};
    
    msg = ('Please select original images');
    images = spm_select(Inf,'image', msg ,[],home_dir,'\.(nii|img)$');
    clear msg;
    imrows = size(images,1);
    
    for zz=1:imrows % Reslice and threshold ROIs
        vol_in = images(zz,:);
        vol_out = images(zz,:);
        exp = [conv_factor '*(i1)'];
        spm_imcalc_ui(vol_in,vol_out,exp);
    end
end

end