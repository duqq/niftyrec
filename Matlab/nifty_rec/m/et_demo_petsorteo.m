
% ET_DEMO_PETSORTEO
%     NiftyRec Demo: Reconstruction of PET-SORTEO Monte Carlo simulation. 
%
%See also
%     ET_DEMO_SIMIND, ET_OSEM_DEMO, ET_OSEM_DEMO_2D, ET_MLEM_DEMO
%
% 
%Stefano Pedemonte
%Copyright 2009-2012 CMIC-UCL
%Gower Street, London, UK


%% Load PET-SORTEO dataset
[sinogram,scaninfo,hd]=et_load_ecat('PET_SORTEO_01_FDG.S');

%% Parameters
N_cameras = 144; 
theta_first = 0.0;   %degrees
theta_last  = 178.5; %degrees
sino_X = 288;
sino_Y = 63;
X = 192; 
Y = 64; 
N_iter_osem = 50; 
subset_order = 8; 
attenuation = 0; 
GPU = 1; 

%% Reshape sinogram, define geometry, PSF
sinogram_reshaped = zeros(X,Y,N_cameras); 
for i=1:N_cameras
    sinogram_reshaped(:,1:sino_Y,i) = sinogram(i,(sino_X-X)/2+1:sino_X-(sino_X-X)/2,:);
end

cameras = zeros(N_projections,3);
cameras(:,2) = linspace(theta_first,theta_first+theta_last-theta_last/N_projections,N_projections)*pi/180.0;

psf= fspecial('gaussian',7,1.5);
PSF = ones(7,7,X);
for i=1:X
PSF(:,:,i)=psf;
end

%% Reconstruct - OSEM
activity = ones(X,Y,X); 
for iter = 1:N_iter_osem
    fprintf('OSEM iter %d / %d (subset order %d) \n',iter,N_iter_osem,subset_order);
    activity = et_osmapem_step(subset_order, activity, sinogram_reshaped, cameras, attenuation, PSF, 0, 0, GPU, 0, 0.0001);
    a = reshape(activity(:,Y/2,:),X,X);
    b = flipud(reshape(activity(X/2,:,:),Y,X));
    c = flipud(reshape(activity(:,:,X/2),X,Y)');
    d = [a;b;zeros(20,X);c;zeros(20,X)];    
    imagesc(d); axis tight equal off; colormap gray; pause(0.1); 
end



