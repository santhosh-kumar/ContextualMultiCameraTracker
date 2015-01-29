%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function performs consensus based on Alternating Direction Method
%   of Multipliers
%
%   Input -- 
%       @cameraNetwork                          - Structure containing the camera networks.
%       @maximumNumberOfConsensusIterations     - Maximum number of consensus iterations
%       @shouldUseDynamicContext                - Should use dynamic scene context
%       @shouldUseStaticContext                 - Should use static scene context
%       @shouldUseSpatialContext                - Should use spatial context
%
%   Output -- 
%       @cameraNetwork - Structure containing the camera networks
%
%   Author  -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cameraNetwork = PerformADMMBasedConsensus( cameraNetwork,...
                                                    maximumNumberOfConsensusIterations,...
                                                    shouldUseDynamicContext,...
                                                    shouldUseStaticContext,...
                                                    shouldUseSpatialContext )
                                             
    numberOfIteration = 1;
    
    %lambda - lagrangian multiplier
    lambda = ConsensusProtocol.LAMBDA;
    lambdas = repmat( lambda, cameraNetwork.GetNumberOfCameras( ), cameraNetwork.GetCameraObject( 1 ).GetNumberOfTargets( ) );
    
    while numberOfIteration <= maximumNumberOfConsensusIterations
    
        %stores the consensus value of each target at each camera
        consensusValues = cell(  cameraNetwork.GetNumberOfCameras( ), cameraNetwork.GetCameraObject( 1 ).GetNumberOfTargets( ) );

        for cameraIndex = 1 : cameraNetwork.GetNumberOfCameras( )
            for targetIndex =  1 : cameraNetwork.GetCameraObject( 1 ).GetNumberOfTargets( ) 
                % continue if the object is not active
                if ~cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).IsActive()
                    continue;
                end

                % Collect measurements from neighborhood cameras
                [ zi, wi ] = ConsensusProtocol.CollectMeasurments( cameraNetwork,...
                                                                   cameraIndex,...
                                                                   targetIndex...
                                                                 );
                if (isempty(zi))
                    continue;
                end
                                                             
                currentLambda = lambdas{ cameraIndex, targetIndex };

                if ( shouldUseDynamicContext || shouldUseStaticContext ||  shouldUseSpatialContext )
                    if shouldUseDynamicContext
                        % Dynamic Sample from ground plane using Metro Polis Hastings Sampler
                        dynamicMPHSample = cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).GetAverageMPHSample()';
                    end
                    
                    if shouldUseStaticContext
                        z                           = sum([ zi(:,1) .* wi  zi(:,2) .* wi],1)';
                        trajectoryDatabase          = cameraNetwork.GetCameraObject( cameraIndex ).GetTrajectoryDatabase( );
                        staticExitSceneInformation  = trajectoryDatabase.GetStaticSceneInformation( z' )';
                    end
                    
                    if shouldUseSpatialContext
                        [ dij, zj ] = ConsensusProtocol.CollectContextInformation( cameraNetwork,...
                                                                                   cameraIndex,...
                                                                                   targetIndex );
                    end
                    
                    consensusValues{ cameraIndex, targetIndex } ...
                        = ConsensusProtocol.PerformConsensusByADMMWithSemanticKnowledge( zi,...
                                                                                         wi,...
                                                                                         currentLambda,...
                                                                                         dynamicMPHSample,...
                                                                                         staticExitSceneInformation,...
                                                                                         dij,...
                                                                                         zj...
                                                                                         );                    
                else
                    consensusValues{ cameraIndex, targetIndex } ...
                        = ConsensusProtocol.PerformConsensusByADMMWithoutSemanticKnowledge( zi,...
                                                                                            wi,...
                                                                                            currentLambda );
                
                end                
            end%targetIndex
        end%cameraIter

        %Update the target positions based on the posterior state
        for cameraIndex =  1 : cameraNetwork.GetNumberOfCameras( )
            for targetIndex =  1 : cameraNetwork.GetCameraObject( 1 ).GetNumberOfTargets( ) 

                consensusValue                  = consensusValues{ cameraIndex, targetIndex };
                if( isempty( consensusValue) )
                    continue;
                end
                
                groundPlanePosition             = [ consensusValue(1); consensusValue(2); 1 ];

                if ( cameraNetwork.GetCameraObject( cameraIndex ).IsTargetActive( targetIndex ) )

                    previousRectangle   =  cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).GetTargetRectangle( );
                    imagePlanePosition  = Camera.BackProjectToImagePlane( groundPlanePosition,...
                                                                        cameraNetwork.GetCameraObject( cameraIndex ).GetHomography( ),...
                                                                        cameraNetwork.GetCameraObject( cameraIndex ).GetCameraModel( ) );

                    fprintf( '%s\n', '' );                                                
                    fprintf( '%s\n', [ 'camera:' num2str(cameraIndex) ' target:' num2str(targetIndex) ] );
                    fprintf( '%s\n', [ 'Object Rectangle before consensus:' '[ ' num2str( cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).GetTargetRectangle( ) ) ' ]'] );
                    fprintf( '%s\n', [ 'Image Plane Position after consensus:' '[ ' num2str( imagePlanePosition' ) ']' ] );
                         
                    if numberOfIteration ==  maximumNumberOfConsensusIterations
                        %store the trajectory history
                        cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).UpdateTrajectoryOnTheGroundPlane( consensusValue' );
                        
                        % Update the Kalman Filter and Sampler
                        cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).UpdateKalmanFilter( imagePlanePosition );

                        % Update Particles with ground plane Kalman Posterior
                        cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).UpdateParticleWeightBasedOnKalmanPosterior();
                    end

                else

                    if ( numberOfIteration <  maximumNumberOfConsensusIterations )
                        % store the temporary message
                        cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).SetTemporaryMessageForConsensus( consensusValue );
                    else
                        cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).ResetTemporaryMessageForConsensus( );
                    end

                end

            end%targetIndex
        end%cameraIndex
        
        %update the lambdas
        for targetIndex =  1 : cameraNetwork.GetCameraObject( 1 ).GetNumberOfTargets( )
            for cameraIndex = 1 : cameraNetwork.GetNumberOfCameras( )
                % continue if the object is not active
                if ~cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).IsActive()
                    continue;
                end
                
                % Collect measurements from neighborhood cameras
                [ zi, wi ] = ConsensusProtocol.CollectMeasurments(  cameraNetwork,...
                                                                    cameraIndex,...
                                                                    targetIndex...
                                                                  );
                                                             
                if ( isempty(zi) )
                    continue;
                end
                                                             
                x = sum([ zi(:,1) .* wi  zi(:,2) .* wi])';
                
                lambdas{cameraIndex,targetIndex}  = lambdas{cameraIndex,targetIndex} + ( consensusValues{ cameraIndex, targetIndex } - x );
            end
        end
        
        numberOfIteration = numberOfIteration + 1;
    end
end%function