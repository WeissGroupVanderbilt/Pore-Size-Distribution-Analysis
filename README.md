# PoreDiameterDistribution

## Description
  This MATLAB script identifies size distribution of pores, developed for use with SEM images of porous silicon, but applicable to any image with approximately circular objects with a distribution of sizes.
  
  If you use this code, please cite: 
    S. J. Ward, T. Cao, X. Zhou, C. Chang and S. M. Weiss "Protein Identification and Quantification Using Porous Silicon Arrays, Optical Measurements, and Machine Learning," Biosensors 13, 879 (2023). doi: https://doi.org/10.3390/bios13090879
  
## Instructions
  Set filname, size of pixels in the units required for pore sizes, threshold greyscale value to differentiate between pores and non-pores, define the start and end and width of the histogram bins, and whether the size of the pores should be weighted by the pore circumference (and consequently the number of adsorption sites on the pore walls, lending more importance to larger pores) in the pore size distributio histogram. Then optionally select the number of tiles the  image should be split into in x and y directions (there should be roughly  a uniform number of pores in each tile).
