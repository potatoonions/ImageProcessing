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
