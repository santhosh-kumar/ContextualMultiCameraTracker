%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This Class is the heart of the entire analysis framework.
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%
%   NOTE: Important RECT = [XMIN YMIN WIDTH HEIGHT]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Camera < handle
    
    properties(GetAccess = 'public', SetAccess = 'private')        
        % Camera Attributes
        m_cameraID;                         % Scalar containing the cameraID in the network
        m_homographyMatrix;                 % Homography projecting point to ground plane
        m_cameraModel;                      % Camera Calibration Model
        m_multiMediaObject;                 % Multimedia Object 
        m_videoFrames;                      % Data, or frames stored in a 4D array
        m_useInitMat;                       % use auto-init mat       
        m_trajectoryDatabase;               % trajectory database
        m_scenarioPath;                     % scenario path
        
        %target attributes
        m_numberOfObjects;                  % Number of objects in camera
        m_targetList;                       % Cell array of detected targets found by the detector
        m_neighborCameraIds;                % A vector of neighborhood cameras
        m_isParticleFilterEnabled;          % is particle filter enabled        
    end
    
    properties(GetAccess = 'public', SetAccess = 'public' )
        %output attributes
        m_outputObj;                        %output video object
    end
    
    properties (Constant)
        IMAGE_FORMAT                       = Config.IMAGE_FORMAT;
        OUTPUT_RECTANGLE_COLOR             = Config.OUTPUT_RECTANGLE_COLOR;
    end
    
    methods( Access = public )
        
        % Constructor
        function obj = Camera(  cameraID,...
                                numberOfObjects,...
                                inputVideoPath,...
                                homographyMATFilePath,...
                                calibrationFilePath,...
                                frameRangeForAnalysis,...
                                neighborCameraIds,...
                                scenarioPath,...
                                trajectoryDatabase )
                            
            try
                obj                         = obj.SetCameraID( cameraID );
                obj.m_numberOfObjects       = numberOfObjects;
                obj.m_neighborCameraIds     = neighborCameraIds;
                obj.m_trajectoryDatabase    = trajectoryDatabase;
                obj.m_scenarioPath          = scenarioPath;
                
                obj                     = obj.ReadVideo( inputVideoPath, frameRangeForAnalysis );
                
                %read the homography from the mat file
                if ~isempty( homographyMATFilePath )
                    obj                 = obj.ReadHomographyFromMATFile( homographyMATFilePath );
                end
                
                %read and create the camera model if the calibration matrix
                %is available
                if ~isempty( calibrationFilePath )
                    obj                 = obj.ReadCalibrationStruct( calibrationFilePath );
                else
                    obj.m_cameraModel   = [];
                end
                
                obj.m_outputObj = VideoWriter( fullfile(scenarioPath, ['C' int2str( cameraID ) '_out'] ) );
                
                %set the video parameters
                obj.m_outputObj.FrameRate = 5;
                obj.m_outputObj.Quality = 100;
                
                open(obj.m_outputObj);
                                
                %use auto-init mat
                obj.m_useInitMat = 1; 
            catch ex
                throwAsCaller( ex );
            end
        end
        
        % Camera Attributes
        function obj = SetCameraID( obj, cameraID )
            assert( ~isempty( cameraID ) );
            obj.m_cameraID = cameraID;
        end
        
        % Get Camera ID
        function cameraID = GetCameraID( obj )
            cameraID = obj.m_cameraID;
        end
        
        % Set Homography matrix
        function obj = SetHomography( obj, homographyMatrix )
            assert( ~isempty( homographyMatrix ) );
            obj.m_homographyMatrix =  homographyMatrix;
        end
        
        % Get homography 
        function homographyList = GetHomography(obj)
            homographyList = obj.m_homographyMatrix;
        end
        
        % Get camera model
        function cameraModel = GetCameraModel(obj)
            cameraModel = obj.m_cameraModel;
        end
        
        % Read video from the video file
        function obj = ReadVideo( obj, videoPath, frameRangeForAnalysis )
            obj.m_videoFrames = Camera.ReadVideosFromImages( videoPath, frameRangeForAnalysis );
        end
        
        % Read homography matrix from the .mat file
        function obj = ReadHomographyFromMATFile( obj, homographyMATFilePath )
            load( homographyMATFilePath ); 
            obj.m_homographyMatrix = Homography{obj.m_cameraID}; %#ok<USENS>
        end
        
        % Read Calibration Struct from Calibration mat
        function obj = ReadCalibrationStruct( obj, calibrationFilePath )
           load(calibrationFilePath)
           obj.m_cameraModel = CameraModel( Calibration{ obj.m_cameraID } );%#ok<USENS>
        end
        
        % Get the video based on the specified frame number
        function frameImage = GetFrame( obj, frameNumber )
            assert( ~isempty(obj.m_videoFrames) );
            frameImage = obj.m_videoFrames(:,:,:,frameNumber);
        end
        
        %Get Frame Resolution
        function [imageHeight,imageWidth] = GetFrameResolution( obj )
            assert( ~isempty(obj.m_videoFrames) );
            [imageHeight,imageWidth,~] = size( obj.m_videoFrames(:,:,:, 1) );
        end
        
        % Get number of targets
        function numberOfTargets = GetNumberOfTargets( obj )
            numberOfTargets = obj.m_numberOfObjects;
        end
        
        % Get the target
        function target = GetTarget( obj, targetIndex )
            assert( targetIndex  <= obj.m_numberOfObjects );
            target = obj.m_targetList{targetIndex};
        end
             
        % Check if the particle filter is enabled or not
        function isParticleFilterEnabled = IsParticleFilterEnabled( obj )
            isParticleFilterEnabled = obj.m_isParticleFilterEnabled;
        end
        
        % Checks if the specified target is active or not
        function isTargetActive = IsTargetActive( obj, objectIndex )
            assert( objectIndex <= obj.m_numberOfObjects );
            isTargetActive = obj.m_targetList{objectIndex}.IsActive();
        end
        
        % Set the number of particles
        function obj = SetNumberOfParticles( obj, numberOfParticles )
            for targetIndex = 1 : obj.m_numberOfObjects
                obj.m_targetList{targetIndex}.SetNumberOfParticles( numberOfParticles ); 
            end
        end
        
        % Add frame to the output stream
        function obj = AddFrameToOutputStream( obj, outputFrame )
            if ( ~isempty( obj.m_outputObj ) )
                writeVideo( obj.m_outputObj, outputFrame);
            end
        end
        
        % Close the output stream
        function obj = CloseOutputStream( obj )
            if ( ~isempty(obj.m_outputObj) )
                close(obj.m_outputObj);
            end
        end
        
        % Initialize Particle Filter
        function obj = InitializeParticleFilter( obj )
            try
                [imageHeight,imageWidth] = obj.GetFrameResolution( );
                
                for targetIndex = 1 : obj.m_numberOfObjects
                    %initialize only for the active targets
                    if ( obj.m_targetList{targetIndex}.IsActive() )
                        obj.m_targetList{targetIndex}.InitializeParticleFilter( imageHeight,...
                                                                                imageWidth ); 
                    end
                end
            catch ex
                fprintf('Failed to initialize particle filter.');
                throwAsCaller(ex);
            end
        end
        
        % Track the objects on the given frame
        function obj = TrackObjectsOnTheGivenFrame( obj, frameNumber )
            try
                assert( frameNumber > 0 );
                frameImage = obj.GetFrame( frameNumber );
                for targetIndex = 1 : obj.m_numberOfObjects
                    previousFrameOtherObjectRectangles = [];
                    for otherTargetIndex = 1 : obj.m_numberOfObjects
                        if otherTargetIndex ~= targetIndex
                            previousFrameOtherObjectRectangles = [previousFrameOtherObjectRectangles;...
                                                                  obj.m_targetList{ otherTargetIndex }.GetTargetRectangle( )];
                        end
                    end
                    
                    obj.m_targetList{ targetIndex }.TrackObjectOnTheGivenFrame( frameImage, previousFrameOtherObjectRectangles );
                end
            catch ex
                fprintf( 'Failed to TrackObjectOnTheGivenFrame' );
                throwAsCaller(ex);
            end
        end
        
        % Get best performing weak classifiers
        function weakClassifierList = GetBestPerformingWeakClassifiers( obj, targetIndex )
            assert( targetIndex <= numel( obj.m_targetList ) );
            weakClassifierList = obj.m_targetList{ targetIndex }.GetBestPerformingWeakClassifiers( );
        end
        
        % Track the objects on the given frame
        function obj = UpdateObjectsAppearancesOnTheGivenFrame( obj, frameNumber, weakClassifierList )
            try
                assert( frameNumber > 0 );
                frameImage = obj.GetFrame( frameNumber );
                
                %Get negative examples from other correlated objects on the scene
                negativeSamplesList = obj.CollectNegativeExamples( weakClassifierList );
                
                for targetIndex = 1 : obj.m_numberOfObjects
                    obj.m_targetList{ targetIndex }.UpdateAppearanceModel( frameImage,...
                                                                           weakClassifierList{targetIndex},...
                                                                           Camera.GetNegativeSamples( negativeSamplesList, targetIndex )...
                                                                         );
                end
            catch ex
                throwAsCaller(ex);
            end
        end
        
        % Collect Negative examples for tracking - a list of negative samples ordered by objects
        function negativeExampleList = CollectNegativeExamples( obj, weakClassifierList )
            assert( ~isempty(weakClassifierList) );
            negativeExampleList = cell(obj.GetNumberOfTargets( ),1);
            for targetIndex = 1 : obj.GetNumberOfTargets( )
                negativeExampleList{targetIndex} = obj.m_targetList{targetIndex}.GetNegativeSamples( weakClassifierList{targetIndex} );
            end
        end

        % Get the trajectory database
        function trajectoryDatabase = GetTrajectoryDatabase(obj)
            trajectoryDatabase = obj.m_trajectoryDatabase;
        end        
    end % non-static methods
    
    methods(Static)
        
        % Reads videos from the image folder
        function sequence = ReadVideosFromImages( path, frameRange )
            dirOutput = dir(fullfile(path, ['*' Camera.IMAGE_FORMAT]));
            fileNames = sort({dirOutput.name})';
            
            numFrames = frameRange(2)-frameRange(1)+1;

            I = imread(fullfile(path,fileNames{frameRange(1)}));

            % Preallocate the array
            sequence = zeros([size(I) numFrames],class(I));

            % Create image sequence array
            for p = frameRange(1) : frameRange(2)
                sequence(:,:,:, p) = imread(fullfile(path,fileNames{p})); 
            end
        end
        
        % Get negative samples for a given target
        function negativeSamples = GetNegativeSamples(  negativeSampleList, targetId )
            assert( nargin == 2 );
            negativeSamples = [] ;
            
            if isempty( negativeSampleList )
                return;
            end
            
            for i = 1 : numel(negativeSampleList)
                if targetId ~= i
                    negativeSamples = [ negativeSamples negativeSampleList{i} ];
                end
            end
        end
        
        % Draw rectangle on the frame at the specified location 
        function DrawRectangle( inputRect, colorCode, lineWidth )
            x_line = [inputRect(1) inputRect(1)               inputRect(1)+inputRect(3) inputRect(1)+inputRect(3) inputRect(1)]; 
            y_line = [inputRect(2) inputRect(2)+inputRect(4)  inputRect(2)+inputRect(4) inputRect(2)              inputRect(2)]; 

            line( x_line, y_line, 'color', colorCode, 'LineWidth', lineWidth );
        end 
        
        % Project to the ground plane using the homography
        function groundPositions = ProjectToGroundPlane( objectRectangle, homoGraphy, cameraModel )
            groundPositions = [];
            if isempty(homoGraphy) && isempty(cameraModel)
                return;
            end
            
            assert( size ( objectRectangle, 2 ) == 4 );
            numberOfRectangles = size( objectRectangle, 1 );
            groundPositions = zeros( numberOfRectangles, 2 );

            for rectangleIter = 1 : numberOfRectangles
                 if isempty(cameraModel)
                    imagePosition                       = [ objectRectangle( rectangleIter, 1 ) + ( objectRectangle( rectangleIter, 3 )/2 ); objectRectangle( rectangleIter, 2 ) + objectRectangle( rectangleIter, 4 ); 1];
                    assert( ~isempty( homoGraphy ) );
                    gpTemp                              = homoGraphy * imagePosition;
                    groundPositions( rectangleIter, : ) = [gpTemp(1)/gpTemp(3); gpTemp(2)/gpTemp(3)]';
                 else
                    imagePosition  = [ objectRectangle( rectangleIter, 1 ) + ( objectRectangle( rectangleIter, 3 )/2 ); objectRectangle( rectangleIter, 2 ) + objectRectangle( rectangleIter, 4 )];
                    worldPosition =  cameraModel.ImageToWorld( imagePosition )';
                    groundPositions( rectangleIter, : ) = worldPosition(1:2);
                 end
            end
        end
        
        % Back project to the image plane
        function imagePlanePosition = BackProjectToImagePlane( groundPlanePosition,...
                                                               homoGraphy,...
                                                               cameraModel )                                         
            assert( length(groundPlanePosition) == 3 ); %[ x;y;1]
            
            if isempty(cameraModel)
                assert( ~isempty(homoGraphy) );
                backProjectedPosition   = (eye(3)/homoGraphy) * groundPlanePosition;
                imagePlanePosition      = [ backProjectedPosition(1)/backProjectedPosition(3); backProjectedPosition(2)/backProjectedPosition(3) ];
            else
                groundPlanePosition(3)  = 0;
                imagePlanePosition      = cameraModel.WorldToImage( groundPlanePosition );
            end
        end
        
        % Get the medial axis of the object
        function axisLine = GetAxisLine( objectRectangle, homoGraphy )
            assert( ~isempty( homoGraphy ) );
            assert( size (objectRectangle, 2 ) == 4 );
            
            startPointTemp = homoGraphy * [ objectRectangle(1) + objectRectangle(3)/2; objectRectangle(2); 1 ];
            endPointTemp   = homoGraphy * [ objectRectangle(1) + objectRectangle(3)/2; objectRectangle(2) + objectRectangle(4); 1 ];
            
            startPoint = [ startPointTemp(1)./startPointTemp(3) startPointTemp(2)./startPointTemp(3) ];
            endPoint   = [ endPointTemp(1)./endPointTemp(3) endPointTemp(2)./endPointTemp(3) ];
            
            axisLine = createLine( startPoint, endPoint );
            
            assert( ~isempty(axisLine) );
        end
    end%static methods
end