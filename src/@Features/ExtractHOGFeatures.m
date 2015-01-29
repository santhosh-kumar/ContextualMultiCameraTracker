%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Features::ExtractHOGFeatures
%
%   Extracts HOG Feature
%
%   Input -- 
%       obj                                   -  Feature Object
%       inputImage                            -  Input Image
%       roiMask                               -  region of interest mask
%       shouldConcatenateWithExistingFeatures -  Should concatenate features or not
%
%   Output -- 
%       obj                                   - Feature Object
%
%   Author -- Santhoshkumar Sunderrajan
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = ExtractHOGFeatures(  obj,...
                                    inputImage,...
                                    roiMask,...
                                    shouldConcatenateWithExistingFeatures )
    assert(  strcmp( obj.m_featureType, 'HOG' ) ||   strcmp( obj.m_featureType, 'HOG_AND_COLOR' ) );

    assert( nargin >= 3 );
    assert( size( inputImage, 3 ) == 3 );
    assert( ~isempty(inputImage) );
    
    grayInput = double( rgb2gray( inputImage ) );

    [ numberOfRows, numberOfColumns, ~ ] = size( inputImage );

    spatialBinSize      = Features.HOG_SPATIAL_BIN_SIZE;
    orientationBinSize  = Features.HOG_ORIENTAITON_BIN_SIZE;

    % compute HOG
    if Features.SHOULD_USE_FAST_HOG
        H = fhog(single(grayInput), spatialBinSize, orientationBinSize );
    else
        H = hog(single(grayInput), spatialBinSize, orientationBinSize );
    end
    no_channels = size( H, 3);
    sr = spatialBinSize+1; er = numberOfRows - mod( numberOfRows, spatialBinSize ) - spatialBinSize;
    sc = spatialBinSize+1; ec = numberOfColumns - mod(numberOfColumns, spatialBinSize) - spatialBinSize;
    for slice_iter = 1 : no_channels
        temp_hog =  padarray( imresize( H( :, :, slice_iter ), [er-sr+1 ec-sc+1], 'cubic' ), [spatialBinSize spatialBinSize] ,'replicate', 'pre');
        hog_full( :,:,slice_iter) =  padarray( temp_hog, [mod(numberOfRows, spatialBinSize)+spatialBinSize mod(numberOfColumns, spatialBinSize)+spatialBinSize] ,'replicate', 'post');       
    end
    hog_full(hog_full<0) = 0;
    stack_features = reshape(hog_full, numberOfRows*numberOfColumns, no_channels)';    
    featureVector  = stack_features(:, roiMask );
    
    if strcmp( obj.m_featureType, 'HOG_AND_COLOR' )
        rgbColorFeatureVector = Features.GenerateRawColorFeatures(rgb2lab(inputImage), roiMask);
        featureVector         = [ featureVector; rgbColorFeatureVector ];
    end

    if Features.ENABLE_NON_LINEAR_FEATURE_SPACE
        featureVector = [ featureVector; (featureVector).^2; (featureVector).^3 ];
    end
    
    if shouldConcatenateWithExistingFeatures
        obj.m_featureVector      = [ obj.m_featureVector featureVector ];
    else
        obj.m_featureVector      =  featureVector;
    end
    
    assert( ~isempty( obj.m_featureVector ) );      
end