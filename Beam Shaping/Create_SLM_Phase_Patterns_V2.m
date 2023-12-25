% User input
path = uigetdir('C:\',"Select path for saving phase patterns");
wavelength = 561; % (nm)

%% SLM specifications and blazed grating
pixel = 6.4e-3; %pixel size (mm)
x_length = 1920; %width (px)
y_length = 1080; %heigth (px)

% Create coordinate system
x = linspace(-pixel*x_length/2,pixel*x_length/2,x_length);
y = linspace(-pixel*y_length/2,pixel*y_length/2,y_length);
global xx yy;
[xx,yy] = meshgrid(x,y);
[theta,rho] = cart2pol(xx,yy);

% Convert wavelength to mm and get wavevector
lambda = wavelength*1e-6;
lambdatxt = string(wavelength);
k = 2*pi/lambda;

% SLM color calibration
switch lambda
    case 561e-6
        grey = 213;
    case 488e-6
        grey = 178;
    case 642e-6
        grey = 255;
    case 405e-6
        grey = 124;
end

% Blazed grating calibration based on 561 nm as a reference
% ref. grating constant at 561 nm (lambda_0):
% g_0 = 5
% calculation of grating constant g from ref.:
% g = (lambda/lamda_0)*g_0
switch lambda
    case 561e-6
        g = 5;
    case 488e-6
        g = 4.35;
    case 642e-6
        g = 5.72;
    case 405e-6
        g = 3.61;
end
BlazedGrating = exp(-1i*2*pi*(xx)/(x(2)-x(1))/g);
BlazedGrating = angle(BlazedGrating)+pi;

%% Gaussian Beam

beam_radius = 0.6; %(determines effective NA) %0.6

% Chromatic correction
switch lambda
    case 561e-6
        f = 300;
    case 488e-6
        f = 280;
    case 642e-6
        f = 270;
    case 405e-6
        f = 160;
end

% Spherical lens phase shift
SphericalLens = exp(-1i*(k.*((rho).^2))/(2*f));
SphericalLens = angle(SphericalLens)+pi;

% Aperture (determines NA)
Aperture = ones(y_length,x_length);
Aperture(rho>beam_radius)=0;
Filter = imgaussfilt(Aperture,50);
Filter = imnoise(Filter,'gaussian',0,0.02);
Aperture(Filter>=0.5)=1;
Aperture(Filter<0.5)=0;
Aperture(rho>beam_radius+1)=0;
Aperture = uint8(Aperture);

%Combine and save
Gaussian = adjust((SphericalLens + BlazedGrating),grey).* Aperture;
PathName = strcat(strcat(path,'Gaussian_Phasemask_',lambdatxt,'nm.bmp'));
imwrite(Gaussian,PathName);

%% Gaussian centerblock

beam_radius = 0.7; %(determines effective NA) %0.6

% Chromatic correction
switch lambda
    case 561e-6
        f = 300;
    case 488e-6
        f = 280;
    case 642e-6
        f = 270;
    case 405e-6
        f = 160;
end

% Spherical lens phase shift
SphericalLens = exp(-1i*(k.*((rho).^2))/(2*f));
SphericalLens = angle(SphericalLens)+pi;

% Aperture (determines NA)
Aperture = ones(y_length,x_length);
Aperture(rho>beam_radius)=0;
Filter = imgaussfilt(Aperture,50);
Filter = imnoise(Filter,'gaussian',0,0.02);
Aperture(Filter>=0.5)=1;
Aperture(Filter<0.5)=0;
Aperture(rho>beam_radius+1)=0;
Aperture = uint8(Aperture);

%centerblock
centerblock = ones(y_length,x_length);
centerblock(abs(xx)<0.2)=0;
Filter = imgaussfilt(centerblock,20);
Filter = imnoise(Filter,'gaussian',0,0.02);
centerblock(Filter>=0.5)=1;
centerblock(Filter<0.5)=0;
centerblock = uint8(centerblock);

%Combine and save
Gaussian_centerblock = adjust((SphericalLens + BlazedGrating),grey).* Aperture .*centerblock;
PathName = strcat(strcat(path,'Gaussian_centerblock_Phasemask_',lambdatxt,'nm.bmp'));
imwrite(Gaussian_centerblock,PathName);

%% Bessel Beam

beam_radius = 1.75; %(determines length and focus pos.)  %3

% Chromatic correction
switch lambda
    case 561e-6
        beam_radius = beam_radius*1;
    case 488e-6
        beam_radius = beam_radius*1;
    case 642e-6
        beam_radius = beam_radius*0.77;
    case 405e-6
        beam_radius = beam_radius*1;
end

% Axicon lens
n = 1.51;                % refractive index of axicon 1.51
alpha_degree = 0.5671;   % DEPENDS ON BESSEL BEAM LENGTH 0.5671
alpha = alpha_degree*(pi/180);
r = 6.5;                 % half length of x
AxiconLens = exp(1i*k.*((r-rho).*tan(alpha)*(n-1)));
AxiconLens = angle(AxiconLens)+pi;

% Bessel_DOF = 2*beam_radius / (tan(alpha)*(n-1));
% Bessel_DOF = Bessel_DOF*0.124;
% 
% Bessel_D = 2*500*tan((n-1)*alpha);

% Aperture (determines length)
Aperture = ones(y_length,x_length);
Aperture(rho>beam_radius)=0;
Aperture(rho<0.8)=0;
Filter = imgaussfilt(Aperture,50);
Filter = imnoise(Filter,'gaussian',0,0.02);
Aperture(Filter>=0.5)=1;
Aperture(Filter<0.5)=0;
Aperture(rho>beam_radius+1)=0;
Aperture = uint8(Aperture);

%Combine and save
Bessel = adjust((AxiconLens + BlazedGrating),grey).* Aperture;
PathName = strcat(strcat(path,'Bessel_PhaseMask_',lambdatxt,'nm.bmp'));
imwrite(Bessel,PathName);

%% Droplet Beam

beam_radius = 1.75; %(determines length and focus pos.)  %3

% Chromatic correction
switch lambda
    case 561e-6
        beam_radius = beam_radius*1;
    case 488e-6
        beam_radius = beam_radius*1;
    case 642e-6
        beam_radius = beam_radius*0.77;
    case 405e-6
        beam_radius = beam_radius*1;
end

% Axicon lens
n = 1.51;                % refractive index of axicon 1.51
alpha_degree = 0.5671;   % DEPENDS ON BESSEL BEAM LENGTH 0.5671
alpha = alpha_degree*(pi/180);
r = 6.5;                 % half length of x
AxiconLens = exp(1i*k.*((r-rho).*tan(alpha)*(n-1)));
AxiconLens = angle(AxiconLens)+pi;

% Aperture (determines length)
Aperture = ones(y_length,x_length);
Aperture(rho>beam_radius)=0;
Aperture(rho<0.8)=0;
Filter = imgaussfilt(Aperture,20);
Filter = imnoise(Filter,'gaussian',0,0.02);
Aperture(Filter>=0.5)=1;
Aperture(Filter<0.5)=0;
Aperture(rho>beam_radius+1)=0;
Aperture = uint8(Aperture);

% Axicon lens2
droplet_ratio = 0.57;
k_2 = k*droplet_ratio;
AxiconLens2 = exp(1i*k_2.*((r-rho).*tan(alpha)*(n-1)));
AxiconLens2 = angle(AxiconLens2)+pi;

% Aperture2 (determines length)
Aperture2 = ones(y_length,x_length);
Aperture2(rho>beam_radius.*droplet_ratio)=0;
Aperture2(rho<0.8.*droplet_ratio)=0;
Filter2 = imgaussfilt(Aperture2,20);
Filter2 = imnoise(Filter2,'gaussian',0,0.02);
Aperture2(Filter2>=0.5)=1;
Aperture2(Filter2<0.5)=0;
Aperture2(rho>beam_radius+1)=0;
Aperture2 = uint8(Aperture2);

combAperture = Aperture + Aperture2;
combAperture(combAperture == 2) = 1;

DropletMask = AxiconLens.*double(Aperture) + AxiconLens2.*double(Aperture2);

%Combine and save
Droplet = adjust((DropletMask + BlazedGrating),grey).* combAperture;
PathName = strcat(strcat(path,'Droplet_',string(droplet_ratio),'_PhaseMask_',lambdatxt,'nm.bmp'));
imwrite(Droplet,PathName);

%% Double Beam

dist = 110;
diameter = 0.35;

% Chromatic correction
switch lambda
    case 561e-6
        f = 300;
    case 488e-6
        f = 280;
    case 642e-6
        f = 270;
    case 405e-6
        f = 160;
end

% Spherical lens phase shift
SphericalLens = exp(-1i*(k.*((rho).^2))/(2*f));
SphericalLens = angle(SphericalLens)+pi;

% Left Aperture
LAperture = ones(y_length,x_length);
LAperture(rho>diameter)=0;
LFilter = imgaussfilt(LAperture,20);
LFilter = imnoise(LFilter,'gaussian',0,0.02);
LAperture(LFilter>=0.5)=1;
LAperture(LFilter<0.5)=0;
LAperture(rho>diameter+0.2)=0;
LAperture = uint8(LAperture);
LAperture = imtranslate(LAperture,[dist/2 0]);
% Right Aperture
RAperture = imtranslate(LAperture,[-dist 0]);

combAperture = LAperture + RAperture;
combAperture(combAperture == 2) = 1;

%Combine and save
Double_beam = adjust((SphericalLens + BlazedGrating),grey).* combAperture;
PathName = strcat(strcat(path,'Double_hrzt_PhaseMask_',lambdatxt,'nm.bmp'));
imwrite(Double_beam,PathName);

Double_beam_rot = adjust((SphericalLens + BlazedGrating),grey).* imrotate(combAperture,90,'bicubic','crop');
PathName = strcat(strcat(path,'Double_vert_PhaseMask_',lambdatxt,'nm.bmp'));
imwrite(Double_beam_rot,PathName);

%% Square Lattice Beam

beam_radius = 1.75; %(determines length and focus pos.)

% Chromatic correction
switch lambda
    case 561e-6
        beam_radius = beam_radius*1;
    case 488e-6
        beam_radius = beam_radius*1;
    case 642e-6
        beam_radius = beam_radius*0.77;
    case 405e-6
        beam_radius = beam_radius*1;
end

% Axicon lens
n = 1.51;                % refractive index of axicon
alpha_degree = 0.5671;   % axicon wedge angle
alpha = alpha_degree*(pi/180);
r = 6.5;                 % half length of x
AxiconLens = exp(1i*k.*((r-rho).*tan(alpha)*(n-1)));
AxiconLens = angle(AxiconLens)+pi;

% Square Lattice (vertical)
d = 180;
w = 45;
Lattice = zeros(y_length,x_length);
Lattice(:,960-w:960+w) = 1;
Lattice(:,960+d-w:960+d+w) = 1;
Lattice(:,960-d-w:960-d+w) = 1;

Filter = imgaussfilt(Lattice,30);
Filter = imnoise(Filter,'gaussian',0,0.02);
Lattice(Filter>=0.5)=1;
Lattice(Filter<0.5)=0;
Lattice = uint8(Lattice);

% Aperture
Aperture = ones(y_length,x_length);
Aperture(rho>beam_radius)=0;
Aperture(rho<0.8)=0;
Filter = imgaussfilt(Aperture,30);
Filter = imnoise(Filter,'gaussian',0,0.02);
Aperture(Filter>=0.5)=1;
Aperture(Filter<0.5)=0;
Aperture(rho>beam_radius+1)=0;
Aperture = uint8(Aperture);

%Combine and save
Lattice_test = adjust((AxiconLens + BlazedGrating) ,grey) .* Lattice .* Aperture;
PathName = strcat(strcat(path,'LatBes_PhaseMask_',lambdatxt,'nm.bmp'));
imwrite(Lattice_test,PathName);

%% Sectioned Bessel Beam

beam_radius = 1.85; %(determines length and focus pos.)

% Chromatic correction
switch lambda
    case 561e-6
        beam_radius = beam_radius*1;
    case 488e-6
        beam_radius = beam_radius*1;
    case 642e-6
        beam_radius = beam_radius*0.77;
    case 405e-6
        beam_radius = beam_radius*1;
end

% Axicon lens
n = 1.51;                % refractive index of axicon
alpha_degree = 0.5671;   % DEPENDS ON BESSEL BEAM LENGTH
alpha = alpha_degree*(pi/180);
r = 6.5;                 % half length of x
AxiconLens = exp(1i*k.*((r-rho).*tan(alpha)*(n-1)));
AxiconLens = angle(AxiconLens)+pi;

% Aperture
Aperture = ones(y_length,x_length);
Aperture(rho>beam_radius)=0;
Aperture(rho<0.75)=0;
Filter = imgaussfilt(Aperture,50);
Filter = imnoise(Filter,'gaussian',0,0.02);
Aperture(Filter>=0.5)=1;
Aperture(Filter<0.5)=0;
Aperture(rho>beam_radius+1)=0;
Aperture = uint8(Aperture);

%Combine and save
for q = 70%10:10:170
    SBB = adjust(  (BlazedGrating + AxiconLens) ,grey) .* Aperture .*sectioning(q);
    PathName = strcat(strcat(path,string(q),'_deg_Sec_Bessel_PhaseMask_rot_',lambdatxt,'nm.bmp'));
    imwrite(SBB,PathName);
    
end

%% Sectioned Droplet Beam

beam_radius = 1.75; %(determines length and focus pos.)  %3

% Chromatic correction
switch lambda
    case 561e-6
        beam_radius = beam_radius*1;
    case 488e-6
        beam_radius = beam_radius*1;
    case 642e-6
        beam_radius = beam_radius*0.77;
    case 405e-6
        beam_radius = beam_radius*1;
end

% Axicon lens
n = 1.51;                % refractive index of axicon 1.51
alpha_degree = 0.5671;   % DEPENDS ON BESSEL BEAM LENGTH 0.5671
alpha = alpha_degree*(pi/180);
r = 6.5;                 % half length of x
AxiconLens = exp(1i*k.*((r-rho).*tan(alpha)*(n-1)));
AxiconLens = angle(AxiconLens)+pi;

% Aperture (determines length)
Aperture = ones(y_length,x_length);
Aperture(rho>beam_radius)=0;
Aperture(rho<0.8)=0;
Filter = imgaussfilt(Aperture,20);
Filter = imnoise(Filter,'gaussian',0,0.02);
Aperture(Filter>=0.5)=1;
Aperture(Filter<0.5)=0;
Aperture(rho>beam_radius+1)=0;
Aperture = uint8(Aperture);

% Axicon lens2
droplet_ratio = 0.57;
k_2 = k*droplet_ratio;
AxiconLens2 = exp(1i*k_2.*((r-rho).*tan(alpha)*(n-1)));
AxiconLens2 = angle(AxiconLens2)+pi;

% Aperture2 (determines length)
Aperture2 = ones(y_length,x_length);
Aperture2(rho>beam_radius.*droplet_ratio)=0;
Aperture2(rho<0.8.*droplet_ratio)=0;
Filter2 = imgaussfilt(Aperture2,20);
Filter2 = imnoise(Filter2,'gaussian',0,0.02);
Aperture2(Filter2>=0.5)=1;
Aperture2(Filter2<0.5)=0;
Aperture2(rho>beam_radius+1)=0;
Aperture2 = uint8(Aperture2);

combAperture = Aperture + Aperture2;
combAperture(combAperture == 2) = 1;

DropletMask = AxiconLens.*double(Aperture) + AxiconLens2.*double(Aperture2);

%Combine and save
for q = 70%10:10:170
    SecDroplet = adjust( ( BlazedGrating + DropletMask) ,grey).* combAperture .*sectioning(q);
    PathName = strcat(strcat(path,'SecDroplet_',string(q),'deg_PhaseMask_',lambdatxt,'nm.bmp'));
    imwrite(SecDroplet,PathName);
end

%% Airy Beam

beam_radius = 1.6; %(determines length and focus pos.)

% Airy Beam
Airybeam = airy_2D_phase(xx,yy,0,0,theta,20);
%Airybeam = Airybeam + airy_2D_phase(xx,yy,0,0,theta,20*0.57);
Airybeam = imrotate(Airybeam,-45,'crop');

% Aperture
Aperture = ones(y_length,x_length);
Aperture(rho>beam_radius)=0;
Filter = imgaussfilt(Aperture,80);
Filter = imnoise(Filter,'gaussian',0,0.02);
Aperture(Filter>=0.5)=1;
Aperture(Filter<0.5)=0;
Aperture(rho>beam_radius+1)=0;
Aperture = uint8(Aperture);

%Combine and save
Airy = adjust((Airybeam + BlazedGrating),grey).* Aperture;
PathName = strcat(strcat(path,'Airy_PhaseMask_',lambdatxt,'nm.bmp'));
imwrite(Airy,PathName);


