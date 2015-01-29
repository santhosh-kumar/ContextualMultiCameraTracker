function classifier = gentleBoost(x, y, Nrounds)
    Nsamples        = size(x, 2); % Nsamples = Number of thresholds that we will consider
    Fx              = zeros(1, Nsamples); 
    w               = ones(1, Nsamples);
    added_indexes   = [];
    for m = 1:Nrounds    
        % Weak regression stump: It is defined by four parameters (a,b,k,th) f_m = a * (x_k > th) + b
        [k, th, a , b, ~] = selectBestRegressionStump(x, y, w, []);

        % Updating and computing classifier output on training samples
        fm = (a * (x(k,:)>th) + b); % evaluate weak classifier
        Fx = Fx + fm; % update strong classifier

        % Reweight training samples
        w = w .* exp(-y.*fm);
        
        current_op = sign(fm);

        sign_checker_pos = current_op( y== 1) .* y( y== 1 );
        sign_checker_neg = current_op( y==-1) .* y( y==-1 );
        pos_err          = sum( sign_checker_pos < 0 ) ./ Nsamples;
        neg_err          = sum( sign_checker_neg < 0 ) ./ Nsamples;
        err              = pos_err + neg_err;

        % Round m update of the weak learners
        classifier{m}.featureNdx = k;
        classifier{m}.th         = th;
        classifier{m}.a          = a;
        classifier{m}.b          = b;
        classifier{m}.pos_err    = pos_err;
        classifier{m}.neg_err    = neg_err;
        classifier{m}.err        = err;
        if classifier{m}.err > 0
            classifier{m}.alpha  = (1/2) * log((1-classifier{m}.err)./classifier{m}.err);
        else
            classifier{m}.alpha  = 1;
        end
        
        added_indexes = [added_indexes; k];
    end
end