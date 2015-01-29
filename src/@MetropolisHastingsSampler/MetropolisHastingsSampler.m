%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MetropolisHastingsSampler
%
%   This class implements the MetroPolisHastings Sampling Algorithm
%
%   Author -- Santhoshkumar Sunderrajan
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef MetropolisHastingsSampler < handle
    % member variables
    properties
       m_sampleMatrix;
       m_trajectoryDatabase;
       m_dataDimension;
       m_numberOfSamples;
       m_sigma;
       m_theta;
    end
    
    % Constant member variables
    properties(Constant)
        NUMBER_OF_SAMPLES = Config.MPHS_NUMBER_OF_SAMPLES;
    end   
    
    methods        
        % Constructor
        function obj = MetropolisHastingsSampler( trajectoryDatabase,...
                                                  numberOfSamples,...
                                                  dataDimension,...
                                                  x0 )
                                                  
              obj.m_trajectoryDatabase  = trajectoryDatabase;
              obj.m_sampleMatrix        = zeros( numberOfSamples, dataDimension );
              obj.m_dataDimension       = dataDimension;
              bw = trajectoryDatabase.GetKernelBandwidth( )';
              obj.m_sigma               = diag( bw(1,1:dataDimension).^2 );
              obj.m_theta               = x0;
              obj.m_numberOfSamples     = numberOfSamples;
        end
        
        % Samples from the posteior distribution
        function obj = Sample( obj )
            u       = obj.m_theta;           
            uProb   = obj.m_trajectoryDatabase.EvaluateKernel( [ u u ] );           
            
            obj.m_sampleMatrix( :, 1:obj.m_dataDimension ) = obj.SampleFromGaussian( obj.m_theta,...
                                                                                     obj.m_sigma ,...
                                                                                     obj.m_numberOfSamples,...
                                                                                     obj.m_dataDimension );
            Y = obj.m_sampleMatrix;
            
            for i = 1 : obj.m_numberOfSamples                 
                y       = Y(i,:);
                yProb   = obj.m_trajectoryDatabase.EvaluateKernel( [u y(1:obj.m_dataDimension)] );
                             
                r = obj.SampleFromUniformDistribution( 0, 1, 1, 1 );
                alpha = min( 1, (yProb./uProb) );
                
                if r <= alpha
                    obj.m_sampleMatrix(i,1:obj.m_dataDimension) = y;
                else
                    obj.m_sampleMatrix(i,1:obj.m_dataDimension) = u;
                end
            end
        end
        
        % Updates theta
        function obj = Update( obj, x )        
            assert( ~isempty(x) );
            obj.m_theta = x;
        end
        
        % Get the average sample
        function averageSample = GetWeightedAverageSample( obj )
            assert( ~isempty(obj.m_sampleMatrix) );            
            averageSample = mean(obj.m_sampleMatrix);
        end
    end
    
    methods(Static)
        
        % Sample from Gaussian distribution
        function z = SampleFromGaussian( mu,...
                                         sigma,...
                                         n,...
                                         d )
          assert( nargin == 4 );
          assert( d > 0 );
          assert( size(mu,2) == d );
          assert( size(sigma,1) == d && size(sigma,2) == d );
          assert( n >0 );
          
          R = chol(sigma);
          z = repmat(mu,n,1) + randn(n,d) * R;
        end
        
        % Sample from uniform distribution
        function z = SampleFromUniformDistribution( a,...
                                                    b,...
                                                    n,...
                                                    d )
            assert( nargin == 4 );
            assert( d > 0 );
            assert( size(a,1) == d );
            assert( size(b,1) == d );
            assert( n >0 );

            z = a + (b-a).*rand(n,d);
        end
    end
end