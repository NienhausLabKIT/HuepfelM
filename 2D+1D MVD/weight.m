function [weights] = weight(views, method, varargin)
%WEIGHT Contribution from each view to the final fused image.
%   WEIGHT(VIEWS,METHOD,ENT_NEIG,MEDIAN,MED_NEIG) calculates the weighted
%   contribution from each view in VIEWS to the fusion process, normalised
%   to 1. If more than one slice is included, the analysis is performed
%   using a for loop.

% views - array containing views of the same slice along third dimension,
% and optionally, more slices along the fourth dimension
% method - parameter employed for the weight calculation:
%   1. 'entropy'
%   2. 'intensity'
% ent_neig - local neighbourhood for differential entropy calculation
% 'median' - determines whether median filtering will be performed
% med_neig - local neighbourhood for median filtering

% W = weight(V,'entropy',n) calculates nxn local entropy-based weight.
% W = weight(V,'intensity','median',m) calculates intensity-based weight
% and applies a median filter in a mxm neighbourhood.
% W = weight(V,'entropy',n,'median',m) calculates nxn local entropy-based
% weight and applies a median filter in a mxm neighbourhood.

nSlices = size(views, 4); %number of slices
weights = zeros(size(views), 'single', 'gpuArray');

for iSlice = 1:nSlices
    %Weighting method
    if strcmp(method, 'intensity') %intensity-based weighting
        parameter = squeeze(views(:,:,:,iSlice));
    elseif strcmp(method, 'entropy') %entropy-based weighting
        ent_neigh = varargin{1};
        parameter = diffentropy(squeeze(views(:,:,:,iSlice)));
    end

    %Calculate weight
    total = sum(parameter, 3);
    weights_view = parameter./total;
    weights_view(isnan(weights_view)) = 0;

    %Apply median filter
    if ~isempty(varargin) && (strcmp(varargin{1}, 'median') || length(varargin)>1)
        if strcmp(method, 'entropy')
            med_neigh = varargin{3};
        elseif strcmp(method, 'intensity')
            med_neigh = varargin{2};
        end
        weights_view = weights_view(:,:); %reshape for faster processing
        weights_view = medfilt2(weights_view, [med_neigh, med_neigh]);
        weights_view = reshape(weights_view, size(views, 1, 2, 3));
    end
    weights(:,:,:,iSlice) = weights_view;
end

% Local differential entropy (normal intensity distribution assumed)
    function ent = diffentropy(img)
       std_dev = single(stdfilt(img, true(ent_neigh)));
       clear img
       arg = 2*pi*exp(1)*round(std_dev.^2);
       clear std_dev
       arg(arg==0) = 1;
       ent = single(1/2*log(arg));
       clear arg
    end
end