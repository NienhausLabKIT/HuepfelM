function [deconvolved1d] = simpldeconv(stack, psf_xz, psf_y, nIterations_xz, nIterations_y)
%SIMPLDECONV 2D + 1D Richardson-Lucy single-view deconvolution.
%   SIMPLEDECONV1D(STACK, PSF_XZ, PSF_Y, NITERATIONS_XZ, NITERATIONS_Y)
%   takes images from a inslge angle and approximates the 3D deconvolution
%   by succesive 2D and 1D deconvolutions.

% stack - array containing different slices along third dimension
% psf_xz - two-dimensional psf
% psf_y - one-dimensional psf
% nIterations_xz - number of 2D deconvolution iterations
% nIterations_y - number of 1D deconvolution iterations

g = gpuDevice;
psf_xz = gpuArray(psf_xz);
psf_y = gpuArray(psf_y);

%Image and PSF parameters - required for linear convolution
[dimx, dimy, nSlices] = size(stack); %image
dim_psf = [size(psf_xz), size(psf_y,1)]; %psf
fft_pad = [dimx+dim_psf(1), dimy+dim_psf(2), nSlices+dim_psf(3)]-1;
crop = floor(dim_psf/2);

%Calculate OTFs
otf_xz = fft2(psf_xz, fft_pad(1), fft_pad(2));
otf_xz_flip = fft2(flip(flip(psf_xz, 1), 2), fft_pad(1), fft_pad(2));
otf_y = fft(psf_y, fft_pad(3), 1);
otf_y_flip = fft(flip(psf_y), fft_pad(3), 1);

%Blending masks - avoid artifacts during Fourier transform
mask2d = blend2d(dimx, dimy, 10, 5); %blending length should be defined depending on the size of the PSF.
mask1d = blend1d(nSlices, 10, 5); %blending length should be defined depending on the size of the PSF.

%% 2D deconvolution
%Divide stack in blocks for GPU parallel processing
gpu_free = g.AvailableMemory;
gpu_required = 16*nSlices*(dimx*dimy + 2*fft_pad(1)*fft_pad(2)); %memory required to process whole block
nBlocks = ceil(gpu_required/gpu_free);
nBlocks = pow2(ceil(log2(nBlocks))); %next power of 2
blockSlices = nSlices/nBlocks; %slices per block

%Deconvolve blocks
deconvolved2d = zeros(dimx, dimy, nSlices, 'single');
for iBlock = 1:nBlocks
    sliceFirst = 1+blockSlices*(iBlock-1); %first slice of the block
    sliceEnd = iBlock*blockSlices; %last slice of the block
    est = single(gpuArray(stack(:,:,sliceFirst:sliceEnd)));
    
    %Apply blending mask to input image
    est = mask2d.*est;
    
    %Richardson-Lucy deconvolution
    for jIteration = 1:nIterations_xz
        hfn = linearconv2d(otf_xz, est);
        hfn(hfn == 0) = 1;
        ratio = est./hfn;
        clear hfn
        correction = linearconv2d(otf_xz_flip, ratio);
        clear ratio
        est = correction.*est;
        clear correction
    end
    deconvolved2d(:, :, sliceFirst:sliceEnd) = gather(est);
    clear est
end

%% 1D deconvolution
if nIterations_y ~= 0
    %Reshape to a 2D array for independent, parallel 1D processing
    deconvolved2d = gpuArray(deconvolved2d);
    deconvolved2d = permute(deconvolved2d, [3, 1, 2]);
    deconvolved2d = reshape(deconvolved2d, nSlices, dimx*dimy);
    [rows, cols] = size(deconvolved2d); %dimensions of the reshaped array
    deconvolved2d = gather(deconvolved2d);

    %Divide stack in blocks for GPU parallel processing
    gpu_free = g.AvailableMemory;
    gpu_required = 8*cols*(rows + 4*fft_pad(3)); %memory required to process whole block
    nBlocks = ceil(gpu_required/gpu_free);
    nBlocks = pow2(ceil(log2(nBlocks))); %next power of 2
    blockColumns = cols/nBlocks; %columns per block

    %Deconvolve blocks
    deconvolved1d = zeros(rows, cols, 'single','gpuArray');

    for iBlock = 1:nBlocks
        columnFirst = 1+blockColumns*(iBlock-1);
        columnEnd = iBlock*blockColumns;
        est = single(gpuArray(deconvolved2d(:,columnFirst:columnEnd)));

        %Apply blending mask to input image
        est = mask1d.*est;

        %Richardson-Lucy deconvolution
        for jIteration = 1:nIterations_y
            hfn = linearconv1d(otf_y, est);
            hfn(hfn == 0) = 1;
            ratio = est./hfn;
            clear hfn
            correction = linearconv1d(otf_y_flip, ratio);
            clear ratio
            est = correction.*est;
            clear correction
        end
        deconvolved1d(:,columnFirst:columnEnd) = est;
        clear est
    end
    clear deconvolved2d


    %Reshape back to original size and normalize to input image range
    %deconvolved1d = gpuArray(deconvolved1d);
    deconvolved1d = uint16(rescale(deconvolved1d, 0, max(stack(:))));
    deconvolved1d = reshape(deconvolved1d, [nSlices, dimx, dimy]);
    deconvolved1d = ipermute(deconvolved1d, [3, 1, 2]);
    deconvolved1d = gather(deconvolved1d);
    
else
   deconvolved1d = deconvolved2d;
   deconvolved1d = uint16(rescale(deconvolved1d, 0, max(stack(:))));
end
%2D linear convolution function in the Fourier space
    function conv = linearconv2d(otf, est)
        conv = otf.*fft2(est, fft_pad(1), fft_pad(2));
        conv = real(ifft2(conv));
        conv = conv(crop(1)+1:dimx+crop(1), crop(2)+1:dimy+crop(2),:);
    end

%1D linear convolution function in the Fourier space
    function conv = linearconv1d(otf, est)
        conv = otf.*fft(est, fft_pad(3), 1);
        conv = real(ifft(conv, [], 1));
        conv = conv(crop(3)+1:nSlices+crop(3), :);
    end    
end