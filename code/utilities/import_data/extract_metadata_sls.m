function data = extract_metadata_sls(data,file_name,files)

if nargin <3 || isempty(files)
    if ~isfield(data,'file') || isempty(data.file)
        files = dir([data.path '*.tif']);
        looking_for_word = ~cellfun(@isempty,strfind({files.name},'Source'));
        files(looking_for_word) = [];
        looking_for_word = ~cellfun(@isempty,strfind({files.name},'MIP'));
        files(looking_for_word) = [];
    else
        files = [];
    end
end



%%% gab here

metafile= import_PrairieMetafile(file_name);

if ~strcmp(metafile.Sequence.typeAttribute,'Linescan')...
    && ~strcmp(metafile.Sequence.PVLinescanDefinition.modeAttribute,'freeHand')
    error('This is not a line scan acquisition!')
end
data.micronsPerPixel_XAxis = metafile.Info.micronsPerPixel_XAxis;
data.micronsPerPixel_YAxis = metafile.Info.micronsPerPixel_YAxis;

%look for reference image
if ispc
    reference_image = dir([data.path 'References\*Reference*.tif']);
else
    reference_image = dir([data.path 'References/*Reference*.tif']);
end
if ~isempty(reference_image)
    if ispc
        data.reference_image = double(imread([data.path '\References\' reference_image(1).name]));
    else
        data.reference_image = double(imread([data.path '/References/' reference_image(1).name]));
    end
    if size(data.reference_image,3)>1
        data.reference_image = squeeze(data.reference_image(:,:,1));
    end
end

data.scanlinePeriod = metafile.Info.scanLinePeriod;
data.dwellTime = metafile.Info.dwellTime/1000000;
data.pixels_per_line = metafile.Info.pixelsPerLine;
data.linesPerFrame = metafile.Info.linesPerFrame;
data.framePeriod = data.scanlinePeriod;
tmp = [metafile.Sequence.Frame(:).relativeTimeAttribute]' + ...
            (0:data.linesPerFrame-1)*data.framePeriod;
data.frameTimes = reshape(tmp', 1, []);
data.duration = numel(metafile.Sequence.Frame)*data.linesPerFrame;
data = reset_data(data); % ???
data.linesPerFrame = 1;

if strcmp(metafile.Sequence.PVLinescanDefinition.modeAttribute,'freeHand')
    data.mode = 'freehand';

    [fileID,~] = fopen(file_name);
    d = textscan(fileID,'%s','Delimiter','\n');
    d = d{1};
    fclose(fileID);
    scan_path = zeros(2,numel(d));
    counter = 0;
    %get laser coordinates and measure path length
    for ind=1:numel(d)
        line = d(ind);
        line = line{1};
        index =  strfind(line,'<Freehand x=');
        if ~isempty(index)
            counter = counter + 1;
            index2 =  strfind(line,'y=');
            scan_path(1,counter) = str2double(line(index+13:index2-3));
            scan_path(2,counter) = str2double(line(index2+3:end-4));
            if counter>1
                if abs(scan_path(2,counter)-scan_path(2,counter-1))>10 || abs(scan_path(1,counter)-scan_path(1,counter-1))>10
                    keyboard
                end
            end
        end
    end
    x = [metafile.Sequence.PVLinescanDefinition.Freehand(:).xAttribute];
    y = [metafile.Sequence.PVLinescanDefinition.Freehand(:).yAttribute];
    data.freehand_scan = [y; x];

    % distancias = (sqrt(diff(scan_path(1,:)).^2 + diff(scan_path(2,:)).^2));
    % distancia = sum(distancias);
    % data.freehand_scan = scan_path(2:-1:1,:);
    
%%%%%%%% end of gab code


% for ind=1:numel(d)
%     line = d(ind);
%     line = line{1};
%     index =  strfind(line,'<Freehand x=');
%     if ~isempty(index)
%         counter = counter + 1;
%         index2 =  strfind(line,'y=');
%         scan_path(1,counter) = str2double(line(index+13:index2-3));
%         scan_path(2,counter) = str2double(line(index2+3:end-4));
%         if counter>1
%             if abs(scan_path(2,counter)-scan_path(2,counter-1))>10 || abs(scan_path(1,counter)-scan_path(1,counter-1))>10
%                 keyboard
%             end
%         end
%     end
% end
% scan_path = scan_path(:,1:counter);
% distancias = (sqrt(diff(scan_path(1,:)).^2 + diff(scan_path(2,:)).^2));
% distancia = sum(distancias);
% data.freehand_scan = scan_path(2:-1:1,:);


%%%%





%read the file again with a different delimiter
% [fileID,~] = fopen(file_name);
% d = textscan(fileID,'%s','Delimiter',' ');
% fclose(fileID);
% xml_info = d{1};
% 
% 
% %get the index of when the information about the lineScan starts
% smart_line_scan_info_start = find(~cellfun(@isempty,strfind(xml_info,'PVLinescanDefinition')),1,'last');
% %get some data
% data.scanlinePeriod = find_values(xml_info,'scanLinePeriod',smart_line_scan_info_start);
% data.dwellTime = find_values(xml_info,'dwellTime',0)/1000000;
% data.pixels_per_line = find_values(xml_info,'pixelsPerLine',smart_line_scan_info_start);
% data.linesPerFrame = find_values(xml_info,'linesPerFrame',smart_line_scan_info_start);
% data.framePeriod = data.scanlinePeriod;
% data.frameTimes = 1:numel(files)*data.linesPerFrame;
% data.frameTimes = data.frameTimes*data.framePeriod-data.framePeriod;
% data.duration = numel(files)*data.linesPerFrame;
% data = reset_data(data); 
% data.linesPerFrame = 1;

% %is it a freehand lineScan?
% looking_for_word = find(~cellfun(@isempty,strfind(xml_info,'freeHand')), 1);

    
    
end