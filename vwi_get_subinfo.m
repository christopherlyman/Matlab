function subinfo = get_subinfo(i)
%
%        FDG Automatic Pipeline
%        get_subinfo
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher Lyman, Cliff Workman, & Dr. Kentaro Hirao
%
%        Usage: get_subinfo
%
%        This function stores study name and subject's number.

%% Store Study Name:

box = ('Enter Subject Number for ');
box1 = [sprintf('%s%d',box,i)];
box2 = {box1, 'Number of MRI scans:', 'Number of FDG PET scans:'};
box_title = 'SPA';
num_lines = 1;
default = {'','1','1'};
subinfo = inputdlg(box2,box_title,num_lines,default);
if isempty(subinfo),
    return,
end;

if isempty(subinfo{1}) == 0 || isempty(subinfo{2}) == 0 || isempty(subinfo{3}) == 0;
    sub = subinfo{1};
    MRInum = subinfo{2};
    FDGnum = subinfo{3};
end

while isempty(subinfo{1})
    uiwait(msgbox('Error: Subject Number not entered.','Error message','error'));
    box = ('Enter Subject Number for ');
    box1 = [sprintf('%s%d',box,i)];
    box2 = {box1, 'Number of MRI scans:', 'Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    default1 = {'',MRInum,FDGnum};
    subinfo = inputdlg(box1,box_title,num_lines,default1);
    if isempty(subinfo{1}) == 0;
        sub = subinfo{1};
        MRInum = subinfo{2};
        FDGnum = subinfo{3};
    end
end

while isempty(subinfo{2})
    uiwait(msgbox('Error: The Number of MRI scans was not entered.','Error message','error'));
    box = ('Enter Subject Number for ');
    box1 = [sprintf('%s%d',box,i)];
    box2 = {box1, 'Number of MRI scans:', 'Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    default3 = {sub,'1',FDGnum};
    subinfo = inputdlg(box1,box_title,num_lines,default3);
    if isempty(subinfo{2}) == 0;
        sub = subinfo{1};
        MRInum = subinfo{2};
        FDGnum = subinfo{3};
    end
end

while isempty(subinfo{3})
    uiwait(msgbox('Error: The Number of FDG PET scans was not entered.','Error message','error'));
    box = ('Enter Subject Number for ');
    box1 = [sprintf('%s%d',box,i)];
    box2 = {box1, 'Number of MRI scans:', 'Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    default4 = {sub,MRInum,'1'};
    subinfo = inputdlg(box1,box_title,num_lines,default4);
    if isempty(subinfo{3}) == 0;
        sub = subinfo{1};
        MRInum = subinfo{2};
        FDGnum = subinfo{3};
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
    MRIdefault = {'1'};
    MRIscan = inputdlg(box1,box_title,num_lines,MRIdefault);
    if isempty(MRIscan{1}) == 0;
        MRIint = MRIscan{1};
        subinfo{2} = MRIint;
        MRInum = subinfo{2};
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
        subinfo{3} = FDGint;
        FDGnum = subinfo{3};
        MRIint = round(str2double(MRInum));
        FDGint = round(str2double(FDGnum));
    end
end


end