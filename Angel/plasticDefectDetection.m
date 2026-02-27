% for plastic glove defect detection, which are burn, frosting and discolouration

function overlay = plasticDefectDetection(img)
%PLASTICDEFECTDETECTION  simple burn detector for plastic gloves
%   overlay = plasticDefectDetection(img) returns an RGBA overlay image of
%   the same size as the input where rectangles and text mark burn
%   locations that lie inside an oven/glove contour.  This is a Matlab
%   translation of the Python OvenBurnDetector class used in the original
%   project.
%
%   The routine depends on two helper routines which locate the glove
%   outline (oven contour) and the burn candidates.  Stubs are provided
%   below; the caller should replace them with the appropriate
%   implementations for your data.

% make sure the image is in uint8 form
if ~isa(img,'uint8')
    img = im2uint8(img);
end

% obtain contours of the oven/glove and of potential burn regions
ovenContours = findOvenContours(img);
burnContours = findBurnContours(img);

% create empty overlay with alpha channel
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');

% nothing to draw if no burns were found
if isempty(burnContours)
    return;
end

message = 'Burn';

for i = 1:numel(ovenContours)
    glove = ovenContours{i};           % N×2 array of [x y] points

    for j = 1:numel(burnContours)
        contour = burnContours{j};     % M×2 array of [x y] points

        % centroid of the burn contour
        cx = mean(contour(:,1));
        cy = mean(contour(:,2));

        % bounding rectangle for the contour
        xMin = floor(min(contour(:,1)));
        yMin = floor(min(contour(:,2)));
        xMax = ceil(max(contour(:,1)));
        yMax = ceil(max(contour(:,2)));
        w = xMax - xMin;
        h = yMax - yMin;

        % test whether the centroid lies inside the glove polygon
        if inpolygon(cx, cy, glove(:,1), glove(:,2))
            % draw a red rectangle in the overlay
            overlay = drawRectangle(overlay, xMin, yMin, w, h, [0 0 255 255], 2);
            % add text above the box if insertText is available
            try
                overlay = insertText(overlay, [xMin, yMin-10], message, ...
                    'FontSize', 10, 'TextColor', 'red', 'BoxOpacity', 0);
            catch
                % insertText not available; ignore
            end
        end
    end
end
end


% example usage (uncomment when ready)
% img = imread('../img/burn_3.png');
% img = imresize(img, [500 500]);
% overlay = plasticDefectDetection(img);
% imshow(overlay);



%% helper functions (replace with your own implementations)

function contours = findOvenContours(img)
%FINDOVENCONTOURS  detect plastic glove boundaries
%   Returns cell array of polygon contours for each glove region
%   Adapted for clear/white polyethene plastic glove detection
%   Uses HSV and intensity-based thresholding to isolate glove from background

if ~isa(img,'uint8')
    img = im2uint8(img);
end

if size(img,3) == 1
    img = repmat(img, 1, 1, 3);
end

% Convert to grayscale
gray = rgb2gray(img);

% Plastic gloves appear as relatively bright regions (white/clear)
% Threshold for bright regions (> 120 intensity)
% This isolates the plastic glove from darker background
glovePixels = gray > 120;

% For better detection, also use saturation-based approach
% Clear plastic has low saturation, so combine approaches
if size(img,3) == 3
    hsv = rgb2hsv(img);
    S = hsv(:,:,2);
    V = hsv(:,:,3);
    % Low saturation (clear/white) AND bright enough
    glovePixels = glovePixels | ((S < 0.15) & (V > 0.45));
end

% Morphological operations to clean and connect glove regions
kernel = strel('disk', 5);
glovePixels = imclose(glovePixels, kernel);
glovePixels = imopen(glovePixels, kernel);

% Find connected components (separate gloves if multiple)
binaryImg = bwlabel(glovePixels);

