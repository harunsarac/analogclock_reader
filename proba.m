%Read the image with the analog clock
I = imread('5.png');

%Perform simple thresholding and image segmentation on the image
Ig = I(:,:,2);
grayt = graythresh(Ig);
cell = im2bw(Ig, grayt);
[a,tresh]=edge(cell,'sobel');
tresh=tresh*0.5;
[b,tresh05]=edge(cell,'sobel', tresh);
subplot(1,3,1)
imshow(cell)
title('Original image')
subplot(1,3,2)
imshow(a)
title('Calculated threshold value')
subplot(1,3,3)
imshow(b)
title('Threshold value multiplied by 0.5')

%Dilate the image
se0 = strel('line',2, 90);
dilatedimage=imdilate(b, se0);
EdgeClean = bwareaopen(dilatedimage,1e3);
imshow(EdgeClean)
title('Dilated image')

%Crop the image by a small amount so we can get rid of any access lines on
%the borders
[height, width, ~] = size(EdgeClean);
croppedimage = EdgeClean ((height/10):(height-(height/10)), (width/10):(width-(width/10)));
imshow(croppedimage)
title('Cropped image')

%Clean the borders of any access lines
clearborders = imclearborder(croppedimage, 4);
imshow(clearborders)
title('Cleared border')

%Fill the interior of the clock lines
filledimage = imfill(clearborders, 'holes');
imshow(filledimage)
title('Filled image')

%Add a center to the image as a reference which is used when detecting the
%lines of the clock
[height, width, numberOfColorChannels] = size(filledimage);
imshow(filledimage), hold on
scatter((width/2), (height/2));
title('Filled image with center')

%Using hough transform we detect the lines on the image 
%The Hough transform is designed to detect lines, 
%using the formula representation of a line:
%rho = x*cos(theta) + y*sin(theta)

%Compute the Hough transform of the binary image
[H,theta,rho] = hough(filledimage);
%Find the peaks in the Hough transform matrix
P = houghpeaks(H,3,'threshold',ceil(0.3*max(H(:))));

theta(P(:,2));
rho(P(:,1));

%Find lines in the image using the houghlines function
lines = houghlines(filledimage,theta,rho,P,'FillGap',2,'MinLength',50);

%Create a plot that displays the original image with the lines superimposed on it
%
figure, imshow(filledimage), hold on
max_len = 0;
center = [(width/2), (height/2)];
roundedcenter = round(center);
for k = 1:length(lines)
   xy = [lines(k).point1; roundedcenter];
   
   % Determine the endpoints of the longest line segment
   len = norm(lines(k).point1 - roundedcenter);
   
   %if statement for any duplicate lines if the clock lines are too thick
   if(len < (max_len+5) && len > (max_len-5))
       continue;
   end
   
   %Getting the lenght of the bigger and smaller clock lines 
   if ( len > max_len)
       max_len = len;
       xy_long = xy;
   else
       min_len = len;
       xy_short = xy;
   end
    
   %Plot the lines on the image to check if they match as they should
   plot(xy(:,1),xy(:,2),'LineWidth',3,'Color','green');

   
end
% highlight the longest line segment with a different color for better
% understanding
plot(xy_long(:,1),xy_long(:,2),'LineWidth',3,'Color','blue');

%Getting the begging and end points of the longer line
u = xy_long([1 3]);
v = xy_long([2 4]);
%Getting the begging and end points of the shorter line
us = xy_short([1 3]);
vs = xy_short([2 4]);

%Getting the angles for each line
minute = v - u;
hour = vs - us;
minute = [minute 0]; %Adding 0 for cross()
hour = [hour 0];
b = [0 1 0];
%Calculating the angles for lines so we can easily get the time on clock
angle_minutes =  atan2d(norm(cross(minute,b)),dot(minute,b)) + 360*(norm(cross(minute,b))<0);
angle_hours =  atan2d(norm(cross(hour,b)),dot(hour,b)) + 360*(norm(cross(hour,b))<0);

%If any of the lines are on the left side of the clock the angle won't be
%good for the calculation, like when clock is at 9 it will display 3, so we
%do this to prevent that
if minute(1) > 0
    angle_minutes = 360 - angle_minutes;
end
if hour(1) > 0
    angle_hours = 360 - angle_hours;
end

%Calculating the time on clock with the angles we got
minute = round((angle_minutes/6) + 60*(angle_minutes/6 < 0));
hour = floor(angle_hours/30) + 12*(floor(angle_hours/30) <= 0);

%Display the time on the clock, also adding a 0 infront of minutes is the
%are less then 10 for better looks and understanding
if(minute <= 9)
    disp(['The time is ',num2str(hour),':0',num2str(minute)])
else
    disp(['The time is ',num2str(hour),':',num2str(minute)])
end
