%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    This function extracts features on the given image and stores it 
%    in the appropriate variable
%
%   Input --
%       @obj -      - Ensemble Classifier Object 
%       @inputImage - Input Image
%       @phase      - TRAIN or TEST phase.
%   Output -- 
%       @obj        - EnsembleClassifier object
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = ExtractFeatures( obj,...
                               inputImage,...
                               phase )

    assert( nargin == 3 );
    assert( ~isempty( inputImage ) );

    % clear the labels from previous training
    if ( strcmp( phase, 'TRAIN' ) )
        obj.m_trainingLabels    = [];
        obj.m_trainingFeature   = obj.m_trainingFeature.ResetFeatures();
    else
        assert( strcmp( phase, 'TEST' ) );
        obj.m_testingFeature    = obj.m_testingFeature.ResetFeatures( );
    end
    
    roiMASK                               = [obj.m_backgroundRegionMask; obj.m_foregroundRegionMask];
    shouldConcatenateWithExistingFeatures = 0;
    
     if ( strcmp( phase, 'TRAIN' ) )
            
        obj.m_trainingFeature = obj.m_trainingFeature.ExtractFeatures( inputImage,...
                                                                       roiMASK,...
                                                                       shouldConcatenateWithExistingFeatures );
        
        obj.m_trainingLabels  = [ -1 * ones( 1, numel(obj.m_backgroundRegionMask) )  1 * ones( 1, numel(obj.m_foregroundRegionMask) ) ];
        
    else

        obj.m_testingFeature = obj.m_testingFeature.ExtractFeatures( inputImage,...
                                                                     roiMASK,...
                                                                     shouldConcatenateWithExistingFeatures );
    end
end