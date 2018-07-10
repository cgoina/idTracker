% This function allows users to display idTrackerResults

function idTrackerResults(path_to_datosegm)
load(path_to_datosegm, 'variable');
datosegm=variable;
datosegm2muestravideo_nuevo(datosegm);
