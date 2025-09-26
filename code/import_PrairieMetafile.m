function [metafile, fullpath] = import_PrairieMetafile(varargin)

if nargin>0
    fullpath = varargin{1};
else
    [file, folder] = uigetfile('*.xml');
    if file == 0
        metafile = [];
        fullpath = [];
        return
    else
        fullpath = strcat( folder, file);
    end     
end
metafile = readstruct(fullpath);
metafile = rearrange_PrairieMetafile(metafile);
end

function metafile = rearrange_PrairieMetafile(metafile)

% fname = [path filesep folder filesep 'dark-GRID-830nm_2.6mW_256_z2-013.xml'];
% metafile = readstruct(fname);
% fname_cnr = '\\192.168.14.193\Data\Data_QNAP\Chloride Imaging\iClima IUE mandata 17102023\Mouse 1\20240130 Mouse 1 CNR\dark_GRID_830nm_512_0.8dwTime_1.5Z-013\dark_GRID_830nm_512_0.8dwTime_1.5Z-013.xml';
% S_cnr = readstruct(fname_cnr);
% S = readstruct(fname_cnr);
version = metafile.versionAttribute;
switch version
    case "5.4.64.200"
        % CNR. Ok così, tramutiamo il tutto in una struttura scalare e sal-
        % viamola come campo 'Info'
        field_names = {metafile.PVStateShard.PVStateValue.keyAttribute};
        values = getAttributeValues(metafile.PVStateShard.PVStateValue);
        args = [field_names;values];
        metafile.Info = struct(args{:});
        metafile = rmfield(metafile,'PVStateShard');
        
    case "5.0.64.100"
        % Nest. Le info sull'acquisizione sono ripetute ad ogni frame.
        str = metafile.Sequence.Frame(1).PVStateShard  ;
        field_names = {str.Key.keyAttribute};
        values = getAttributeValues(str.Key);
        args = [field_names;values];
        metafile.Info = struct(args{:});
        metafile.Info.scanLinePeriod = metafile.Info.scanlinePeriod;
        metafile.Info = rmfield(metafile.Info,'scanlinePeriod');
        metafile = rmfield(metafile,'SystemConfiguration');
end
end

function values = getAttributeValues(in)
    values = {in.valueAttribute};
    missing_vals = cellfun(@(x)(isa(x,'missing')),values);
    if isfield(in,'IndexedValue')
        indexed = {in.IndexedValue};
        values(missing_vals) = indexed(missing_vals);
        missing_vals = cellfun(@(x)(isa(x,'missing')),values);
    end
    if isfield(in,'SubindexedValues')
        subindexed = {in.SubindexedValues};
        values(missing_vals) = subindexed(missing_vals);
        missing_vals = cellfun(@(x)(isa(x,'missing')),values);
    end
    descr = {in.descriptionAttribute};
    values(missing_vals) = descr(missing_vals);
end
