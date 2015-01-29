%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function collects contextual information from the given camera
%   view
%
%   Input -- 
%       @cameraNetwork - neighbor measurements
%       @cameraIndex
%       @targetIndex
%
%   Output -- 
%       @dij - distances in time t-1
%       @zij - current measurement on the ground plane of co-occurring
%       targets
%
%   Author  -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ dij, zj ] = CollectContextInformation( cameraNetwork,...
                                                  cameraIndex,...
                                                  targetIndex )
                                                
    targetLastState = cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetIndex ).GetLastStateOnGroundPlane( );
    dij             =[];
    zj              =[];

    for targetId = 1 : cameraNetwork.GetCameraObject( cameraIndex ).GetNumberOfTargets()        
        if  ( targetId ~= targetIndex && ...
                cameraNetwork.GetCameraObject( cameraIndex ).GetTarget(targetId).IsActive() )
            
            lastState = cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetId ).GetLastStateOnGroundPlane();
            dij = [ dij; (lastState'-targetLastState').^2 ];
            zj  = [ zj; cameraNetwork.GetCameraObject( cameraIndex ).GetTarget( targetId ).GetGroundPlaneLocation()];
            
        end
    end                       
                        
    %length should correspond
    assert( size(dij,1) == size(zj,1) );
end