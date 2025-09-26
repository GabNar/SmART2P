function raster_movie = from_ls_to_raster_gab(movie,scan_path,n_rows,n_col)

nt = size(movie,1);
nch = size(movie,3);
oneD_scan_path = twoD_to_oneD(n_rows,round(scan_path)');

raster_movie = nan(nt,n_rows*n_col,nch);

for it=1:nt
    for ich = 1:nch
        aux = nan(n_row,n_col);
        aux(oneD_scan_path) = movie(it,:,ich);
        img = aux;
        raster_movie(it,:,ich) = img(:)';
    end
end
end

function oneD_coord = twoD_to_oneD(size_mat,twoD_coord)
%size_mat is the number of lines
    oneD_coord = (twoD_coord(:,2)-1)*size_mat+twoD_coord(:,1);
end