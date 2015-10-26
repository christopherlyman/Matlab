function T2nltP(a1,a2)
% Write image of P-values (spm_nltP_?) for a T image
%
% FORMAT T2nltP
% SPM will ask you which spmT_? file you want to convert to spm_nltP_?
%
% FORMAT T2nltP(Timg,df)
% Timg  Filename of T image
% df    Degrees of freedom
%
%
% As per SPM convention, T images are zero masked, and so zeros will have
% P-value NaN.
%
% @(#)T2nltP.m  1.2 T. Nichols 03/07/15
% Modified 04/01/20 by MAM - for SPM2 compatibility

if nargin==0

     % Ask user for SPM.mat file and specific contrast
     [SPM,xSPM]=spm_getSPM;

     % If a 'T' contrast, get degrees of freedom (df) and fname of spmT_?
     if xSPM.STAT ~= 'T', error('Not a T contrast'); end
     df=xSPM.df(2);
     Tnm=xSPM.Vspm.fname;

elseif nargin==2
   Tnm = a1;
   df  = a2;
end


Tvol = spm_vol(Tnm);

Pvol        = Tvol;
Pvol.dim(4) = spm_type('float');
Pvol.fname  = strrep(Tvol.fname,'spmT','spm_nltP');
if strcmp(Pvol.fname,Tvol.fname)
   Pvol.fname = fullfile(spm_str_manip(Tvol.fname,'H'), ...
                         ['nltP' spm_str_manip(Tvol.fname,'t')]);
end


Pvol = spm_create_vol(Pvol);

for i=1:Pvol.dim(3),
   img         = spm_slice_vol(Tvol,spm_matrix([0 0 i]),Tvol.dim(1:2),0);
   img(img==0) = NaN;
   tmp         = find(isfinite(img));
   if ~isempty(tmp)
       % Create map of P values
       %img(tmp)  = (max(eps,1-spm_Tcdf(img(tmp),df)));

       % Create map of -log10(P values)
       img(tmp)  = -log10(max(eps,1-spm_Tcdf(img(tmp),df)));
   end
   Pvol        = spm_write_plane(Pvol,img,i);
end;

spm_close_vol(Pvol);
