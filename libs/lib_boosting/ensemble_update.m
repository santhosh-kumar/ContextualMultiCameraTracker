function classifier = ensemble_update(x, y, Nrounds, ensemble, K)
    Nsamples    = size(x, 2);

    % 6. Initialize w to be a uniform distribution
    w  = ones(1, Nsamples);
    
    added_indexes = [];

    % 7. Removing the K oldest weak classifiers...
    for iter = K+1:Nrounds
        weakClassifier = ensemble{iter-K};
        k              = weakClassifier.featureNdx;
        a              = weakClassifier.a;
        b              = weakClassifier.b;
        th             = weakClassifier.th;
        fm             = (a * (x(k,:)>th) + b);

        current_op       = sign(fm);
        sign_checker_pos = current_op( y== 1) .* y( y== 1 );
        sign_checker_neg = current_op( y==-1) .* y( y==-1 );
        pos_err          = sum( sign_checker_pos < 0 ) ./ Nsamples;
        neg_err          = sum( sign_checker_neg < 0 ) ./ Nsamples;
        err              = pos_err + neg_err;
        
        % Reweight training samples
        w = w .* exp(-y.*fm);
        
        classifier{iter}         = weakClassifier;
        classifier{iter}.pos_err = pos_err;
        classifier{iter}.neg_err = neg_err;
        classifier{iter}.err     = err;
        classifier{iter}.alpha   = (1/2) * log((1-classifier{iter}.err)./classifier{iter}.err);
        
        added_indexes = [added_indexes; k];
    end

    % 8. Change K new weak classifiers
    for m = 1:K
        % Weak regression stump: It is defined by four parameters (a,b,k,th) f_m = a * (x_k > th) + b
        [k, th, a , b, ~] = selectBestRegressionStump(x, y, w, added_indexes);
        
        % Round m update of the weak learners
        classifier{m}.featureNdx = k;
        classifier{m}.th         = th;
        classifier{m}.a          = a;
        classifier{m}.b          = b;
        
        % Updating and computing classifier output on training samples
        fm = (a * (x(k,:)>th) + b); % evaluate weak classifier
        
        % Reweight training samples
        w = w .* exp(-y.*fm);

        % Additional Part for Checking Efficiency
        fm_modified = fm;
        current_op = sign(fm_modified);

        sign_checker_pos = current_op(y==1) .* y(y==1);
        sign_checker_neg = current_op(y==-1) .* y(y==-1);

        classifier{m}.pos_err    = sum( sign_checker_pos < 0 ) ./ Nsamples;
        classifier{m}.neg_err    = sum( sign_checker_neg < 0 ) ./ Nsamples;
        classifier{m}.err        = classifier{m}.pos_err + classifier{m}.neg_err;
        classifier{m}.alpha      = (1/2) * log((1-classifier{m}.err)./classifier{m}.err);
        
        added_indexes            = [added_indexes;k];
    end
end