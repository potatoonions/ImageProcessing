function overlay = plasticBloodDetection(img)
%PLASTICBLOODDETECTION  simple blood detector for plastic gloves
%   Works similar to other defect detectors but draws red boxes and the
%   label "Blood".  This follows the same flow; swap in your own
%   contour finder via findBloodContours.

if ~isa(img,'uint8')
    img = im2uint8(img);
end
ovenContours = findOvenContours(img);
bloodContours = findBloodContours(img);
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');
if isempty(bloodContours)
    return;
end
message = 'Blood';

for i = 1:numel(ovenContours)
    glove = ovenContours{i};
    for j = 1:numel(bloodContours)
        contour = bloodContours{j};
        cx = mean(contour(:,1));
        cy = mean(contour(:,2));
        xMin = floor(min(contour(:,1)));
        yMin = floor(min(contour(:,2)));
        xMax = ceil(max(contour(:,1)));
        yMax = ceil(max(contour(:,2)));
        w = xMax - xMin;
        h = yMax - yMin;
        if inpolygon(cx, cy, glove(:,1), glove(:,2))
            overlay = drawRectangle(overlay, xMin, yMin, w, h, [255 0 0 255], 2);
            try
                overlay = insertText(overlay, [xMin, yMin-10], message, ...
                    'FontSize', 10, 'TextColor', [255 0 0], 'BoxOpacity', 0);
            catch
                % ignore if insertText unavailable
            end
        end
    end
end
end

function contours = findBloodContours(img)
%FINDBLOODCONTOURS  detect blood regions on plastic gloves
%   Blood appears as BRIGHT RED stains, not dark brown/burnt regions
%   Filters strictly by color to avoid false positives on burnt areas
%   Must be bright red (high saturation AND high brightness)

if ~isa(img,'uint8')
    img = im2uint8(img);
end

if size(img,3) == 1
    img = repmat(img, 1, 1, 3);
end

% Convert RGB to HSV for better color detection
hsv = rgb2hsv(img);
H = hsv(:,:,1);
S = hsv(:,:,2);
V = hsv(:,:,3);

% Blood detection: STRICT criteria
% 1. Red hue: 0-10 degrees (0-0.025) or 350-360 degrees (0.972-1.0)
% 2. VERY high saturation (> 0.5) - blood is vibrant red
% 3. HIGH brightness (> 0.4) - blood is bright red, not dark brown
redHue = (H < 0.03) | (H > 0.97);
highSaturation = S > 0.5;
highBrightness = V > 0.4;

% Combine conditions: ALL must be true for blood
bloodPixels = redHue & highSaturation & highBrightness;

% Apply morphological operations for noise reduction
kernel = strel('disk', 2);
bloodPixels = imopen(bloodPixels, kernel);
bloodPixels = imclose(bloodPixels, kernel);

% Find connected components
labeledImg = bwlabel(bloodPixels);
props = regionprops(labeledImg, 'BoundingBox', 'Area', 'Eccentricity');

% Extract contours with strict filtering
contours = {};
for i = 1:numel(props)
    area = props(i).Area;
    
    % Area thresholds: blood stains must be within reasonable range
    if area < 80 || area > 10000
        continue;  % Too small or too large
    end
    
    % Filter by shape: avoid extremely elongated artifacts
    if props(i).Eccentricity > 0.90
        continue;
    end
    
    bbox = props(i).BoundingBox;
    x = bbox(1);
    y = bbox(2);
    w = bbox(3);
    h = bbox(4);
    
    % Create contour from bounding box
    contour = [x, y; x+w, y; x+w, y+h; x, y+h];
    contours{end+1} = contour;
end

% Return empty if no blood detected
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
