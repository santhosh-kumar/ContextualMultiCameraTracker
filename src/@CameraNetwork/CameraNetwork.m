%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CameraNetwork class stores all the information about the network.
%   Derives from HANDLE class, so any changes to the obj need not use "=" 
%   operator.
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef CameraNetwork < handle
    
    properties(GetAccess = 'public', SetAccess = 'private')        
        m_numberOfCameras;
        m_numberOfObjects;
        m_cameraList;
        m_scenarioPath;
        m_homographyMatFilePath;
        m_calibrationMatFilePath;
        m_networkStructure;
        m_trajectoryDatabase;
    end%properties

    properties(Constant)
    end%constant properties

    methods( Access = public )
        
        % Constructor
        function obj = CameraNetwork( numberOfCameras,...
                                      numberOfObjects,...
                                      cameraIdList,...
                                      scenarioPath,...
                                      homographyFilePath,...
                                      calibrationFilePath,...
                                      frameRangeForAnalysis,...
                                      networkStructure,...
                                      trajectoryDatabase )
                                  
            assert( nargin == 9 );
            
            try
                obj.m_numberOfCameras           = numberOfCameras;
                obj.m_numberOfObjects           = numberOfObjects;
                obj.m_scenarioPath              = scenarioPath;
                obj.m_homographyMatFilePath     = homographyFilePath;
                obj.m_calibrationMatFilePath    = calibrationFilePath;
                obj.m_networkStructure          = networkStructure;
                obj.m_trajectoryDatabase        = trajectoryDatabase;
                
                for cameraIndex = 1 : numberOfCameras
                    inputImagesPath = [ scenarioPath filesep 'InputImages' ];
                    obj.m_cameraList{cameraIndex} = Camera( cameraIdList( cameraIndex ),...                                 
                                                            numberOfObjects,...                                             
                                                            [ inputImagesPath filesep 'C' num2str( cameraIdList( cameraIndex ) ) ],... 
                                                            homographyFilePath,...                                          
                                                            calibrationFilePath,...
                                                            frameRangeForAnalysis,...
                                                            find( networkStructure.adjacencyMatrix( cameraIndex, : ) == 1  ),...
                                                            scenarioPath,...
                                                            obj.m_trajectoryDatabase );

                end            
            catch ex
                throwAsCaller(ex);
            end
        end
        
        % Get camera object
        function cameraObject = GetCameraObject( obj, cameraIndex )
            assert( cameraIndex <= obj.m_numberOfCameras );
            cameraObject = obj.m_cameraList{ cameraIndex };
        end
        
        % Get number of cameras in the network
        function numberOfCameras = GetNumberOfCameras( obj )
            numberOfCameras = obj.m_numberOfCameras;
        end
        
        % Get Network Structure
        function networkStructure = GetNetworkStructure( obj )
            assert( ~isempty( obj.m_networkStructure) );
            networkStructure = obj.m_networkStructure;
        end
        
        % Initialize Tracker across different views
        function obj = InitializeTrackerAcrossDifferentViews(   obj,...
                                                                initializationFrameNumber,...
                                                                objectIdList,...
                                                                featureType,...
                                                                shouldUseConsensusBasedPositionOnlyForTraining,...
                                                                shouldUseParticleFiltering )
            assert( initializationFrameNumber > 0 );
            
            for cameraIndex = 1 : obj.m_numberOfCameras
                obj.GetCameraObject( cameraIndex ).InitializeTracker( initializationFrameNumber,...
                                                                      objectIdList,...
                                                                      featureType,...
                                                                      shouldUseConsensusBasedPositionOnlyForTraining,...
                                                                      shouldUseParticleFiltering );
            end
        end
        
        % Track object across different views for the specified frame
        function obj = TrackObjectsAcrossDifferentViews( obj, frameNumber )
            try
                assert( frameNumber > 0 );
                obj.IncrementClock( );
                for cameraIndex = 1 : obj.m_numberOfCameras
                    obj.GetCameraObject( cameraIndex ).TrackObjectsOnTheGivenFrame( frameNumber );
                end
            catch ex 
                throwAsCaller(ex);
            end
        end
        
        % Learn the object appearance model across different views
        function obj = LearnObjectsAppearancesAcrossDifferentViews( obj, frameNumber )
            try
                assert( frameNumber > 0 );

                %collect weak classifiers from the other views
                weakClassifierList = obj.CollectWeakClassifiers( );
                for cameraIndex = 1 : obj.m_numberOfCameras
                   obj.GetCameraObject( cameraIndex ).UpdateObjectsAppearancesOnTheGivenFrame( frameNumber, weakClassifierList );
                end
            catch ex
                throwAsCaller( ex );
            end
        end
        
        % Increment network clock
        function obj = IncrementClock( obj )
             obj.m_networkStructure.clock = obj.m_networkStructure.clock + 1;
        end
        
        % Visualize Network Analysis output
        function obj = VisualizeNetworkAnalysisOutput( obj )
            for cameraIndex = 1 : obj.m_numberOfCameras
                obj.GetCameraObject( cameraIndex ).VisualizeTrackerOutput( obj.m_networkStructure );
            end
        end
        
        % Close the output streams
        function obj = CloseOutputStream( obj )
             for cameraIndex = 1 : obj.m_numberOfCameras
                obj.GetCameraObject( cameraIndex ).CloseOutputStream( );
            end
        end
        
        % Collect Best Weak Classifiers from multiple views
        function weakClassifierList = CollectWeakClassifiers( obj )
            weakClassifierList = cell( 1, obj.m_numberOfObjects );
            
            for targetIndex = 1 : obj.m_numberOfObjects
                
                mergedWeakClassifiers = [];
                for cameraIndex = 1 : obj.m_numberOfCameras
                    weakClassifiers = obj.GetCameraObject( cameraIndex ).GetBestPerformingWeakClassifiers( targetIndex );
                    for weakClassifierId = 1 : length(weakClassifiers);
                        mergedWeakClassifiers = [ mergedWeakClassifiers; weakClassifiers{weakClassifierId} ];
                    end
                end
                
                % weak classifiers are organized by objects
                weakClassifierList{targetIndex} = mergedWeakClassifiers;
            end
        end
        
        % Save results on a mat file
        function SaveResults( obj )            
            results.numberOfCameras = obj.m_numberOfCameras;
            results.numberOfObjects = obj.GetCameraObject( 1 ).GetNumberOfTargets();
            
            for i = 1 : obj.m_numberOfCameras 
                for j = 1 : obj.GetCameraObject( 1 ).GetNumberOfTargets()
                    results.imagePlaneRectangles{i,j} = obj.GetCameraObject(i).GetTarget(j).GetImagePlaneTrajectoryHistory();
                    results.groundPlanePositions{i,j} = obj.GetCameraObject(i).GetTarget(j).GetGroundPlaneTrajectoryHistory();
                end
            end
            
            %save the results
            save([obj.m_scenarioPath filesep 'results.mat'], 'results');
        end        
    end%methods public

    methods( Access = private )
    end%methods private

    methods(Static)
    end%static methods   
end%classdef