%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    This function gets the best performing classifier to be shared
%    with the other views
%
%   Input --
%       @obj -                      - Ensemble Classifier Object 
%
%   Output -- 
%       @weakClassifierList         - Weak Classifier List
%
%   Author -- Santhoshkumar Sunderrajan( santhosh@ece.ucsb.edu )
%   Website -- http://vision.ece.ucsb.edu/~santhosh/   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function weakClassifierList = GetBestPerformingWeakClassifiers( obj )
    error = zeros( numel( obj.m_weakClassifiers), 3);
    for iter = 1 : numel( obj.m_weakClassifiers )
        error(iter,1)   = obj.m_weakClassifiers{iter}.err;
        error(iter,2)   = obj.m_weakClassifiers{iter}.pos_err;
        error(iter,3)   = obj.m_weakClassifiers{iter}.neg_err;
    end

    [ ~, pick_class_index ] = sort( error(:,1), 'ascend' );

    assert( EnsembleClassifier.NUMBER_BEST_WEAK_CLASSIFIERS_TO_SHARE < numel(obj.m_weakClassifiers) );
    
    % Reordering classifiers in ascending order according to error ...
    for iter= 1 : EnsembleClassifier.NUMBER_BEST_WEAK_CLASSIFIERS_TO_SHARE
        weakClassifierList{iter} = obj.m_weakClassifiers{ pick_class_index(iter) };
    end
end%function