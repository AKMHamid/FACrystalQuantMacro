/* Author: Ahmad Kamal Hamid, Wagner group, Institute of Physiology, University of Zurich
 *  This script is an automated batch macro that processes brightfield images of renal tissue containing folic acid (FA) crystals (relevant for the folic acid-induced acute kidney injury model)
 *  The end result is a histogram of the Euclidean distance map of all crystal pixels relative to the centroid of an active selection (input image must contain a ROI delineating the tissue)
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
// This block generates a Euclidean distance map with the same resolution as the original image
		setBackgroundColor(0, 0, 0);
		run("Set Measurements...", "centroid display redirect=None decimal=3");
		// Removes global scale and determines ROI centroid (an active selection must be present in the input image)
		getPixelSize(DistanceUnit, pixelWidth, pixelHeight);
		InverseScale=d2s(1/pixelWidth, 5);
		run("Set Scale...", "distance=0 known=0 unit=pixel");
		run("Measure");
		CentroidX=getResult("X", nResults-1);
		CentroidY=getResult("Y", nResults-1);	
		Original=getTitle();
		// Here is horizontal and vertical ramp images are generated to facilitate the calculation of distances in accordance with the formula sqrt[((X2-X1)^2)+((Y2-Y1)^2)]
		w=getWidth();
		h=getHeight();		
		newImage("Horizontal", "32-bit ramp", w, h, 1);
		run("Multiply...", "value=" + w);
		run("Subtract...", "value=" + CentroidX);
		run("Square");
		newImage("Untitled", "32-bit ramp", h, w, 1);
		rename("Vertical");
		run("Rotate 90 Degrees Right");
		run("Multiply...", "value=" + h);
		run("Subtract...", "value=" + CentroidY);
		run("Square");
		imageCalculator("Add create", "Horizontal","Vertical");
		rename("Distance");
		run("Square Root");
// This block sets the value of  white pixels (crystals) to 1, and multiplies it by the distance image from above such that every crystal pixel value is equivalent to its distance from the ROI centroid in pixels
		selectWindow(Original);
		run("Duplicate...", "title=Map");
		setThreshold(1, 255);
		run("Convert to Mask");
		run("Divide...", "value=255");
		imageCalculator("Multiply create 32-bit", "Distance", "Map");
		rename("DistanceMap");
		close("\\Others");
		run("Restore Selection");
		//This deletes the last row from the results table (corresponding to the centroid measurement) to reset the table for the next image processing
		IJ.deleteRows(nResults-1, nResults-1); 
		/* These variables describe the output histogram
		 *  nBins can be adjusted to whichever number of bins is preferred
		 *  histMin is set to 1 to exclude background pixels (where no crystals are present)
		 *  histMax must be set to at least the maximum radius (in pixels) of the ROI such that all crystals are included
		 */
		nBins=250;
		histMin=1;
		histMax=20000;
		getHistogram(values, counts, nBins, histMin, histMax);	
		Table.setColumn("Values_"+k+"_"+Original, values);
		Table.setColumn("Counts_"+k+"_"+Original, counts);
		run("Fire");
		// Scale is restored for later reference to the images
		run("Set Scale...", "distance=1 known="+pixelWidth+" unit="+DistanceUnit);
		saveAs("Tiff", outputDir+"EuclideanDistanceMap_"+image_list[k]);
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
// Histogram data is saved as a CSV file with the bin and range information in the title as well as the image scale (assuming a calibrated image) to facilitate later unit conversion
saveAs("Results",outputDir+"EuclideanDistanceMap_Histogram_"+nBins+"Bins_"+histMax+"Range_"+InverseScale+"Pixels_per_"+DistanceUnit+".CSV");
//Elapsed time and time per image
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





		