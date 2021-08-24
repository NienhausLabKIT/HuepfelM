function [bin_mask] = binmask(stack)
%BINMASK Field of view of each acquisition angle after registration
%   BINMASK(STACK) calculates a binary mask containing ones in the region
%   depicting the field of view of each measurement angle and zeros where
%   the image has been zero-padded for registration.

% stack - the input image should be a 3D slice with its third dimension
% along the z axis of the camera coordinate system.

%This mask must be applied to the weights to avoid regions that are not
%part of the field of view of all angles from being neglected.

%Maximum intensity projection of all slices belonging to one view
mip = squeeze(max(stack, [], 1));
mip(mip~=0) = 1;

%Closing operation (fill in gaps)
se = strel('disk', 10);
bin_mask = imclose(logical(mip), se);
se = strel('disk', 30);
bin_mask = imerode(bin_mask, se);
end

