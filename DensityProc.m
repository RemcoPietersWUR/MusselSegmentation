%Mussel density

%Load density data with GUI
uiopen('load');

Nslices = numel(density);

%histogram(A,[0:100:2^16])

Bit_depth = 16;
bin_size = 100;

counts = zeros(1,numel(0:bin_size:2^Bit_depth)-1);
Edges = 0:bin_size:2^Bit_depth;

for idx=1:Nslices
    Narea = numel(density{1,idx});
    for idy = 1:Narea
        N(idx,:) = counts + histcounts(density{1,idx}(idy).PixelValues,Edges);
    end      
end

[filename, pathname] = uiputfile('DensityDistribution.xlsx',...
                       'Save file');
xlswrite(fullfile(pathname,filename),N)

%Plot function
slice=101;
ref_gray = 20000;
histogram('BinEdges',Edges,'BinCounts',N(slice,:)) 
title(['Gray value distribution @ slice ',num2str(slice)])
xlabel('Gray level, 16bit scale (1 bin = 100 levels)')
ylabel('Counts (pixels)')
hold on 
h = gca;

plot(ones(1,max(get(h,'ylim'))+1).*ref_gray,0:1:max(get(h,'ylim')),'r')

