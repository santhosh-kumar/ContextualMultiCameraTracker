%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Update the particle weights
%
%   Input -- 
%       @obj - object of type ParticleFilter
%       @weightList - particle weights
%      
%   Output -- 
%       @obj - object of type ParticleFilter
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%
%   Website -- http://vision.ece.ucsb.edu/~santhosh/  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = Update( obj,...
                       weightList )
                   
   assert( length(weightList) == obj.m_numberOfParticles );

   %update the particle weights
   obj.m_stateMatrix( :, obj.m_stateDimension+1 ) = obj.m_stateMatrix(:, obj.m_stateDimension+1 )...
                                                    .* weightList;

   %normalize the weights
   obj.NormalizeParticleWeights( );

   %resample if required
   obj.ResampleIfRequired( );
end