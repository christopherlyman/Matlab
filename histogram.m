% 	V      = spm_vol(spm_get(1,'*.img','Select image...'));
	V      = spm_vol(spm_get(1,'*','Select image...'));
	[n, x] = histvol(V, 100);
	figure;
	bar(x,n);