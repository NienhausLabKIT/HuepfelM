function [psf_views] = psf2d(psf_centered, varargin)
%PSF2D 2D PSF for different views
%   PSF2D(PSF_CENTERED, NVIEWS, REF_ANGLE) takes an interpolated and
%   centered 3D PSF or set of PSFs. If only one PSF is passed, it selects the
%   middle slice and rotates it to derive the PSF from all the views. If a
%   4D array is passed, with different PSFs along the 4th dimension, the
%   middle slice from each PSF is extracted.

% psf_centered - three-dimensional psf or psfs. Preprocessing
% must have ben applied so that it matches image pixel size
% nViews - number of measured angles 
% ref_angle - angle of the view employed as a reference for registration


%Zero-pad to cube
psf_centered = make_cubic(psf_centered);
psf_centered = psfadjust(psf_centered, 1, 1);
%Push to GPU
psf_centered = gpuArray(psf_centered);

%PSF parameters
[dimy_psf, dimx_psf, dimz_psf, npsf] = size(psf_centered);

%Select middle slice
mid = floor(dimy_psf/2)+1;

if npsf == 1 %only one PSF is measured
    %Normalise middle slice
    mid_slc = rescale(squeeze(psf_centered(mid,:,:)));
    
    %Rotate middle slice to extract different views
    psf_views = zeros(dimx_psf, dimz_psf, varargin{1}, 'single', 'gpuArray');
    for iView = 1:varargin{1}
        psf_views(:,:,iView) = imrotate(mid_slc, -varargin{2}+360/varargin{1}*(iView-1), 'bilinear', 'crop');
    end
    
elseif npsf > 1 %one PSF per view is measured
    psf_views = zeros(dimx_psf, dimz_psf, npsf, 'single', 'gpuArray');
    for iView = 1:npsf
        psf_views(:,:,iView) = rescale(squeeze(psf_centered(mid,:,:,iView)));
    end
end
end