% Extract contours for each glove
contours = {};
for gloveIdx = 1:max(binaryImg(:))
    gloveMask = (binaryImg == gloveIdx);
    
    % Only keep reasonably sized gloves
    if sum(gloveMask(:)) < 500
        continue;  % Too small, likely noise
    end
    
    % Find boundary of this glove region
    boundaries = bwboundaries(gloveMask);
    if ~isempty(boundaries)
        boundary = boundaries{1};
        % Convert to [x y] format and add to contours
        contour = fliplr(boundary);  % Convert from row-col to x-y
        contours{end+1} = contour;
    end
end

% Return empty if no gloves found
if isempty(contours)
    contours = {};
end
end

function contours = findBurnContours(img)
%FINDBURNCONTOURS  detect burn regions on plastic gloves
%   Burns appear as darker/discolored regions on clear plastic
%   Can be brown, tan, or darkened plastic from heat damage
%   Filters by texture and intensity to avoid false positives

if ~isa(img,'uint8')
    img = im2uint8(img);
end

if size(img,3) == 1
    img = repmat(img, 1, 1, 3);
end

% Convert to grayscale
gray = rgb2gray(img);

% Calculate glove mean intensity (bright regions are plastic)
glovePixels = gray > 90;
if sum(glovePixels(:)) > 100
    gloveMeanIntensity = mean(gray(glovePixels));
    gloveStdIntensity = std(double(gray(glovePixels)));
else
    gloveMeanIntensity = mean(gray(:));
    gloveStdIntensity = std(double(gray(:)));
end

% Burn detection: darker than glove baseline (1.5-2.0 std below mean)
% This captures burnt/damaged areas while avoiding shadows
burnThreshold = gloveMeanIntensity - (1.8 * gloveStdIntensity);
burnPixels = gray < burnThreshold;

% Also detect subtle burns using local contrast
% Burnt areas often have texture changes
localStd = stdfilt(double(gray), ones(5, 5));
medianStd = median(localStd(:));
highTextureAreas = localStd > (medianStd * 1.3);
darkAreas = gray < (gloveMeanIntensity - 10);
burnPixels = burnPixels | (highTextureAreas & darkAreas);

% Apply morphological operations
kernel = strel('disk', 3);
burnPixels = imopen(burnPixels, kernel);
burnPixels = imclose(burnPixels, kernel);

% Find connected components
labeledImg = bwlabel(burnPixels);
props = regionprops(labeledImg, 'BoundingBox', 'Area', 'Eccentricity', 'Solidity');

% Extract contours with reasonable filtering
contours = {};
for i = 1:numel(props)
    area = props(i).Area;
    
    % Area thresholds: burns can vary in size
    if area < 80 || area > 20000
        continue;  % Too small (noise) or too large (not realistic)
    end
    
    % Filter by shape: some elongation is ok for irregular burns
    if props(i).Eccentricity > 0.97
        continue;  % Too thin/line-like
    end
    
    % Filter by solidity: burn should be somewhat solid, not empty
    if props(i).Solidity < 0.4
        continue;
    end
    
    bbox = props(i).BoundingBox;
    x = bbox(1);
    y = bbox(2);
    w = bbox(3);
    h = bbox(4);
    
    % Create contour
    contour = [x, y; x+w, y; x+w, y+h; x, y+h];
    contours{end+1} = contour;
end

% Return empty if no burns detected
if isempty(contours)
    contours = {};
end
end

function overlay = drawRectangle(overlay, x, y, w, h, color, thickness)
%DRAWRECTANGLE  draw a rectangle on an RGBA overlay image.
%   color is a 1x4 uint8 [R G B A] vector; thickness is an integer.

[r,c,~] = size(overlay);

% clip coordinates
x = max(1, min(x, c));
y = max(1, min(y, r));

for t = 0:thickness-1
    % top edge
    overlay(y+t, x:x+w, 1:4) = repmat(reshape(color,1,1,4), 1, w+1);
    % bottom edge
    overlay(min(r,y+h+t), x:x+w, 1:4) = repmat(reshape(color,1,1,4), 1, w+1);
    % left edge
    overlay(y:y+h, x+t, 1:4) = repmat(reshape(color,1,1,4), h+1, 1);
    % right edge
    overlay(y:y+h, min(c,x+w+t), 1:4) = repmat(reshape(color,1,1,4), h+1, 1);
