# idTracker
Videotracking system that keeps track of individual identities. www.idtracker.es

# Build the executables
To build the executables simply run make in this directory. Make sure you have the environment variable MATLAB_ROOT 
set to the location of your MATLAB, e.g, on OSX
`
export MATLAB_ROOT=/Applications/MATLAB_R2018a.app
`

# Running in headless mode.

To run in headless mode first your have to create the segmentation file: 'datosegm.mat'. To do that you can start 
`idTracker` with and open the video file that you want to track and after you set all your configuration parameters,
click on save and exit. This will save a file 'datosegm.mat' in your output directory, which defaults to:
`<input__video__directory>/segm`. Then you can use this file and pass it to `idTracker_batch` and once that
completes pass the same file to `idTrackerResults`
, e.g.

```
idTracker data/test_video.avi
idTracker_batch data/segm/datosegm.mat
idTrackerResults data/segm/datosegm.mat
```
