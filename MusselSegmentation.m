%Mussel segmentation
clear all
close all

%Segmentation parameters
%Sensitivity edge-detection
sigmaCanny=2.5;
%Structering element for morphological closing 
se=strel('disk',1);
%Structering element for morphological opening 
se2=strel('disk',3);
%Remove objects equal or smaller than 200 px
areaopen = false;

%%Get file info CT images
FileInfo = importCT; %TEMP for debug
%load FileInfo.mat;
%%Load image sequence in memory
FirstSlice = FileInfo.id_start; %First slice for segmentation, type char
LastSlice = '0500';%FileInfo.id_stop %Last slice for segmentation, type char
CTstack=loadIMsequence(FileInfo,FirstSlice,LastSlice,1);

%%Orientate mussel
[~,~,~,ui_slice] = size(CTstack);
ui_slice = floor(ui_slice/2);
[orientation_angle,IMrot] = select_cross_section(CTstack,ui_slice);

%Free memory
clear CTstack

%Select processing region between foot and nose
pos_foot_nose=processing_selection(IMrot,'X');
%pos_foot_nose=[14,512;499,512];
%Make substack
IMrot=IMrot(:,:,floor(pos_foot_nose(1,1)):floor(pos_foot_nose(2,1)));


%%Preprocessing
%Apply 3D Gaussian filter 
sigma3D = 2; %standard deviation smoothing kernel
CTgauss = imgaussfilt3(IMrot,sigma3D);
%Compute global gray threshold, Otsu's method
graylevel=graythresh(CTgauss);

%%Processing
[px_x,px_y,px_z] = size(CTgauss);
%Threshold image with global thresholding value
%Preallocation
BWthres_xy=true(size(CTgauss));
BWthres_yz=true(size(CTgauss));
%Define morphological structuring element to dilate boundary of the
%thresholded shell to include strong edges.
se_thres=strel('disk',2,4);
%nose-foot
for id=1:px_z
    BWxy=imbinarize(CTgauss(:,:,id),graylevel);
    BWthres_xy(:,:,id)=imdilate(BWxy,se_thres);
end
%lateral
for id=1:px_x
    BWyz=imbinarize(squeeze(CTgauss(id,:,:)),graylevel);
    BWthres_yz(id,:,:)=imdilate(BWyz,se_thres);
end
%slider_showpair(BWthres_xy,BWthres_yz,'falsecolor')
%Combine foot-nose + lateral gray scale thresholding
BWthres=and(BWthres_xy,BWthres_yz);


%Get ROI (shell) 
%Preallocation
Shell_roi = true(size(CTgauss));
graylevels=2^16;
hist_counts=zeros(graylevels,px_z);
thres_level=zeros(1,px_z);
for id=1:px_z
    [hist_counts(:,id),~]=imhist(immultiply(CTgauss(:,:,id),BWthres(:,:,id)),graylevels);
    thres_level(1,id)=otsuthresh(hist_counts(2:end,id));
    Shell_roi(:,:,id)=imbinarize(CTgauss(:,:,id),thres_level(1,id));
end
%slider_showpair(CTgauss,Shell_roi,'falsecolor')
%slider_showpair(BWthres,Shell_roi,'falsecolor')
% %Histogram equalisation
% CThist=zeros(size(CTgauss),class(CTgauss));
% for id=1:NumberOfSlices
% CThist(:,:,id)=adapthisteq(immultiply(bwconvhull(BWthres(:,:,id),'objects'),CTgauss(:,:,id)));
% end

%Edge detection, Canny method: double threshold less effected by noise
sigmaCanny=sigmaCanny;
%foot-nose
%Preallocation
BWcanny_xy=true(size(CTgauss));
BWsobel_xy=true(size(CTgauss));
ThresCanny_xy=zeros(2,px_z);
for id=1:px_z
    [~,ThresCanny_xy(:,id)]= edge(CTgauss(:,:,id),...
        'canny',[],sigmaCanny);
    [BWcanny_xy(:,:,id),ThresCanny_xy(:,id)]= edge(IMrot(:,:,id),...
        'canny',[ThresCanny_xy(1,id),0.5*ThresCanny_xy(2,id)],sigmaCanny);
    BWsobel_xy(:,:,id)=edge(CTgauss(:,:,id),'sobel');
end
BWedge_xy=BWcanny_xy|BWsobel_xy;
clear BWcanny_xy BWsobel_xy
%lateral
sigmaCanny=sigmaCanny;
BWcanny_yz=true(size(CTgauss));
BWsobel_yz=true(size(CTgauss));
ThresCanny_yz=zeros(2,px_x);
for id=1:px_x
    [~,ThresCanny_yz(:,id)]= edge(squeeze(CTgauss(id,:,:)),...
        'canny',[],sigmaCanny);
    [BWcanny_yz(id,:,:),ThresCanny_yz(:,id)]= edge(squeeze(IMrot(id,:,:)),...
        'canny',[ThresCanny_yz(1,id),0.5*ThresCanny_yz(2,id)],sigmaCanny);
    BWsobel_yz(id,:,:)=edge(squeeze(CTgauss(id,:,:)),'sobel');
