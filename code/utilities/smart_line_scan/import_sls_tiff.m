function data = import_sls_tiff(data,frame_num)

files = dir([data.path '*.tif']);
looking_for_word = ~cellfun(@isempty,strfind({files.name},'Source'));
files(looking_for_word) = [];
looking_for_word = ~cellfun(@isempty,strfind({files.name},'MIP'));
files(looking_for_word) = [];

if ispc %save file name
    ind_aux = strfind(data.path,'\');
else
    ind_aux = strfind(data.path,'/');
end
if ~isempty(ind_aux)
    data.file = data.path(ind_aux(end)+1:end);
end

%%%% gab: get n channels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
names = regexp({files.name},"_Ch\d_","match");
names = [names{:}];
unique_names = unique(names);
n_ch = numel(unique_names);
n_frames = numel(files)/n_ch;
%%%%%%%%% end of gab %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get lineScan movie
d_bar = waitbar(0,'Loading data');
% movie = zeros(data.duration,data.pixels_per_line*data.linesPerFrame);
movie = zeros(data.duration,data.pixels_per_line*data.linesPerFrame,n_ch); % gab
counter = 0;
files_ch1 = files(contains(names,unique_names{1}));
% for ind_frame=1:min(numel(files),frame_num)
for ind_frame=1:min(n_frames,frame_num) % gab

    waitbar(ind_frame/min(numel(files),frame_num),d_bar);
    % aux = double(imread([data.path files(ind_frame).name]));
    aux = double(imread([data.path files_ch1(ind_frame).name])); % gab
    if size(aux,3)>1
        aux = squeeze(aux(:,:,1));
    end
    if size(movie,2)~=size(aux,2)
        aux = aux';
    end
    % movie(counter+1:counter+size(aux,1),:) = aux;
    movie(counter+1:counter+size(aux,1),:,1) = aux; % gab
    %%%%% gab here %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for ind_ch = 2:n_ch
        tmp_name = strrep(files_ch1(ind_frame).name,unique_names{1},unique_names{ind_ch});
        aux = double(imread([data.path tmp_name]));
        if size(aux,3)>1
            aux = squeeze(aux(:,:,1));
        end
        if size(movie,2)~=size(aux,2)
            aux = aux';
        end
        movie(counter+1:counter+size(aux,1),:,ind_ch) = aux;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    counter = counter + size(aux,1);
end

%remove rows with no activity (probably because the there are less frames
%than initialy expected)
% movie(sum(movie,2)==0,:) = [];
movie(sum(movie,[2 3])==0,:,:) = []; % gab
%if we remove some frames, we need to update the duration and some fields
%in the data struct
if size(movie,1)~=data.duration
    data.duration = size(movie,1);
    data.activities = zeros(1,data.duration);
    data.activities_original = zeros(1,data.duration);
    data.pixelsTimes = zeros(1,data.duration);
    data.bg_activity =  zeros(1,data.duration);
    data.activities_deconvolved = zeros(1,data.duration);
    data.frameTimes = data.frameTimes(1:data.duration);
end

%save the movie
data.movie_doc.movie_ruido = movie;
data.movie_doc.num_frames = data.duration;

close(d_bar);