function [activity_new, update] = et_mapem_step(activity_old, normalization, sinogram, cameras, attenuation, psf, beta, gradient_prior, GPU, background, background_attenuation, epsilon)
%ET_MAPEM_STEP
%    Step of Maximum A Posteriori iterative reconstsruction algorithm for Emission Tomography
%
%Description
%    This function computes an estimate of the activity, given the previous estimate and the gradient 
%    of the prior distribution.
%
%    [NEW_ACTIVITY, UPDATE] = ET_MAPEM_STEP(ACTIVITY, NORM, SINO, CAMERAS, PSF, BETA, GRAD_PRIOR, USE_GPU, BACKGROUND, EPSILON)
%
%    ATIVITY is a 2D or 3D matrix of activity, typically estimated in the previous MAPEM step
%
%    NORM specifies a normalization volume, See examples.
%
%    SINO is a 2D or 3D sinogram.
%
%    CAMERAS specifies camera positions and it can be expressed in two forms: 
%    a matrix of size [n,3] representing angular position of each camera 
%    with respect of x,y,z axis; or a column vector of length n where for each 
%    camera, only rotation along z axis is specified. This is the most common 
%    situation in PET and SPECT where the gantry rotates along a single axis.
%
%    ATTENUATION is the attenuation map (adimensional). Refer to the programming manual. 
%    If it's set to a scalar then attenuation is not applied (faster).
%
%    PSF is a Depth-Dependent Point Spread Function.
%
%    BETA parameter for sensitivity of the prior term
%
%    GRAD_PRIOR gradient of the prior probability distribution
%
%    USE_GPU is optional and it enables GPU acceleration if a compatible GPU 
%    device is installed in the system. By default use_gpu is set to 0 (disabled).
%
%    BACKGROUND is the value the background is set to when performing rotation.
%    It defaults to 0.
%
%    BACKGROUND_ATTENUATION is the value the attenuation background is set to when performing rotation.
%    It defaults to 0.
%
%    EPSILON is a small value that is added to the projection in order to avoid division by zero.
%
%GPU acceleration
%    If a CUDA compatible Grahpics Processing Unit (GPU) is installed, 
%    the projection algorithm can take advantage of it. Set use_gpu parameter
%    to 1 to enable GPU acceleration. If GPU acceleration is not available, 
%    the value of the parameter is uninfluential.
%
%Algorithm notes
%    Rotation based projection algorithm with trilinear interpolation.
%    Depth-Dependent Point Spread Function is applyed in the frequency domain.
%
%Reference
%    Pedemonte, Bousse, Erlandsson, Modat, Arridge, Hutton, Ourselin, 
%    "GPU Accelerated Rotation-Based Emission Tomography Reconstruction", NSS/MIC 2010
%
%Example
%   N = 128;
%   n_cameras = 120;
%   mlem_steps = 100;
%   USE_GPU = 1;
%   phantom = et_spherical_phantom(N,N,N,N/8,100,0);
%   cameras = [0:2*pi/n_cameras:2*pi-2*pi/n_cameras];
%   sinogram = poissrnd(et_project(phantom,cameras,psf,USE_GPU));
%   norm = et_backproject(ones(N,N,n_cameras));
%   activity = ones(N,N,N);  %initial activity
%   for i=1:mlem_steps
%       activity = et_mapem_step(activity, norm, sinogram, cameras, 0, 0, 0, 0, 0, USE_GPU);
%   end
%
%See also
%   ET_PROJECT, ET_BACKPROJECT
%
% 
%Stefano Pedemonte
%Copyright 2009-2010 CMIC-UCL
%Gower Street, London, UK

if not(exist('beta','var'))
    beta = 0;
end
if not(exist('gradient_prior','var'))
    gradient_prior = 0;
end
if not(exist('GPU','var'))
    GPU = 0;
end
if not(exist('background','var'))
    background = 0;
end
if not(exist('background_attenuation','var'))
    background_attenuation = 0;
end
if not(exist('espilon','var'))
    epsilon = 0.000001;
end
if not(exist('psf','var'))
    psf = 0;
end
if not(exist('attenuation','var'))
    attenuation = 0;
end

proj = et_project(activity_old, cameras, attenuation, psf, GPU, background, background_attenuation);
proj = proj.*(proj>0) + epsilon ;
update = et_backproject(sinogram ./ proj, cameras, attenuation, psf, GPU, background, background_attenuation);
update = update.*(update>0);
activity_new = activity_old .* update;
activity_new = activity_new ./ (normalization - beta * gradient_prior);

return 