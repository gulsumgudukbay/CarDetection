function car_detect = car_detection(name)

cur_image = imread(name);
figure;
imshow(cur_image);
name = extractAfter(name,'/');
name = extractBefore(name,'.');

% title('Original Image');

cur_image_greyscale = rgb2gray(cur_image);
figure;
imshow(cur_image_greyscale, []);
title(strcat('Greyscale Image - ', name));

[rows, cols] = size(cur_image_greyscale);

d_cur_img = double(cur_image_greyscale);
d_cur_img = imgaussfilt(d_cur_img);

horizontal_gradient = d_cur_img;
vertical_gradient = d_cur_img;

for i=1:rows-2
    for j=1:cols-2
        % horizontal gradients with Sobel mask
        horizontal_gradient(i,j) = ((2*d_cur_img(i+2,j+1) + d_cur_img(i+2,j) + d_cur_img(i+2,j+2)) - (2*d_cur_img(i,j+1) + d_cur_img(i,j) + d_cur_img(i,j+2)));
        
        % vertical gradients with Sobel mask
        vertical_gradient(i,j) = ((2*d_cur_img(i+1,j+2) + d_cur_img(i,j+2) + d_cur_img(i+2,j+2)) - (2*d_cur_img(i+1,j) + d_cur_img(i,j) + d_cur_img(i+2,j)));
    end
end

% angles of the gradients
Gdir = atand(horizontal_gradient./vertical_gradient);

% magnitudes of the gradients
Gmag = sqrt(horizontal_gradient.^2 + vertical_gradient.^2);

% zeroing out the non-horizontal gradients
horizontal_gradients = ((Gdir > 80) & (Gdir < 110)) | ((Gdir < -80) & (Gdir > -110));
figure;
imshow(horizontal_gradients, []);
title(strcat('Detected Horizontal Edges - ', name));

% col-wise summation of number of horizontal edges
summed_up_horizontals = zeros(1, cols);
for j=1:cols
    for i=1:rows
        summed_up_horizontals(j) = summed_up_horizontals(j) + horizontal_gradients(i,j);
    end
end

figure
stem(summed_up_horizontals);
title(strcat('Col-Wise Summation of Number of Horizontal Edges - ', name));

%smooth the horizontal edge values histogram
%prepare structuring element
se = strel('square', 40);

% morphological opening for image smoothing
summed_up_horizontals = imopen(summed_up_horizontals, se);
figure;
stem(summed_up_horizontals);
title(strcat('Smoothed Col-Wise Summation of Number of Horizontal Edges - ', name));

% determine important peaks
% determine min peak height for thresholding
min_peak_height = max(summed_up_horizontals) - 11;
[peak_values,locations,widths,prominences] = findpeaks(summed_up_horizontals,'MinPeakHeight',min_peak_height, 'MinPeakProminence',2);
[no_of_rows, no_of_cols] = size(locations);

img_col_locs = cur_image_greyscale;
for i=1:no_of_cols
    img_col_locs(:,locations(i)) = 255;
end

% rowwise addition of horizontal edges
rowwise_summed_up_horizontals = zeros(1,rows);
for i=1:rows
    for j=1:cols
        rowwise_summed_up_horizontals(i) = rowwise_summed_up_horizontals(i) + horizontal_gradients(i,j);
    end
end

figure
stem(rowwise_summed_up_horizontals);
title(strcat('Row-Wise Summation of Number of Horizontal Edges - ', name));

% smooth the rowwise summed horizontal edge values histogram
% prepare structuring element
se = strel('square',35);

% morphological opening for image smoothing
rowwise_summed_up_horizontals = imopen(rowwise_summed_up_horizontals,se);
figure;
stem(rowwise_summed_up_horizontals);
title(strcat('Smoothed Row-Wise Summation of Number of Horizontal Edges - ', name));

% determine important peaks
% determine min peak height for thresholding
min_peak_height2 = max(rowwise_summed_up_horizontals) - std(rowwise_summed_up_horizontals);
[peak_values2,locations2,widths2,prominences2] = findpeaks(rowwise_summed_up_horizontals,'MinPeakHeight',min_peak_height2, 'MinPeakProminence',2);
if(numel(locations2) == 0)
    min_peak_height2 = max(rowwise_summed_up_horizontals) - std(rowwise_summed_up_horizontals)*2;
    [peak_values2,locations2,widths2,prominences2] = findpeaks(rowwise_summed_up_horizontals,'MinPeakHeight',min_peak_height2, 'MinPeakProminence',2);
end
[no_of_rows2, no_of_cols2] = size(locations2);

% find all symmetry axes and draw them
img_row_locs = img_col_locs;
for i=1:no_of_cols2
    img_row_locs(locations2(i),:) = 255;
end

figure;
imshow(img_row_locs, []);
title('Symmetry Axes');

% draw rectangles!
figure;
imshow(cur_image, []);
bool = 1;

%draw rectangles on the original image
hold on;
for i=1:no_of_cols
    if(bool == 1)
        for j=1:no_of_cols2
            cur_width = max(widths(i), widths2(j));
            if(no_of_cols2 >= 3)
                if(j == 2 ) %since there will not be any cars on top of eachother
                    rectangle('Position',[(locations(i)-widths(i)/2) (locations2(j)-widths2(j)/2) cur_width*1.25 cur_width*1.25], 'EdgeColor','g', 'LineWidth', 3);
                    break;
                end
            elseif(no_of_cols2 == 2 && j < no_of_cols2)
                if(locations2(j) >= locations2(j+1)-widths2(j+1)/4 && locations2(j) <= locations2(j+1)+widths2(j+1)/4) % number of horizontal symmetry axes equal to 2 (commonly found case)
                    rectangle('Position',[(locations(i)-widths(i)/2) (locations2(j)-widths2(j)/2) cur_width*1.25 cur_width*1.25], 'EdgeColor','g', 'LineWidth', 3);
                    break;
                end
            elseif(no_of_cols == 2 && i <= no_of_cols) %number of vertical symmetry axes equal to 2 (commonly found case)
                if(locations(j) >= locations(j+1)-widths(j+1) && locations(j) <= locations(j+1)+widths(j+1))
                    rectangle('Position',[(locations(i)-widths(i)/2) (locations2(j)-widths2(j)/2) cur_width*1.25 cur_width*1.25], 'EdgeColor','g', 'LineWidth', 3);
                    bool = 0;
                    break;
                else
                    rectangle('Position',[(locations(i)-widths(i)/2) (locations2(j)-widths2(j)/2) cur_width*1.25 cur_width*1.25], 'EdgeColor','g', 'LineWidth', 3);
                end
            elseif( no_of_cols ~= 2 || no_of_cols2 ~= 2 )
                rectangle('Position',[(locations(i)-widths(i)/2) (locations2(j)-widths2(j)/2) cur_width*1.25 cur_width*1.25], 'EdgeColor','g', 'LineWidth', 3);
            end
        end
    end
end
hold off;

title(strcat('Detected Cars - ', name));

car_detect = img_row_locs;
end
