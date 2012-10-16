
% ET_DEMO_OSEM_2D
%     NiftyRec Demo: Ordered Subsets Expectation Maximisation (OSEM) SPECT
%     reconstruction - 2D.
%
%See also
%   ET_DEMO_MLEM, ET_DEMO_MAPEM_MRF, ET_OSMAPEM_STEP
%
% 
%Stefano Pedemonte
%Copyright 2009-2012 CMIC-UCL
%Gower Street, London, UK


%% Parameters
N          = 128;
N_cameras  = 120;
cameras = zeros(N_cameras,3);
cameras(:,2)=(pi/180)*(0:180/N_cameras:180-180/N_cameras);
psf        = ones(5,5,N);
N_counts   = 150e6/128;

iter_osem    = 100;
subset_order = 8;
GPU          = 0;

%% Simulate SPECT scan 
disp('Creating synthetic sinogram..');
mask = et_spherical_phantom(N,N,N,N*0.45,1,0,(N+1)/2,(N+1)/2,(N+1)/2);
phantom = mask .* (et_spherical_phantom(N,N,N,N/8,30,5,N/2,N/2,N/4)+ ...
                   et_spherical_phantom(N,N,N,N/12,20,5,N/2,N/2,1.1*3*N/4)+ ...
                   et_spherical_phantom(N,N,N,N/10,40,5,N/2,N/2,1.1*N/2) ) ;
phantom = phantom(:,N/2,:);
attenuation = 0;
ideal_sinogram = et_project(phantom, cameras, attenuation, psf, GPU);
ideal_sinogram = ideal_sinogram/sum(ideal_sinogram(:))*N_counts;
sinogram = et_poissrnd(ideal_sinogram);


%% Reconstruction:

disp('Reconstructing..');
activity = ones(N,1,N);
for i=1:iter_osem
    fprintf('\nMLEM step: %d',i);
    activity = et_osmapem_step(subset_order, activity, sinogram, cameras, attenuation, psf, 0, 0, GPU, 0, 0.0001);
    imagesc(squeeze(activity(:,1,:))); colormap gray; axis square; pause(0.2)
end
disp('Done');

if GPU
    et_reset_gpu();
end

