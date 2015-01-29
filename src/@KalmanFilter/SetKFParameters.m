%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function sets the parameters of the KF based on the intial state
%
%   Input --   
%       @m      - dimension of the state vector
%       @p      - dimension of the measurement vector
%       @option - state space model
%
%   Output -- 
%       @w      - Process Noise Variance (scalar)
%       @v      - Measurement Noise Variance (scalar)
%       @A      - State Transition Model
%       @H      - Measurement Model
%       @scale  - scale value
%
%   Author  -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ w, v, A, H, scale ] = SetKFParameters(m, p, option)

    switch option
        %State space of the form [x, y, velocityX, velocityY]
        case 1            
            w       =  KalmanFilter.PROCESS_NOISE_VARIANCE;         % Give a very low value of process noise
            v       =  KalmanFilter.MEASUREMENT_NOISE_VARIANCE;     % Measurement noise variance
            A       =  eye( m ); A( 1, 3 ) = 1; A( 2, 4 ) = 1;      % A = [ 1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1], constant accelaration model
            H       =  zeros( p, m ); H(1,1) = 1; H(2,2) = 1;       % H = [ 1 0 0 0; 0 1 0 0]
            scale   =  KalmanFilter.INITIAL_ERROR_COVARIANCE;        
        otherwise
            error('Option did not match for setting the DKF parameters.');
    end%switch

end % function
        
        
