function mask = solution_selection(I1u, I1v, I2u, I2v, k1, k2, k1_, k2_, method)
n = length(I1u);
mask = zeros(6, n); % mask (boolean array) should indicate the most desirable real solution
if method.method == 0
    I1u_all = repmat(I1u, 6, 1); I1v_all = repmat(I1v, 6, 1);
%     I2u_all = repmat(I2u, 6, 1); I2v_all = repmat(I2v, 6, 1);

    k3 = 1 - I1u_all .* k1 - I1v_all .* k2;
%     k3_ = 1 - I2u_all .* k1_ - I2v_all .* k2_;
    measure = (k1 ./ k3) .^ 2 + (k2 ./ k3) .^ 2;
%     measure = measure + (k1_ ./ k3_) .^ 2 + (k2_ ./ k3_) .^ 2;
    
    for i = 1:n
        tem = measure(:, i);
        tem = tem(~isnan(tem)); % only select the real roots
        % (note we have set the complex numbers as NaN)
        % we choose the one with least norm
        mask(:, i) = abs(measure(:, i)) == min(abs(tem));
    end
end

if method.method == 1
    tic
    I1u_all = repmat(I1u, 6, 1); I1v_all = repmat(I1v, 6, 1);
    I2u_all = repmat(I2u, 6, 1); I2v_all = repmat(I2v, 6, 1);
    k3 = 1 - I1u_all .* k1 - I1v_all .* k2;    
    k3_ = 1 - I2u_all .* k1_ - I2v_all .* k2_;
    sigma = method.sigma;
    ratio = method.ratio;
    

    F1 = [I1u; I1v]; % image coordinates on first view
    F2 = [I2u; I2v]; % image coordinates on second view

    % compute distance maps for image coordinates
    dist_map1 = zeros(n, n);
    dist_map2 = zeros(n, n);
    for i = 1:n
        dist_map1(:, i) = sum((F1 - F1(:, i)) .^ 2);
        dist_map2(:, i) = sum((F2 - F2(:, i)) .^ 2);
    end

    % compute the adjacency matrix for first view
    avg_dist1 = sum(sum(dist_map1)) / (n ^ 2 - n);
    thre1 = ratio * avg_dist1;
    dist_mask1 = dist_map1 > thre1;
    W1 = exp(-dist_map1 / (2 * sigma ^ 2));
    W1 = W1 - eye(n); % leave zero on diagonal
    W1(dist_mask1) = 0;
    
    % compute the adjacency matrix for second view
    avg_dist2 = sum(sum(dist_map2)) / (n ^ 2 - n);
    thre2 = ratio * avg_dist2;
    dist_mask2 = dist_map2 > thre2;
    W2 = exp(-dist_map2 / (2 * sigma ^ 2));
    W2 = W2 - eye(n);
    W2(dist_mask2) = 0;

%     spy(W1)

    % compute the graph Laplacians (unormalized form)
    L = diag(sum(W1)) - W1; 
    L_ = diag(sum(W2)) - W2;
    
    non_nan_index = cell(1, n);
    
    normal_mat = zeros(3, 6 * n);
    normal_mat_ = zeros(3, 6 * n);
    x_index = zeros(1, 6 * n);
    
    start_index = 1;
    index_list = zeros(1, n);    
    measure = (k1 ./ k3) .^ 2 + (k2 ./ k3) .^ 2;
    V0 = zeros(6 * n, 1);
    for i = 1:n
        tem1 = k1(:, i);
        tem_mask = ~isnan(tem1);
        tem1 = tem1(tem_mask);
        tem2 = k2(:, i);
        tem2 = tem2(tem_mask);
        tem3 = k3(:, i);
        tem3 = tem3(tem_mask);        
        
        tem1_ = k1_(:, i);
        tem1_ = tem1_(tem_mask);
        tem2_ = k2_(:, i);
        tem2_ = tem2_(tem_mask);
        tem3_ = k3_(:, i);
        tem3_ = tem3_(tem_mask);              

        num_sol = length(tem1);
        [~, id] = min(measure(tem_mask, i));
        V0(start_index + id - 1) = 1;
        
        index_list(i) = num_sol;
        
        non_nan_index{i} = find(tem_mask);
        
        normal_mat(:, start_index:(start_index + num_sol - 1)) = [tem1, tem2, tem3]';
        normal_mat_(:, start_index:(start_index + num_sol - 1)) = [tem1_, tem2_, tem3_]';
        x_index(start_index:(start_index + num_sol - 1)) = ones(1, num_sol) * i;
        start_index = start_index + index_list(i);        
    end       
    

    
    m = start_index - 1;
    
    normal_mat = normal_mat(:, 1:m);
    normal_mat_ = normal_mat_(:, 1:m);
    x_index = x_index(1:m);
    y_index = 1:m;
    
    normal_mat = normal_mat ./ sqrt(sum(normal_mat .^ 2, 1));
    normal_mat_ = normal_mat_ ./ sqrt(sum(normal_mat_ .^ 2, 1));    
    
    S1 = sparse(x_index, y_index, normal_mat(1, :), n, m);
    S2 = sparse(x_index, y_index, normal_mat(2, :), n, m);
    S3 = sparse(x_index, y_index, normal_mat(3, :), n, m);
    S1_ = sparse(x_index, y_index, normal_mat_(1, :), n, m);
    S2_ = sparse(x_index, y_index, normal_mat_(2, :), n, m);
    S3_ = sparse(x_index, y_index, normal_mat_(3, :), n, m);
    R1 = sparse(x_index, y_index, normal_mat(1, :) ./ normal_mat(3, :), n, m);
    R2 = sparse(x_index, y_index, normal_mat(2, :) ./ normal_mat(3, :), n, m);
    R1_ = sparse(x_index, y_index, normal_mat_(1, :) ./ normal_mat_(3, :), n, m);
    R2_ = sparse(x_index, y_index, normal_mat_(2, :) ./ normal_mat_(3, :), n, m);

    S3_plus = normal_mat(3, :);
    S3_plus(S3_plus > 0) = 0;
