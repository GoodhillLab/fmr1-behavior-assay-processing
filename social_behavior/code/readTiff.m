function f = readTiff(file_name)
warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning')
tiff_link = Tiff(file_name, 'r');
tiff_link.setDirectory(1)
f = tiff_link.read();
tiff_link.close();