end
BWedge_yz=BWcanny_yz|BWsobel_yz;
clear BWcanny_yz BWsobel_yz
%slider_showpair(BWedge_xy,BWedge_yz,'falsecolor')
%Multiply detected edge and gray level thresholded image to cancel edge
%'noise' detected in the 'middle' of the shell. Use a convex hull to
%include both shell halfs
%Preallocation
%foot-nose
BWshell_xy=true(size(CTgauss));
BWconvperim_xy=true(size(CTgauss));
se_conv=strel('disk',8,4);
for id=1:px_z
    BWconvperim_xy(:,:,id)=imdilate(bwperim(bwconvhull(BWthres_xy(:,:,id))),se_conv);
    BWshell_xy(:,:,id)=immultiply((BWthres_xy(:,:,id)|BWconvperim_xy(:,:,id)),BWedge_xy(:,:,id));
end
clear BWconvperim_xy BWedge_xy BWthres_xy
%lateral
BWshell_yz=true(size(CTgauss));
BWconvperim_yz=true(size(CTgauss));
se_conv=strel('disk',8,4);
for id=1:px_z
    BWconvperim_yz(:,:,id)=imdilate(bwperim(bwconvhull(BWthres_yz(:,:,id))),se_conv);
    BWshell_yz(:,:,id)=immultiply((BWthres_yz(:,:,id)|BWconvperim_yz(:,:,id)),BWedge_yz(:,:,id));
end
    clear BWconvperim_yz BWedge_yz BWthres_yz
%Remove small objects from binary image, 3D
NoiseSize = 4000; %in pixels
conn=26; %connectifity
BWclean_xy=bwareaopen(BWshell_xy,NoiseSize,conn);
clear BWshell_xy
BWclean_yz=bwareaopen(BWshell_yz,NoiseSize,conn);
clear BWshell_yz

%Remove small objects from binary image, 2D
NoiseSize = 15; %in pixels
conn=8; %connectifity
for id=1:px_z
BWclean_xy(:,:,id)=bwareaopen(BWclean_xy(:,:,id),NoiseSize,conn);
BWclean_yz(:,:,id)=bwareaopen(BWclean_yz(:,:,id),NoiseSize,conn);
end

BWclean=or(BWclean_xy,BWclean_yz);
clear BWclean_xy BWclean_yz
se=se;

for id=1:px_z
    %Remove single isolated pixels
    BWclean(:,:,id)=bwmorph(BWclean(:,:,id),'clean');
    %Fill single isolated gaps
    BWclean(:,:,id)=bwmorph(BWclean(:,:,id),'fill');
    %Remove spur pixels
    BWclean(:,:,id)=bwmorph(BWclean(:,:,id),'spur');
    BWclean2(:,:,id)=imclearborder(BWclean(:,:,id),8);
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'clean');
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'bridge');
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'diag');
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'hbreak');
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'spur');
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'clean');
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'fill');
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'close');
    BWclean2(:,:,id)=imfill(BWclean2(:,:,id),'holes');
    BWclean2(:,:,id)=bwmorph(BWclean2(:,:,id),'remove');
end
BWline=or(BWclean2,BWclean);
%Dilate edge for filling image, using cross element
%se90 = strel('line', 2, 90);
%se0 = strel('line', 2, 0);
%BWdil = imdilate(BWclean, [se0,se90]);
BWfill=true(size(CTgauss));
%Fill in 2D
se2=se2;
for id=1:px_z
    if areaopen 
   BWfill(:,:,id)=bwareaopen(BWclean2(:,:,id),200,4);
    else
    BWfill(:,:,id)=BWclean2(:,:,id);
    end
BWfill(:,:,id)=bwareaopen(BWclean2(:,:,id),200,4);
BWfill(:,:,id) = imfill(BWfill(:,:,id),'holes');
BWfill(:,:,id)=bwmorph(BWfill(:,:,id),'remove');
BWfill(:,:,id)=imclose(BWfill(:,:,id),se);
BWfill(:,:,id)=bwmorph(BWfill(:,:,id),'remove');
BWfill(:,:,id) =imfill(BWfill(:,:,id),'holes');
BWfill(:,:,id)=imopen(BWfill(:,:,id),se2);
end
%Erode edge with a disk to compensate for dilation
%sed = strel('disk',1);
%BWerode = imerode(BWfill, [se0,se90]);


%%Data display

%Compute area of segmented part(s)
%Preallocate
% BWarea=zeros(1,NumberOfSlices);
% for id=1:NumberOfSlices
% BWarea(:,id)=bwarea(BWfinal(:,:,id));
% end

%Output methods
%showOutline(CTstack(:,:,:,slice),BWfinal(:,:,slice),'Segmented Outline');
%showOverlay(CTstack(:,:,:,slice),BWfinal(:,:,slice),'Segmented Area');


%Slider GUI
% type='Area'; %or 'Outline'
% slider(FirstSlice,LastSlice,IMrot,BWfinal,type)
slider_showpair(BWfill,IMrot,'falsecolor')
uisave({'IMrot','BWline','BWfill','px_x','px_y','px_z','se2','FileInfo'},[FileInfo.prefix,'.mat']);



% %Plots
% VarPlot=table2array(SliceProps);
% scatter(VarPlot(:,1),VarPlot(:,2),2,'filled')
% xlabel('Height (px)')
% ylabel('Cross sectional area (px)')
% figure
% s1=scatter3(VarPlot(:,3),VarPlot(:,4),VarPlot(:,1),2,[0,0,1],'filled');
% hold on
% s2=scatter3(VarPlot(:,10),VarPlot(:,11),VarPlot(:,1),2,[1,0,0],'filled');
% hold off
% xlabel('X (px)')
% ylabel('Y (px)')
% zlabel('Height (px)')
% title('Centroid of shell part (Blue none weighted,Red density weighted)')

