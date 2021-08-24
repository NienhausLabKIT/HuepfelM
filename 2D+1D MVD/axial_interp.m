function res = axial_interp(image, px_sze, stp_sze)
% Interpolates in z-direction to achieve isotropic pixel size.
% 
% GPU processing is used.
% "imresize3" does not support GPU processing.
% "imresize" is used in 2D instead.
%
% The function imresize uses bicubic interpolation on GPU
% The output pixel value is a weighted average of pixels
% in the nearest 4-by-4 neighborhood. Bicubic interpolation 
% is the default method for numeric and logical images.
%
% image - image data as matrix
% px_sze - lateral image pixel size
% stp_sze - axial step size

z_scale_factor = stp_sze/px_sze;

%interpolate
image = single(gpuArray(image));
img_size = size(image);
out = zeros([img_size(1) img_size(2) round(z_scale_factor*img_size(3))],'single','gpuArray');

for q = 1:img_size(1)
out(q,:,:) = imresize(squeeze(image(q,:,:)), [img_size(2) round(z_scale_factor*img_size(3))]);
end

res = gather(uint16(out));
end

