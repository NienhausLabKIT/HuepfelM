%------------Sectioning-------------------------------
function Sectioning = sectioning(beta_degree)
global xx yy;
[theta,~] = cart2pol(xx,yy);
beta = beta_degree/2*(pi/180);  % beta_degree = sectioning angle
Sectioning = -1*(heaviside(theta + (pi/2 - beta)) - heaviside(theta + (pi/2 + beta))) ...
    + heaviside(theta - (pi/2 - beta)) - heaviside(theta - (pi/2 + beta)) ;

Filter = imgaussfilt(Sectioning,30);
Filter = imnoise(Filter,'gaussian',0,0.02);
Sectioning(Filter>=0.5)=1;
Sectioning(Filter<0.5)=0;
Sectioning = uint8(Sectioning);
Sectioning = imrotate(Sectioning,90,'crop');
end