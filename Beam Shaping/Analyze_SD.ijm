function sumArray(array) { 
	// calculates sum of all array elements
	sum_array=0;
	for (i = 0; i < lengthOf(array); i++) {
		sum_array = sum_array + array[i];
	}
	return sum_array;
}

function weightedSumArray(array, weights) { 
	// calculates weighted sum of all array elements
	sum_array=0;
	for (i = 0; i < lengthOf(array); i++) {
		sum_array = sum_array + (array[i]*weights[i]);
	}
	sum_array = sum_array / sumArray(weights);
	return sum_array;
}

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

csd = true;

dir = getDir("Choose a Directory");
imagelist=getFileList(dir);

for (k=0;k<imagelist.length;k++) {
	open(dir + imagelist[k]);

	img = getTitle();
	
	//Threshold 1% to remove noise influence
	run("Clear Results");
	run("Subtract...", "value=3");
	run("32-bit");
	Stack.setXUnit("µm");
	run("Properties...", "channels=1 slices=1 frames=1 pixel_width=2.94 pixel_height=2.94 voxel_depth=2.94");
	run("Set Measurements...", "min redirect=None decimal=3");
	run("Measure");
	maxInt = getResult("Max", 0);
	minInt = getResult("Min", 0);
	run("Subtract...", "value="+minInt+" slice");
	run("Divide...", "value="+maxInt+" slice");
	run("Min...", "value=0 slice");
	run("Remove Outliers...", "radius=5 threshold=0 which=Bright");
		
	if (csd) {
		makeRectangle(0, 500, 1280, 24);
	}
	else {
		makeRectangle(1280/4, 256, 1280/2, 512);
	}
		
	//Get Profile
	run("Plot Profile");
	Plot.getValues(xvals, profile);
	close();
	
	//Calculate weighted mean
	w_mean = weightedSumArray(xvals, profile);
		
	//Calculate WSD
	values = newArray(lengthOf(xvals));
	for (i = 1; i < lengthOf(xvals); i++) {
		values[i] = pow((xvals[i] - w_mean),2);
	}
	w_sd = sqrt(weightedSumArray(values, profile));
	print(imagelist[k] , w_sd/21);
	close(imagelist[k]);
}
