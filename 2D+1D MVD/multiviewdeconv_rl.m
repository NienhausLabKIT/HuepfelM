function [deconvolved] = multiviewdeconv_rl(imageStruct, psf_views, nIterations, deconvMethod, varargin)
%MULTIVIEWDECONV_RL Two dimensional Richardson-Lucy multi-view
%deconvolution.
%   MULTIVIEWDECONV_RL(IMAGESTRUCT, PSF_VIEWS, NITERATIONS, DECONVMETHOD, WEIGHTMETHOD,
%   ENT_NEIG, MEDIAN, MED_NEIG) takes images from different angles in a
%   multiview measurement and performs multiview deconvolution.

% imageStruct - struct containing different views, each one in a separate
% stack within the field image(i).data
% psf_views - PSF views taken from each one of the measurement angles
% nIterations - number of deconvolution iterations
% deconvMethod - optimisation for multiview deconvolution, more information
% can be found in the documentation of the function psfprocess
%   1. 'independent'
%   2. 'opt1'
%   3. 'opt2'
% weightmethod - more information can be found in the documentation of the
% function weight
%   1. 'entropy'
%   2. 'intensity'
% ent_neig - entropy neighbourhood
% 'median' - median filter
% med_neig - median filter neighbourhood

g = gpuDevice;
psf_views = gpuArray(psf_views);

%Image and PSF parameters - required for linear convolution
nViews = length(imageStruct);
[nSlices, dimx, dimz] = size(imageStruct(1).data); %image
dim_psf = size(psf_views, 1, 2); %PSF
fft_pad = [dimx+dim_psf(1), dimz+dim_psf(2)]-1;
crop = floor(dim_psf/2);

%Calculate OTFs
[otf, otf_comp] = psfprocess(psf_views, dimx, dimz, deconvMethod);

%Binary mask - blending mask and boundary weight correction
bin_mask = zeros(dimx, dimz, nViews, 'gpuArray');
for iView = 1:nViews
    bin_mask(:,:,iView) = binmask(imageStruct(iView).data); %field of view of each angle
end

bin_mask_est = any(bin_mask, 3); %combined fields of view

%Gaussian profile
bin_mask = imgaussfilt(single(bin_mask), 20, 'Padding', 0);
bin_mask_est = imgaussfilt(single(bin_mask_est), 20, 'Padding', 0);

%Divide stack in blocks for GPU parallel processing
gpu_free = g.AvailableMemory;
gpu_required = 4*nSlices*(2*dimx*dimz*nViews + 4*dimx*dimz + 4*fft_pad(1)*fft_pad(2)); %memory required to process whole block
nBlocks = ceil(gpu_required/gpu_free);
nBlocks = pow2(ceil(log2(nBlocks))); %next power of 2
blockSlices = nSlices/nBlocks; %slices per block

%Check number of elements per block - avoid exceeding maximum gpu thread block size
nElements = dimx*dimz*nViews*blockSlices;
while  nElements > prod(g.MaxThreadBlockSize) 
    nBlocks = pow2(log2(nBlocks)+1);
    blockSlices = nSlices/nBlocks;
    nElements = dimx*dimz*nViews*blockSlices;
end

%Deconvolve blocks
deconvolved = zeros(dimx, dimz, nSlices, 'uint16', 'gpuArray');
for iBlock = 1:nBlocks
    block = zeros(dimx, dimz, nViews, blockSlices, 'single','gpuArray');
    sliceFirst = 1+blockSlices*(iBlock-1); %first slice of the block
    sliceEnd = iBlock*blockSlices; %last slice of the block
    for iView = 1:nViews
        block(:,:,iView,:) = single(permute(gpuArray(imageStruct(iView).data(sliceFirst:sliceEnd,:,:)), [2,3,1]));
    end
    
    %Apply blending mask to input images
    block = block.*bin_mask;

    %Weight calculation
    weights = bin_mask.*weight(block, varargin{:});
    
    %Estimation of fused image
    est = bin_mask_est.*squeeze(mean(block, 3));
    
    
    %Bayesian-based deconvolution
    for jIteration = 1:nIterations
        for kView = 1:nViews
            hfn = real(linearconv2d(otf(:, :, kView), est));
            hfn(hfn == 0) = 1;
            ratio = squeeze(block(:, :, kView, :))./hfn;
            clear hfn
            correction = linearconv2d(otf_comp(:, :, kView), ratio);
            clear ratio
            est = real(correction.^squeeze(weights(:, :, kView,:))).*est;
            clear correction
        end
    end
    clear weights
    clear block
    deconvolved(:,:,sliceFirst:sliceEnd) = uint16(est);
    clear est
end

%Permute back to match input view
deconvolved = ipermute(deconvolved,[2,3,1]);
deconvolved = gather(deconvolved);

%2D linear convolution function in the Fourier space
    function conv = linearconv2d(otf, est)
        conv = otf.*fft2(est, fft_pad(1), fft_pad(2));
        conv = ifft2(conv);
        conv = conv(crop(1)+1:dimx+crop(1), crop(2)+1:dimz+crop(2),:);        
    end
end
