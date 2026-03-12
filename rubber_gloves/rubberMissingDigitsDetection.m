function overlay = rubberMissingDigitsDetection(img)
%RUBBERMISSINGDIGITSDETECTION  locate fingers that appear to be missing
%   overlay = rubberMissingDigitsDetection(img) returns an RGBA overlay
%   image in which boxes and the label "Missing digit" mark regions of
%   the glove that are judged to correspond to one or more detached
%   fingertips.  The simple algorithm uses the glove contour and compares
%   it with its convex hull; large concavities are reported as missing
%   digits.  Replace "findMissingDigitContours" with a more appropriate
%   routine for your glove style.

if ~isa(img,'uint8')
    img = im2uint8(img);
end

gloveContours = findRubberGloveContours(img);
missingContours = findMissingDigitContours(img);
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');

if isempty(missingContours)
    return;
end

message = 'Missing digit';

for i = 1:numel(gloveContours)
    glove = gloveContours{i};
    for j = 1:numel(missingContours)
        contour = missingContours{j};
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
                    'FontSize', 10, 'TextColor', 'red', 'BoxOpacity', 0);
            catch
                % insertText may not be available; ignore
            end
        end
    end
end
end

function contours = findMissingDigitContours(img)
%FINDMISSINGDIGITCONTOURS  stub implementation
%   returns rectangles around large concavities in the glove contour

contours = {};

% naive approach: reuse glove contour and look for convex hull differences

gloves = findRubberGloveContours(img);
for i = 1:numel(gloves)
    poly = gloves{i};
    if size(poly,1) < 10
        continue;
    end
    k = convhull(poly(:,1), poly(:,2));
    hull = poly(k,:);
    % compute difference area (approx)
    % this simple example draws the bounding box of the hull minus the
    % glove; in practice one would look for individual concavities.
    % here we just return the hull itself to allow visualisation.
    contours{end+1} = hull;
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
