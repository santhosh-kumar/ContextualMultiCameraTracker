%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    This function initializes Ensemble Classifier.
%
%   Input --
%       @obj -                      - Ensemble Classifier Object 
%       @initializationImageFrame   - Input Image
%       @objectRectangle            - object rectangle
%
%   Output -- 
%       @obj        - EnsembleClassifier object
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = Initialize(  obj,...
                            initializationImageFrame,...
                            objectRectangle )
    obj = obj.PrepareForegroundAndBackgroundMasks(  initializationImageFrame,...
                                                        objectRectangle,...
                                                        'TRAIN' );

    obj = obj.ExtractFeatures(  initializationImageFrame,...
                                'TRAIN' );

    assert( ~isempty( obj.m_trainingFeature.GetFeatureVector() ) );
    assert( ~isempty( obj.m_trainingLabels ) );

    if strcmp(EnsembleClassifier.WEAK_CLASSIFIER_TYPE, 'BOOST')
        obj.m_weakClassifiers = gentleBoost( obj.m_trainingFeature.GetFeatureVector(),...
                                            obj.m_trainingLabels,...
                                            obj.m_numberOfWeakClassifiers...
                                            );
    elseif strcmp(EnsembleClassifier.WEAK_CLASSIFIER_TYPE, 'SVM')
        obj.m_weakClassifiers = [];
    else
        error( 'Choose a Valid Weak Classifier' );
    end

    assert( ~isempty( obj.m_weakClassifiers ) ); 
end