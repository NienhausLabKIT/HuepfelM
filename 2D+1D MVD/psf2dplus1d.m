function [psf2d, psf1d] = psf2dplus1d(psf_3d)
%PSF2DPLUS1D 2D and 1D PSF
%   PSF2DPLUS1D(PSF_3D) takes a tree-dimensional PSF and shifts it so that
%   the center of gravity of the PSF is located in the center of the array.
%   Then it extracts a 2D and a 1D PSF.

%Push to GPU
psf_3d = single(gpuArray(psf_3d));

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
shift_px = floor(psf_size/2) + 1 - centre; %translation in pixels
shift_xyz = [shift_px(2), shift_px(1), shift_px(3)]; %translation in xyz coordinates
psf_centered = gpuArray(imtranslate(gather(psf_3d), shift_xyz));

%Extract 2D PSF
psf2d = squeeze(psf_centered(:, :,floor(psf_size(3)/2+1)));

%Extract 1D PSF
%psf1d = squeeze(psf_centered(:, floor(psf_size(2)/2)+1, floor(psf_size(3)/2)+1));
psf1d = squeeze(psf_centered(floor(psf_size(1)/2)+1, floor(psf_size(2)/2)+1, :));
end