%Post processsing 

%Load segmentated data
uiopen('load');

%Check segmentation results
[BWfill,BWline]=check_segmentation(BWfill,BWline,IMrot,'blend',se2,FileInfo);

disp('Saving vars')
save({'IMrot','BWline','BWfill','px_x','px_y','px_z','se2','FileInfo'},[FileInfo.prefix,'.mat']);

%Compute region props
shell_regionprops(BWfill,IMrot,px_z)


