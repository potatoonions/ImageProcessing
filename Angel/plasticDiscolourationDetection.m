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
%FINDDISCOLOURATIONCONTOURS  detect discoloration regions on plastic gloves
%   Discoloration: color/shade variations that are NOT blood (red) and NOT burns (very dark)
%   Targets moderate intensity changes and color deviations

if ~isa(img,'uint8')
    img = im2uint8(img);
end

if size(img,3) == 1
    img = repmat(img, 1, 1, 3);
end

% Convert to HSV for better discoloration detection
hsv = rgb2hsv(img);
H = hsv(:,:,1);
S = hsv(:,:,2);
V = hsv(:,:,3);

gray = rgb2gray(img);

% Discoloration criteria:
% 1. NOT blood (not bright red): exclude high saturation red hues
notBrightRed = ~((H < 0.03 | H > 0.97) & S > 0.5 & V > 0.4);

% 2. NOT very dark burns: must have reasonable brightness
notVeryDark = gray > (mean(gray(:)) - 60);

% 3. Slightly abnormal saturation or hue
% Discolored areas often have color shifts or reduced saturation
hueDifference = abs(H - median(H(:)));
saturationDifference = abs(S - median(S(:)));

% Pixels with unusual color characteristics
discolorPixels = notBrightRed & notVeryDark & ...
    ((hueDifference > 0.08 | saturationDifference > 0.15));

% Apply morphological operations
kernel = strel('disk', 2);
discolorPixels = imopen(discolorPixels, kernel);
discolorPixels = imclose(discolorPixels, kernel);

% Find connected components
labeledImg = bwlabel(discolorPixels);
props = regionprops(labeledImg, 'BoundingBox', 'Area', 'Eccentricity');

% Extract contours with filtering
contours = {};
for i = 1:numel(props)
    area = props(i).Area;
    
    % Area thresholds
    if area < 100 || area > 12000
        continue;
    end
    
    % Filter extreme elongation
    if props(i).Eccentricity > 0.92
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

% Return empty if no discoloration detected
if isempty(contours)
    contours = {};
end
end

function contours = findOvenContours(img)
%FINDOVENCONTOURS  locate the glove (latex region).
%
%   contours = findOvenContours(img) returns a cell array of oven/glove
%   contours. Each element is an N×2 array of [x y] points listed
%   counter-clockwise, representing the boundary of one region.
%
%   Temporary implementation: simple color threshold in HSV space.

if ~isa(img,'uint8')
    img = im2uint8(img);
end

if size(img,3) == 1
    img = repmat(img, 1, 1, 3);
end

hsv = rgb2hsv(img);
S = hsv(:,:,2);
V = hsv(:,:,3);
% magic formula for isolating latex (high saturation, not too dark)
glove = S > 0.05 & V > 0.2;
glove = imclose(glove, strel('disk', 3));

B = bwboundaries(glove);
contours = cellfun(@(b) fliplr(b), B, 'UniformOutput', false);
end

function overlay = drawRectangle(overlay, x, y, w, h, color, thickness)
%DRAWRECTANGLE draw a rectangular outline with anti-aliasing on overlay.
%   overlay = drawRectangle(overlay, x, y, w, h, color, thickness)
%   color is [R G B A]
%   thickness is line width in pixels
color = uint8(color);
for t = 0 : thickness - 1
    % draw four edges
    yy = max(1, y-t) : min(size(overlay,1), y+h+t);
    xx = max(1, x-t) : min(size(overlay,2), x+w+t);
    
    % top edge
    overlay(max(1, y-t), xx, 1:4) = repmat(reshape(color,1,1,4), 1, length(xx));
    
    % bottom edge
    overlay(min(size(overlay,1), y+h+t), xx, 1:4) = repmat(reshape(color,1,1,4), 1, length(xx));
    
    % left edge
    overlay(yy, max(1, x-t), 1:4) = repmat(reshape(color,1,1,4), length(yy), 1);
    
    % right edge
    c = min(size(overlay,2), x+w+t);
    if c > 0 && c <= size(overlay,2)
        overlay(yy, c, 1:4) = repmat(reshape(color,1,1,4), length(yy), 1);
    end
end
end
