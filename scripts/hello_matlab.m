% hello_matlab.m 
% basical practice
disp('Hello, MATLAB!');

% Display a simple arithmetic operation
result = 2 + 2;
disp(['The result of 2 + 2 is: ', num2str(result)]);

% martix
% Create a simple matrix and display it
matrix = [1, 2; 3, 4];
disp('The created matrix is:');
disp(matrix);

% Perform a matrix operation and display the result
transposedMatrix = matrix';
disp('The transposed matrix is:');
disp(transposedMatrix);

% Calculate the determinant of the matrix and display it
determinant = det(matrix);
disp(['The determinant of the matrix is: ', num2str(determinant)]);

% vectore a
x = 0:0.01:2*pi;
% Calculate the sine of the vector x and display the result
sineValues = sin(x);
disp('The sine values of the vector x are:');
disp(sineValues);

% Plot the sine values against the vector x
figure;
plot(x, sineValues);
xlabel('x (radians)');
ylabel('sin(x)');
title('Sine Function Plot');
grid on;

% Display a message indicating the end of the script
disp('End of the hello_matlab script.');