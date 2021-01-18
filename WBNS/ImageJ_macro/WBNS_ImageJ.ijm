/* Wavelet-based Background Subtraction Macro
 *  
 * Created by Manuel Hüpfel
 * Karlsruher Institut für Technologie (KIT) 
 * Institute of Applied Physics (APH)
 * Wolgang-Gaede Str.1
 * 76131 Karlsruhe
 * 
 * Corresponding author: 
 * G. U. Nienhaus (uli@uiuc.edu)
 * 
 */

//Create and show intro dialog-----------------------
Dialog.create("WBNS");
Dialog.addMessage("Wavelet-based Background Subtraction Macro", 20, "#00008B");
Dialog.addMessage("Created by Manuel H"+fromCharCode(0x00FC)+"pfel\nKarlsruher Institut f"+fromCharCode(0x00FC)+"r Technologie (KIT) \nInstitute of Applied Physics (APH)\nWolgang-Gaede Str.1\n76131 Karlsruhe.", 14, "#00008B");
//Dialog.addMessage("Corresponding author:\nG. U. Nienhaus (uli@uiuc.edu)", 14);
Dialog.addMessage("This macro extracts the low frequency background \nand the high-frequency noise of the input image \nand subsequently subtracts these components.", 14);
//Dialog.addMessage("For further information check our XXXJournalXXX Publication \nDOI:XXX.XXX.XXXX or click on the \"Help\"-Button.", 14);
//Dialog.addHelp("GITHUB");
Dialog.show();

//Get image------------------------------------------
img_list_default = newArray("None");
img_list = getList("image.titles");
img_list = Array.concat(img_list,img_list_default);
if (lengthOf(img_list) <= 1) {
	open();
	image = getTitle();
}
else {
	Dialog.create("WBNS");
	Dialog.addMessage("Select image:");
	Dialog.addChoice("Image:", img_list, "None");
	Dialog.show();
	
	img_choice = Dialog.getChoice();
	if (img_choice == "None") {
		open();
		image = getTitle();
	}
	else {
		selectImage(img_choice);
	}
	image = getTitle();
}

selectImage(image);
getDimensions(width, height, channels, slices, frames);
bit = bitDepth();

//Specify parameters dialog--------------------------
items = newArray("WBNS","WBS");
Dialog.create("WBNS");
Dialog.addMessage("Choose a method:",14);
Dialog.addChoice("\t \t \t \t \t \t  Method:", items, "WBNS");
Dialog.addMessage("FWHM of your PSF in units of pixels:",14);
Dialog.addNumber("\t \t \t \t \t \t  FWHM :", 5);
Dialog.addMessage("No. of levels for noise subtraction (WBNS):",14);
Dialog.addNumber("\t \t \t \t \t \t  Noise Levels :", 1);
Dialog.addCheckbox("Show background", false);
Dialog.addCheckbox("Show noise (only WBNS)", false);
Dialog.show();

method = Dialog.getChoice();
FWHM = Dialog.getNumber();
noise_lvl = Dialog.getNumber();
show_bg = Dialog.getCheckbox();
show_nse = Dialog.getCheckbox();

lvls = Math.ceil(log(FWHM)/log(2));
sigma = Math.pow(2,lvls);
print("FWHM Input: "+FWHM+" \n #Levels: "+lvls+" \n Sigma: "+sigma+" ");

setBatchMode(true);
starttime = getTime();

selectImage(image);
run("Duplicate...", "duplicate");
rename("Input");
setOption("ScaleConversions", false);
run("32-bit");

for (i = 1; i <= slices; i++) { //WBS
	selectImage("Input");
	setSlice(i);
	run("Wavelets 2D", "wavelet=Daubechies particular=DB1 border=[Zero padding] decomposition="+lvls+" reconstructible value=255 thickness=1 dash=0");
	makeRectangle(0, 0, (width/sigma)+1, (height/sigma)+1);
	run("Make Inverse");
	run("Set...", "value=0");
	run("Wavelets 2D", "wavelet=Daubechies particular=DB1 border=[Zero padding] decomposition="+lvls+" inverse reconstructible value=255 thickness=1 dash=0");
	run("Gaussian Blur...", "sigma="+sigma+"");
	rename("Background "+i+"");

	imageCalculator("Subtract create 32-bit", "Input","Background "+i+"");
	rename("Result of WBS "+i+"");
	selectWindow("Result of WBS "+i+"");
	run("Min...", "value=0");
	if (show_bg == false) {
		close("Background "+i+"");
	}
	if (method == "WBS") {
		setOption("ScaleConversions", false);
		run(""+bit+"-bit");
	}
	else { //WBNS
		selectImage("Input");
		setSlice(i);
		run("Wavelets 2D", "wavelet=Daubechies particular=DB1 border=[Zero padding] decomposition="+noise_lvl+" reconstructible value=255 thickness=1 dash=0");
		makeRectangle(0, 0, (width/Math.pow(2,noise_lvl)+1), (height/Math.pow(2,noise_lvl)+1));
		run("Set...", "value=1");
		run("Select None");
		run("Wavelets 2D", "wavelet=Daubechies particular=DB1 border=[Zero padding] decomposition="+noise_lvl+" inverse reconstructible value=255 thickness=1 dash=0");
		rename("Noise "+i+"");
		selectImage("Noise "+i+"");
		run("Min...", "value=0");
		getStatistics(area, mean, min, max, std);
		run("Max...", "value="+ mean + 2*std +"");
		selectImage("Result of WBS "+i+"");
		imageCalculator("Subtract create 32-bit", "Result of WBS "+i+"","Noise "+i+"");
		rename("Result of WBNS "+i+" ");
		run("Min...", "value=0");
		setOption("ScaleConversions", false);
		run(""+bit+"-bit");
		close("Result of WBS "+i+"");
		if (show_nse == false) {
			close("Noise "+i+"");
		}
	}
	showProgress(i, slices);
}

run("Images to Stack", "name=[Result of "+method+"] title=Result of WB");
setBatchMode("show");

if (show_bg == true) {
	run("Images to Stack", "name=[Background of "+method+"] title=Background");
	setOption("ScaleConversions", false);
	run(""+bit+"-bit");
	setBatchMode("show");
}

if (method == "WBNS") {
if (show_nse == true) {
	run("Images to Stack", "name=[Noise of "+method+"] title=Noise");
	setOption("ScaleConversions", false);
	run(""+bit+"-bit");
	setBatchMode("show");
}
}

endtime = getTime();
time = (endtime - starttime)/1000;
print("Time elapsed: " + time + "s");
