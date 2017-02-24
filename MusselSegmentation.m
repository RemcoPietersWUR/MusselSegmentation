%Mussel segmentation
clear all
close all
%%Get file info CT images
FileInfo = importCT;
%load FileInfo.mat;
%%Load image sequence in memory
FirstSlice = '0002'; %First slice for segmentation, type char
LastSlice = '0500'; %Last slice for segmentation, type char
CTstack=loadIMsequence(FileInfo,FirstSlice,LastSlice,1);

%%Preprocessing
%Apply 3D Gaussian filter 
sigma3D = 1; %standard deviation smoothing kernel
CTgauss = imgaussfilt3(squeeze(CTstack),sigma3D);
%Compute global gray threshold, Otsu's method
graylevel=graythresh(CTgauss);

%%Processing
[~,~,NumberOfSlices] = size(CTgauss);
%Threshold image with global thresholding value
%Preallocation
BWthres=true(size(CTgauss));
%Define morphological structuring element to dilate boundary of the
%thresholded shell to include strong edges.
se_thres=strel('disk',2,4);
for id=1:NumberOfSlices
    BW=im2bw(CTgauss(:,:,id),graylevel);
    BWthres(:,:,id)=imdilate(BW,se_thres);
end

% %Histogram equalisation
% CThist=zeros(size(CTgauss),class(CTgauss));
% for id=1:NumberOfSlices
% CThist(:,:,id)=adapthisteq(immultiply(bwconvhull(BWthres(:,:,id),'objects'),CTgauss(:,:,id)));
% end

%Edge detection, Canny method: double threshold less effected by noise
sigmaCanny=2.5;
%Preallocation
BWcanny=true(size(CTgauss));
ThresCanny=zeros(2,NumberOfSlices);
for id=1:NumberOfSlices
    [BWcanny(:,:,id),ThresCanny(:,id)]= edge(CTgauss(:,:,id),...
        'canny',[],sigmaCanny);
end

%Multiply detected edge and gray level thresholded image to cancel edge
%'noise' detected in the 'middle' of the shell.
%Preallocation
BWshell=true(size(CTgauss));
se_thres2=strel('disk',8,8);
for id=1:NumberOfSlices
BWshell(:,:,id)=immultiply(imdilate(BWthres(:,:,id),se_thres2),BWcanny(:,:,id));
end

%Remove small objects from binary image, 3D
NoiseSize = 200; %in pixels
conn=26; %connectifity
BWclean=bwareaopen(BWshell,NoiseSize,conn);

%Dilate edge for filling image, using cross element
se90 = strel('line', 4, 90);
se0 = strel('line', 4, 0);
BWdil = imdilate(BWclean, [se0,se90]);
BWfill=true(size(CTgauss));
%Fill in 2D
for id=1:NumberOfSlices
BWfill(:,:,id) = imfill(BWdil(:,:,id),'holes');
end
%Erode edge with a disk to compensate for dilation
sed = strel('disk',1);
BWerode = imerode(BWfill, [se0,se90]);

%Remove small defects 2D
NoiseSize = 200; %in pixels
conn=8; %connectifity
%Preallocate
BWfinal=true(size(CTgauss));
for id=1:NumberOfSlices
BWfinal(:,:,id)=bwareaopen(BWerode(:,:,id),NoiseSize,conn);
end

%%Data display

%Compute area of segmented part(s)
%Preallocate
BWarea=zeros(1,NumberOfSlices);
for id=1:NumberOfSlices
BWarea(:,id)=bwarea(BWfinal(:,:,id));
end

%Output methods
%showOutline(CTstack(:,:,:,slice),BWfinal(:,:,slice),'Segmented Outline');
%showOverlay(CTstack(:,:,:,slice),BWfinal(:,:,slice),'Segmented Area');

%Slider GUI
type='Area'; %or 'Outline'
slider(FirstSlice,LastSlice,CTstack,BWfinal,type)

uisave({'BWfinal'},'SegmentedCT');

%Calculate region properties
%first for slice 1 to determine size table
stats = regionprops('table',BWfinal(:,:,1),CTstack(:,:,:,1),'Area',...
    'BoundingBox','Centroid','Perimeter','MaxIntensity','MeanIntensity',...
    'MinIntensity','WeightedCentroid');
Slice = ones(height(stats),1).*1;
SliceProps = [table(Slice),stats];
for slice = 2:NumberOfSlices
stats = regionprops('table',BWfinal(:,:,slice),CTstack(:,:,:,slice),'Area',...
    'BoundingBox','Centroid','Perimeter','MaxIntensity','MeanIntensity',...
    'MinIntensity','WeightedCentroid');
Slice = ones(height(stats),1).*slice;
SliceProps = [SliceProps;[table(Slice),stats]];
end
[filenameProps, pathnameProps] = uiputfile('ShellProps.xlsx',...
                       'Save file');
if isequal(filenameProps,0) || isequal(pathnameProps,0)
   disp('User selected Cancel')
else
   writetable(SliceProps,fullfile(pathnameProps,filenameProps));
end

%Plots
VarPlot=table2array(SliceProps);
scatter(A(:,1),A(:,2),2,'filled')
xlabel('Height (px)')
ylabel('Cross sectional area (px)')
figure
s1=scatter3(A(:,3),A(:,4),A(:,1),2,[0,0,1],'filled');
hold on
s2=scatter3(A(:,10),A(:,11),A(:,1),2,[1,0,0],'filled');
hold off
xlabel('X (px)')
ylabel('Y (px)')
zlabel('Height (px)')
title('Centroid of shell part (Blue none weighted,Red density weighted)')
