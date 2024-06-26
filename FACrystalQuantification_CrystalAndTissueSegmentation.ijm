/* Author: Ahmad Kamal Hamid, Wagner group, Institute of Physiology, University of Zurich
 *  This script is an automated batch macro that processes brightfield images of renal tissue containing folic acid (FA) crystals (relevant for the folic acid-induced acute kidney injury model)
 *  It was written on ImageJ 1.53t
 */
// Commands below prompt the user to select an input folder (of image files, e.g. tiff, dicom, fits, pgm, jpeg, bmp, gif) and output folder where measured images will be stored for later reference/validation
inputDir=getDirectory("Select input folder");
outputDir=getDirectory("Select output folder");
// Obtaining first timestamp to eventually calculate runtime for the macro
TimeStamp1=getTime();
// Commands below initiate batching and a for loop that iterates through images in the input folder list while running the analysis
setBatchMode(true); 
image_list = getFileList(inputDir);
for (k=0; k<image_list.length; k++) {
	title = "[Progress]";
	run("Text Window...", "name="+ title +" width=30 height=2 monospaced");
// The for loop below codes for a progress bar for the processing
	for (k=0; k<image_list.length; k++) {
		print(title, "\\Update:"+k+"/"+image_list.length+" ("+(k*100)/image_list.length+"%)\n"+getBar(k, image_list.length));
		open(inputDir+image_list[k]);
// Command below simply ensures that no selection is active on the image upon opening, as can occur after removing artifacts and saving the image in preparation
		run("Select None");
		setBackgroundColor(0, 0, 0);
// Command below replaces all truly black pixels with white, this is relevant in stitched images where background may be white while canvas (signal absence) is black (microscope dependent)
		//changeValues(0x000000,0x000000,0xffffff);
//A series of duplications is then run for downstream use
		ImageTitle=getTitle();
		run("Duplicate...", "title=Original1");
		run("Duplicate...", "title=Original2");
		run("Duplicate...", "title=Original3");
		run("Duplicate...", "title=Original0");
/* This block constitutes the preprocessing phase: tissue delineation where the ROI can be used in downstream processing stages
 *  First the image is downsampled 4x for rapid computation and then thresholded using the saturation map from the HSB color space
 *  The floodFill command is used to convert canvas (at the corners in a square-tiled stitched image) color to black to prevent downstream interference with the variance filtering
 *  Main approach is to denoise the thresholded image, dilate to partially fill space occupied by tissue
 *  smoothen with a Gaussian blur, accentuate borders with variance filtering, and finally fill holes to create a continuous homogenous surface
 *  Afterwards, a wand selection is made at the center of the image (where the tissue has highest probability of being, but many alternative approaches exist):
 *  e.g.: for non-automated selection, use code below, but then batch mode has to be set as false significantly increasing computational demand
	setTool("wand");
	{waitForUser("Please click the white ROI \n\nThen click OK");
	};
 */ 
		run("Scale...", "x=0.25 y=0.25 interpolation=Bilinear average create title=Downscaled.tif");
		X=getWidth();
		Y=getHeight();
		run("HSB Stack");
		run("Convert Stack to Images");
		close("Hue");
		close("Brightness");
		selectWindow("Saturation");
		run("Invert");
		setThreshold(245, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Remove Outliers...", "radius=1 threshold=1 which=Bright");
		setForegroundColor(0, 0, 0);
		floodFill(0, 0);
		floodFill(X-1, 0);
		floodFill(X-1, Y-1);
		floodFill(0, Y-1);
		for (i=0; i<3; i++) {
				run("Dilate");
		}
		for (i=0; i<20; i++) {
				run("Despeckle");
		}
		run("Remove Outliers...", "radius=30 threshold=1 which=Bright");
		for (i=0; i<2; i++) {
				run("Gaussian Blur...", "sigma=10");
		}
		run("Variance...", "radius=20");
		run("Multiply...", "value=255");
		run("Fill Holes");
		rename("TraceImage");
		centroidX=round(X/2);
		centroidY=round(Y/2);
		setTool("wand");
		doWand(centroidX, centroidY);
/* This block constitutes the first processing phase: generation of the total tissue image to which normalization will be made
 *  The original image is first downsampled by binning without bilinear interpolation
 *  Next, the image is red-thresholded to isolate tissue from background
 *  A mild Gaussian blur is then applied to smoothen and debinarize the image, and a heavy variance filter follows along with denoisning
 *  The goal is to create an image where all tissue-occupied space is white, including tubular lumens, but not large anatomical and artifactual spaces
 */
		selectWindow("Original1");
		run("Bin...", "x=4 y=4 bin=Average");
		// Color Thresholder 2.9.0/1.53t
		// Autogenerated macro, single images only!
		min=newArray(3);
		max=newArray(3);
		filter=newArray(3);
		a=getTitle();
		run("RGB Stack");
		run("Convert Stack to Images");
		selectWindow("Red");
		rename("0");
		selectWindow("Green");
		rename("1");
		selectWindow("Blue");
		rename("2");
		min[0]=0;
		max[0]=155;
		filter[0]="pass";
		min[1]=0;
		max[1]=255;
		filter[1]="pass";
		min[2]=0;
		max[2]=255;
		filter[2]="pass";
		for (i=0;i<3;i++){
		  selectWindow(""+i);
		  setThreshold(min[i], max[i]);
		  run("Convert to Mask");
		  if (filter[i]=="stop")  run("Invert");
		}
		imageCalculator("AND create", "0","1");
		imageCalculator("AND create", "Result of 0","2");
		for (i=0;i<3;i++){
		  selectWindow(""+i);
		  close();
		}
		selectWindow("Result of 0");
		close();
		selectWindow("Result of Result of 0");
		rename(a);
		// Colour Thresholding-------------
		run("Gaussian Blur...", "sigma=1");
		run("Variance...", "radius=10");
		run("Remove Outliers...", "radius=50 threshold=1 which=Bright");
		setThreshold(254, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		rename("NormalizationImage");
// Here the ROI selected in the preprocessing phase is restored to the total tissue image, and then both the image and the selection are upsampled to original size
		selectWindow("TraceImage");
		selectWindow("NormalizationImage");
		run("Restore Selection");
		run("Clear Outside");
		run("Select None");
		run("Scale...", "x=4 y=4 interpolation=Bilinear average create title=Total_tissue_area");
		run("Restore Selection");
		run("Scale... ", "x=4 y=4");
		setThreshold(1, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Restore Selection");
/* This block constitutes the second processing phase: generation of a crystal signal image
 * The original image is first hue-thresholded to isolate crystal-positive regions
 * Next, white islands and non-specific objects (e.g. RBCs) are removed using iterative despeckling and the analyze particles function 
 * This will generate a binary image where crystals are white and all else is black
 * The "set Measurements" command dictates what parameters are measured downstream. Currently, only integrated density is selected 
 * Pixel count can be easily calculated from RawIntDen by dividing by 255 
 */
 		selectWindow("Original2");
		// Color Thresholder 2.9.0/1.53t
		// Autogenerated macro, single images only!
		min=newArray(3);
		max=newArray(3);
		filter=newArray(3);
		a=getTitle();
		run("HSB Stack");
		run("Convert Stack to Images");
		selectWindow("Hue");
		rename("0");
		selectWindow("Saturation");
		rename("1");
		selectWindow("Brightness");
		rename("2");
		min[0]=25;
		max[0]=50;
		filter[0]="pass";
		min[1]=0;
		max[1]=255;
		filter[1]="pass";
		min[2]=0;
		max[2]=255;
		filter[2]="pass";
		for (i=0;i<3;i++){
		  selectWindow(""+i);
		  setThreshold(min[i], max[i]);
		  run("Convert to Mask");
		  if (filter[i]=="stop")  run("Invert");
		}
		imageCalculator("AND create", "0","1");
		imageCalculator("AND create", "Result of 0","2");
		for (i=0;i<3;i++){
		  selectWindow(""+i);
		  close();
		}
		selectWindow("Result of 0");
		close();
		selectWindow("Result of Result of 0");
		rename(a);
		// Colour Thresholding-------------
		for (i=0; i<20; i++) {
				run("Despeckle");
		}
		run("Analyze Particles...", "size=100-Infinity pixel show=Masks");
		run("Invert");
		run("Set Measurements...", "integrated display redirect=None decimal=3");
		run("Invert");
		run("Restore Selection");
		LUT=is("Inverting LUT");
		if (LUT==true) {
			run("Invert LUT");
		}
		run("Clear Outside");
		saveAs("Tiff", outputDir+"FA_Crystal_Signal_Binary_"+image_list[k]);
		run("Measure");
		rename("BinaryCrystals");
/* This block constitutes an optional segment which replaces all white pixels in the binary crystal image with the respective saturation in the original image
 * The saturation and inverted brightness maps of the original image are obtained and computed with the binary crystal image using the min function 
 */
		selectWindow("Original3");
		run("Restore Selection");
		run("Clear Outside");
		run("Select None");
		run("HSB Stack");
		run("Stack to Images");
		close("Hue");
		close("Brightness");
		// Overlaying saturation
		imageCalculator("Min create", "BinaryCrystals","Saturation");
		selectWindow("Result of BinaryCrystals");
		run("Restore Selection");
		saveAs("Tiff", outputDir+"FA_Crystal_Signal_Saturation_"+image_list[k]);
		run("Measure");
		// Total tissue area
		selectWindow("Total_tissue_area");
		saveAs("Tiff", outputDir+"Total_Area_Signal_"+image_list[k]);
		run("Measure");
 		close("*");
 	}
// Below is the continuation of the progress bar for loop initiated above
 	print(title, "\\Close");
 	function getBar(p1, p2) {
        n = 20;
        bar1 = "--------------------";
        bar2 = "********************";
        index = round(n*(p1/p2));
        if (index<1) index = 1;
        if (index>n-1) index = n-1;
        return substring(bar2, 0, index) + substring(bar1, index+1, n);
	}
}	
// Below, the results are saved in a CSV file 
saveAs("Results",outputDir+"Crystal_Binary&SaturationGrayscale_RawIntDen.CSV");
// Elapsed time and time per image
TimeStamp2=getTime();
ElapsedTimeMS=TimeStamp2-TimeStamp1
	if (ElapsedTimeMS<60000) {
		ElapsedTime=d2s(ElapsedTimeMS/1000, 0);
		TimeUnit="sec";
	}
	if (ElapsedTimeMS>60000) {
		ElapsedTime=d2s(ElapsedTimeMS/60000, 1);
		TimeUnit="min";
	}
	if (ElapsedTimeMS>3600000) {
		ElapsedTime=d2s(ElapsedTimeMS/3600000, 2);
		TimeUnit="hr";
	}
TimePerImage=d2s((ElapsedTimeMS/1000)/image_list.length, 2);
setBatchMode(false);
waitForUser("Done!", image_list.length+" images have been processed, and the output images and results have been saved to the indicated directory at:\n\n"+outputDir+"\n Elapsed time = "+ElapsedTime+" "+TimeUnit+"\n On average, "+TimePerImage+" sec/image");



		