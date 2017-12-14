function canny_edge_detector = canny_edge_detect(d_cur_img);

[rows, cols] = size(d_cur_img);
d_cur_img = double(d_cur_img);
horizontal_gradient = d_cur_img;
vertical_gradient = d_cur_img;

% apply gaussian filter to smooth the image out
d_cur_img = imgaussfilt(d_cur_img);
figure;
imshow(d_cur_img, []);

for i=1:rows-2
    for j=1:cols-2
        % horizontal gradients with Sobel mask
        horizontal_gradient(i,j) = ((2*d_cur_img(i+2,j+1) + d_cur_img(i+2,j) + d_cur_img(i+2,j+2)) - (2*d_cur_img(i,j+1) + d_cur_img(i,j) + d_cur_img(i,j+2)));
        
        % vertical gradients with Sobel mask
        vertical_gradient(i,j) = ((2*d_cur_img(i+1,j+2) + d_cur_img(i,j+2) + d_cur_img(i+2,j+2)) - (2*d_cur_img(i+1,j) + d_cur_img(i,j) + d_cur_img(i+2,j)));
    end
end


% angles of the gradients
angles = imadd(atand(horizontal_gradient./vertical_gradient), 90);

% magnitudes of the gradients
magnitudes = sqrt(horizontal_gradient.^2 + vertical_gradient.^2);

% zeroing out the undefined parts of the matrices
for i=1:rows-2
    for j=1:cols-2
        if(isnan(angles(i,j)))
            angles(i,j) = 0;
        end
        if(isnan(magnitudes(i,j)))
            magnitudes(i,j) = 0;
        end
    end
end

% discretise the gradient directions
for i=1:rows-2
    for j=1:cols-2
        if ((angles(i,j) >= 0) && (angles(i,j) < 22.5)) || ((angles(i,j) >= 157.5) && (angles(i,j) <= 180))
            angles(i,j) = 0;
        elseif (angles(i,j) >= 22.5) && (angles(i,j) < 67.5)
            angles(i,j) = 45;
        elseif (angles(i,j) >= 67.5) && (angles(i,j) < 112.5)
            angles(i,j) = 90;
        elseif (angles(i,j) >= 112.5) && (angles(i,j) < 157.5)
            angles(i,j) = 135;
        end
    end
end


%non maxima suppression
for i=2:rows-2
    for j=2:cols-2
        if (angles(i,j) == 0 && ((magnitudes(i-1,j) > magnitudes(i,j)) || (magnitudes(i+1,j) > magnitudes(i,j)))) %zero out if not vertical maxima
            magnitudes(i,j) = 0;
        elseif (angles(i,j) == 45 && ((magnitudes(i-1,j-1) > magnitudes(i,j)) || (magnitudes(i+1,j+1) > magnitudes(i,j)))) %zero out if not diagonal local maxima
            magnitudes(i,j) = 0;
        elseif (angles(i,j) == 90 && ((magnitudes(i,j-1) > magnitudes(i,j)) || (magnitudes(i,j+1) > magnitudes(i,j)))) %zero out if not horizontal maxima
            magnitudes(i,j) = 0;
        elseif (angles(i,j) == 135 && ((magnitudes(i+1,j-1) > magnitudes(i,j)) || (magnitudes(i-1,j+1) > magnitudes(i,j)))) %zero out if not diagonal local maxima
            magnitudes(i,j) = 0;
        end
    end
end

%thresholding
edge_detected_img = uint8( magnitudes);
thresholded_img = zeros( size( angles));
thresh_top = 180;
thresh_bottom = 115;

for i=2:rows-2
    for j=2:cols-2
        if(edge_detected_img(i,j) > thresh_top)
            thresholded_img(i,j) = edge_detected_img(i,j);
        elseif (edge_detected_img(i,j) > thresh_bottom && edge_detected_img(i,j) < thresh_top)
            thresholded_img(i,j) = edge_detected_img(i,j);
        %connecting edges
        elseif ( edge_detected_img(i+1,j) > thresh_top || edge_detected_img(i-1,j) > thresh_top... % top and bottom
                || edge_detected_img(i,j+1) > thresh_top || edge_detected_img(i,j-1) > thresh_top... % right and left
                || edge_detected_img(i-1, j-1) > thresh_top || edge_detected_img(i-1, j+1) > thresh_top... % bottom right and left
                || edge_detected_img(i+1, j+1) > thresh_top || edge_detected_img(i+1, j-1) > thresh_top) % top right and left
            thresholded_img(i,j) = edge_detected_img(i, j);
        end
    end
end
canny_edge_detector = thresholded_img;
end