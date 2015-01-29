%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Predict the particle state with brownian motion
%
%   Input -- 
%       @obj - object of type ParticleFilter
%       @standardDeviationX -  x position standard deviation
%       @standardDeviationY -  y position standard deviation
%       @standardDeviationScaleX  -  x scale standard deviation
%       @standardDeviationScaleY  -  y scale standard deviation
%      
%   Output -- 
%       @obj - object of type ParticleFilter
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = Predict( obj,...
                        standardDeviationX,...
                        standardDeviationY,...
                        standardDeviationScaleX,...
                        standardDeviationScaleY )
    try
        assert( nargin == 5 );

        standardDeviationX        = max( 1e-10, standardDeviationX );
        standardDeviationY        = max( 1e-10, standardDeviationY );
        standardDeviationScaleX   = max( 1e-10, standardDeviationScaleX );
        standardDeviationScaleY   = max( 1e-10, standardDeviationScaleY );

        mu    = [ 0 0 0 0];
        sigma = [   standardDeviationX.^2 0 0 0;
                    0 standardDeviationY.^2 0 0;
                    0 0 standardDeviationScaleX.^2 0;
                    0 0 0 standardDeviationScaleY.^2 ];
                
        %cholesky factorization for getting a proper covariance matrix
        R = chol(sigma);

        z = repmat(mu,obj.m_numberOfParticles,1) + randn(obj.m_numberOfParticles, 4)*R;

        obj.m_stateMatrix( :, 1:obj.m_stateDimension ) = obj.m_stateMatrix(:, 1:obj.m_stateDimension) + z;

        % correct the maximum and minimum scales
        obj.m_stateMatrix( :, 3 ) = max(min( obj.m_stateMatrix( :, 3 ),...
                                   obj.m_maxScaleChange .* ones( obj.m_numberOfParticles, 1 ) ), obj.m_minScaleChange .* ones( obj.m_numberOfParticles, 1 ));

        obj.m_stateMatrix( :, 4 ) = max(min( obj.m_stateMatrix( :, 4 ),...
                                   obj.m_maxScaleChange .* ones( obj.m_numberOfParticles, 1 ) ), obj.m_minScaleChange .* ones( obj.m_numberOfParticles, 1 ));
        
        %increment the time index
        obj.m_timeIndex  = obj.m_timeIndex  + 1;

    catch ex
        error( [ 'Failed to predict particle filter:', ex] );
    end
    
end%function