end
end


% --- frosting detector --------------------------------------------------
function overlay = plasticFrostingDetection(img)
%PLASTICFROSTINGDETECTION  simple frosting detector for plastic gloves
%   Works just like plasticDefectDetection but draws lavender boxes and the
%   label "Frosting".  The algorithm is identical except it calls
%   findFrostingContours instead of findBurnContours.

if ~isa(img,'uint8')
    img = im2uint8(img);
end
ovenContours = findOvenContours(img);
frostingContours = findFrostingContours(img);
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');
if isempty(frostingContours)
    return;
end
message = 'Frosting';

for i = 1:numel(ovenContours)
    glove = ovenContours{i};
    for j = 1:numel(frostingContours)
        contour = frostingContours{j};
        cx = mean(contour(:,1));
        cy = mean(contour(:,2));
        xMin = floor(min(contour(:,1)));
        yMin = floor(min(contour(:,2)));
        xMax = ceil(max(contour(:,1)));
        yMax = ceil(max(contour(:,2)));
        w = xMax - xMin;
        h = yMax - yMin;
        if inpolygon(cx, cy, glove(:,1), glove(:,2))
            overlay = drawRectangle(overlay, xMin, yMin, w, h, [180 105 255 255], 2);
            try
                overlay = insertText(overlay, [xMin, yMin-10], message, ...
                    'FontSize', 10, 'TextColor', [180 105 255], 'BoxOpacity', 0);
            catch
                % ignore if insertText unavailable
            end
        end
    end
end
end

function contours = findFrostingContours(img)
%FINDFROSTINGCONTOURS  stub for locating frosting regions.
%   Same output format as other contour helpers.
contours = {};
% example stub:
% gray = rgb2gray(img);
% thresh = gray > 200;        % bright spots
% B = bwboundaries(thresh);
% contours = cellfun(@(b) fliplr(b), B, 'UniformOutput', false);
end


% --- discolouration detector -------------------------------------------
function overlay = plasticDiscolourationDetection(img)
%PLASTICDISCOLOURATIONDETECTION  detect colour changes on plastic gloves
%   Similar to the other detectors but labels regions as "Discolouration"
%   using an orange box.  This follows the same flow; swap in your own
%   contour finder via findDiscolourationContours.

if ~isa(img,'uint8')
    img = im2uint8(img);
end
ovenContours = findOvenContours(img);
discContours = findDiscolourationContours(img);
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');
if isempty(discContours)
    return;
end
message = 'Discolouration';

for i = 1:numel(ovenContours)
    glove = ovenContours{i};
    for j = 1:numel(discContours)
        contour = discContours{j};
        cx = mean(contour(:,1));
        cy = mean(contour(:,2));
        xMin = floor(min(contour(:,1)));
        yMin = floor(min(contour(:,2)));
        xMax = ceil(max(contour(:,1)));
        yMax = ceil(max(contour(:,2)));
        w = xMax - xMin;
        h = yMax - yMin;
        if inpolygon(cx, cy, glove(:,1), glove(:,2))
            overlay = drawRectangle(overlay, xMin, yMin, w, h, [255 165 0 255], 2);
            try
                overlay = insertText(overlay, [xMin, yMin-10], message, ...
                    'FontSize', 10, 'TextColor', [255 165 0], 'BoxOpacity', 0);
            catch
                % ignore if insertText unavailable
            end
        end
    end
end
end

function contours = findDiscolourationContours(img)
%FINDDISCOLOURATIONCONTOURS  stub for locating discolouration regions.
%   Output format consistent with other contour helpers.
contours = {};
% example stub:
% gray = rgb2gray(img);
% % threshold range could be mid-intensity variations, adjust as needed
% thresh = (gray > 80) & (gray < 180);
% B = bwboundaries(thresh);
% contours = cellfun(@(b) fliplr(b), B, 'UniformOutput', false);
end

