%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Features::ExtractColorHistogramFeature
%   Extracts Multi-dimensional color histogram.
%   Input -- 
%       obj          -  Feature Object
%       imageBlock   -  Image Block
%       isVectorized -  Is Vectorized Image
%       numberOfBins -  Number of histogram bins
%       imageROI     -  image region of interest
%
%   Output -- 
%       obj          -  Feature object
%
%   Author -- Santhoshkumar Sunderrajan
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = ExtractColorHistogramFeature( obj,...
                                            imageBlock,...
                                            isVectorized,...
                                            numberOfBins,...
                                            imageROI )
                                        
    assert( strcmp( obj.m_featureType, 'MULTI_DIMENSIONAL_COLOR_HISTOGRAM' ) );
    assert( nargin >= 2);

    %set the default values
    if ( nargin < 5 )
        imageROI     =  1 : sizeX * sizeY;
        imageROI     =  imageROI';
        if ( nargin < 4 )
            numberOfBins = 1; %default number of bins
            if ( nargin < 3 )
                isVectorized = 0;
            end
        end
    end

    % Get multi-dimensional 
    obj.featureVector = GetMultiDimensionalColorHistogram( imageBlock,...
                                                            isVectorized,...
                                                            numberOfBins,...
                                                            imageROI );
end