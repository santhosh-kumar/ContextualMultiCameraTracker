%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This function sets the parameters of the DKF based on the intial state   
%                                                                               
%   Input --   
%       @I               - Input color image ( can be a vectorized image)
%       @isVectorized   -  Is the image vectorized into RGB components
%       @numberOfBins    - Number of Bins
%       @imageROI        - Region of interest
%
%   Output --
%       @multiDimensionalColorHistogram - A [numberOfBins numberOfBins
%       numberOfBins] matrix containing the histogram
%
%   Author(s) -- Vignesh Jagadeesh ( vignesh@ece.ucsb.edu ),
%             Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%             
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function multiDimensionalColorHistogram ...
                    = GetMultiDimensionalColorHistogram( I,...
                                                        isVectorized,...
                                                        numberOfBins,...
                                                        imageROI )
                                                    
    assert( nargin >= 1 );
    [ sizeX sizeY sizeC ] = size(I);
    
    %set the default values
    if ( nargin ==1 )
        isVectorized = 0;
        numberOfBins = 1; %default number of bins
        imageROI     =  1 : sizeX * sizeY;
        imageROI     =  imageROI';
    elseif ( nargin == 2 )
        numberOfBins = Features.DEFAULT_BINS_MULTI_COLOR_HIST; %default number of bins
        imageROI     =  1 : sizeX * sizeY;
        imageROI     =  imageROI';
    elseif ( nargin == 3 )
        imageROI     =  1 : sizeX * sizeY;
        imageROI     =  imageROI';
    end
    
    if ( isVectorized )
        imageROI = 1 : length(I);
        imageROI     =  imageROI';
    end
    
    if( ~isVectorized && sizeC ~= 3 )
        error('Input is not a color Image');
    end

    if( ~isempty( numberOfBins ) )
        numberOfBins = Features.DEFAULT_BINS_MULTI_COLOR_HIST; %default number of bins
    end

    if( ~isempty( imageROI ) )
        %imageROI should be a column vector
        assert( size( imageROI, 1) >= 1 && size( imageROI, 2) == 1 );
    else
        imageROI =  1 : sizeX * sizeY;
        imageROI =  imageROI';
    end

    I = double(I);            

    if (~isVectorized)
        R = I(:, :, 1); 
        G = I(:, :, 2); 
        B = I(:, :, 3);
    else
        R = I(:, 1); 
        G = I(:, 2); 
        B = I(:, 3);
    end
    
    roiPixels   = [ R(imageROI), G(imageROI), B(imageROI) ];

    %binWidth is the bin width while numberOfBins is the number of bins
    binWidth    = 256 ./ numberOfBins;
    
    %binning pixels
    h           = double( ceil( roiPixels / binWidth ) );
    h(h==0)     = 1; %change zeros to 1

    multiDimensionalColorHistogram    = zeros( numberOfBins, numberOfBins, numberOfBins );

    for rowIter = 1:size(h,1)
        multiDimensionalColorHistogram( h(rowIter,1), h(rowIter,2), h(rowIter,3) ) =...
        multiDimensionalColorHistogram( h(rowIter,1), h(rowIter,2), h(rowIter,3) ) + 1;
    end

    %Normalize to convert to a pdf
    multiDimensionalColorHistogram = multiDimensionalColorHistogram ./ sum( multiDimensionalColorHistogram(:) );
    
    multiDimensionalColorHistogram = Features.NormalizeFeatures( multiDimensionalColorHistogram,...
                                                                 [ 0 1],...
                                                                 0 );
end