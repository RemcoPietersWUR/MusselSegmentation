%imshow(imopen(imfill(or(imclose(or(BW3,BWdump),se),BWfill(:,:,97)),'holes'),se))
function [BWfillnew,BWlinenew] = IMclose_gap(BWfill,BWoutline2,CT)
%BWoutline1 = BWfill
%BWoutline2 = BWclean2
%Select 
%title('Select shell contour by double clicking on it')
BW2 = bwselect(BWoutline2,4); %indices available

h_im=imshow(imfuse(BW2,CT,'falsecolor'));
h = imfreehand(gca,'Closed',false);
line_coord=round(getPosition(h));
BW3=false(size(BW2));
for id = 1:length(line_coord)
    BW3(line_coord(id,2),line_coord(id,1))=1;
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




