function [deconvolved] = deconv1d(stack, psf_y, nIterations)
%DECONV1D One dimensional Richardson-Lucy single-view deconvolution.
%   DECONV1D(STACK, PSF_Y, NITERATIONS) takes images from a single angle
%   and performs deconvolution.

% stack - array containing slices orthogonal to rotation axis along first dimension
% psf_y - one-dimensional psf
% nIterations - number of deconvolution iterations

g = gpuDevice;
psf_y = gpuArray(psf_y);

%Image and PSF parameters - required for linear convolution
% [dimx, dimz, nSlices] = size(stack); %image
[nSlices, dimz, dimx] = size(stack); %image
dim_psf = size(psf_y, 1); %PSF
fft_pad = nSlices + dim_psf - 1;
crop = floor(dim_psf/2);

%Calculate OTF
otf = fft(psf_y, fft_pad, 1);
otf_flip = fft(flip(psf_y), fft_pad, 1);

%Blending mask - avoid artifacts during Fourier transform
mask = blend1d(nSlices, 10, 5); %blending length should be defined depending on the size of the PSF.

%Reshape to a 2D array for independent, parallel 1D processing
stack = gpuArray(stack);
stack = reshape(stack, [nSlices, dimx*dimz]);
[rows, cols] = size(stack); %dimensions of the reshaped array

%Divide stack in blocks for GPU processing
gpu_free = g.AvailableMemory;
gpu_required = 8*cols*(rows + 4*fft_pad); %memory required to process whole block
nBlocks = ceil(gpu_required/gpu_free);
nBlocks = pow2(ceil(log2(nBlocks))); %next power of 2

%Check number of elements per block - larger blocks slow down processing, exceeding maximum gpu thread block size
nElements = dimx*dimz*nSlices/nBlocks; 

while nElements > prod(g.MaxThreadBlockSize)
    nBlocks = pow2(log2(nBlocks)+1);
    nElements = nElements/2;
end

blockColumns = cols/nBlocks; %columns per block

%Deconvolve blocks
deconvolved = zeros(rows, cols, 'uint16', 'gpuArray');

for iBlock = 1:nBlocks
    columnFirst = 1+blockColumns*(iBlock-1);
    columnEnd = iBlock*blockColumns;
    est = single(stack(:,columnFirst:columnEnd));
    
    %Apply blending mask to input image
    est = mask.*est;
    
    %Richardson-Lucy deconvolution
    for jIteration = 1:nIterations
        hfn = linearconv1d(otf, est);
        hfn(hfn == 0) = 1;
        ratio = est./hfn;
        clear hfn
        correction = linearconv1d(otf_flip, ratio);
        clear ratio
        est = correction.*est;
        clear correction
    end
    deconvolved(:,columnFirst:columnEnd) = uint16(est);
    clear est
end

%Reshape back to original size and normalize to input image range
deconvolved = reshape(deconvolved, [nSlices, dimx, dimz]);
deconvolved = gather(deconvolved);

%1D linear convolution function in the Fourier space
    function conv = linearconv1d(otf, est)
        conv = otf.*fft(est, fft_pad, 1);
        conv = real(ifft(conv, [], 1));
        conv = conv(crop+1:nSlices+crop, :);
    end
end

