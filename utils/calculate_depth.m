function P_grid=calculate_depth(N_res,u,v,par)
% nC=40;
nC = 20;
t = 1e-1; % 0.1
P_grid = zeros(3*size(u,1),size(u,2));
for i=1:size(u,1)
    idx = find(u(i,:)~=0) & find(v(i,:)~=0);
    umin=min(u(i,idx))-t;umax=max(u(i,idx))+t;
    vmin=min(v(i,idx))-t;vmax=max(v(i,idx))+t;
    bbsd = bbs_create(umin, umax, nC, vmin, vmax, nC, 1);
    colocd = bbs_coloc(bbsd, u(i,idx), v(i,idx));
    lambdas = par(i)*ones(nC-3, nC-3);
    bendingd = bbs_bending(bbsd, lambdas);
    [ctrlpts3Dn]=ShapeFromNormals(bbsd,colocd,bendingd,[u(i,idx);v(i,idx);ones(1,length(u(i,idx)))],N_res(3*(i-1)+1:3*(i-1)+3,idx));
    mu=bbs_eval(bbsd, ctrlpts3Dn,u(i,idx)',v(i,idx)',0,0);
    P_grid(3*(i-1)+1:3*(i-1)+3,idx) = [u(i,idx);v(i,idx);ones(1,length(u(i,idx)))].*[mu;mu;mu];
end
