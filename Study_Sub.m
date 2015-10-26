function varargout = Study_Sub(varargin)
% STUDY_SUB M-file for Study_Sub.fig
%      STUDY_SUB, by itself, creates a new Study_Sub or raises the existing
%      singleton*.
%
%      H = STUDY_SUB returns the handle to a new Study_Sub or the handle to
%      the existing singleton*.
%
%      STUDY_SUB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in Study_Sub.M with the given input arguments.
%
%      STUDY_SUB('Property','Value',...) creates a new Study_Sub or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Study_Sub_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Study_Sub_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Study_Sub

% Last Modified by GUIDE v2.5 21-Oct-2013 17:39:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Study_Sub_OpeningFcn, ...
                   'gui_OutputFcn',  @Study_Sub_OutputFcn, ...
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



% --- Executes just before Study_Sub is made visible.
function Study_Sub_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Study_Sub (see VARARGIN)

% Choose default command line output for Study_Sub
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
[pth] = fileparts(which('vwi'));
studies = [pth '\Studies\Studies.txt'];
fid_r = fopen(studies, 'r');
S = textscan(fid_r, '%s');
set(handles.StudyMenuObject,'String', S{1});

% UIWAIT makes Study_Sub wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Study_Sub_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.StudyMenuObject;



% --- Executes on button press in new_study_pushbutton.
function new_study_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to new_study_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
vwi_new_study;
guidata(hObject, handles);
[pth] = fileparts(which('vwi'));
studies = [pth '\Studies\Studies.txt'];
fid_r = fopen(studies, 'r');
S = textscan(fid_r, '%s');
set(handles.StudyMenuObject,'String', S{1});

% --- Executes on button press in new_study_pushbutton.
function DelStudpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to new_study_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
vwi_delete_study;
guidata(hObject, handles);
[pth] = fileparts(which('vwi'));
studies = [pth '\Studies\Studies.txt'];
fid_r = fopen(studies, 'r');
S = textscan(fid_r, '%s');
set(handles.StudyMenuObject,'String', S{1});

% --- Executes on selection change in Study_popupmenu.
function Study_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to Study_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns Study_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Study_popupmenu
val = get(hObject,'Value');
[pth] = fileparts(which('vwi'));
studies = [pth '\Studies\Studies.txt'];
fid_r = fopen(studies, 'r');
D = textscan(fid_r, '%s');
study = D{1}(val);
study = study{1};
assignin('base','study',study);



% --- Executes during object creation, after setting all properties.
function Study_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Study_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.StudyMenuObject=hObject;
guidata(hObject, handles);


function Sub_num_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Sub_num_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Sub_num_edit as text
%        str2double(get(hObject,'String')) returns contents of Sub_num_edit as a double
str = get(handles.Sub_num_edit,'String');
assignin('base','sub',str);


% --- Executes during object creation, after setting all properties.
function Sub_num_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Sub_num_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in submit_pushbutton.
function submit_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to submit_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close all;