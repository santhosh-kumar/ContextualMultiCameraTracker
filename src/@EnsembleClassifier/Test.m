%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function tests the Ensemble Classifier on the given test image
%
%   Input --
%       @obj -                      - Ensemble Classifier Object 
%       @frameImage                 - Input Image
%       @previousTargetRectangle    - object rectangle
%
%   Output -- 
%       @obj                        - EnsembleClassifier object
%       @currentRectangle           - Current Target Rectangle
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ obj, currentRectangle, fgConfidenceMap ] = Test( obj,...
                                                            frameImage,...
                                                            previousTargetRectangle )        
    assert( nargin >= 3 );
    assert( ~isempty(frameImage) );

    [ obj, previousTargetRectangle ] = obj.PrepareForegroundAndBackgroundMasks(frameImage, previousTargetRectangle, 'TEST');

    currentRectangle = previousTargetRectangle;

    % Extract features for testing
    obj = obj.ExtractFeatures( frameImage, 'TEST' );

    assert( ~isempty( obj.m_testingFeature.GetFeatureVector() ) );

    % Run the learned classifier on the test features
    if strcmp(EnsembleClassifier.WEAK_CLASSIFIER_TYPE, 'BOOST')
        [~, Fx, ~ ] = strongGentleBoostClassifier( obj.m_testingFeature.GetFeatureVector(),...
                                                    obj.m_weakClassifiers );
    elseif strcmp(EnsembleClassifier.WEAK_CLASSIFIER_TYPE, 'SVM')
        error( 'Currently not supported' );
    else
        error( 'Choose a Valid Weak Classifier' );
    end
                                       
    fgConfidenceMap = zeros( size(frameImage,1), size(frameImage,2) );
    backgroundForegroundMask = [obj.m_backgroundRegionMask; obj.m_foregroundRegionMask];

    % use the sigmoid of the classifier response as the confidence
    fgConfidenceMap( backgroundForegroundMask ) = 1 ./ (1 + exp(-EnsembleClassifier.CONFIDENCE_MULTIPILICATION_FACTOR * Fx) );

    maxConfidence = max(max(fgConfidenceMap));
    minConfidence = min(min(fgConfidenceMap));
    threshold     = (maxConfidence - minConfidence) * EnsembleClassifier.CONFIDENCE_THRESHOLD;
    fgConfidenceMap(fgConfidenceMap < threshold)=0;
    
    [tracker_y, tracker_x ] = find( fgConfidenceMap > 0 );
    weights = fgConfidenceMap(sub2ind(size(frameImage),tracker_y, tracker_x));
    if ( numel(tracker_y) < 10 ),
        display('Tracker for has failed this pass');
        return;
    end

    mode = meanshiftSpatial( [ tracker_x(:)'; tracker_y(:)' ],...
                             min(previousTargetRectangle(3), previousTargetRectangle(4))/2,...
                             EnsembleClassifier.MEANSHIFT_EPSILON,... 
                             [previousTargetRectangle(1)+previousTargetRectangle(3)/2 previousTargetRectangle(2)+previousTargetRectangle(4)/2]',...
                             weights',...
                             EnsembleClassifier.MEANSHIFT_ITERATIONS );

    currentRectangle(1) = ceil( mode(1) - previousTargetRectangle(3)/2 );
    currentRectangle(2) = ceil( mode(2) - previousTargetRectangle(4)/2 ); 
end