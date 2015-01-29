%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function selects the best regression stump
%
%   [th, a , b] = fitRegressionStump(x, z);
%   z = a * (x>th) + b;
%   where (a,b,th) are so that it minimizes the weighted error:
%   error = sum(w * |z - (a*(x>th) + b)|^2) / sum(w)
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [featureNdx, th, a , b, error] = selectBestRegressionStump(x, z, w, prev_added_indexes)
    Nfeatures   = size(x, 1);
    w           = w./sum(w); 
    th          = zeros(1,Nfeatures);
    a           = zeros(1,Nfeatures);
    b           = zeros(1,Nfeatures);
    errors      = zeros(1,Nfeatures);

    % Iterates through the total number of dimensions ...
    for n = 1:Nfeatures 
        [th(n), a(n) , b(n), errors(n)] = fitRegressionStump(x(n,:), z, w);
    end

    for n = 1 : Nfeatures
        [error, featureNdx] = min(errors);
        if isempty( find(prev_added_indexes==featureNdx, 1) )
            break;
        else 
            errors(featureNdx) = Inf;
        end
    end
    
    th  = th(featureNdx);
    a   = a(featureNdx);
    b   = b(featureNdx);
end