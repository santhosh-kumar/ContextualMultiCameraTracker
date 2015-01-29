%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This file sets the global constants.
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Config < handle
    properties (Constant)
        %% Folder and Dataset Settings
        LIBS_FOLDER                      = [ '..' filesep 'libs' filesep];  % Library folder
        DATA_FOLDER                      = [ '..' filesep 'data' filesep];  % Data folder
        DATASET                          = 'PETS';                          % 'PETS' or 'UCSB'
        IMAGE_FORMAT                     = '.png';                          % '.png' or '.jpg' or '.jpeg'
        OUTPUT_RECTANGLE_COLOR           = [0 1 0];                         % Output rectangle color for display
        SCENARIO                         = 4;                               % Scenario count      
        INITIALIZATION_FRAME_NUMBER      = 1;                               % Initialization Frame Number 
        NUMBER_OF_FRAMES                 = 100;                             % Number of frames to track
        NUMBER_CAMERAS                   = 2;                               % Number of cameras in the network
        NUMBER_OF_OBJECTS                = 7;                               % Number of objects to track
        CAMERA_INDICES                   = [1 3];                           % Camera Indices
        OBJECT_INDICES                   = [1 2 3 4 5 6 7];                 % Object Indices to Track
        
        %% Image Plane Particle Filter Related Settings
        USE_PARTICLE_FILTERING           = 1;                               % Should Use Particle Filters
        NUMBER_PARTICLES                 = 100;                             % Number of Particles for the image plane
        PARTICLES_RESAMPLING_THRESHOLD   = 0.5;                             % Resampling threshold for particles
        RESAMPLING_STRATEGY              = 'multinomial_resampling';        % systematic_resampling or multinomial_resampling
        NUMBER_OF_PARTICLES_TO_DISPLAY   = 10;                              % Number of Particles to display
        MAX_SCALE_CHANGE_IN_ONE_INTERVAL = 0.1;                             % Max scale change in one interval
        MAX_SCALE_CHANGE                 = 1.1;                             % Max allowed scale w.r.t initial
        MIN_SCALE_CHANGE                 = 0.9;                             % Min allowed scale w.r.t initial
        STD_POSITION_X                   = 6;                              % Standard Deviation Position X
        STD_POSITION_Y                   = 6;                              % Standard Deviation Position Y
        STD_SCALE_X                      = 0.1;                             % Standard Deviation Scale X
        STD_SCALE_Y                      = 0.1;                             % Standard Deviation Scale Y
        ENABLE_MEAN_SHIFT_REWEIGHTING    = 1;                               % Enable particle reweighting based on meanshift estimate
        USE_TOP_N_FOR_AVERAGE            = 0;                               % Use Top 'N' particles for getting the state
        PERCENTAGE_TOP_N                 = 25;                              % Percentage of particles for top N averaging to find posterior
        ENABLE_OCCLUSION_HANDLING        = 1;                               % Should Enable Occlusion Handling
        OCCLUSION_CONFIDENCE_THRESHOLD   = 0.5;                             % Occlusion Threshold
        
        %% Feature related settings
        FEATURE_TYPE                     = 'HOG_AND_COLOR';                 % Type of feature [RAW_COLOR, HOG, HOG_AND_COLOR]
        HOG_SPATIAL_BIN_SIZE             = 8;                               % Spatial Bin Size
        HOG_ORIENTAITON_BIN_SIZE         = 12;                              % Orientation Bin Size
        DEFAULT_BINS_MULTI_COLOR_HIST    = 8;                               % Multi-color histogram bins
        ENABLE_NON_LINEAR_FEATURE_SPACE  = 0;                               % enable non-linear feature
        WHITEN_FEATURES                  = 1;                               % enable whitening transform on features
        SHOULD_USE_FAST_HOG              = 0;                               % Should use Fast HOG
        
        %% Number of weak classifiers in Ensemble classifier
        NUMBER_OF_WEAK_CLASSIFIER_ENSEMBLE_CLASSIFIER    = 24;              % Number of weak classifiers in Ensemble classifier
        NUMBER_OF_WEAK_CLASSIFIERS_CHANGED               = 6;               % Number of weak classifiers changed in ensemble classifier
        NUMBER_BEST_WEAK_CLASSIFIERS_TO_SHARE            = 3;               % Number of best weak classifiers to share across the views
        POSITIVE_SAMPLE_SELECTION_THRESHOLD              = 0.8;             % Positive sample selection threshold
        MEANSHIFT_BANDWIDTH                              = 20;              % Meanshift Bandwidth parameter
        MEANSHIFT_EPSILON                                = 0.5;             % Meanshift Epsilon
        MAX_NUMBER_SHARED_NEGATIVE_EXAMPLES              = 200;             % Max Negative Samples from other objects for training
        WEAK_CLASSIFIER_TYPE                             = 'BOOST';         % Weak Classifier Type BOOST or SVM
        CONFIDENCE_THRESHOLD                             = 0.5;             % Confidence threshold for meanshift
        MEANSHIFT_ITERATIONS                             = 1000;            % Number of iterations for meanshift
        CONFIDENCE_MULTIPILICATION_FACTOR                = 10;              % Multiplication factor used in sigmoid function
        
        %% Consensus related settings
        ENABLE_CONSENSUS                                 = 1;               % Enable or Disable Consensus algorithm
        USE_ADMM_BASED_CONSENSUS                         = 1;               % Enable ADMM based consensus algorithm
        USE_DYNAMIC_CONTEXT_FOR_CONSENSUS                = 1;               % Should use Dynamic Scene Context
        USE_STATIC_CONTEXT_FOR_CONSENSUS                 = 1;               % Should use static scene context
        USE_SPATIAL_CONTEXT_FOR_CONSENSUS                = 1;               % Should use Spatial Context
        USE_CONSENSUS_BASED_POSITION_ONLY_FOR_TRAINING   = 0;               % Should use consensus only for training
        MAXIMUM_NUMBER_OF_CONSENSUS_ITERATION            = 2;               % Maximum number of consensus iterations
        ALPHA                                            = 1e-2;            % weight of dynamic scene property
        BETA                                             = 1e-2;            % weight of static scene
        GAMMA                                            = 1e-2;            % weight of spatial context
        LAMBDA                                           = {[0.01; 0.01]}; % consensus parameter
        RHO                                              = 5;               % consensus parameter
        
        %% Ground Plane Kalman Filter Related Settings    
        KF_PROCESS_NOISE_VARIANCE                        = 10;             % Process noise variance
        KF_MEAS_NOISE_VARIANCE                           = 25;             % Measurement noise variance
        KF_INITIAL_ERROR_COVARIANCE                      = 4;              % Initial Error Co-variance

        %% MetropolisHastings Sampler
        MPHS_NUMBER_OF_SAMPLES                           = 50;              % Number of samples for posterior
    end
end