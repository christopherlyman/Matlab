function xls2csv()
%   Converts all .xls files in processing directory to .csv format
%%
clear global;
clear classes;
[pth] = fileparts(which('vwi'));
home_dir = char(textread([pth '\home_dir.txt'],'%s'));

proc_dir = uigetdir(home_dir,'Select folder containg .xls files you wish to convert to .csv:');

excelfiles = dir([proc_dir,'\*.xls']);

for ii=1:1:size(excelfiles,1),
    [~,name,ext] = fileparts([proc_dir '\' excelfiles(ii,1).name]);
    xlsfile = xlsread([proc_dir '\' excelfiles(ii,1).name]);
    csvwrite([proc_dir '\' name '.csv'],xlsfile);
    clear name ext xlsfile
end
