% Setup the sensors and motor ports
brick.SetColorMode(1, 2);  % Set color sensor to Color Code mode (COL-COLOR)

% Sensor and motor ports
ultrasonicPort = 2;         % Ultrasonic sensor port (for detecting obstacles)
touchPortFront = 4;         % Front touch sensor port (for detecting obstacles in front)
killSwitchPort = 3;         % Kill switch touch sensor port
leftMotor = 'C';            % Left motor port
rightMotor = 'A';           % Right motor port
grannyLifter = 'B';         % Granny lifter motor port
colorSensorPort = 1;        % Color sensor port (adjust as needed)

% Define motor speeds (these can be adjusted at the start)
leftMotorSpeed = 63;        % Speed for left motor
rightMotorSpeed = 60;       % Speed for right motor
turnSpeedLeft = 75;         % Speed for left turn
turnSpeedRight = 85;        % Speed for right turn
reverseSpeed = -60;         % Speed for reverse
manualControlFlag = false;  % Flag to track if manual control is active

% Main control loop
while true
    % Check if kill switch is pressed
    if brick.TouchPressed(killSwitchPort)
        brick.MoveMotor(leftMotor, 0);
        brick.MoveMotor(rightMotor, 0);
        disp('Kill switch activated! Motors stopped.');
        break;  % Exit the loop to stop the program
    end
    
    % Read the color sensor to detect blue or green using ColorCode mode
    colorDetected = brick.ColorCode(colorSensorPort);  % Get color code from color sensor
    
    % Check if the detected color is blue (2) or green (3)
    if colorDetected == 2 || colorDetected == 3
        disp('Blue or Green Detected, entering manual control...');
        manualControlFlag = true;  % Set flag to true, switching to manual control mode
    elseif manualControlFlag && (colorDetected ~= 2 && colorDetected ~= 3)
        disp('No Blue or Green Detected, resuming maze-solving...');
        manualControlFlag = false;  % Turn off manual control mode
    end

    if manualControlFlag
        % Manual Control Loop
        global key;
        leftMotorPort = 'C';
        rightMotorPort = 'A';
        grannyLifter = 'B';
        speed = 150;
        gSpeed = 30;
        InitKeyboard();

        while manualControlFlag
            pause(0.1);

            switch key
                case 'uparrow'
                    disp('Up Arrow Pressed!');
                    brick.MoveMotor(leftMotorPort, speed);
                    brick.MoveMotor(rightMotorPort, speed);
                case 'downarrow'
                    disp('Down Arrow Pressed!');
                    brick.MoveMotor(leftMotorPort, -speed);
                    brick.MoveMotor(rightMotorPort, -speed);
                case 'leftarrow'
                    disp('Left Arrow Pressed!');
                    brick.MoveMotor(leftMotorPort, -speed);
                    brick.MoveMotor(rightMotorPort, speed);
                case 'rightarrow'
                    disp('Right Arrow Pressed!');
                    brick.MoveMotor(leftMotorPort, speed);
                    brick.MoveMotor(rightMotorPort, -speed);
                case 'w'
                    disp('W Arrow Pressed!');
                    brick.MoveMotor(leftMotorPort, gSpeed);
                    brick.MoveMotor(rightMotorPort, gSpeed);
                case 's'
                    disp('S Arrow Pressed!');
                    brick.MoveMotor(leftMotorPort, -gSpeed);
                    brick.MoveMotor(rightMotorPort, -gSpeed);
                case 'a'
                    disp('A Pressed!');
                    brick.MoveMotor(leftMotorPort, -gSpeed);
                    brick.MoveMotor(rightMotorPort, gSpeed);
                case 'd'
                    disp('D Pressed!');
                    brick.MoveMotor(leftMotorPort, gSpeed);
                    brick.MoveMotor(rightMotorPort, -gSpeed);
                case 'r'
                    disp('Lifting object');
                    brick.MoveMotorAngleRel(grannyLifter, -10, 30, 'Brake');
                case 'f'
                    disp('Lowering object');
                    brick.MoveMotorAngleRel(grannyLifter, 10, 10, 'Brake');
                case 0
                    disp('No Key Pressed!');
                    brick.StopMotor(leftMotorPort, 'Brake');
                    brick.StopMotor(rightMotorPort, 'Brake');
                    brick.StopMotor(grannyLifter, 'Brake');
                    brick.ResetMotorAngle(grannyLifter);
                case 'q'
                    disp('Exiting Manual Control...');
                    manualControlFlag = false;
            end
            
            % Check if robot should switch back to maze solving
            colorDetected = brick.ColorCode(colorSensorPort);
            if colorDetected ~= 2 && colorDetected ~= 3
                disp('No Blue or Green Detected, resuming maze-solving...');
                manualControlFlag = false;
            end
        end
        CloseKeyboard();
    else
        % Autonomous maze-solving logic
        % Move forward at a steady speed
        brick.MoveMotor(leftMotor, leftMotorSpeed);
        brick.MoveMotor(rightMotor, rightMotorSpeed);

        % Read the ultrasonic sensor to detect an obstacle in front
        distance = brick.UltrasonicDist(ultrasonicPort);
        
        % Check for obstacles and decide actions based on the Left-Hand Rule:
        if distance > 30  % If there's plenty of space ahead (more than 30 cm)
            disp('Plenty of space ahead (distance > 30 cm), turning left...');
            pause(0.6);  % Wait a little to get past the wall
            brick.StopMotor('AC', 'Brake');  % Stop both motors
            brick.MoveMotor('C', -46.2);  % Move left motor backward
            pause(1.45);  % Turn left for exact 90 degrees
            brick.StopMotor('C', 'Brake');  % Stop the left motor
            brick.MoveMotor('C', leftMotorSpeed);  % Move left motor forward
            brick.MoveMotor('A', rightMotorSpeed);  % Move right motor forward
            pause(2);  % Resume moving forward for 2 seconds
        elseif brick.TouchPressed(touchPortFront)  % Obstacle in front
            % Stop immediately when the touch sensor is pressed
            brick.StopMotor(leftMotor, 'Brake');
            brick.StopMotor(rightMotor, 'Brake');
            disp('Obstacle detected in front, reversing for 0.9 seconds...');
            
            % Reverse for 0.9 seconds
            brick.MoveMotor(leftMotor, reverseSpeed);
            brick.MoveMotor(rightMotor, reverseSpeed);
            pause(0.9);
            
            % After reversing, stop the motors
            brick.StopMotor(leftMotor, 'Brake');
            brick.StopMotor(rightMotor, 'Brake');
            pause(0.5);  % Small pause after reversing
            
            % Decide whether to turn left or right based on the space available
            leftSpace = brick.UltrasonicDist(ultrasonicPort);
            if leftSpace > 50  % If there's plenty of space on the left, turn left
                disp('Reversed, plenty of space on the left. Turning left...');
                brick.MoveMotor(leftMotor, -150);
                brick.MoveMotor(rightMotor, 150);
                pause(0.45);  % Turn left for exact 90 degrees
            else
                % Otherwise, if space is not enough on the left, turn right
                disp('Reversed, turning right...');
                brick.MoveMotor(leftMotor, 150);
                brick.MoveMotor(rightMotor, -150);
                pause(0.45);  % Turn right for exact 90 degrees
            end
            
            % Continue moving forward after turn
            brick.MoveMotor(leftMotor, leftMotorSpeed);
            brick.MoveMotor(rightMotor, rightMotorSpeed);
        end
    end
end

disp('Program ended.');