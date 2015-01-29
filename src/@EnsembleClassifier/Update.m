%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    This function updates the Ensemble Classifier on the given training
%    image
%
%   Input --
%       @obj -                      - Ensemble Classifier Object 
%       @frameImage                 - Input Image
%       @objectRectangle            - object rectangle
%
%   Output -- 
%       @obj                        - EnsembleClassifier object
%       @objectRectangle            - Current Target Rectangle
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ obj, objectRectangle ] = Update( obj,...
                                            frameImage,...
                                            objectRectangle,...
                                            sharedWeakClassifierList,...
                                            sharedNegativeSamples )
        
    assert( nargin == 5 );
    assert( ~isempty(frameImage) );
    assert( ~isempty(objectRectangle) );
    
    [ obj, objectRectangle ] = obj.PrepareForegroundAndBackgroundMasks( frameImage,...
                                                                        objectRectangle,...
                                                                        'TRAIN' );

    obj = obj.ExtractFeatures( frameImage, 'TRAIN' );

    assert( ~isempty( obj.m_trainingFeature.GetFeatureVector() ) );
    assert( ~isempty( obj.m_trainingLabels ) );
    
    weakClassifiers             = obj.m_weakClassifiers;
    numberOfLocalClassifiers    = numel(weakClassifiers);
    numberOfSharedClassifiers   = length( sharedWeakClassifierList );
    for iter = 1 : numberOfSharedClassifiers
        weakClassifiers{iter+numberOfLocalClassifiers} = sharedWeakClassifierList(iter);
    end

    error = zeros( numel( weakClassifiers), 3 );
    for iter = 1 : numel( weakClassifiers )
        error(iter,1)   = weakClassifiers{iter}.err;
        error(iter,2)   = weakClassifiers{iter}.pos_err;
        error(iter,3)   = weakClassifiers{iter}.neg_err;
    end

    % Reordering classifiers in ascending order according to error ...
    [ ~, pick_class_index ] = sort( error(:,1), 'ascend' );
    for iter= 1 : numel( weakClassifiers )
        selectedWeakClassifier = weakClassifiers{ pick_class_index(iter) };
        if selectedWeakClassifier.err < 50
            ensembleSort{iter}     = selectedWeakClassifier;
        end
    end
    
    numberOfSharedNegativeExamples = size( sharedNegativeSamples, 2 );
    
    if numberOfSharedNegativeExamples > 0
        randomPermutations  = randperm(numberOfSharedNegativeExamples);
        selectionNumbers    = min( EnsembleClassifier.MAX_NUMBER_SHARED_NEGATIVE_EXAMPLES, numberOfSharedNegativeExamples );
        selectedSharedNegativeSamples = sharedNegativeSamples(:,randomPermutations(1:selectionNumbers) );
    else
        selectedSharedNegativeSamples = [];
    end
    
    trainingFeatures    = [ obj.m_trainingFeature.GetFeatureVector()  selectedSharedNegativeSamples ];
    traningLabels       = [ obj.m_trainingLabels -1 .* ones(1,size( selectedSharedNegativeSamples, 2 )) ];
 
    % Train the appearance model
    obj.m_weakClassifiers = ensemble_update( trainingFeatures,...
                                             traningLabels,...
                                             obj.m_numberOfWeakClassifiers,...
                                             ensembleSort,...
                                             obj.m_numberOfWeakClassifiersChanged );

    assert( ~isempty( obj.m_weakClassifiers ) );
end