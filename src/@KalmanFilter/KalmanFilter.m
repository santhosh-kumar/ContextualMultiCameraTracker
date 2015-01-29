%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   A Kalman Filter implementation with constant acceleration 
%   Linear Motion Model
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef KalmanFilter < handle
    
    properties(GetAccess = 'public', SetAccess = 'private')
       %Dimensional Properties
       m;                   %Dimensionality of the State Vector(scalar)
       p;                   %Dimensionality of the measurement Vector(scalar)
       
       %Noise variances
       w;                   %Process Noise variance(scalar)
       v;                   %Measurement Noise Variance(scalar)
       
       %Noise covariances
       Q;                   %Process Noise Covariance(m x m)
       R;                   %Measurement Noise Covariance(p x p)
       
       %State Parameters
       A;                   %State Model(m x m)
       B;                   %Noise Transition matrix(m x m)
       H;                   %Measurement Model(p x m)
       
       Xposterior;          %Posterior State Vector(m x 1)
       Xprior;              %Prior State Vector(m x 1)
       P;                   %Posterior Error Covariance(m x m)
       
       XposteriorList;      %stores the Xposterior for all "T"
    end%properties

    properties(Constant)
        PROCESS_NOISE_VARIANCE       =  Config.KF_PROCESS_NOISE_VARIANCE;       % Process noise variance
        MEASUREMENT_NOISE_VARIANCE   =  Config.KF_MEAS_NOISE_VARIANCE;          % Measurement noise variance
        INITIAL_ERROR_COVARIANCE     =  Config.KF_INITIAL_ERROR_COVARIANCE;     % Initial Error Co-variance
    end%constant properties

    methods( Access = public )
        
        % Constructor
        function obj = KalmanFilter( m, p, w, v, x, A, H, scaleValue )
        
            assert( nargin == 8 );
            assert( m > 0 );
            assert( p > 0 );
            assert( ~isempty(A) );
            assert( ~isempty(H) );
            assert( length(x) == m );
            assert( w ~= 0 );
            assert( v ~= 0 );

            %Set the parameters
            obj.m = m;
            obj.p = p;

            obj.w = w;
            obj.v = v;

            obj.A = A;
            obj.H = H;
            obj.B = eye(m);
            obj.P = scaleValue .* eye(m); %Though initial measurement is known precisely, give a non-zero error covariance

            obj.XposteriorList{1} = x;
            obj.Xposterior        = x;
            obj.Xprior            = zeros(m, 1);

            obj.Q = w .* eye(m);
            obj.R = v .* eye(p);
        end
        
        % Predict the state of the Kalman filter
        function obj = Predict( obj )
            %x' = Ax
            obj.Xprior = obj.A * obj.Xposterior;
            obj.P      = obj.A * obj.P  * (obj.A)' + obj.Q;         
        end
        
        % Update the state with the measurement
        function obj = Update( obj, z )
        
            yHat = z - obj.H * obj.Xprior;
            S    = obj.H * obj.P * (obj.H)' + obj.R;
            K    = obj.P * (obj.H)' * ( eye(obj.p) / S );
            
            % Kalman update equation
            obj.Xposterior = obj.Xprior + K * yHat;
            obj.P          = (eye(obj.m) - K*obj.H) * obj.P;
            
            %store for processing
            timeIndex                       = numel(obj.XposteriorList);
            obj.XposteriorList{timeIndex+1} = obj.Xposterior;
        end
        
        % Get the posteior of Kalman
        function posteriorState = GetPosteriorState(obj)
            assert( ~isempty(obj.Xposterior));
            posteriorState = obj.Xposterior(1:2);
        end
        
        % Evaluate posterior state density
        function prob = EvaluatePosteriorDensity( obj,...
                                                  x )
             d          = length( x );
             sigma      = obj.P( 1:d, 1:d );
             cholSig    = chol(sigma);
             mu         = obj.Xposterior(1:d);
             prob       = mvnormpdf( x', mu, [], cholSig );
             
             assert( prob >= 0  && prob <= 1 );
        end
        
        %Evaluate Density on a List
        function probabilityList = EvaluatePosteriorDensityList( obj, x )
            n = size( x, 1 );
            probabilityList = zeros( n,1);
            
            for i = 1 : n
                probabilityList(i) = obj.EvaluatePosteriorDensity( x(i,:)' );
            end
        end

    end%methods public

    methods(Static)
        % set the default parameters for KF
        [ w, v, A, H, scale ] = SetKFParameters( m,...
                                                 p,...
                                                 option );                                             
    end%static methods   
end%classdef