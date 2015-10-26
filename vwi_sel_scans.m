function varargout = sel_scans(varargin)
%
%        FDG Automated Pipeline
%        get_data
%        Copyright (C) 2013 Johns Hopkins University
%        Software by Chrisotpher H. Lyman, Clifford Workman
%
%        Usage: get_data
%
%        This function stores which scans are available for a given
%        participant.
%
% SEL_SCANS M-file for sel_scans.fig
%      SEL_SCANS, by itself, creates a new SEL_SCANS or raises the existing
%      singleton*.
%
%      H = SEL_SCANS returns the handle to a new SEL_SCANS or the handle to
%      the existing singleton*.
%
%      SEL_SCANS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SEL_SCANS.M with the given input arguments.
%
%      SEL_SCANS('Property','Value',...) creates a new SEL_SCANS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sel_scans_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sel_scans_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sel_scans

% Last Modified by GUIDE v2.5 04-Mar-2013 17:53:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sel_scans_OpeningFcn, ...
                   'gui_OutputFcn',  @sel_scans_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before sel_scans is made visible.
function sel_scans_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sel_scans (see VARARGIN)

% Choose default command line output for sel_scans
handles.output = hObject;
set(handles.FDG1_yn,'Value',1);
handles.FDG1_value = 'yes';
set(handles.FDG2_yn,'Value',1);
handles.FDG2_value = 'yes';
handles.FDG3_value = 'no';
set(handles.MR1_yn,'Value',1);
handles.MR1_value = 'yes';
handles.MR2_value = 'no';

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes sel_scans wait for user response (see UIRESUME)
% uiwait(handles.sel_scans);


% --- Outputs from this function are returned to the command line.
function varargout = sel_scans_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Baseline FDG checkbox
% --- Executes on button press in FDG1_yn.
function FDG1_yn_Callback(hObject, eventdata, handles)
% hObject    handle to FDG1_yn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of FDG1_yn
if strcmp(handles.FDG1_value,'no'),
    handles.FDG1_value = 'yes'; guidata(handles.output,handles);
    disp('Baseline FDG for this participant.');
elseif strcmp(handles.FDG1_value,'yes'),
    handles.FDG1_value = 'no'; guidata(handles.output,handles);
    disp('No baseline FDG for this participant.');
end

% Follow-up FDG checkbox
% --- Executes on button press in FDG2_yn.
function FDG2_yn_Callback(hObject, eventdata, handles)
% hObject    handle to FDG2_yn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of FDG2_yn
if strcmp(handles.FDG2_value,'no'),
    handles.FDG2_value = 'yes'; guidata(handles.output,handles);
    disp('Follow-up FDG scan for this participant.');
elseif strcmp(handles.FDG2_value,'yes'),
    handles.FDG2_value = 'no'; guidata(handles.output,handles);
    disp('No follow-up FDG for this participant.');
end

% Additional follow-up FDG checkbox
% --- Executes on button press in FDG3_yn.
function FDG3_yn_Callback(hObject, eventdata, handles)
% hObject    handle to FDG3_yn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of FDG3_yn
if strcmp(handles.FDG3_value,'no'),
    handles.FDG3_value = 'yes'; guidata(handles.output,handles);
    disp('Additional follow-up FDG for this participant.');
elseif strcmp(handles.FDG3_value,'yes'),
    handles.FDG3_value = 'no'; guidata(handles.output,handles);
    disp('No additional follow-up FDG for this participant.');
end


% --- Executes on button press in MR1_yn.
function MR1_yn_Callback(hObject, eventdata, handles)
% hObject    handle to MR1_yn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of MR1_yn
if strcmp(handles.MR1_value,'no'),
    handles.MR1_value = 'yes'; guidata(handles.output,handles);
    disp('MRI scan for this participant.');
elseif strcmp(handles.MR1_value,'yes'),
    handles.MR1_value = 'no'; guidata(handles.output,handles);
    disp('No MRI scan for this participant.');
end


% --- Executes on button press in MR2_yn.
function MR2_yn_Callback(hObject, eventdata, handles)
% hObject    handle to MR2_yn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of MR2_yn
if strcmp(handles.MR2_value,'no'),
    handles.MR2_value = 'yes'; guidata(handles.output,handles);
    disp('Follow-up MRI scan for this participant.');
elseif strcmp(handles.MR2_value,'yes'),
    handles.MR2_value = 'no'; guidata(handles.output,handles);
    disp('No follow-up MRI scan for this participant.');
end


% --- Executes on button press in Submit1.
function Submit1_Callback(hObject, eventdata, handles)
% hObject    handle to Submit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scans_available{1} = handles.FDG1_value;
scans_available{2} = handles.FDG2_value;
scans_available{3} = handles.FDG3_value;
scans_available{4} = handles.MR1_value;
scans_available{5} = handles.MR2_value;
assignin('base','scans_available',scans_available);
close(handles.sel_scans);
clear, clc;
