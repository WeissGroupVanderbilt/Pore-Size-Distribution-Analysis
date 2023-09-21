%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pore Diameter Distribution Calculator
%
% If you use this code, please cite: 
%  S. J. Ward, T. Cao, X. Zhou, C. Chang and S. M. Weiss "Protein
%  Identification and Quantification Using Porous Silicon Arrays, Optical
%  Measurements, and Machine Learning," Biosensors 13, 879 (2023).
%  doi: https://doi.org/10.3390/bios13090879
%
% DESCRIPTION:
% This MATLAB script identifies size distribution of pores, developed for
% use with SEM images of porous silicon, but applicable to any image with
% approximately circular objects with a distribution of sizes.
%
% INSTRUCTIONS:
% Set filname, size of pixels in the units required for pore sizes,
% threshold greyscale value to differentiate between pores and non-pores,
% define the start and end and width of the histogram bins,
% and whether the size of the pores should be weighted by the pore
% circumference (and consequently the number of adsorption sites on the pore
% walls, lending more importance to larger pores) in the pore size
% distributio histogram. Then optionally select the number of tiles the 
% image should be split into in x and y directions (there should be roughly 
% a uniform number of pores in each tile)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf;
clear;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% REQUIRED

Filename = 'Filename.tif';

% pixel size units determine units of output
PixelSize = 1;

% Distinguish between material or void space pixels
GreyscaleThreshold = 50;

LowerBoundHistBin = 0;
BinWidth = 2.5;
UpperBoundHistBin = 100;
PoreDistributionBins = LowerBoundHistBin:BinWidth:UpperBoundHistBin;

% circumference is proportional to number of binding sites
% weighting pores by circumference assigns more importance
% to larger pores with more binding sites
WeightByCircumference = 'True';

% distance from top of image that doesn't contain SEM info banner
CropHeightPixels = 670;

% size of kernel for image filter
FilterKernelHeight = 3;
FilterKernelWidth = 3;

% OPTIONAL

% Split image into tiles for contrast enhancement
% (each tile should contain roughly the same number of pores)
ntilesx = 8;
ntilesy = 8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROCESS IMAGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OpenTiffFile = Tiff(Filename,'r'); 
RawImage = read(OpenTiffFile);
RawImage = RawImage(1:CropHeightPixels,:); 

%Enhance contrast of image
AdjustedImage = adapthisteq(RawImage, 'NumTiles', [ntilesx ntilesy], ...
                            'NBins', 1024, 'Distribution', 'uniform'); 

BinaryImage = gt(AdjustedImage,GreyscaleThreshold);

% Removes isolated and almost isolated 'spur' pixels from image
BinaryImage=bwmorph(BinaryImage,'clean');
BinaryImage=bwmorph(BinaryImage,'spur');

BinaryImage = 1-BinaryImage;

% Median of surrounding 3x3 square of each pixel
BinaryImage = medfilt2(BinaryImage,[FilterKernelHeight FilterKernelWidth]);  
imshow(RawImage)

%Create green RGB array the same size as RawImage
GreenArray = cat(3, zeros(size(RawImage)), ones(size(RawImage)), zeros(size(RawImage))); 
hold on
GreenImage = imshow(GreenArray);

% Set transparency of GreenImage to the Binary image
% non pores are totally transparent, pores are green with 1/3 transparency
set(GreenImage, 'AlphaData', BinaryImage/3) 
hold off

% Removes stray silicon pixels in the pores
FilledPoresBinaryImage = imfill(BinaryImage,'holes');  

PoreBoundaries = bwboundaries(FilledPoresBinaryImage);

% Assign unique number to each pore 
Label = bwlabel(BinaryImage);

%Calculate area and circumference of every pore
stats = regionprops(Label, BinaryImage, 'Area', 'Perimeter');
PoreAreas = [stats.Area];
PoreCircumference = [stats.Perimeter];

%Convert from number of pixels to units of distance
CircumferencePores = PoreCircumference*(PixelSize);
DiameterPores = 2*(sqrt(PoreAreas/pi))*(PixelSize);

figure('DefaultAxesFontSize',14)

%Calculate number of pores in each bin and an index mask for these pores
[BinCount,~,Bindex]=histcounts(DiameterPores,PoreDistributionBins);

% Find the mean circumference of every pore in each bin
for i = 1:length(PoreDistributionBins)
    MeanCircumferenceBin(i) = mean(nonzeros((Bindex==i).*CircumferencePores)); 
end

%Set the average circumference to 0 for empty bins
MeanCircumferenceBin(isnan(MeanCircumferenceBin))=0;

% For each bin weight count by average circumference
if(WeightByCircumference)
    BinCount=BinCount.*MeanCircumferenceBin(1:end-1);  
end

HistogramPlot = histogram('BinEdges', PoreDistributionBins, ...
                          'BinCounts', BinCount, FaceColor='k');
xlabel('Pore Diameter (nm)', FontSize=18)
ylabel('Pore Count', FontSize=18)

MeanPoreSize = mean(DiameterPores)
MedianPoreSize = median(DiameterPores)