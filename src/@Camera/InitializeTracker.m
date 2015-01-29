%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function initializes target manually.
%
%   Input -- 
%       @obj - camera object.
%       @frameNumber - Starting frame number
%       @objectIdList - Object ID List
%       @featureType - Feature Type for appearance modeling
%       @shouldUseConsensusBasedPositionOnlyForTraining - boolean  config
%       @isParticleFilterEnabled - Particle filter enabled or not
%
%   Output -- 
%       @obj - camera object
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = InitializeTracker(   obj,...
                                    frameNumber,...
                                    objectIdList,...
                                    featureType,...
                                    shouldUseConsensusBasedPositionOnlyForTraining,...
                                    isParticleFilterEnabled )
    
    obj.m_isParticleFilterEnabled   = isParticleFilterEnabled;
    initializationImageFrame        = obj.GetFrame( frameNumber );

    if obj.m_useInitMat
        load( [obj.m_scenarioPath filesep 'InputImages' filesep 'initRect.mat'] );
        initMat = initRect{obj.m_cameraID};
        for i = 1 : obj.m_numberOfObjects
           targetRect = initMat( objectIdList(i), : );
           
           if sum(targetRect) ~= 0
               obj.m_targetList{i} = Target( obj.m_cameraID,...
                                              objectIdList(i),...
                                              obj.GetHomography(),...
                                              obj.GetCameraModel(),...
                                              initializationImageFrame,...
                                              targetRect,...
                                              1,...
                                              Camera.ProjectToGroundPlane( targetRect, obj.GetHomography(), obj.GetCameraModel() ),...
                                              featureType,...
                                              shouldUseConsensusBasedPositionOnlyForTraining,...
                                              obj.m_trajectoryDatabase );
           else
               obj.m_targetList{i} = Target( obj.m_cameraID,...
                                           objectIdList(i),...
                                           obj.GetHomography( ),...
                                           obj.GetCameraModel( ) );
           end
        end
    else
        error( 'init file is missing' );
    end
    
    if ( obj.IsParticleFilterEnabled( ) )
        %Instantiate Particle Filters with all Particles at Init Position
        obj.InitializeParticleFilter( );
    end    
end  %function