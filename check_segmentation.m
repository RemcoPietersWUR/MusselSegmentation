%check_seg
function [BWfill,BWline]=check_segmentation(BWfill,BWline,CT,method,se)
%Slider GUI
scrsz = get(groot,'ScreenSize');
hFig = figure('OuterPosition',[0 0.05*scrsz(4) scrsz(3) 0.95*scrsz(4)]);
hAx = axes('Parent',hFig);
startSlice = 1;
[px,py,stopSlice] = size(CT);
%Slider control
sld = uicontrol('Parent',hFig, 'Style','slider', 'Value',startSlice, 'Min',startSlice,...
    'Max',stopSlice, 'SliderStep', [1 10]./(stopSlice-startSlice), ...
    'Position',[150 5 300 20], 'Callback',@slider_callback);
btn = uicontrol('Style', 'pushbutton', 'String', 'Edit',...
    'Position', [20 20 50 20],...
    'Callback', @edit_callback);
%Text above slider
hTxt = uicontrol('Style','text', 'Position',[290 28 150 15], 'String',['Slice ',num2str(startSlice)]);
%Show overlay
imshowpair(BWfill(:,:,startSlice),CT(:,:,startSlice),method)
hold on
perim = bwperim(BWfill(:,:,startSlice));
[I,J]=ind2sub([px,py],find(perim));
plot(J,I,'.r')
hold off
% Callback function slider
    function slider_callback(sld, eventdata)
        %Get slide number from slider position
        slice = round(get(sld,'Value'));
        %Update slice image
        imshowpair(BWfill(:,:,slice),CT(:,:,slice),method)
        hold on
        perim = bwperim(BWfill(:,:,slice));
        [I,J]=ind2sub([px,py],find(perim));
        plot(J,I,'.r')
        %Update slider text
        set(hTxt, 'String',['Slice ',num2str(slice)]);
        hold off
    end
% Callback function Edit
    function edit_callback(btn, eventdata)
        %Get slide number from slider position
        slice = round(get(sld,'Value'));
        BWedit = IMclose_gap(BWfill(:,:,slice),BWline(:,:,slice),CT(:,:,slice));
        BWfill(:,:,slice)=imopen(BWedit,se);
        imshowpair(BWfill(:,:,slice),CT(:,:,slice),method);
        hold on
        perim = bwperim(BWfill(:,:,slice));
        [I,J]=ind2sub([px,py],find(perim));
        plot(J,I,'.r')
        hold off
    end
uiwait(hFig);
end


