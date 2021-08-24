function [mask] = blend1d(nSlices, blendinglength, std)
%This function creates a mask for blending in the outer boundaries of image
%   It takes a 1D image of length imageLength and creates a cosine blending
%   function extended along the distance blendingLength.

%Define mask with image size according to number of slices
mask = ones(nSlices, 1, 'single', 'gpuArray');

%Define Gaussian function
gauss_x = linspace(0, blendinglength, blendinglength); %domain
gauss_y = gaussmf(gauss_x, [std 0]); %range values

%Extend to both ends
mask(1:blendinglength) = flip(gauss_y);
mask(end-blendinglength+1:end) = gauss_y;

end

