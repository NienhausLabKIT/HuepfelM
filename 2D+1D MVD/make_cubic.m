function res = make_cubic(image)
% Zero-padding to get a cubic volume shape.
%
% image - image data as matrix

input_size = size(image);
trgt_sze = max(input_size);

image = gpuArray(image);

result = zeros([trgt_sze trgt_sze trgt_sze],'uint16','gpuArray');
result(1:input_size(1),1:input_size(2),1:input_size(3)) = image;

clear image;

res = gather(uint16(result));
end

