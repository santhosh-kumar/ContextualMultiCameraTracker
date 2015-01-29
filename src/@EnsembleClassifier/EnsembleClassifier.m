%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This class implements the Ensemble Classifier
%
%   Reference:
%       "Ensemble Tracking" - Avidan, S.
%
%   Author  -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef EnsembleClassifier < handle
    
    properties(GetAccess = 'public', SetAccess = 'private')        
        m_numberOfWeakClassifiers;              % number of weak classifiers
        m_numberOfWeakClassifiersChanged;       % number of weak classifiers changed at each time instance
        
        m_foregroundRegionMask;                 % foreground mask of the object from which positive training samples are generated
        m_backgroundRegionMask;                 % background mask of the object from which negative training samples are generated
        
        m_featureType;                          % RAW_COLOR or HOG
        m_trainingFeature;                      % training feature samples
        m_testingFeature;                       % testing feature samples
        
        m_trainingLabels;                       % training labels
        
        m_foregroundBackgroundShuffleIndices;   % shuffle, sorted for training/testing
        m_numberOfRowsForBoosting;              % number of rows in ROI
        m_numberOfColumnsForBoosting;           % number of columns in ROI
        
        m_weakClassifiers;                      % learned weak classifier struct            
    end%properties

    properties( Constant )
        NUMBER_OF_WEAK_CLASSIFIER_ENSEMBLE_CLASSIFIER    = Config.NUMBER_OF_WEAK_CLASSIFIER_ENSEMBLE_CLASSIFIER;
        NUMBER_OF_WEAK_CLASSIFIERS_CHANGED               = Config.NUMBER_OF_WEAK_CLASSIFIERS_CHANGED;
        NUMBER_BEST_WEAK_CLASSIFIERS_TO_SHARE            = Config.NUMBER_BEST_WEAK_CLASSIFIERS_TO_SHARE;
        POSITIVE_SAMPLE_SELECTION_THRESHOLD              = Config.POSITIVE_SAMPLE_SELECTION_THRESHOLD;
        MEANSHIFT_BANDWIDTH                              = Config.MEANSHIFT_BANDWIDTH;
        MEANSHIFT_EPSILON                                = Config.MEANSHIFT_EPSILON;
        MAX_NUMBER_SHARED_NEGATIVE_EXAMPLES              = Config.MAX_NUMBER_SHARED_NEGATIVE_EXAMPLES;
        WEAK_CLASSIFIER_TYPE                             = Config.WEAK_CLASSIFIER_TYPE;
        CONFIDENCE_THRESHOLD                             = Config.CONFIDENCE_THRESHOLD;
        MEANSHIFT_ITERATIONS                             = Config.MEANSHIFT_ITERATIONS;
        CONFIDENCE_MULTIPILICATION_FACTOR                = Config.CONFIDENCE_MULTIPILICATION_FACTOR;
    end%constant properties

    methods( Access = public )        
        function obj = EnsembleClassifier(  initializationImageFrame,...
                                            objectRectangle,...
                                            numberOfWeakClassifiers,...
                                            numberOfWeakClassifiersChanged,...
                                            featureType )
                                        
            assert( nargin ==  5 );
            assert( numberOfWeakClassifiers > 0 && numberOfWeakClassifiersChanged >= 0 );
            assert( numberOfWeakClassifiers > numberOfWeakClassifiersChanged );
            assert( ~isempty( featureType ) );
            
            obj.m_numberOfWeakClassifiers           = numberOfWeakClassifiers;
            obj.m_numberOfWeakClassifiersChanged    = numberOfWeakClassifiersChanged;
            obj.m_featureType                       = featureType;
            
            obj.m_trainingFeature                   = Features( featureType );
            obj.m_testingFeature                    = Features( featureType );
            
            % initialize image frame
            obj                                     = obj.Initialize( initializationImageFrame,...
                                                                      objectRectangle );
        
        end
        
        % initialize the ensemble classifier
        obj = Initialize(   obj,...
                            initializationImageFrame,...
                            objectRectangle );
        
        % update the ensemble classifier
        [ obj, objectRectangle ] = Update( obj,...
                                           frameImage,...
                                           trainingRectangle,...
                                           sharedWeakClassifierList,...
                                           sharedNegativeSamples );
        
        % test the classifier on a given image
        [ obj, currentLocation, confidenceMap ] = Test( obj,...
                                                        frameImage,...
                                                        previousTargetRectangle );
        
        % prepare foreground and background masks 
        [ obj, objectRectangle ] = PrepareForegroundAndBackgroundMasks( obj,...
                                                                        frameImage,...
                                                                        objectRectangle,...
                                                                        phase );
        
        % extract features on a given image
        obj = ExtractFeatures( obj,...
                               inputImage,...
                               phase );
                           
        % get best performing weak classifiers
        weakClassifierList = GetBestPerformingWeakClassifiers( obj );
        
        % get negative examples
        negativeSamples = GetNegativeSamplesForCorrelatedObjects( obj, weakClassifierList );        
    end%methods public   
end%classdef