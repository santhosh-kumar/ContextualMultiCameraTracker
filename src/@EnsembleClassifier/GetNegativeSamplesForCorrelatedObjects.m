%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function extracts negative examples that are consistent 
%   across views
%
%   Input --
%       @obj                    - Ensemble Classifier Object 
%       @weakClassifierList     - weak classifier list
%
%   Output -- 
%       @negativeSamples        - Negative samples for the other objects
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function correlatedNegativeSamples = GetNegativeSamplesForCorrelatedObjects( obj,...
                                                                             weakClassifiers )
                                                                         
    assert( ~isempty(weakClassifiers) );
    
    positiveLabelIndex = (obj.m_trainingLabels == 1);
    featurevector = obj.m_trainingFeature.GetFeatureVector( );

    positiveFeatureVector = featurevector( :,  positiveLabelIndex );
    
    sharedWeakClassifierList = cell( length( weakClassifiers ), 1 );
    for i = 1 : length( weakClassifiers )
        sharedWeakClassifierList{i} = weakClassifiers(i);
    end

    if strcmp(EnsembleClassifier.WEAK_CLASSIFIER_TYPE, 'BOOST')
        [~, Fx ] = strongGentleBoostClassifier( positiveFeatureVector,...
                                                sharedWeakClassifierList );
    elseif strcmp(EnsembleClassifier.WEAK_CLASSIFIER_TYPE, 'SVM')
        
    else
        error( 'Choose a Valid Weak Classifier' );
    end

    strongPositiveFeatureIndex =  (1 ./ (1 + exp(-Fx) ) > EnsembleClassifier.POSITIVE_SAMPLE_SELECTION_THRESHOLD);
    correlatedNegativeSamples = positiveFeatureVector( :, strongPositiveFeatureIndex );
end