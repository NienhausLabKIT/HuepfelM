System requirements:

The software has been tested on Windows 7 and Windows 10 with Python version 3.7 installed. 
Anaconda 3 was used as python distribution and Spyder 4 as python editor. 
No non-standard hardware is required. 
To process large data, enough RAM is required. 

Installation: 

The software is provided as a python script. 
Therefore, only a python distribution (e.g. Anaconda 3) must be installed on the PC. 
The following packages are used and need to be installed:

-	Numpy
-	scikit-image
-	Skimage
-	Scipy
-	Matplotlib
-	Pywavelets
-	Joblib
-	Multiprocessing
-	tifffile

Using Anaconda the packages can be installed by typing:

conda install "package” 	or 	pip install "package"

into the IPython console. 
Installation of the packages takes up to 10 minutes.

Usage: 

-	Open WBNS.py in your python editor (e.g. Spyder 4)
-	In the top section of the script, insert file location and file name of the image data (TIFF format).
	Python requires only "/" in the directory path. Therefore "\" must be replaced!
-	Insert the resolution in units of pixels. 
-	Set the number of levels used to extract the noise. (Default is ‘1’. For low resolution images ‘2’ may yield better results.)
-	Run the script.
-	Outputs (TIFF format) will be saved in the same folder as the input data.

Demo data:

The resolution parameter and noise level parameter are given in the ..._INFO.txt file.

The run time for 3D demo data (Simulation_Microtubules_3D.tif) is 7 s (on Intel(R) Core(TM) i7-8700K CPU; 32 GB RAM) and 
21 s (on Pentium(R) Dual-Core CPU E5700; 6 GB RAM).


If you have any problems or ideas how to improve the script
please give me some feedback:

manuel.huepfel@kit.edu

Enjoy!
