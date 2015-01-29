function [Cx, Fx, weak_output] = strongGentleBoostClassifier(x, classifier)
    Nstages     = numel(classifier);
    Nsamples    = size(x, 2);
    Fx          = zeros(1, Nsamples);
    weak_output = zeros(Nstages, Nsamples);
    for m = 1:Nstages % Number of classifiers
        if ~isempty(classifier{m})
            featureNdx  = classifier{m}.featureNdx; % The dimension in which the stump is present
            th          = classifier{m}.th;                 % Threshold for the classifier in that dimension
            a           = classifier{m}.a;                  % slope of the line
            b           = classifier{m}.b;                  % intercept of the line
            alpha       = classifier{m}.alpha;
            error       = classifier{m}.err;

            if error < 50
                weak_output(m, :) = (a * (x(featureNdx,:)>th) + b);
                Fx = Fx + alpha .* weak_output(m, :); %add regression stump
            end
        end
    end

    Cx = sign(Fx);
end
