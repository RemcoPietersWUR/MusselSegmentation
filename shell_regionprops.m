function shell_regionprops(BWfill,IMrot,px_z)
%Calculate region properties
%first for slice 1 to determine size table
stats = regionprops('table',BWfill(:,:,1),IMrot(:,:,1),'Area','Perimeter','MinIntensity','MaxIntensity');
density{1} = regionprops('struct',BWfill(:,:,1),IMrot(:,:,1),'PixelValues');
Slice = ones(height(stats),1).*1;
ShellProps = [table(Slice),stats];
for id = 2:px_z
stats = regionprops('table',BWfill(:,:,id),IMrot(:,:,id),'Area','Perimeter','MinIntensity','MaxIntensity');
density{id} = regionprops('struct',BWfill(:,:,id),IMrot(:,:,id),'PixelValues');
Slice = ones(height(stats),1).*id;
ShellProps = [ShellProps;[table(Slice),stats]];
end
[filenameProps, pathnameProps] = uiputfile('ShellProps.xlsx',...
                       'Save file');
if isequal(filenameProps,0) || isequal(pathnameProps,0)
   disp('User selected Cancel')
else
   writetable(ShellProps,fullfile(pathnameProps,filenameProps));
   save(fullfile(pathnameProps,'density.mat'),'density')
end
