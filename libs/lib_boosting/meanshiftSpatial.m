function [mode] = meanshiftSpatial(data, h, epsilon, init_pt, w, iterations)

[d N] = size(data);
eps2 = epsilon*epsilon;

mode = ones(d, 1);
    if( size(init_pt) ~= size(mode) )
        error('Not the proper dimension');
    end

x = init_pt;
for iter = 1:iterations
    [m, s] = mean_shift_iteration(x, data, h, eps2, w);
    if(size(m,2) ~= 1) 
         m = m'; 
    end
    x = m;
end

mode = m; %% Return Value ...
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function [mode, score] = mean_shift_iteration(x, data, h, eps2, w)
% iterate mean shift search from starting point x
% compute the first mean shift step

[ms, score] = m_hG(x, data, h, w);
% iterate untill no step is achieved
while  ( dist2(ms , x) >= eps2 ) 
    x = ms;
    [ms, score] = m_hG(x, data, h, w);
end

mode = ms;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ms, score]=m_hG(x, data, h, w)
%       SUM Xi exp( -.5 || dist(X,Xi)/h ||^2 )
% m   = ---------------------------------
%  h,G  SUM exp( -.5 || dist(X,Xi)/h ||^2 )

e = dist2(repmat(x, 1, size(data,2)), data ) ./ (h.^2);
e = exp(-0.5*e) .* w;
score = sum(e); 
ms =  (data*e' ./ score);


function dist_op = dist2(mat1, mat2)

% This function is written exclusively for shai bagon's code 
% Input parameters 
% mat1 and mat2 -> size d*N

% Output parameters
% dist_op -> size 1*N
% dist(mat1',mat2)
dist_op = sum((mat1-mat2).^2);