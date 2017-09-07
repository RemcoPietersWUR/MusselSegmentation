%Post processsing 

% %Load segmentated data
% uiopen('load');
% 
% %Check segmentation results
% [BWfill,BWline]=check_segmentation(BWfill,BWline,IMrot,'blend',se2);
% 
% disp('Saving vars')
% uisave({'IMrot','BWline','BWfill','px_x','px_y','px_z','se2','FileInfo'},[FileInfo.prefix,'_post_proc.mat']);

uiopen('load')
%Compute region props
shell_regionprops(BWfill,IMrot,px_z)


