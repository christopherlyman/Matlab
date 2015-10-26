function stdysubnum = get_stdysubnum()
%
%        FDG Automatic Pipeline
%        get_stdysubnum
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Christopher Lyman, Cliff Workman, & Dr. Kentaro Hirao
%
%        Usage: get_stdysubnum
%
%        This function stores study name and the number of subjects to be analyzed.

%% Store Study Name:
box1 = {'Enter Study Name:', 'Enter Number of Subjects to Analyze:'};
box_title = 'SPA';
num_lines = 1;
default = {'','1'};
stdysubnum = inputdlg(box1,box_title,num_lines,default);
if isempty(stdysubnum),
    return,
end;

if isempty(stdysubnum{1}) == 0 || isempty(stdysubnum{2}) == 0;
    stdy = stdysubnum{1};
    subnum = stdysubnum{2};
end
%% Check that a Study name was entered
% while isempty(stdysubnum{1})
%     uiwait(msgbox('Error: Study Name not entered.','Error message','error'));
%     box1 = {'Enter Study Name:', 'Enter Subject Number:', 'Number of MRI scans:', 'Number of FDG PET scans:'};
%     box_title = 'SPA';
%     num_lines = 1;
%     default1 = {'',subnum};
%     stdysubnum = inputdlg(box1,box_title,num_lines,default1);
%     if isempty(stdysubnum{1}) == 0;
%         stdy = stdysubnum{1};
%         subnum = stdysubnum{2};
%     end
% end

%% Check that a number of subjects to be analyzed was entered
while isempty(stdysubnum{2})
    uiwait(msgbox('Error: The Number of subjects to be analzyed cannot be 0.','Error message','error'));
    box1 = {'Enter Study Name:', 'Enter Subject Number:', 'Number of MRI scans:', 'Number of FDG PET scans:'};
    box_title = 'SPA';
    num_lines = 1;
    default2 = {stdy,'1'};
    stdysubnum = inputdlg(box1,box_title,num_lines,default2);
    if isempty(stdysubnum{2}) == 0;
        stdy = stdysubnum{1};
        subnum = stdysubnum{2};
    end
end

%% Check that the value entered for subnum was an integer.

subint = round(str2double(subnum));
while isnan(subint)
    % They didn't enter a number.
    % They clicked Cancel, or entered a character, symbols, or something else not allowed.
    uiwait(msgbox('Error: A number must be entered','Error message','error'));
    box1 = {'Enter Number of MRI scans:'};
    box_title = 'SPA';
    num_lines = 1;
    Subnumdefault = {'1'};
    subval = inputdlg(box1,box_title,num_lines,Subnumdefault);
    if isempty(subval{1}) == 0;
        subint = subval{1};
        stdysubnum{2} = subint;
        subnum = stdysubnum{2};
        subint = round(str2double(subnum));
    end
end

end