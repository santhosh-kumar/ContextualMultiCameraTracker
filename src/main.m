%% Clean up
clear;
close all; 
clc;

%% Setup the camera network and start tracking
try
    % Set up the camera network
    [cameraNetwork, frameRangeForAnalysis] = setup( );
    
    % Initialize Tracker Across Different Views
    cameraNetwork.InitializeTrackerAcrossDifferentViews( Config.INITIALIZATION_FRAME_NUMBER,...                    % initializationFrameNumber
                                                         Config.OBJECT_INDICES,...                                 % object indices to track
                                                         Config.FEATURE_TYPE,...                                   % featureType
                                                         Config.USE_CONSENSUS_BASED_POSITION_ONLY_FOR_TRAINING,... % useConsensusOnlyForTraining
                                                         Config.USE_PARTICLE_FILTERING...                          % useParticleFilter
                                                       );               
                                                   
    % Iterate Over time to estimate States using Prior Information
    for frameIndex = frameRangeForAnalysis(1)+1 : frameRangeForAnalysis(2)

        fprintf( '%s\n', [ '===============================Clock Tick: ' num2str(frameIndex) '===============================' ] );

        % test on the given frame
        cameraNetwork.TrackObjectsAcrossDifferentViews( frameIndex );
        
        % apply consensus protocol
        if ( Config.ENABLE_CONSENSUS && cameraNetwork.GetNumberOfCameras( ) > 1 )            
            cameraNetwork = ConsensusProtocol.PerformConsensus(   cameraNetwork,...
                                                                  Config.USE_ADMM_BASED_CONSENSUS,...
                                                                  Config.MAXIMUM_NUMBER_OF_CONSENSUS_ITERATION,... 
                                                                  Config.USE_DYNAMIC_CONTEXT_FOR_CONSENSUS,...
                                                                  Config.USE_STATIC_CONTEXT_FOR_CONSENSUS,...
                                                                  Config.USE_SPATIAL_CONTEXT_FOR_CONSENSUS );
        end
        
        % update the appearance model
        cameraNetwork.LearnObjectsAppearancesAcrossDifferentViews( frameIndex );
        
        % visualize the output
        cameraNetwork.VisualizeNetworkAnalysisOutput( );
        
    end%for frameIndex
    
    fprintf( '%s\n', '===============================End===================================' );
    
    % close the output stream
    cameraNetwork.CloseOutputStream( );
    
    % save the results
    cameraNetwork.SaveResults( );
catch ex
    fprintf( '%s\n', ex.message );
    fprintf( '%s\n', '===============================Exception Stack========================');
    fprintf( '%s\n',[ex.stack.file] );
    fprintf( '%s\n', [ex.stack.line] );
    fprintf( '%s\n', [ex.stack.name] );
    fprintf( '%s\n', '===============================End===================================' );
end