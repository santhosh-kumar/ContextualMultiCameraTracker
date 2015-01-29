%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function performs consensus based on Alternating Direction Method
%   of Multipliers with semantic scene knowledge
%
%   Input -- 
%       @neighborMeasurements       - Structure containing the camera networks.
%       @measurementWeights         - Measurement weights
%       @lambda                     - Optimization constants
%       @dynamicPositionInformation - Dynamic Scene Context Information
%       @staticExitSceneInformation - Static Scene Context Information
%       @dij                        - Co-occurring Object Distances
%       @zj                         - Co-occurring Object Locations
%   Output -- 
%       @x - consensus state value
%
%   Author  -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ x ] = PerformConsensusByADMMWithSemanticKnowledge(  neighborMeasurements,...
                                                               measurementWeights,...
                                                               lambda,...
                                                               dynamicPositionInformation,...
                                                               staticExitSceneInformation,...
                                                               dij,...
                                                               zj )
 
    assert( size(neighborMeasurements,1) == length(measurementWeights) );
    
    %get the average measurement
    averageMeasurement = sum([ neighborMeasurements(:,1) .* measurementWeights  neighborMeasurements(:,2) .* measurementWeights],1)';
    nj = size(dij, 1);
    
    % Constants for optimization
    RHO      = ConsensusProtocol.RHO;
    ALPHA 	 = ConsensusProtocol.ALPHA;
    BETA     = ConsensusProtocol.BETA;
    GAMMA    = ConsensusProtocol.GAMMA;

    %CVX status
    cvx_status = [];
    
    n = length( averageMeasurement );
    try
        %Solve the convex optimization problem of the Lagrangian
        if ( ~isempty( dynamicPositionInformation ) && nj ~= 0 && ~isempty(staticExitSceneInformation) )
            cvx_begin
                variable x(n)

                minimize (  lambda' * ( x - averageMeasurement ) +...                   % part 1 of ADMM
                            ( RHO/2 ) .* norm(x-averageMeasurement,2) +...              % part 2 of ADMM
                            ALPHA * norm( x-dynamicPositionInformation,2)+...           % dynamic scene context
                            BETA *  norm( x-staticExitSceneInformation,2)+...           % static scene context
                            GAMMA * norm(( repmat(x',nj,1)-zj ), 2 ) ...                % spatial context
                         );
            cvx_end
        elseif isempty( dynamicPositionInformation ) && nj ~= 0
             cvx_begin
                variable x(n)

                minimize (  lambda' * ( x - averageMeasurement ) +...                   % part 1 of ADMM
                            ( RHO/2 ) .* norm(x-averageMeasurement,2) +...              % part 2 of ADMM
                             GAMMA * norm(( repmat(x',nj,1)-zj ), 2 ) ...               % spatial context 
                         );
            cvx_end
        elseif ~isempty( dynamicPositionInformation ) && ~isempty(staticExitSceneInformation) && nj == 0
             cvx_begin
                variable x(n)

                minimize (  lambda' * ( x - averageMeasurement ) +...                   % part 1 of ADMM
                            ( RHO/2 ) .* norm(x-averageMeasurement,2) +...              % part 2 of ADMM
                            ALPHA * norm( x-dynamicPositionInformation,2)+...           % dynamic scene context
                            BETA *  norm( x-staticExitSceneInformation,2)...            % static scene context
                         );
            cvx_end
        else
            cvx_begin
                variable x(n)

                minimize (  lambda' * ( x - averageMeasurement ) +...                   % part 1 of ADMM
                            ( RHO/2 ) .* norm(x-averageMeasurement,2) ...               % part 2 of ADMM
                        );
            cvx_end
        end
        
    catch
        x = averageMeasurement;
    end

    if ( isempty(cvx_status) || ~strcmp(cvx_status,'Solved') )
        x = averageMeasurement;
        fprintf( 'Error in CVX, Failed to Solve' );
    end
end