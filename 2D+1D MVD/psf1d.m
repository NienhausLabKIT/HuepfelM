function [psf_y] = psf1d(psf_centered)
%PSF1D 1D PSF
%   PSF1D(PSF_CENTERED) takes an interpolated and centered PSF or set of
%   PSFs. If only one PSF is passed, it selects the central column and
%   extracts the PSF along Y. If a 4D array is passed, with different PSFs
%   along the 4th dimension, the central column from each PSF is extracted
%   and the mean returned.

% psf_centered - threedimensional, resliced psf or psfs. Preprocessing must
% have been applied so that it matches image pixel size

%Push to GPU
psf_centered = single(gpuArray(psf_centered));

%PSF parameters
[dimy_psf, dimx_psf, dimz_psf, npsf] = size(psf_centered);
ndim_psf = ndims(psf_centered);

%Select middle point
mid = [floor(dimx_psf/2)+1, floor(dimz_psf/2)+1];

if ndim_psf == 3 %only one PSF is measured
    %Extract and normalise 1D PSF along Y
    psf_y = rescale(squeeze(psf_centered(:, mid(1), mid(2))));
    
elseif ndim_psf == 4 %one PSF per view is measured
    psf_y = zeros(dimy_psf, 1, npsf, 'single', 'gpuArray');
    for iView = 1:npsf
        psf_y(:,:,iView) = rescale(psf_centered(:,mid(1),mid(2),iView));
    end
    psf_y = mean(psf_y, 3);
end
end

