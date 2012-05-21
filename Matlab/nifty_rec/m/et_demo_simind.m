
% ET_DEMO_SIMIND
%     NiftyRec Demo: Reconstruction of SIMIND Monte Carlo simulation. 
%
%See also
%     ET_DEMO_PETSORTEO, ET_SIMIND_SIMULATE, ET_OSEM_DEMO, ET_OSEM_DEMO_2D, ET_MLEM_DEMO
%
% 
%Stefano Pedemonte
%Copyright 2009-2012 CMIC-UCL
%Gower Street, London, UK


%% Load SIMIND dataset
N_projections = 120; 
X = 128; 
Y = 128;
theta_first = 0.0;   
theta_last  = 2*pi; 
sinogram = et_load_simind('SIMIND_01_PERFUSION.a00',X,Y,N_projections);

%% Parameters 
N_iter_osem = 50; 
subset_order = 8; 
attenuation = 0; 
USE_GPU = 1; 

cameras = zeros(N_projections,3);
cameras(:,1) = linspace(theta_first,theta_last,N_projections);

psf= fspecial('gaussian',5,1.5);
PSF = ones(5,5,X);
for i=1:X
PSF(:,:,i)=psf;
end

%% Reconstruct - OSEM
activity = ones(X,Y,X); 
for iter = 1:N_iter_osem
    fprintf('OSEM iter %d / %d (subset order %d) \n',iter,N_iter_osem,subset_order);
    activity = et_osmapem_step(subset_order, activity, sinogram, cameras, attenuation, PSF, 0, 0, USE_GPU, 0, 0.0001);
    subplot(1,3,1); imagesc(reshape(activity(X/2,:,:),Y,X)); axis tight equal off; colormap gray; 
    subplot(1,3,2); imagesc(reshape(activity(:,Y/2,:),X,X)); axis tight equal off; colormap gray; 
    subplot(1,3,3); imagesc(reshape(activity(:,:,X/2),X,Y)); axis tight equal off; colormap gray; pause(0.1);
end



