%imshow(imopen(imfill(or(imclose(or(BW3,BWdump),se),BWfill(:,:,97)),'holes'),se))
function [BWfillnew,BWlinenew] = IMclose_gap(BWfill,BWoutline2,CT)
%BWoutline1 = BWfill
%BWoutline2 = BWclean2
%Select 
%title('Select shell contour by double clicking on it')
 %indices available
scrsz = get(groot,'ScreenSize');
        hFig2 = figure('OuterPosition',[0 0.05*scrsz(4) scrsz(3) 0.95*scrsz(4)]);
        BW2 = bwselect(BWoutline2,4);
        close(hFig2)
                hFig3 = figure('OuterPosition',[0 0.05*scrsz(4) scrsz(3) 0.95*scrsz(4)]);
        hAx = axes('Parent',hFig3);
imshow(imfuse(BW2,CT,'falsecolor'));
h = imfreehand(hAx,'Closed',false);
if exist('h')>0
line_coord=round(getPosition(h));
end
close(hFig3)
BW3=false(size(BW2));
for id = 1:length(line_coord)
    BW3(line_coord(id,2),line_coord(id,1))=1;
    BW3=bwmorph(BW3,'diag');
end
%imshow(BW3);
%uiwait
se = strel('disk',2);
BW4 = imclose(or(BW2,BW3),se);

BWfillnew=imopen(imfill(or(BW4,BWfill),'holes'),se);
BWlinenew=or(BWoutline2,BW3);
%newOutline = bwmorph(BW5,'remove');
%imshowpair(newOutline,CT)
end




