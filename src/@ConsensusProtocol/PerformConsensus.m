%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function performs consensus on the ground plane states
%
%   Input -- 
%       @cameraNetwork                          - Structure containing the camera networks
%       @useADMMBasedConsensus                  - Should use admm based consensus
%       @maximumNumberOfConsensusIterations     - Maximum number of consensus iterations
%       @shouldUseDynamicContext                - Should use dynamic scene context
%       @shouldUseStaticContext                 - Should use static scene context
%       @shouldUseSpatialContext                - Should use spatial context
%
%   Output -- 
%       @cameraNetwork - Structure containing the camera networks
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cameraNetwork = PerformConsensus( cameraNetwork,...
                                           useADMMBasedConsensus,...
                                           maximumNumberOfConsensusIterations,...
                                           shouldUseDynamicContext,...
                                           shouldUseStaticContext,...
                                           shouldUseSpatialContext )
    assert( nargin == 6 );

    % no consensus numberOfCameras <= 1
    if ( cameraNetwork.GetNumberOfCameras( ) <= 1 )
        return;
    end

    if useADMMBasedConsensus        
        cameraNetwork = ConsensusProtocol.PerformADMMBasedConsensus(  cameraNetwork,...
                                                                      maximumNumberOfConsensusIterations,...
                                                                      shouldUseDynamicContext,...
                                                                      shouldUseStaticContext,...
                                                                      shouldUseSpatialContext );
        
    else        
        error( 'Choose a proper consensus algorithm' );        
    end    
end
