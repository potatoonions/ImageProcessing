function overlay = rubberThinMaterialDetection(img)
%RUBBERTHINMATERIALDETECTION  highlight regions where the material
%   appears unusually thin or translucent.  This frequently indicates a
%   manufacturing defect.  The provided stub looks for bright (backlit)
%   spots on the glove mask; adapt as needed.

if ~isa(img,'uint8')
    img = im2uint8(img);
end

gloveContours = findRubberGloveContours(img);
thinContours = findThinMaterialAreas(img);
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');

if isempty(thinContours)
    return;
end

message = 'Thin material';

for i = 1:numel(gloveContours)
    glove = gloveContours{i};
    for j = 1:numel(thinContours)
        contour = thinContours{j};
        cx = mean(contour(:,1));
        cy = mean(contour(:,2));
        xMin = floor(min(contour(:,1)));
        yMin = floor(min(contour(:,2)));
        xMax = ceil(max(contour(:,1)));
        yMax = ceil(max(contour(:,2)));
        w = xMax - xMin;
        h = yMax - yMin;
        if inpolygon(cx, cy, glove(:,1), glove(:,2))
            overlay = drawRectangle(overlay, xMin, yMin, w, h, [0 255 0 255], 2);
            try
                overlay = insertText(overlay, [xMin, yMin-10], message, ...
                    'FontSize', 10, 'TextColor', 'green', 'BoxOpacity', 0);
            catch
            end
        end
    end
end
end

function contours = findThinMaterialAreas(img)
%FINDFINMATERIALAREAS  detect bright/translucent spots on glove

contours = {};

if ~isa(img,'uint8')
    img = im2uint8(img);
end

gray = rgb2gray(img);

% assume thin areas are unusually bright relative to surrounding
thresh = gray > 220;  % tune as required

thresh = imopen(thresh, strel('disk',3));
thresh = imclose(thresh, strel('disk',3));

labels = bwlabel(thresh);
props = regionprops(labels, 'BoundingBox','Area');
for j = 1:numel(props)
    if props(j).Area < 50 || props(j).Area > 5000
        continue;
    end
    bb = props(j).BoundingBox;
    x = bb(1); y = bb(2); w = bb(3); h = bb(4);
    contours{end+1} = [x y; x+w y; x+w y+h; x y+h];
end

if isempty(contours)
    contours = {};
end
end

function contours = findRubberGloveContours(img)
%FINDRUBBERGLOVECONTOURS  locate the outline(s) of the rubber glove(s).
%   This stub simply thresholds in HSV to look for coloured/matte rubber
%   material and returns a cell array of N×2 [x y] polygons.  Replace with
%   a more reliable segmentation for your images.

if ~isa(img,'uint8')
    img = im2uint8(img);
end

if size(img,3) == 1
    img = repmat(img,1,1,3);
end

hsv = rgb2hsv(img);
H = hsv(:,:,1);
S = hsv(:,:,2);
V = hsv(:,:,3);

% assume rubber gloves are reasonably saturated and not extremely
% bright; tune thresholds to suit actual glove colours
mask = (S > 0.2) & (V < 0.9);

% clean up
mask = imclose(mask, strel('disk',5));
mask = imopen(mask, strel('disk',5));

labels = bwlabel(mask);
contours = {};
for k = 1:max(labels(:))
    m = labels == k;
    if sum(m(:)) < 1000
        continue;
    end
    b = bwboundaries(m);
    if ~isempty(b)
        % convert from row,col to x,y
        contours{end+1} = fliplr(b{1});
    end
end

if isempty(contours)
    contours = {};
end
end

function overlay = drawRectangle(overlay, x, y, w, h, color, thickness)
%DRAWRECTANGLE  copy of utility from plasticDefectDetection

[r,c,~] = size(overlay);

x = max(1, min(x, c));
y = max(1, min(y, r));

for t = 0:thickness-1
    overlay(y+t, x:x+w, 1:4) = repmat(reshape(color,1,1,4), 1, w+1);
    overlay(y+t, x:x+w, 1:4) = repmat(reshape(color,1,1,4), 1, w+1);
    if y+h <= r
        overlay(y+h+t, x:x+w, 1:4) = repmat(reshape(color,1,1,4), 1, w+1);
    end
    if x+w <= c
        overlay(y:y+h, x+w+t, 1:4) = repmat(reshape(color,1,1,4), 1, h+1);
    end
    overlay(y:y+h, x+t, 1:4) = repmat(reshape(color,1,1,4), 1, h+1);
end
end
