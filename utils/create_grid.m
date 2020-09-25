function [I1u,I1v,I2u,I2v,visb2] = create_grid(q_n,visb,p)

n = size(visb,1);
er = 1e-4;
t= 1e-3;
nC = 40;
idx = visb(1,:)==1;
q1 = q_n(1:2,idx);  
umin = min(q1(1,:))-t; umax = max(q1(1,:))+t;
vmin = min(q1(2,:))-t; vmax = max(q1(2,:))+t;
bbs = bbs_create(umin, umax, nC, vmin, vmax, nC, 2);
lambdas = er*ones(nC-3, nC-3);

% delta = -cos(pi / (p - 1) * (0:(p - 1)));
% u_nodes = (bbs.umax + bbs.umin) / 2 + (bbs.umax - bbs.umin) / 2 * delta;
% v_nodes = (bbs.vmax + bbs.vmin) / 2 + (bbs.vmax - bbs.vmin) / 2 * delta;
u_nodes = linspace(bbs.umin,bbs.umax,p);
v_nodes = linspace(bbs.vmin,bbs.vmax,p);


[xv,yv]=meshgrid(u_nodes, v_nodes);

I1u = repmat(xv(:)',n-1,1);
I1v = repmat(yv(:)',n-1,1);
visb2 = ones(n,length(I1u(1,:)));
for i = 2:n
    idx = visb(1,:)==1 & visb(i,:)==1;
    coloc = bbs_coloc(bbs, q_n(1,idx), q_n(2,idx));
    bending = bbs_bending(bbs, lambdas);
    q2 = q_n(2*(i-1)+1:2*(i-1)+2,idx);
    cpts = (coloc'*coloc + bending) \ (coloc'*q2');
    ctrlpts = cpts';
    q1 =  bbs_eval(bbs,ctrlpts,q_n(1,idx)',q_n(2,idx)',0,0);
    error=sqrt(mean((q1(1,:)-q_n(2*(i-1)+1,idx)).^2+(q1(2,:)-q_n(2*(i-1)+2,idx)).^2));
%     disp(fprintf('[ETA] Internal Rep error = %f',error));
    q =  bbs_eval(bbs,ctrlpts,I1u(1,:)',I1v(1,:)',0,0);
    I2u(i-1,:) = q(1,:);
    I2v(i-1,:) = q(2,:);
%     %Visualize Point Registration Error
%     figure;
%     plot(q_n(1,:),q_n(2,:),'ro');
%     hold on;
%     plot(q(1,:),q(2,:),'b*');
%     %mesh(reshape(q(1,:),size(xv)),reshape(q(2,:),size(xv)),zeros(size(xv)));
%     axis equal
%     hold off;
end

