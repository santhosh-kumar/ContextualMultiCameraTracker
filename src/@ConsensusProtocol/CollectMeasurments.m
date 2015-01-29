%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function collects measurements from different cameras for the 
%   specified object.
%
%   Input -- 
%       @cameraNetwork  - Structure containing the camera networks.
%       @cameraIndex    - camera index
%       @targetIndex    - target index
%
%   Output -- 
%       @zi - measurement matrix
%       @wi - weights of measurements
%
%   Author  -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ zi, wi, yi, Si, xPriors ] = CollectMeasurments(   cameraNetwork,...
                                                             cameraIndex,...
                                                             targetIndex )
    networkStructure = cameraNetwork.GetNetworkStructure( ); 
    assert( ~isempty( networkStructure ) );
    
    % initialize the output variable
    zi      = [];    % measurment matrix
    wi      = [];    % weight of each measurement( confidence )
    xPriors = {};
    yi      = {};
    Si      = {};

    measurementCount = 1;
    for otherCameraIndex = 1 : cameraNetwork.GetNumberOfCameras( )

        if networkStructure.adjacencyMatrix( cameraIndex, otherCameraIndex ) == 1

            groundPlaneMeasurement = cameraNetwork.GetCameraObject( otherCameraIndex ).GetTarget( targetIndex ).GetGroundPlaneLocation( );
            if isempty( groundPlaneMeasurement ) 
                continue;
            end
            zi( measurementCount, : ) = groundPlaneMeasurement;
            wi(measurementCount) = 1;
            measurementCount = measurementCount + 1;

        end

    end

    %normalize the weights
    wi = wi' ./ norm( wi, 1 );    
end% function