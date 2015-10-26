function stdysub = get_stdysub_IMnum()
%
%        FDG Automatic Pipeline
%        get_stdysub
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher Lyman, Cliff Workman, & Dr. Kentaro Hirao
%
%        Usage: get_stdysub
%
%        This function stores study name and subject's number.

%% Store Study Name:
box1 = {'Enter Study Name:', 'Enter Subject Number:', 'Number of MRI scans:', 'Number of FDG PET scans:'};
box_title = 'SPA';
num_lines = 1;
default = {'','','0','1'};
stdysub = inputdlg(box1,box_title,num_lines,default);
if isempty(stdysub),
    return,
end;

if isempty(stdysub{1}) == 0 || isempty(stdysub{2}) == 0 || isempty(stdysub{3}) == 0 || isempty(stdysub{4}) == 0;
    stdy = stdysub{1};
    sub = stdysub{2};
    MRInum = stdysub{3};
    FDGnum = stdysub{4};
end
while isempty(stdysub{1})
    uiwait(msgbox('Error: Study Name not entered.','Error message','error'));
    box1 = {'Enter Study Name:', 'Enter Subject Number:', 'Number of MRI scans:', 'Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    default1 = {'',sub,MRInum,FDGnum};
    stdysub = inputdlg(box1,box_title,num_lines,default1);
    if isempty(stdysub{1}) == 0;
        stdy = stdysub{1};
        sub = stdysub{2};
        MRInum = stdysub{3};
        FDGnum = stdysub{4};
    end
end

while isempty(stdysub{2})
    uiwait(msgbox('Error: Subject Number was not entered.','Error message','error'));
    box1 = {'Enter Study Name:', 'Enter Subject Number:', 'Number of MRI scans:', 'Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    default2 = {stdy,'',MRInum,FDGnum};
    stdysub = inputdlg(box1,box_title,num_lines,default2);
    if isempty(stdysub{2}) == 0;
        stdy = stdysub{1};
        sub = stdysub{2};
        MRInum = stdysub{3};
        FDGnum = stdysub{4};
    end
end

while isempty(stdysub{3})
    uiwait(msgbox('Error: The Number of MRI scans was not entered.','Error message','error'));
    box1 = {'Enter Study Name:', 'Enter Subject Number:', 'Number of MRI scans:', 'Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    default3 = {stdy,sub,'0',FDGnum};
    stdysub = inputdlg(box1,box_title,num_lines,default3);
    if isempty(stdysub{3}) == 0;
        stdy = stdysub{1};
        sub = stdysub{2};
        MRInum = stdysub{3};
        FDGnum = stdysub{4};
    end
end

while isempty(stdysub{4})
    uiwait(msgbox('Error: The Number of FDG PET scans was not entered.','Error message','error'));
    box1 = {'Enter Study Name:', 'Enter Subject Number:', 'Number of MRI scans:', 'Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    default4 = {stdy,sub,MRInum,'1'};
    stdysub = inputdlg(box1,box_title,num_lines,default4);
    if isempty(stdysub{4}) == 0;
        stdy = stdysub{1};
        sub = stdysub{2};
        MRInum = stdysub{3};
        FDGnum = stdysub{4};
    end
end

MRIint = round(str2double(MRInum));
FDGint = round(str2double(FDGnum));
while isnan(MRIint)
    % They didn't enter a number.
    % They clicked Cancel, or entered a character, symbols, or something else not allowed.
    uiwait(msgbox('Error: A number must be entered','Error message','error'));
    box1 = {'Enter Number of MRI scans:'};
    box_title = 'SPA';
    num_lines = 1;
    MRIdefault = {'0'};
    MRIscan = inputdlg(box1,box_title,num_lines,MRIdefault);
    if isempty(MRIscan{1}) == 0;
        MRIint = MRIscan{1};
        stdysub{3} = MRIint;
        MRInum = stdysub{3};
        MRIint = round(str2double(MRInum));
        FDGint = round(str2double(FDGnum));
    end
end
while isnan(FDGint)
    % They didn't enter a number.
    % They clicked Cancel, or entered a character, symbols, or something else not allowed.
    uiwait(msgbox('Error: A number must be entered for FDG scans','Error message','error'));
    box1 = {'Enter Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    FDGdefault = {'1'};
    FDGscan = inputdlg(box1,box_title,num_lines,FDGdefault);
    if isempty(FDGscan{1}) == 0;
        FDGint = FDGscan{1};
        stdysub{4} = FDGint;
        FDGnum = stdysub{4};
        MRIint = round(str2double(MRInum));
        FDGint = round(str2double(FDGnum));
    end
end

end