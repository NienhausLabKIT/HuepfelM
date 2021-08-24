function res = read_tiff(ImagePath)
% Aims to reads .tiff or .btf images from hard drive 
% in fastest possible way.
% Image data is kept in RAM as 2D or 3D matrix.
% ImagePath - path of the image file to be read
warning('off','all'); %suppress warinings because of field "PageNumber"

obj = Tiff(ImagePath,'r');
dimx = obj.getTag('ImageWidth');   
dimy = obj.getTag('ImageLength');  
dimz = size(imfinfo(ImagePath),1);
Image3D = zeros(dimy,dimx,dimz,'uint16');
for i = 1:dimz
   obj.setDirectory(i);
   Image3D(:,:,i) = obj.read();
end
res = Image3D;
warning('on','all');
end

