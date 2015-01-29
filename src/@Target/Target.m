%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This class encapsulates all the target related features.
%   Target class holds the ensemble classifier
%
%   Also, all the state space related information is stored in this class.
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Target < handle
    
   properties( GetAccess = 'public', SetAccess = 'private' )
       
        m_cameraID;                                         % camera Id of the target
        m_homographyMatrix;                                 % camera homography passed from the camera
        m_cameraModel;                                      % camera calibration model
        m_targetID;                                         % target ID
        m_isActive;                                         % active or not
      
        m_featureType;                                      % feature type for the classifier
        m_ensembleClassifier;                               % ensemble classifier
        
        m_isParticleFilterEnabled;                          % is particle filter enabled
        m_particleFilter;                                   % particle filter
        
        m_groundMPHS;                                       % ground plane Metropolis Hastings Sampler
        m_groundKF;                                         % ground plane Kalman filter
        m_trajectoryDatabase;                               % ground plane Trajectory Database
        
        m_rectangle;                                        % object rectangle on image plane
        m_initRectangle;                                    % initial rectangle on image plane
        m_appearanceTrainingRectangle;                      % object recatangle for appearance training
        m_aspectRatio;                                      % aspect ratio of the object
        m_imageResolution;                                  % Number of rows x number of columns
        m_groundPlaneTrajectoryHistory;                     % ground plane trajectory history
        m_imagePlaneTrajectoryHistory;                      % Trajectory history on the image plane
        m_groundPlaneLocationForConsensusMessagePassing;    % ground plane location, used for non-active targets
        m_shouldUseConsensusBasedPositionOnlyForTraining;   % should use consensus based position only for training    
        
   end%properties
   
   properties(Constant)
       USE_MAXIMUM_LIKELIHOOD_FOR_WEIGHTING     = 0;
       OCCLUSION_CONFIDENCE_THRESHOLD           = Config.OCCLUSION_CONFIDENCE_THRESHOLD;
       ENABLE_OCCLUSION_HANDLING                = Config.ENABLE_OCCLUSION_HANDLING;
   end%constant properties
   
    methods( Access = public )
       
        % Constructor
        function obj = Target( cameraID,...
                              targetID,...
                              homographyMatrix,...
                              cameraModel,...
                              initializationImageFrame,...
                              objectRectangle,...
                              isTargetActive,...
                              groundPlanePosition,...
                              featureType,...
                              shouldUseConsensusBasedPositionOnlyForTraining,...
                              trajectoryDatabase )
                          
            try
                assert( nargin >= 4 );
                assert( cameraID ~= 0 );
                assert( targetID ~= 0 );

                % set the default values
                if nargin < 11
                    trajectoryDatabase = [];
                    if nargin < 10
                        shouldUseConsensusBasedPositionOnlyForTraining = false;
                        if nargin < 9
                            featureType = 'RAW_COLOR';
                            if nargin == 4
                                objectRectangle                   = [];
                                isTargetActive                    = false;
                                groundPlanePosition               = [];
                                initializationImageFrame          = [];
                            end
                        end
                    end
                end

                obj.m_cameraID                                        = cameraID;
                obj.m_targetID                                        = targetID;
                obj.m_homographyMatrix                                = homographyMatrix;
                obj.m_cameraModel                                     = cameraModel;
                obj.m_rectangle                                       = floor(objectRectangle);
                obj.m_initRectangle                                   = floor(objectRectangle);
                obj.m_imagePlaneTrajectoryHistory                     = objectRectangle;
                obj.m_isActive                                        = isTargetActive;
                obj.m_groundPlaneTrajectoryHistory                    = groundPlanePosition;
                obj.m_groundPlaneLocationForConsensusMessagePassing   = [];
                obj.m_shouldUseConsensusBasedPositionOnlyForTraining  = shouldUseConsensusBasedPositionOnlyForTraining;
                obj.m_trajectoryDatabase                              = trajectoryDatabase;
                obj.m_imageResolution                                 = size( initializationImageFrame );
                obj.m_featureType                                     = featureType;

                if ~isempty( objectRectangle )
                    assert( length(objectRectangle) == 4 );
                    obj.m_aspectRatio = objectRectangle(3) / objectRectangle(4);
                end

                % initialize ensemble classifier if the object is active
                % Also the ground plane Kalman filter and Metropolis Sampler
                if obj.IsActive( )
                    if ~isempty(groundPlanePosition)
                        obj = obj.InitializeKalmanFilter();
                        obj = obj.InitializeMetropolisHastingsSampler();
                    end                    
                    
                    % initialize the ensemble classifier
                    obj = obj.InitializeEnsembleClassifier( initializationImageFrame,...
                                                            EnsembleClassifier.NUMBER_OF_WEAK_CLASSIFIER_ENSEMBLE_CLASSIFIER,...
                                                            EnsembleClassifier.NUMBER_OF_WEAK_CLASSIFIERS_CHANGED );
                end
            catch ex
                throwAsCaller( ex );
            end
        end
   
        % Get rectangle on the image plane
        function objectRectangle = GetTargetRectangle( obj )
            objectRectangle = obj.m_rectangle;
        end
        
        % Get the target ID
        function targetID = GetTargetID( obj )
            targetID = obj.m_targetID;
        end
        
        % Initialize the Kalman Filter
        function obj = InitializeKalmanFilter( obj )
            assert( obj.IsActive() == 1);
            m   = 4;
            p   = 2;
            x0  =  [obj.m_rectangle(1) + obj.m_rectangle(3)/2  obj.m_rectangle(2) + obj.m_rectangle(4) 0 0]; % foot position
            [ w, v, A, H, scale ] = KalmanFilter.SetKFParameters( m, p, 1 );
            obj.m_groundKF        = KalmanFilter( m, p, w, v, x0', A, H, scale );
        end
        
        % Initialize MetropolisHastingsSampler
        function obj = InitializeMetropolisHastingsSampler( obj )
            assert( obj.IsActive() == 1);
            assert( ~isempty(obj.m_trajectoryDatabase) );
            
            x0 =  obj.GetGroundPlaneLocation();
            obj.m_groundMPHS = MetropolisHastingsSampler( obj.m_trajectoryDatabase,...
                                                          MetropolisHastingsSampler.NUMBER_OF_SAMPLES,...
                                                          2,...
                                                          x0 );
        end
        
        % Update Kalman Filter
        function obj = UpdateKalmanFilter( obj, x )
            if ~isempty(obj.m_groundKF)
                assert( ~isempty(x) );
                obj.m_groundKF = obj.m_groundKF.Update(x);
            end
        end
        
        % Update Metropolis Hastings Sampler
        function obj = UpdateMPHS( obj, x )
            if ~isempty(obj.m_groundMPHS)
                assert( ~isempty(x) );
                obj.m_groundMPHS = obj.m_groundMPHS.Update( x );
            end
        end
        
        % Get the average sample from MPH sampler
        function averageSample = GetAverageMPHSample(obj)
            assert( ~isempty(obj.m_groundMPHS) );
            averageSample = obj.m_groundMPHS.GetWeightedAverageSample();
            assert( ~isempty(averageSample) );
        end
        
        % Set target rectangle
        function obj = SetTargetRectangle( obj, targetRectangle )
            assert( length(targetRectangle) == 4 );
            obj.m_rectangle = targetRectangle;
        end
        
        % Get appearance training rectangle on the image plane
        function objectRectangle = GetTargetAppearanceTrainingRectangle( obj )
            objectRectangle = obj.m_appearanceTrainingRectangle;
        end
        
        % Set target appearance training rectangle
        function obj = SetTargetAppearanceTrainingRectangle( obj, targetRectangle )
            assert( length(targetRectangle) == 4 );
            obj.m_appearanceTrainingRectangle = targetRectangle;
        end
        
        % Update target trajectory history on the ground plane
        function obj = UpdateTrajectoryOnTheGroundPlane( obj, groundPlanePosition )
            assert( length(groundPlanePosition) == 2 );
            obj.m_groundPlaneTrajectoryHistory = [ obj.m_groundPlaneTrajectoryHistory; groundPlanePosition ];
        end
        
        % Get last state
        function lastState = GetLastStateOnGroundPlane(obj)
            lastIndex = size(obj.m_groundPlaneTrajectoryHistory, 1);
            if lastIndex > 0
                lastState = obj.m_groundPlaneTrajectoryHistory(lastIndex,:)';
            else
                lastState = [];
            end
        end
        
        % Set temporary message for consensus
        function obj = SetTemporaryMessageForConsensus( obj, currentConsensusState )
            assert( ~isempty( currentConsensusState ) );
            assert( ~obj.IsActive() );
            obj.m_groundPlaneLocationForConsensusMessagePassing = currentConsensusState;
        end
        
        % Reset temporary message for consensus
        function obj = ResetTemporaryMessageForConsensus( obj )
            assert( ~obj.IsActive() );
            obj.m_groundPlaneLocationForConsensusMessagePassing = [];
        end
        
        % Is target active?
        function isActive = IsActive( obj )
            isActive = obj.m_isActive;
        end
        
        % Get ground plane location
        function currentGroundPlaneLocation = GetGroundPlaneLocation( obj )
            if ( obj.IsActive( ) )
                if obj.m_shouldUseConsensusBasedPositionOnlyForTraining && ~isempty( obj.GetTargetAppearanceTrainingRectangle( ) )
                    currentGroundPlaneLocation = Camera.ProjectToGroundPlane( obj.GetTargetAppearanceTrainingRectangle( ), obj.m_homographyMatrix, obj.m_cameraModel );
                else
                    currentGroundPlaneLocation = Camera.ProjectToGroundPlane( obj.GetTargetRectangle( ), obj.m_homographyMatrix, obj.m_cameraModel );
                end
            else
                currentGroundPlaneLocation = obj.m_groundPlaneLocationForConsensusMessagePassing;
            end
        end
        
        % Get ground plane trajectory history
        function groundPlaneTrajectoryHistory = GetGroundPlaneTrajectoryHistory( obj )
            groundPlaneTrajectoryHistory = obj.m_groundPlaneTrajectoryHistory;
        end
        
        % Get ground plane trajectory history
        function imagePlaneTrajectoryHistory = GetImagePlaneTrajectoryHistory( obj )
            imagePlaneTrajectoryHistory = obj.m_imagePlaneTrajectoryHistory;
        end
        
        % Setters
        
        %Initialize particle filters
        function obj = InitializeParticleFilter( obj, imageHeight, imageWidth )
            assert( nargin == 3 );
            particleStateDimension = 4; %[centerX, centerY, scaleX, scaleY];
            
            %create particle filter object
            obj.m_particleFilter = ParticleFilter( obj.m_rectangle,...
                                                   imageHeight,...
                                                   imageWidth,...
                                                   particleStateDimension );
                                               
           obj.m_isParticleFilterEnabled = 1;
           
           % initialize the particle filter
           centerX  = obj.m_rectangle(1) + obj.m_rectangle(3) / 2;
           centerY  = obj.m_rectangle(2) + obj.m_rectangle(4) / 2;
           scaleX   = 1; % initial scale-x value 
           scaleY   = 1; % initial scale-y value           
                                               
           obj.m_particleFilter.Initialize( centerX,...
                                            centerY,...
                                            scaleX,...
                                            scaleY,...
                                            ParticleFilter.MAX_SCALE_CHANGE_IN_ONE_INTERVAL,...
                                            ParticleFilter.MAX_SCALE_CHANGE,...
                                            ParticleFilter.MIN_SCALE_CHANGE );
        end
        
        % Initialize ensemble classifier
        function obj = InitializeEnsembleClassifier( obj,...
                                                     initializationImageFrame,...
                                                     numberOfWeakClassifiers,...
                                                     numberOfWeakClassifiersChanged )
            assert( nargin == 4 );
            
            try
                obj.m_ensembleClassifier = EnsembleClassifier(  initializationImageFrame,...
                                                                obj.m_rectangle,...
                                                                numberOfWeakClassifiers,...
                                                                numberOfWeakClassifiersChanged,...
                                                                obj.m_featureType  );
            catch ex
                throwAsCaller(ex);
            end
        end
        
        % Track object on the given frame
        function obj = TrackObjectOnTheGivenFrame( obj, frameImage, previousFrameOtherObjectRectangles )
            assert( nargin == 3 );
            if obj.IsActive( )
                assert( ~isempty(frameImage) );
                if ( obj.m_isParticleFilterEnabled )
                    % Predict particles
                    obj.m_particleFilter.Predict( ParticleFilter.STD_POSITION_X,...
                                                  ParticleFilter.STD_POSITION_Y,...
                                                  ParticleFilter.STD_SCALE_X,...
                                                  ParticleFilter.STD_SCALE_Y );
                end
                
                [ obj.m_ensembleClassifier, objectRectangle, confidenceMap ]   = obj.m_ensembleClassifier.Test( frameImage,...
                                                                                                                obj.m_rectangle );
                visibility = 1;
                % Occlusion Handling                                                                                        
                if ~isempty(previousFrameOtherObjectRectangles) && Target.ENABLE_OCCLUSION_HANDLING
                    overlapScores = zeros(size(previousFrameOtherObjectRectangles, 1));
                    
                    for j = 1 : size(previousFrameOtherObjectRectangles, 1)
                        overlapScores(j) = Target.GetRelativeOverlapScore(objectRectangle, previousFrameOtherObjectRectangles(j, :));
                    end
                    
                    visibility = exp(-sum(overlapScores));
                end
                
                if ( obj.m_isParticleFilterEnabled )
                    if visibility >= Target.OCCLUSION_CONFIDENCE_THRESHOLD
                        confidenceMapLikelihoodList = ones( obj.m_particleFilter.GetNumberOfParticles( ), 1 );%obj.UpdateParticleWeightsBasedOnTheConfidenceMap( confidenceMap );
                        meanshiftLikelihoodList     = ones( size(confidenceMapLikelihoodList, 1), size(confidenceMapLikelihoodList, 2) );
                        if ParticleFilter.ENABLE_MEAN_SHIFT_REWEIGHTING
                            meanshiftLikelihoodList = obj.UpdateParticleWeightsBasedOnMeanShiftEstimate( objectRectangle,...
                                                                                                         frameImage );
                        end

                        likelihoodList = confidenceMapLikelihoodList .* meanshiftLikelihoodList;

                        % rescale the likelihood
                        maxValue = max(likelihoodList);
                        minValue = min(likelihoodList);
                        if maxValue ~= minValue
                           range = maxValue-minValue;
                           if range == 0
                               range = 1;
                           end
                           likelihoodList = (likelihoodList - minValue)./ range;
                        end

                        obj.m_particleFilter.Update( likelihoodList );

                        averageParticle = obj.m_particleFilter.GetAverageParticle();

                        obj.m_rectangle(1) = averageParticle(1) - obj.m_rectangle(3)/2 * averageParticle(3);
                        obj.m_rectangle(2) = averageParticle(2) - obj.m_rectangle(4)/2 * averageParticle(4);   
                        obj.m_rectangle(3) = obj.m_initRectangle(3) * averageParticle(3);
                        obj.m_rectangle(4) = obj.m_initRectangle(4) * averageParticle(4);

                        %display particles
                        if ( ParticleFilter.NUMBER_OF_PARTICLES_TO_DISPLAY > 0 )
                            obj.m_particleFilter.DisplayParticles( frameImage, (obj.m_cameraID * 100 + 1) );
                        end
                    end
                else
                    obj.m_rectangle = objectRectangle;
                end
                
                %predict the kalman state
                if ~isempty(obj.m_groundKF)
                    obj.m_groundKF = obj.m_groundKF.Predict();
                end
                
                %sample from ground plane kernel density
                if ~isempty(obj.m_groundMPHS)
                    obj.m_groundMPHS = obj.m_groundMPHS.Sample();
                end
            end
        end
        
        %Update particle weights based on meanshift posterior
        function likelihoodList = UpdateParticleWeightsBasedOnMeanShiftEstimate( obj,...
                                                                                 meanShiftEstimate,...
                                                                                 frameImage )

            likelihoodList = zeros( obj.m_particleFilter.GetNumberOfParticles( ), 1 );          
            
            for particleIndex = 1 : obj.m_particleFilter.GetNumberOfParticles( )   
                particle = obj.m_particleFilter.GetParticle( particleIndex );

                % Note x is column index and y is row index
                xMin = particle(1) - obj.m_rectangle(3)/2 * particle(3);
                yMin = particle(2) - obj.m_rectangle(4)/2 * particle(4);

                 if ( xMin < 1 ||...
                     yMin < 1 ||...
                     (xMin + obj.m_rectangle(3)) > size(frameImage,2) ||...
                     (yMin + obj.m_rectangle(4) ) > size(frameImage,1) )
                 
                    likelihoodList(particleIndex) = 0;
                 else
                    sigma = min(meanShiftEstimate(3)/2, meanShiftEstimate(4)/2);
                    likelihoodList(particleIndex) = mvnormpdf( [particle(1) particle(2)]',...
                                                                [ meanShiftEstimate(1)+meanShiftEstimate(3)/2  meanShiftEstimate(2)+meanShiftEstimate(4)/2]',...
                                                                [],...
                                                                sigma*eye(2) );
                end
            end
        end
        
        %Update particle weights based on the confidence map
        function likelihoodList = UpdateParticleWeightsBasedOnTheConfidenceMap( obj,...
                                                                                confidenceMap )
             likelihoodList = zeros( obj.m_particleFilter.GetNumberOfParticles( ), 1 );
             for particleIndex = 1 : obj.m_particleFilter.GetNumberOfParticles( )                                             
                particle = obj.m_particleFilter.GetParticle( particleIndex );
                
                % Note x is column index and y is row index
                xMin = floor(particle(1) - obj.m_rectangle(3)/2 * particle(3));
                yMin = floor(particle(2) - obj.m_rectangle(4)/2 * particle(4));
                
                if ( xMin < 1 ||...
                     yMin < 1 ||...
                     (xMin + obj.m_rectangle(3)) > size(confidenceMap,2) ||...
                     (yMin + obj.m_rectangle(4) ) > size(confidenceMap,1) )
                    likelihoodList(particleIndex) = 0;
                else
                    if ( Target.USE_MAXIMUM_LIKELIHOOD_FOR_WEIGHTING )
                        likelihoodList(particleIndex) = max( max( confidenceMap( yMin : floor(yMin + obj.m_rectangle(4)), xMin : floor( xMin + obj.m_rectangle(3) ) ) ) );
                    else
                        foregroundLikelihood = sum( sum( confidenceMap( yMin : floor( yMin + obj.m_rectangle(4) ), xMin : floor( xMin + obj.m_rectangle(3) ) ) ) )...
                                                        ./ ( obj.m_rectangle(3) * obj.m_rectangle(4) );                                                    
                        likelihoodList(particleIndex) = foregroundLikelihood;
                    end
                end
             end
        end
        
        % Update Particle Weights based on ground plane KF posterior density
        function obj = UpdateParticleWeightBasedOnKalmanPosterior( obj )
             % ground plane likelihood list
             likelihoodList = zeros( obj.m_particleFilter.GetNumberOfParticles( ), 1 );
             
             kfX    = obj.m_groundKF.GetPosteriorState();       % foot position
             kfXc   = [ kfX(1); kfX(2) - obj.m_rectangle(4)/2]; % centroid
             
             for particleIndex = 1 : obj.m_particleFilter.GetNumberOfParticles( )                                             
                particle = obj.m_particleFilter.GetParticle( particleIndex );
                
                % Note x is column index and y is row index
                xMin = particle(1) - obj.m_rectangle(3)/2 * particle(3);
                yMin = particle(2) - obj.m_rectangle(4)/2 * particle(4);
                
                if ( xMin < 1 ||...
                     yMin < 1 ||...
                     (xMin + obj.m_rectangle(3)) >  obj.m_imageResolution(2) ||...
                     (yMin + obj.m_rectangle(4) ) > obj.m_imageResolution(1) )
                    likelihoodList(particleIndex) = 0;
                else
                    if norm( kfXc - particle(1:2)' ) < min(obj.m_rectangle(3), obj.m_rectangle(4))
                        % Set particle weight according to ground plane KF filter posterior density
                        particleRectangle               = [ xMin, yMin, obj.m_rectangle(3).*particle(3), obj.m_rectangle(4).*particle(4)];
                        gpX                             = [particleRectangle(1) + particleRectangle(3)/2 particleRectangle(2) + particleRectangle(4)];
                        likelihoodList(particleIndex)   = obj.m_groundKF.EvaluatePosteriorDensity( gpX );
                    else
                        particle(1:2)                   = kfXc(1:2);
                        obj.m_particleFilter            = obj.m_particleFilter.SetParticle( particleIndex, particle );
                        obj.m_particleFilter            = obj.m_particleFilter.SetWeight( 1/obj.m_particleFilter.GetNumberOfParticles( ), particleIndex );
                        likelihoodList(particleIndex)   = 1 ./ obj.m_particleFilter.GetNumberOfParticles( );
                    end
                end
             end
             
             if (sum(likelihoodList) <= 0)
                 return;
             end
             
             maxValue = max(likelihoodList);
             minValue = min(likelihoodList);
             if maxValue ~= minValue
                likelihoodList = (likelihoodList - minValue)./(maxValue-minValue);
             end

             obj.m_particleFilter.Update( likelihoodList );
             
             averageParticle = obj.m_particleFilter.GetAverageParticle();
             
             obj.m_rectangle(1) = averageParticle(1) - obj.m_rectangle(3)/2 * averageParticle(3);             
             obj.m_rectangle(2) = averageParticle(2) - obj.m_rectangle(4)/2 * averageParticle(4);
             obj.m_rectangle(3) = obj.m_initRectangle(3) * averageParticle(3);
             obj.m_rectangle(4) = obj.m_initRectangle(4) * averageParticle(4);
             
             % Set the training rectangle
             obj.m_appearanceTrainingRectangle = obj.m_rectangle;
             
             % Update the MPHS state
             obj.UpdateMPHS( Camera.ProjectToGroundPlane( obj.m_rectangle, obj.m_homographyMatrix, obj.m_cameraModel ) );
        end
        
        % Update the Appearance model using Ensemble classifier
        function obj = UpdateAppearanceModel( obj,...
                                              frameImage,...
                                              sharedWeakClassifierList,...
                                              sharedNegativeSamples )
            assert( nargin >= 2 );
            if ( obj.IsActive( ) )
                
                assert( ~isempty(frameImage) );
                
                % use training rectangle got from multiple camera consensus
                if  obj.m_shouldUseConsensusBasedPositionOnlyForTraining && ~isempty(obj.m_appearanceTrainingRectangle)
                    trainingRectangle = obj.m_appearanceTrainingRectangle;
                else
                    trainingRectangle = obj.m_rectangle;
                end
                
                [ obj.m_ensembleClassifier ]   = obj.m_ensembleClassifier.Update(   frameImage,...
                                                                                    trainingRectangle,...
                                                                                    sharedWeakClassifierList,...
                                                                                    sharedNegativeSamples );
                %Set the image plane trajectory history
                obj.m_imagePlaneTrajectoryHistory = [ obj.m_imagePlaneTrajectoryHistory; obj.m_rectangle ];                
            end
        end
        
        % Get best performing weak classifiers
        function weakClassifierList = GetBestPerformingWeakClassifiers( obj )
            if obj.IsActive()
                weakClassifierList = obj.m_ensembleClassifier.GetBestPerformingWeakClassifiers( );
            else
                weakClassifierList = {};
            end
        end%function
        
        % Get negative examples for training other objects
        function negativeExamples = GetNegativeSamples( obj, weakClassifierList )
            if obj.IsActive()
                assert( ~isempty(weakClassifierList) );
                negativeExamples = obj.m_ensembleClassifier.GetNegativeSamplesForCorrelatedObjects( weakClassifierList );
            else
                negativeExamples = [];
            end
        end
    end%methods public

    methods( Access = private )        
        % Initialize Kinematics based distributed kalman filter.
        obj = InitializeKinematicsBasedDKF( obj );
         
        % Check region of Interest
        obj = CheckRegionOfInterest( obj, frameImage );        
    end%methods private

    methods(Static)
        % get the overlap score
        function vocScore = GetRelativeOverlapScore( rect1, rect2 )
            interArea = rectint( rect1, rect2 );
            area1    = rect1(3) * rect1(4);
            vocScore = interArea ./ area1;
        end 
    end%static methods

end%classdef