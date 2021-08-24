function [psf_centered] = psfadjust(psf_3d, px_sze, stp_sze)
%PSFADJUST Rescale and shift PSF
%   PSFADJUST(PSF_3D, PX_SIZE, STP_SZE) takes an input PSF and interpolates
%   to achieve isotropic pixel size. The PSF is then shifted to ensure
%   centering.

% psf_3d - as loaded PSF
% px_sze - lateral image pixel size
% stp_sze - axial step size

%px_sze and stp_sze must be specified so as to match the pixel size of the
%image to deconvolve

%Push to GPU
psf_3d = single(gpuArray(psf_3d));

%Check isotropic pixel size
if px_sze ~= stp_sze %interpolate PSF
    psf_3d = single(axial_interp(psf_3d, px_sze, stp_sze));
end

%Find center of mass
psf_size = size(psf_3d);
centre = zeros(1, ndims(psf_3d));

for iDim = 1:ndims(psf_3d)
    shp = ones(1, ndims(psf_3d));
    shp(iDim) = psf_size(iDim);
    rep = psf_size;
    rep(iDim) = 1;
    ind = repmat(reshape(1:psf_size(iDim), shp), rep);
    centre(iDim) = round(sum(ind(:).*psf_3d(:))./sum(psf_3d(:)));
end

%Shift center of mass to center of array
shift_px = floor(psf_size/2) +1 - centre; %translation in pixels
shift_xyz = [shift_px(2), shift_px(1), shift_px(3)]; %translation in xyz coordinates
psf_centered = gpuArray(imtranslate(gather(psf_3d), shift_xyz));
end

