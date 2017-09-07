%RefGray

% Ask user to define folder with reconstructed images
[filename, pathname] = ...
     uigetfile({'*.tif';'*.*'},'Select multiple *.tif files','MultiSelect','on');
% if no files are selected give feedback to command window
if isequal(pathname,0)
   disp('User selected Cancel')
end
if ischar(filename)
    %convert to cell array
    filename={filename};
end

%Load first image
IM=imread(fullfile(pathname,filename{1,1}));
imshow(IM)
title('Draw circle inside the reference shell material & close it by a double click')
h = imellipse(gca);
fcn = makeConstrainToRectFcn('imellipse',get(gca,'XLim'),get(gca,'YLim'));
setPositionConstraintFcn(h,fcn);
setFixedAspectRatioMode(h,true)
position = wait(h);
mask = createMask(h);
close all

linear_ind_mask = find(mask);

avg_gray = zeros(1,numel(filename));
for idx=1:numel(filename)
    IM=imread(fullfile(pathname,filename{1,idx}));
    avg_gray(1,idx)=mean(IM(linear_ind_mask));
    clear IM
end
avg_gray = mean(avg_gray);