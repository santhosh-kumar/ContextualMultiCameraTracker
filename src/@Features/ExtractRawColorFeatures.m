%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Features::ExtractRawColorFeatures
%
%   Extracts raw color pixel features Feature
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
function  obj  = ExtractRawColorFeatures(  obj,...
                                           inputImage,...
                                           roiMask,...
                                           shouldConcatenateWithExistingFeatures )
                                           
    assert(  strcmp( obj.m_featureType, 'RAW_COLOR' ) ||  strcmp( obj.m_featureType, 'HOG_AND_COLOR' ) );

    assert( nargin >= 3 );
    assert( ~isempty(inputImage) );
    assert( ~isempty(roiMask) );

    rgbColorFeatureVector = Features.GenerateRawColorFeatures( inputImage, roiMask );

    if shouldConcatenateWithExistingFeatures
        obj.m_featureVector        = [ rgbColorFeatureVector obj.m_featureVector ];
    else
        obj.m_featureVector        =  rgbColorFeatureVector;
    end

    assert( ~isempty( obj.m_featureVector ) );

end