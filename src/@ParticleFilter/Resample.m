%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Resample particles
%
%   Input -- 
%       @obj - object of type ParticleFilter
%      
%   Output -- 
%       @obj - object of type ParticleFilter
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = Resample( obj )
    %normalize the particle weights
    obj.NormalizeParticleWeights();

    %get the weight list
    wk = obj.GetWeightList();

    if strcmp(  ParticleFilter.RESAMPLING_STRATEGY, 'systematic_resampling' )
        edges = min([0 cumsum(wk)'],1); 
        edges(end) = 1;
        u1 = rand/obj.m_numberOfParticles;
        [~, idx] = histc(u1:1/obj.m_numberOfParticles:1, edges);
    elseif strcmp(  ParticleFilter.RESAMPLING_STRATEGY, 'multinomial_resampling' )
        edges = min([0 cumsum(wk)'],1); % protect against accumulated round-off
        edges(end) = 1;                 % get the upper edge exact
        [~, idx] = histc(sort(rand(obj.m_numberOfParticles, 1)), edges);
    else
        error( 'Unknown resampling strategy' );
    end
    
    resampledStateMatrix = obj.m_stateMatrix(idx,:);
    resampledStateMatrix(:, obj.m_stateDimension+1) = 1/obj.m_numberOfParticles;

    obj.m_stateMatrix = resampledStateMatrix;
end