%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This class implements particle filter.
%
%   Reference:
%       A Tutorial on Particle Filters for Online
%       Nonlinear/Non-Gaussian Bayesian Tracking
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef ParticleFilter < handle
    properties(GetAccess = 'public', SetAccess = 'private')       
        m_numberOfParticles;
        m_objectRectangle;
        m_imageHeight;
        m_imageWidth;
        
        m_timeIndex;
        m_maxScaleChange;
        m_minScaleChange;
        m_maxScaleChangeInOneInterval;
        
        m_stateDimension;
        m_stateMatrix; %[ x, y, scaleX, scaleY, weight ]        
    end%properties

    properties(Constant)
        PARTICLES_RESAMPLING_THRESHOLD      = Config.PARTICLES_RESAMPLING_THRESHOLD;
        RESAMPLING_STRATEGY                 = Config.RESAMPLING_STRATEGY;
        NUMBER_OF_PARTICLES_TO_DISPLAY      = Config.NUMBER_OF_PARTICLES_TO_DISPLAY;
        NUMBER_OF_PARTICLES                 = Config.NUMBER_PARTICLES;
        MAX_SCALE_CHANGE_IN_ONE_INTERVAL    = Config.MAX_SCALE_CHANGE_IN_ONE_INTERVAL;
        MAX_SCALE_CHANGE                    = Config.MAX_SCALE_CHANGE;
        MIN_SCALE_CHANGE                    = Config.MIN_SCALE_CHANGE;
        STD_POSITION_X                      = Config.STD_POSITION_X;
        STD_POSITION_Y                      = Config.STD_POSITION_Y;
        STD_SCALE_X                         = Config.STD_SCALE_X;
        STD_SCALE_Y                         = Config.STD_SCALE_Y;
        ENABLE_MEAN_SHIFT_REWEIGHTING       = Config.ENABLE_MEAN_SHIFT_REWEIGHTING;
        USE_TOP_N_FOR_AVERAGE               = Config.USE_TOP_N_FOR_AVERAGE;
        PERCENTAGE_TOP_N                    = Config.PERCENTAGE_TOP_N;
    end%constant properties

    methods( Access = public )

        %constructor
        function obj = ParticleFilter(  objectRectangle,...
                                        imageHeight,...
                                        imageWidth,...
                                        particleStateDimension )
            try
                assert( nargin == 4 );

                %Set the initial parameters for particle filter.
                obj.m_numberOfParticles = ParticleFilter.NUMBER_OF_PARTICLES;
                obj.m_objectRectangle   = objectRectangle;
                obj.m_imageHeight       = imageHeight;
                obj.m_imageWidth        = imageWidth;
                obj.m_stateDimension    = particleStateDimension;
                obj.m_timeIndex         = 0;
                obj.m_stateMatrix       = zeros( ParticleFilter.NUMBER_OF_PARTICLES, particleStateDimension+1 );
                     
            catch ex
                error( [ 'Failed to construct particle Filter:' ex ] );
            end
        end

        %initialize the particle filter
        obj = Initialize(  obj,...
                           centerX,...
                           centerY,...
                           scaleX,...
                           scaleY,...
                           maxScaleChangeInOneInterval,...
                           maxScaleChange,...
                           minScaleChange );

        %predict the state with brownian motion
        obj = Predict(  obj,...
                        standardDeviationX,...
                        standardDeviationY,...
                        standardDeviationScaleX,...
                        standardDeviationScaleY,...
                        currentWidth,...
                        currentHeight );
        
        %update the particle weights
        obj = Update( obj,...
                      weightList );
                 
        %displayParticles on the image plane
        DisplayParticles( obj, imageFrame, figureHandle );
                
        % Getters
        function weightList = GetWeightList( obj )
            weightList = obj.m_stateMatrix(:, obj.m_stateDimension+1 );
        end
        
        % Get particle for the given index
        function particle = GetParticle( obj, index )
            particle = obj.m_stateMatrix( index, 1 : 4 );
        end
        
        % Set Particle for the given index
        function obj = SetParticle( obj, index, particle )
            obj.m_stateMatrix(index, 1:obj.m_stateDimension) = particle;
        end
        
        % Get Number of Particles
        function numberOfParticles = GetNumberOfParticles( obj )
           numberOfParticles = obj.m_numberOfParticles;
        end
        
        %Get Average Particle
        function averageParticle = GetAverageParticle( obj )
            if ParticleFilter.USE_TOP_N_FOR_AVERAGE
                numberOfParticles = floor(obj.m_numberOfParticles * ParticleFilter.PERCENTAGE_TOP_N / 100);
                particleList = obj.GetTopNParticles(numberOfParticles);                
            else
                numberOfParticles = obj.m_numberOfParticles;
                particleList = obj.m_stateMatrix;
            end
            
            totalWeight = sum( particleList(:, obj.m_stateDimension+1) );
            averageParticle = zeros( 4, 1 );

            for i = 1 : numberOfParticles
               averageParticle = averageParticle + particleList(i, 1:obj.m_stateDimension)' .* particleList(i, obj.m_stateDimension+1);
            end

            averageParticle = averageParticle ./ totalWeight;
        end
        
        %Get top N particles
        function particleList = GetTopNParticles( obj, N )
            assert( N > 0 );
            
            weightList = obj.GetWeightList( );
            [ ~, sortedIndex ] = sort( weightList, 1, 'descend' );
            
            assert( ~isempty(obj.m_stateMatrix) );
            
            particleList = obj.m_stateMatrix( sortedIndex(1:N), 1:obj.m_stateDimension+1 );
       
            assert( ~isempty(particleList) );
        end
        
        % Setters
        function obj = SetWeights( obj,...
                                   weightList )
            assert( length(weightList) == obj.m_numberOfParticles );
            obj.m_stateMatrix( :, obj.m_stateDimension+1 ) =  weightList;
        end
        
        % Set the weight
        function obj = SetWeight( obj,...
                                  weight,...
                                  index )
            assert( index <= obj.GetNumberOfParticles() );
            assert( weight >= 0  && weight <= 1);
            obj.m_stateMatrix( index, obj.m_stateDimension+1 ) = weight;
        end    
    end %methods public

    methods( Access = private )        
        % Resample - Systematic Resampling
        obj = Resample( obj );
        
        % Normalize particle weights
        function NormalizeParticleWeights( obj )
        
            weightList = obj.GetWeightList();
            
            normalizedWeightList = weightList ./ sum( weightList );
            
            % assign equals weights if all the weights are zero
            if sum( normalizedWeightList ) > 0 
                obj.m_stateMatrix( :, obj.m_stateDimension+1 ) = normalizedWeightList;
            else
                obj.m_stateMatrix( :, obj.m_stateDimension+1 ) = ones( obj.m_numberOfParticles, 1 );
            end
        end
        
        % Resample particles if required
        function ResampleIfRequired( obj )
            particleWeightList  = obj.m_stateMatrix( :, obj.m_stateDimension+1 );            
            sumWeightSquare     = sum( particleWeightList .^ 2 );
            nEffective          = 0;
            if sumWeightSquare ~= 0
                nEffective = ( 1 ./ sumWeightSquare );
            else
                obj.m_stateMatrix( :, obj.m_stateDimension+1 ) = ones( obj.m_numberOfParticles, 1 ) * (1/obj.m_numberOfParticles);
                return;
            end
            
            nThreshold = ParticleFilter.PARTICLES_RESAMPLING_THRESHOLD * obj.m_numberOfParticles;
            
            if nEffective < nThreshold
                obj.Resample();
            end
        end
    end%methods privates
end%classdef