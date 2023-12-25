function indexOfArray(array, value) {
	// returns index of value in array (e.g. position of maximum)
    count=0;
    for (a=0; a<lengthOf(array); a++) {
        if (array[a]==value) {
            return count;
        }
        else {
			count++;
        }
    }
}


//-------------------------------------------------------------------------


run("Clear Results");
//init GPU
run("CLIJ2 Macro Extensions", "cl_device=");

dir = getDir("Choose Directory containing Files");
imagelist=getFileList(dir);

setBatchMode(true);

//Open Background Image
path = File.openDialog("Select Background");
open(path); // open the file
offset = getTitle();

// mean of Ref
mean_GT = 50;

dir2 = getDir("Choose Directory for Results");

for (i=0;i<imagelist.length;i++) {
	//open, offset correction
	open(path); // open the file
	offset = getTitle();
	
	open(dir + imagelist[i]);	
	image = getTitle();
	imageCalculator("Subtract stack", image,offset);
	run("32-bit");
	run("Fire");
	
	//norm to ref (mean of all pixels)
	Ext.CLIJ2_push(image);
	Ext.CLIJ2_meanOfAllPixels(image);
	
	mean_img = getResult("Mean", 0);
	ratio = mean_GT/mean_img;
	run("Multiply...", "value="+ratio+" stack");
	
	//Save Slice and MIP Front
	setSlice(68);
	makeRectangle(518, 620, 1024, 1024);
	run("Duplicate...", " ");
	run("Square Root");
	saveAs("tiff", dir2 + "Slice_68_" +imagelist[i] + ".tif");
	close();
	
	run("Z Project...", "projection=[Max Intensity]");
	makeRectangle(518, 620, 1024, 1024);
	run("Crop");
	run("Square Root");
	run("Fire");
	saveAs("tiff", dir2 + "Front_MIP_" +imagelist[i] + ".tif");
	close();
	
	//Reslice
	selectWindow(image);
	makeRectangle(580, 0, 822, 2048);
	run("Reslice [/]...", "output=1.000 start=Top avoid");
	run("Scale...", "x=1.0 y=2.5 interpolation=Bicubic process create");
	run("Gaussian Blur...", "sigma=2 stack");
	
	//Find Slice number
	run("Plot Z-axis Profile");
	Plot.getValues(max_idx, max_val);
	close();
	//Get Maximum position
	Array.getStatistics(max_val, lmin, lmax, lmean, lstdDev);
	max_pos = indexOfArray(max_val, lmax);
	
	//Save Slice and MIP Top
	setSlice(max_pos);
	run("Duplicate...", " ");
	run("Square Root");
	saveAs("tiff", dir2 + "Slice_1085_" +imagelist[i] + ".tif");
	close();
	
	run("Z Project...", "projection=[Max Intensity]");
	run("Square Root");
	run("Fire");
	saveAs("tiff", dir2 + "Top_MIP_" +imagelist[i] + ".tif");
	
	Ext.CLIJ2_clear();
	run("Clear Results");
	close("*");
}
