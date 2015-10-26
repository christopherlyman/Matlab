function stdysub = get_stdysub()
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
box1 = {'Enter Study Name:', 'Enter Subject Number:'};
box_title = 'SPA';
num_lines = 1;
default = {'',''};
stdysub = inputdlg(box1,box_title,num_lines,default);
if isempty(stdysub),
    return,
end;

if isempty(stdysub{1}) == 0 || isempty(stdysub{2}) == 0;
    stdy = stdysub{1};
    sub = stdysub{2};
end
while isempty(stdysub{1})
    uiwait(msgbox('Error: Study Name not entered.','Error message','error'));
    box1 = {'Enter Study Name:', 'Enter Subject Number:'};
    box_title = 'SPA';
    num_lines = 1;
    default1 = {'',sub};
    stdysub = inputdlg(box1,box_title,num_lines,default1);
    if isempty(stdysub{1}) == 0;
        stdy = stdysub{1};
        sub = stdysub{2};
    end
end

while isempty(stdysub{2})
    uiwait(msgbox('Error: Subject Number was not entered.','Error message','error'));
    box1 = {'Enter Study Name:', 'Enter Subject Number:'};
    box_title = 'SPA';
    num_lines = 1;
    default2 = {stdy,''};
    stdysub = inputdlg(box1,box_title,num_lines,default2);
    if isempty(stdysub{2}) == 0;
        stdy = stdysub{1};
        sub = stdysub{2};
    end
end

end