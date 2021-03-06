function slider_showpair(IM1,IM2,method)
%Slider GUI
hFig = figure;
hAx = axes('Parent',hFig);
startSlice = 1;
[~,~,stopSlice] = size(IM2);
%Slider control
uicontrol('Parent',hFig, 'Style','slider', 'Value',startSlice, 'Min',startSlice,...
    'Max',stopSlice, 'SliderStep', [1 10]./(stopSlice-startSlice), ...
    'Position',[150 5 300 20], 'Callback',@slider_callback)
%Text above slider
hTxt = uicontrol('Style','text', 'Position',[290 28 150 15], 'String',['Slice ',num2str(startSlice)]);
%Show overlay
imshowpair(IM1(:,:,startSlice),IM2(:,:,startSlice),method)
% Callback function
    function slider_callback(hObj, eventdata)
        %Get slide number from slider position
        slice = round(get(hObj,'Value'));
        %Update slice image
        imshowpair(IM1(:,:,slice),IM2(:,:,slice),method)
        %Update slider text
        set(hTxt, 'String',['Slice ',num2str(slice)]);
        hold off
    end
uiwait(hFig);
end