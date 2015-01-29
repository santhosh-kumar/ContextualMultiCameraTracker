%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function sets up the camera network
%
%   Input --
%       void
%   Output -- 
%       @cameraNetwork          - Structure containing the camera networks
%       @frameRangeForAnalysis  - frame range
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ cameraNetwork,...
           frameRangeForAnalysis ] = setup( )
    
    fprintf( '\nSetting Up the Libraries...' );
    fprintf( '\n ############################################################' );
    
    % set up the necessary libraries
    addpath( Config.LIBS_FOLDER );
    addpath_recurse( Config.LIBS_FOLDER );
    
    % install cvx
    currentDirectory = pwd;
    cvx_setup;
    cd(currentDirectory);
    
    % set up 2d geometry toolbox
    setupGeom2d;
    cd(currentDirectory);
    
    fprintf('\n ############################################################');
    fprintf('Completed setting up the libraries... \n');
    
    fprintf('Setting up the camera network... \n');
    
    numberOfCameras         = Config.NUMBER_CAMERAS;
    numberOfObjects         = Config.NUMBER_OF_OBJECTS;
    frameRangeForAnalysis   = [ Config.INITIALIZATION_FRAME_NUMBER  (Config.INITIALIZATION_FRAME_NUMBER + Config.NUMBER_OF_FRAMES-1) ];
    cameraIndices           = Config.CAMERA_INDICES;
    objectIndices           = Config.OBJECT_INDICES;
    
    % Network Structure
    networkStructure.numberOfCamera           = numberOfCameras;
    networkStructure.trackWindow              = 1;
    networkStructure.boostWindow              = 2;
    networkStructure.interactWindow           = 3;
    networkStructure.spRows                   = numberOfCameras + 1;    
    networkStructure.spCols                   = 1;
    networkStructure.adjacencyMatrix          = TrajectoryDatabase.GetNetworkTopology(1, numberOfCameras);
    networkStructure.clock                    = 1;
    
    % Initialize camera network path
    homographFile           = '';
    cameraModelFile         = '';
    trajectoryDatabasePath  = [Config.DATA_FOLDER Config.DATASET filesep 'Scenario ' num2str(Config.SCENARIO) filesep 'TrajectoryDatabase'];
    if strcmp( Config.DATASET, 'UCSB' ) == 1
        homographFile   = [Config.DATA_FOLDER Config.DATASET filesep 'Scenario ' num2str(Config.SCENARIO) filesep 'Homography.mat'];
        trajectoryDatabase = TrajectoryDatabase( 6,...                      % numberOfCameras
                                                [3,3,3,3,3,3],...           % subsampleIndices     
                                                [30,20,23,20,27,31],...     % numberOfObjectsInEachCameraList
                                                [ 1, 2, 3, 4, 5, 6 ],...    % cameraIndices
                                                trajectoryDatabasePath,...  % databasePath
                                                0,...                       % shouldUseCameraModel
                                                { 1 2 3 4 5 6}...           % homographyIndices
                                                );
    elseif strcmp( Config.DATASET, 'PETS' ) == 1
        cameraModelFile = [Config.DATA_FOLDER Config.DATASET filesep 'Scenario ' num2str(Config.SCENARIO) filesep 'Calibration.mat'];
        trajectoryDatabase = TrajectoryDatabase( 7,...                      % numberOfCameras   
                                                [1,1,1,1,1,1,1],...         % subsampleIndices
                                                [50,66,81,72,72,67,121],... % numberOfObjectsInEachCameraList
                                                [ 1, 3, 4, 5, 6, 7, 8 ],... % cameraIndices
                                                trajectoryDatabasePath,...  % databasePath
                                                1,...                       % shouldUseCameraModel
                                                {}...                       % homographyIndices
                                                );
    else
        error( 'Choose a valid [PETS/UCSB] dataset in config file' );
    end

    % Create Objects for each camera with their respective data and camera attributes
    cameraNetwork = CameraNetwork( numberOfCameras,...
                                   numberOfObjects,...
                                   cameraIndices,...
                                   [Config.DATA_FOLDER Config.DATASET filesep 'Scenario ' num2str(Config.SCENARIO) filesep],...
                                   homographFile,...
                                   cameraModelFile,...
                                   frameRangeForAnalysis,...
                                   networkStructure,...
                                   trajectoryDatabase );
                              
   fprintf('Camera Network Setup Complete... \n');   
end%function