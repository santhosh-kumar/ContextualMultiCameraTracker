%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function performs consensus based on Alternating Direction Method
%   of Multipliers without semantic knowledge
%
%   Input -- 
%       @neighborMeasurements - neighbor measurements
%
%   Output -- 
%       @x - consensus state
%
%   Author  -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function x = PerformConsensusByADMMWithoutSemanticKnowledge(  neighborMeasurements,...
                                                              measurementWeights,...
                                                              lambda  )
    averageMeasurement =  sum([ neighborMeasurements(:,1) .* measurementWeights  neighborMeasurements(:,2) .* measurementWeights], 1)';

    n        = length( averageMeasurement );
    RHO      = ConsensusProtocol.RHO;
    
    %Solve the convex optimization problem of the Lagrangian
    try
        cvx_begin
            variable x(n)
            minimize ( lambda' * ( x - averageMeasurement ) +...
                       (RHO/2) .* norm(x-averageMeasurement,2) );
        cvx_end

        if(~strcmp(cvx_status,'Solved'))
           x = averageMeasurement;
           fprintf('Error in CVX, Failed to Solve');
        end
    catch
        x = averageMeasurement;
    end
end