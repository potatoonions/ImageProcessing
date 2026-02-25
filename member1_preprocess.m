function member1_preprocess
% Member 1 (Data Collection & Pre-processing) - MATLAB
% Handles BOTH RGB and grayscale images safely.

clc; clear;

%% ---------------- CONFIG ----------------
DATASET_DIR = fullfile(pwd, "gloves_dataset");

GLOVE_TYPES  = ["cloth gloves"];
DEFECT_TYPES = ["Hole", "Stains", "Snags"];

OUT_PROC = fullfile(pwd, "processed");
OUT_LOGS = fullfile(pwd, "logs");

TARGET_SIZE = [256 256];
GAUSS_SIGMA = 1.0;
MED_WIN     = [3 3];

MIN_BLOB_AREA = 700;
CLOSE_RADIUS  = 5;

SAMPLES_PER_CLASS = 2;
IMG_EXTS = [".jpg",".jpeg",".png",".bmp",".tif",".tiff",".webp"];

%% ---------------- CREATE OUTPUT FOLDERS ----------------
if ~isfolder(OUT_PROC), mkdir(OUT_PROC); end
if ~isfolder(OUT_LOGS), mkdir(OUT_LOGS); end

subs = ["resized","gray","hsv","filtered_gaussian","filtered_median","masks","isolated","samples_for_report"];
for s = subs
    p = fullfile(OUT_PROC, s);
    if ~isfolder(p), mkdir(p); end
end

statsRows = {};
sampleCount = containers.Map;

%% ---------------- MAIN LOOP ----------------
for gt = GLOVE_TYPES
    for dt = DEFECT_TYPES

        folderPath = fullfile(DATASET_DIR, gt, dt);
        assert(isfolder(folderPath), "Missing folder: %s", folderPath);

        imgs = listImages(folderPath, IMG_EXTS);
        statsRows(end+1,:) = {char(gt), char(dt), numel(imgs)}; %#ok<SAGROW>

        for i = 1:numel(imgs)
            I = imread(imgs(i));
            I = im2uint8(I);
            I = imresize(I, TARGET_SIZE);

            % --- Ensure grayscale + HSV source ---
            if size(I,3) == 3
                gray = rgb2gray(I);
                hsv01 = rgb2hsv(I);              % double [0,1]
            else
                gray = I;
                hsv01 = rgb2hsv(repmat(I,[1 1 3])); % convert grayscale -> pseudo RGB for hsv
            end

            % --- Filters (on grayscale) ---
            gauss = im2uint8(imgaussfilt(im2double(gray), GAUSS_SIGMA));
            med   = im2uint8(medfilt2(im2double(gray), MED_WIN));

            % --- Mask using HSV S channel ---
            S = hsv01(:,:,2);
            mask = imbinarize(S, graythresh(S));
            mask = cleanMask(mask, MIN_BLOB_AREA, CLOSE_RADIUS);

            % --- Isolate glove (HANDLE 1-CHANNEL + 3-CHANNEL) ---
            isolated = I;
            if size(I,3) == 1
                isolated(~mask) = 0;
            else
                for c = 1:3
                    tmp = isolated(:,:,c);
                    tmp(~mask) = 0;
                    isolated(:,:,c) = tmp;
                end
            end

            [~, baseName, ~] = fileparts(imgs(i));
            relDir = fullfile(gt, dt);

            % --- Save outputs ---
            saveP(OUT_PROC,"resized",relDir,baseName,I);
            saveP(OUT_PROC,"gray",relDir,baseName,gray);
            saveP(OUT_PROC,"filtered_gaussian",relDir,baseName,gauss);
            saveP(OUT_PROC,"filtered_median",relDir,baseName,med);
            saveP(OUT_PROC,"masks",relDir,baseName,im2uint8(mask));
            saveP(OUT_PROC,"isolated",relDir,baseName,isolated);

            hsvVis = im2uint8(hsv2rgb(hsv01));
            saveP(OUT_PROC,"hsv",relDir,baseName,hsvVis);

            % --- Sample panels ---
            key = string(gt)+"|"+string(dt);
            if ~isKey(sampleCount,key), sampleCount(key)=0; end
            if sampleCount(key) < SAMPLES_PER_CLASS
                panelPath = fullfile(OUT_PROC,"samples_for_report", ...
                    sprintf("%s__%s__%s.png",safeName(gt),safeName(dt),baseName));
                exportPanel(I,gray,hsvVis,gauss,med,mask,isolated,panelPath);
                sampleCount(key) = sampleCount(key)+1;
            end
        end
    end
end

% --- Write dataset stats ---
T = cell2table(statsRows,"VariableNames",["glove_type","defect_type","count"]);
writetable(T, fullfile(OUT_LOGS,"dataset_stats.csv"));

disp("Member 1 preprocessing completed.");
end

%% ---------------- HELPER FUNCTIONS ----------------
function imgs = listImages(folderPath, exts)
d = dir(folderPath);
imgs = strings(0);
for k = 1:numel(d)
    if d(k).isdir, continue; end
    [~,~,e] = fileparts(d(k).name);
    if any(strcmpi(exts,string(e)))
        imgs(end+1) = fullfile(folderPath,d(k).name); %#ok<AGROW>
    end
end
end

function saveP(root, sub, rel, name, I)
outDir = fullfile(root, sub, rel);
if ~isfolder(outDir), mkdir(outDir); end
imwrite(I, fullfile(outDir, name+".png"));
end

function m = cleanMask(m, minArea, r)
m = bwareaopen(m, minArea);
m = imclose(m, strel("disk", r));
cc = bwconncomp(m);
if cc.NumObjects < 1, return; end
[~,idx] = max(cellfun(@numel,cc.PixelIdxList));
tmp = false(size(m));
tmp(cc.PixelIdxList{idx}) = true;
m = tmp;
end

function exportPanel(I,G,H,Ga,M,mask,iso,outPath)
f = figure("Visible","off");
t = tiledlayout(2,4,"TileSpacing","compact");
nexttile; imshow(I); title("Original");
nexttile; imshow(G); title("Gray");
nexttile; imshow(H); title("HSV");
nexttile; imshow(mask); title("Mask");
nexttile; imshow(Ga); title("Gaussian");
nexttile; imshow(M); title("Median");
nexttile; imshow(iso); title("Isolated");
nexttile; imshow(zeros(size(I),"like",I));
exportgraphics(t,outPath,"Resolution",200);
close(f);
end

function n = safeName(s)
n = regexprep(string(s),"\s+","_");
n = regexprep(n,"[^\w\-]","");
end
