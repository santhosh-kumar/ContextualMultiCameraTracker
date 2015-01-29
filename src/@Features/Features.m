%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Features class computes the image features based on the specified type
%
%   Author -- Santhoshkumar Sunderrajan
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Features < handle
    
   properties(GetAccess = 'public', SetAccess = 'private')       
       m_featureVector;     %stores the computed features
       m_featureType;       %type of the feature eg.colorHistogram, HOG, pHOG       
   end% properties
   
   properties( Constant )
        HOG_SPATIAL_BIN_SIZE            = Config.HOG_SPATIAL_BIN_SIZE;
        HOG_ORIENTAITON_BIN_SIZE        = Config.HOG_ORIENTAITON_BIN_SIZE;
        DEFAULT_BINS_MULTI_COLOR_HIST   = Config.DEFAULT_BINS_MULTI_COLOR_HIST;
        ENABLE_NON_LINEAR_FEATURE_SPACE = Config.ENABLE_NON_LINEAR_FEATURE_SPACE;
        WHITEN_FEATURES                 = Config.WHITEN_FEATURES;
        SHOULD_USE_FAST_HOG             = Config.SHOULD_USE_FAST_HOG;
    end%constant properties
   
   methods
       
       % Constructor
        function obj = Features( featureType )
           if nargin == 0
               featureType = 'RAW_COLOR';
           end
           obj.m_featureType = featureType;
        end
        
        % Extract Features
        function obj = ExtractFeatures( obj,...
                                        inputImage,...
                                        roiMask,...
                                        shouldConcatenateWithExistingFeatures,...
                                        isVectorized,...
                                        numberOfBins )
                                    
            if ( strcmp( obj.m_featureType, 'MULTI_DIMENSIONAL_COLOR_HISTOGRAM' ) )
                
                assert( nargin  == 6 );
                
                obj = ExtractColorHistogramFeature( obj,...
                                            imageBlock,...
                                            isVectorized,...
                                            numberOfBins,...
                                            roiMask );
                
            elseif ( strcmp( obj.m_featureType, 'RAW_COLOR' ) )
                
                obj  = ExtractRawColorFeatures( obj,...
                                               inputImage,...
                                               roiMask,...
                                               shouldConcatenateWithExistingFeatures );
                
            elseif ( strcmp( obj.m_featureType, 'HOG' ) || strcmp( obj.m_featureType, 'HOG_AND_COLOR' ) )
                
                obj = ExtractHOGFeatures(   obj,...
                                            inputImage,...
                                            roiMask,...
                                            shouldConcatenateWithExistingFeatures );    
            else
                error( 'Unsupported Feature Type' );
            end
            
            if Features.WHITEN_FEATURES
                obj.m_featureVector = Features.PerformWhiteninig(obj.m_featureVector')';
            end
        end
                          
        % Get the feature vector - feature vector has to be computed before calling this method
        function featureVector = GetFeatureVector( obj )
            assert( ~isempty( obj.m_featureVector ) );
            featureVector = obj.m_featureVector;
        end
        
        % Reset the feature vector
        function obj = ResetFeatures( obj )
            obj.m_featureVector = [];
        end
        
        % Shuffle features
        function obj = ShuffleFeatures( obj, shuffleIndices )
            assert( nargin ==2 && ~isempty(shuffleIndices) );
            assert( ~isempty( obj.m_featureVector ) );
            obj.m_featureVector = obj.m_featureVector( :, shuffleIndices );
        end
        
        
   end% methods
   
   methods( Access = private )
       
        % Extracts raw color features.
        obj  = ExtractRawColorFeatures( obj,...
                                       inputImage,...
                                       roiMASK,...
                                       shouldConcatenateWithExistingFeatures );
                                   
        % Extracts HOG features
        obj = ExtractHOGFeatures( obj,...
                                inputImage,...
                                roiMASK,...
                                shouldConcatenateWithExistingFeatures );
                            
        % Extracts multi-dimensional color histogram feature.
        obj = ExtractColorHistogramFeature( obj,...
                                            imageBlock,...
                                            isVectorized,...
                                            numberOfBins,...
                                            imageROI );
   end
   
   methods(Static)     
        % Perform whitening transformation on the features
        function whitenedFeatures = PerformWhiteninig( features )            
            whitenedFeatures = whiten( features, 0.01 );
        end
        
        function rgbColorFeatureVector = GenerateRawColorFeatures( inputImage, roiMask )
        
            assert( nargin >= 2 );
            assert( ~isempty(inputImage) );
            assert( ~isempty(roiMask) );

            inputImage = double( ( inputImage ) );
            [ numberOfRows, numberOfColumns, numberOfChannels ] = size( inputImage );

            assert( numberOfChannels == 3 );

            vectorizedInputImage           = reshape( inputImage, numberOfRows * numberOfColumns, 3);  
            rgbColorFeatureVector          = vectorizedInputImage( roiMask, : )';

        end
   end
   
end%classdef