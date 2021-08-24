function [otf,otf_comp] = psfprocess(psf_views, dimx, dimz, method)
%PSFPROCESS 2D Optical transfer functions for multiview deconvolution
%   PSFPROCESS(PSF_VIEWS,DIMX,DIMY,METHOD) calculates the
%   OTF and compound OTF corresponding to each one of the views, depending
%   on the optimisation method.

% psf_views - array containing 2D psfs corresponding to each view
% dimx - length of image to deconvolve along rows
% dimy - length of image to deconvolve along columns
% method - optimisation for multiview deconvolution:
%   1. 'independent' - independent views are assumed
%   2. 'opt1' - Bayesian dependence and first ad hoc simplification
%   2. 'opt2' - Bayesian dependence, additional ad hoc simplifications

% psf_views must be normalised to 1.

%Push to GPU
psf_views = gpuArray(psf_views);

%PSF and padding parameters
[dimx_psf, dimz_psf, nViews] = size(psf_views);
fft_padx = dimx+dimx_psf-1; %length of convolved array along x dimension
fft_padz = dimz+dimz_psf-1; %length of convolved array along x dimension

%Basic PSF processing
psf_flipped = zeros(dimx_psf, dimz_psf, nViews, 'single', 'gpuArray');
otf = zeros(fft_padx, fft_padz, nViews, 'single', 'gpuArray');
for iView = 1:nViews
    psf_flipped(:,:,iView) = flip(flip(psf_views(:,:,iView), 1), 2);
    otf(:,:,iView) = fft2(psf_views(:,:,iView), fft_padx, fft_padz);
end

%Optimisation selection
otf_comp = zeros(fft_padx, fft_padz, nViews, 'single', 'gpuArray');
if strcmp(method, 'independent') %independent PSFs
    for iView = 1:nViews
        otf_comp(:,:,iView) = fft2(psf_flipped(:,:,iView), fft_padx, fft_padz);
    end
elseif strcmp(method, 'opt1') %bayesian dependence - optimisation II
    conv_intermediate = zeros(dimx_psf, dimz_psf, nViews, 'single', 'gpuArray');
    for iView = 1:nViews
        for jView = 1:nViews
            conv_intermediate(:,:,jView) = conv2(psf_flipped(:,:,iView),psf_views(:,:,jView), 'same');
        end
        conv_intermediate(:,:,iView) = [];
        comp_kernel_real = psf_flipped(:,:,iView).*prod(conv_intermediate,3);
        otf_comp(:,:,iView) = fft2(comp_kernel_real, fft_padx, fft_padz);
    end
elseif strcmp(method, 'opt2') %bayesian dependence - optimisation II
    for iView = 1:nViews
        otf_comp(:,:,iView) = fft2((psf_flipped(:,:,iView).^(nViews-1)), fft_padx, fft_padz);
    end
end
end
