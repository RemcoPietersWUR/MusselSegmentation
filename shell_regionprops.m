function shell_regionprops(BWfill,IMrot,px_z)
%Calculate region properties
%first for slice 1 to determine size table
stats = regionprops('table',BWfill(:,:,1),IMrot(:,:,1),'Area',...
    'BoundingBox','Centroid','Perimeter','MaxIntensity','MeanIntensity',...
    'MinIntensity','WeightedCentroid');
Slice = ones(height(stats),1).*1;
ShellProps = [table(Slice),stats];
for id = 2:px_z
stats = regionprops('table',BWfill(:,:,id),IMrot(:,:,id),'Area',...
    'BoundingBox','Centroid','Perimeter','MaxIntensity','MeanIntensity',...
    'MinIntensity','WeightedCentroid');
Slice = ones(height(stats),1).*id;
ShellProps = [ShellProps;[table(Slice),stats]];
end
[filenameProps, pathnameProps] = uiputfile('ShellProps.xlsx',...
                       'Save file');
if isequal(filenameProps,0) || isequal(pathnameProps,0)
   disp('User selected Cancel')
else
   writetable(ShellProps,fullfile(pathnameProps,filenameProps));
end