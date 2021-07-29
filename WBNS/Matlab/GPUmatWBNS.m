function clrImg = GPUmatWBNS(Img, psfw, nlvl)

% This implementation of WBNS in MATLAB uses gpuArrays to speed up the algorithm
% psfw - PSF width in pixels
% nlvl - level of DWT decomposition for noise subtraction 

blvl = ceil(log2(psfw)); % level of DWT decomposition for background subtraction 
sigma = pow2(blvl);
Img = single(Img);

clrImg = Img; %cleared image initialization

for f_idx = 1:size(Img,3)
    
    % background estimation
    if (blvl > 0)
        [a,h,v,d] = haart2(gpuArray(Img(:,:,f_idx)),blvl);

        h{1,1} = zeros(size(h{1,1}),'gpuArray');
        h{1,2} = zeros(size(h{1,2}),'gpuArray');
        h{1,3} = zeros(size(h{1,3}),'gpuArray');
        
        v{1,1} = zeros(size(v{1,1}),'gpuArray');
        v{1,2} = zeros(size(v{1,2}),'gpuArray');
        v{1,3} = zeros(size(v{1,3}),'gpuArray');
        
        d{1,1} = zeros(size(d{1,1}),'gpuArray');
        d{1,2} = zeros(size(d{1,2}),'gpuArray');
        d{1,3} = zeros(size(d{1,3}),'gpuArray');

        bkgImg = ihaart2(a,h,v,d);
        bkgImg = imgaussfilt(bkgImg,sigma);
        bkgImg(bkgImg < 0) = 0;
    end
    
    % noise estimation
    if (nlvl > 0)

        [a,h,v,d] = haart2(gpuArray(Img(:,:,f_idx)),nlvl);
        a = ones(size(a),'gpuArray');
        nseImg = ihaart2(a,h,v,d);

        nseImg(nseImg < 0) = 0;
		nseImg(nseImg > (mean(mean(nseImg)) + 2*std(std(nseImg))) ) = (mean(mean(nseImg)) + 2*std(std(nseImg)));
    end

    clrImg(:,:,f_idx) = gather(Img(:,:,f_idx) - bkgImg - nseImg);
end

clrImg(clrImg < 0) = 0;