%     S3_plus(S3_plus < 0) = 1;
    S3_plus = sparse(x_index, y_index, S3_plus, n, m);
    
    S3_plus_ = normal_mat_(3, :);
    S3_plus_(S3_plus_ > 0) = 0;
%     S3_plus_(S3_plus_ < 0) = 1;
    S3_plus_ = sparse(x_index, y_index, S3_plus_, n, m);    
    
    V0 = V0(1:m);   

%     c0 = (norm(R1 * V0) ^ 2 + norm(R2 * V0) ^ 2) / n
%     disp(V0' * (S1' * L * S1 + S2' * L * S2 + S3' * L * S3) * V0)
%     disp(V0' * (S1_' * L_ * S1_ + S2_' * L_ * S2_ + S3_' * L_ * S3_) * V0)
    c0 = 1.0;
    c1 = 1.0;
    c2 = 1.0;
%     c2 = (norm(R1_ * V0) ^ 2 + norm(R2_ * V0) ^ 2) / n
    c3 = 1.0;
    
    c4 = 1.0;
    
    B = full(sparse(x_index, y_index, ones(1, m), n, m)); 
    A_original = c0 * (S1' * L * S1 + S2' * L * S2 + S3' * L * S3);
    A = A_original + c2 * (S1_' * L_ * S1_ + S2_' * L_ * S2_ + S3_' * L_ * S3_);
    
    loss = max(V0' * A_original * V0, 0);
    A = A + c1 * (R1' * R1 + R2' * R2); % regularization
    A = A + c3 * (R1_' * R1_ + R2_' * R2_);
    A = A / n;
    A = A + c4 * (S3_plus' * S3_plus + S3_plus_' * S3_plus_);

    % use L1 norm to replace the inequality constraint
    s = 0.1;
    tau = 5;
    lam1 = 10;
    lam2 = lam1 * s;
    max_iter = 40;
    mu = zeros(m, 1);
    W = V0;

    A = A + eye(m) * (tau - lam2);

    invA = inv(A);
    BinvA = B * invA;
    BAB_inv_BA_inv = (BinvA * B') \ BinvA;
    C = invA - BinvA' * BAB_inv_BA_inv;
    b = sum(BAB_inv_BA_inv, 1)';
    if loss > 0
        for i = 1:max_iter
            V = C * (tau * (W + mu)) + b;
            
            z = V - mu;
            W = sign(z) .* max(abs(z) - lam1 / tau, 0);

            mu = mu + W - V;
        end
        j = 1;
        for i = 1:n
            subV = V(j:(j + index_list(i) - 1)); % v_i
            tem_mask = max(subV) == subV;
            subV(tem_mask) = 1;
            subV(~tem_mask) = 0;
            V(j:(j + index_list(i) - 1)) = subV;
            j = j + index_list(i);
        end
        loss_new = V' * A_original * V;
        if loss_new >= loss
            V = V0;
        end

    else
        V = V0;
    end

    j = 1;
    for i = 1:n
        subV = V(j:(j + index_list(i) - 1)); % v_i
        j = j + index_list(i);
        mask(:, i) = zeros(6, 1);
        mask(non_nan_index{i}(subV == 1), i) = 1;
        
    end
    toc
end


if method.method == 2
    %%% least median method
    
    pairs_num = length(method.eq_coef);
    
    
    for i = 1:n
        
        % extract the real roots
        tem1 = k1(:, i);
        mask(:, i) = ~isnan(tem1);
        tem1 = tem1(~isnan(tem1));
        tem2 = k2(:, i);
        tem2 = tem2(~isnan(tem2));
       
        % ready to collect the sum of squared errors
        err_list = zeros(length(tem1), pairs_num);
        for j = 1:pairs_num
            if j ~= (method.view_id - 1)
                f1 = method.f1_coef{j};
                f2 = method.f2_coef{j};
                r = method.first_cubic_coef{j};
                J21_all = method.J21_all{j};
                
                J21 = J21_all(:, i); % a,b,c,d
                x1 = J21(1) * tem1 + J21(2) * tem2;
                x2 = J21(3) * tem1 + J21(4) * tem2;
                
                % first cubic (r0 + r1.*x1 + r2.*x2 + r3.*x1.*x2 + r4.*x1.^2 + r5.*x2.^2 + r6.*x1.*x2.^2 + r7.*x2.*x1.^2)
                % second cubic is f1 x1 + f2 = 0
                
                % first cubic
                c1 = r(1, i) + r(2, i).*x1 + r(3, i).*x2 + r(4, i).*x1.*x2 + r(5, i).*x1.^2 + r(6, i).*x2.^2 + r(7, i).*x1.*x2.^2 + r(8, i).*x2.*x1.^2;
                
                % second cubic
                c2 = polyval(flipud(f2(:, i))', x2) + x1 .* polyval(flipud(f1(:, i))', x2);
                err_list(:, j) = c1 .^ 2 + c2 .^ 2; % sum of squared errors
            end
        end
        err_list(:, method.view_id - 1) = [];
        
        [~, index] = min(median(err_list, 2)); % choose least median
        
        all_index = find(mask(:, i) == 1);
        mask(all_index(index), i) = 2;
        mask(:, i) = mask(:, i) == 2;
    end

end




mask = mask == 1;  
end

