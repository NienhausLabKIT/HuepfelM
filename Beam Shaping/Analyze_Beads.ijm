dir = getDir("Choose Directory containing Files");
imagelist=getFileList(dir);

setBatchMode(true);

//Open Background Image
path = File.openDialog("Select Background");
open(path); // open the file
offset = getTitle();

dir2 = getDir("Choose Directory for Results");

for (i=0;i<imagelist.length;i++) {
	//open, offset correction
	open(dir + imagelist[i]);	
	Stack.setXUnit("µm");
	run("Properties...", "pixel_width=0.406 pixel_height=0.406 voxel_depth=1");
	image = getTitle();
	imageCalculator("Subtract stack", image,offset);
	
	run("Z Project...", "start=50 stop=250 projection=[Max Intensity]");
	mip = getTitle();
	makeRectangle(512, 0, 1024, 2048);
	run("Clear Results");
	run("Find Maxima...", "prominence=100 output=List");

	//Get Point list
	x_coord = newArray(nResults);
	y_coord = newArray(nResults);
	for (q = 0; q < nResults; q++) {
		x_coord[q] = getResult("X", q);
		y_coord[q] = getResult("Y", q);
	}
	close(mip);
	
	//Loop through list and get FWHM
	selectImage(image);
	FWHM = newArray(nResults);
	Bright = newArray(nResults);
	for (q = 0; q < nResults; q++) {
		makeRectangle(x_coord[q]-1, y_coord[q]-1, 3, 3);
		run("Plot Z-axis Profile");
		Plot.getValues(xpoints, ypoints);
		close();
		
		//Gaussian fit
		Fit.doFit("Gaussian (no offset)", xpoints, ypoints);
		if (2.355*Fit.p(2) < 20 && 2.355*Fit.p(2) > 1) {
			FWHM[q] = 2.355*Fit.p(2);
		}
		if (Fit.p(0) < 5000 && Fit.p(0) > 0) {
			Bright[q] = Fit.p(0);
		}
	}
	
	run("Clear Results");
	for (q=0; q<FWHM.length; q++)
    setResult("Value", q, FWHM[q]);
    updateResults();
    saveAs("Results", dir2 + "FWHM_" +imagelist[i] + ".csv");  
    
    run("Clear Results");
	for (q=0; q<Bright.length; q++)
    setResult("Value", q, Bright[q]);
    updateResults();
    saveAs("Results", dir2 + "Bright_" +imagelist[i] + ".csv");

	Array.getStatistics(FWHM, min, max, mean, stdDev);
	Array.getStatistics(Bright, Brightmin, Brightmax, Brightmean, BrightstdDev);
	print(image + "  " + "FWHM_Z = " + mean + " +- " + stdDev/sqrt(FWHM.length) + "  Brightness = " + Brightmean + " +- " + BrightstdDev/sqrt(Bright.length));
	
	close(image);
}
