function ModifiedData = AMBRCHO_PreScript(Data)
% Performs modification on InputData
    global p_state;
    global processing_fig;
    processing_fig = uifigure;

    % get start date and end date
    start_date = Data.temp_DateTime(1);
    end_date = Data.temp_DateTime(end);
    Data.temp_DateTime = [];

    disp("Data range: " + string(start_date) + " to " + string(end_date));
    
    processing_figure();

    % wait until p_state.weather_data is set while not blocking execution
    while ~isfield(p_state, 'weather_data')
        pause(0.1);
    end

    Time = seconds(Data.Time);

    % convert date to datetime object
    date_format_string = 'yyyy-MM-dd''T''HH:mm:ss';
    p_state.weather_data.DATE = datetime(p_state.weather_data.DATE, 'InputFormat', date_format_string);
    w = timetable(p_state.weather_data.DATE);
    
    % convert sea level pressure from comma-delimited text to number
    p_state.weather_data.SLP = strrep(p_state.weather_data.SLP, ',', ''); % replace commas with periods
    w.SLP = str2double(p_state.weather_data.SLP); % convert to decimal number
    
    % grab weather data
    w.ELEVATION = p_state.weather_data.ELEVATION;
    
    % select only the relvant data
    range = timerange(start_date, end_date);
    w = w(range, :);
    w = w(w.SLP ~= 999999, :); % remove missing data row
    
    % Use online formula to convert slp, temperature, and elevation into
    % atmospheric pressure
    % P0 = SLP*(1 - (0.0065h)/(T - 0.0065h))^−5.257
    w.ATM_PRE = w.SLP .* ((288 - (0.0065 * p_state.elevation))/288).^(5.2561);
    
    %% Get Pressure At Each Point in Data
    empty_timetable = timetable(Time);
    pressure_timetable = w;
    pressure_timetable.SLP = []; % delete slp column
    pressure_timetable.Time = pressure_timetable.Time - start_date;
    atmospheric_pressure = synchronize(empty_timetable, pressure_timetable, Time, 'nearest');

    Data.Pressure = Data.Pressure + atmospheric_pressure.ATM_PRE;

    %% Ignore all negative time values
    Data.Time = Time;
    tempData = table2timetable(Data);

    nonzero_range = timerange(seconds(0), inf);
    tempData = tempData(nonzero_range, :);

    % convert back to numbers from duration
    tempData = timetable2table(tempData);
    tempData.Time = seconds(tempData.Time);
    
    ModifiedData = tempData;

    close(processing_fig)
end

function processing_figure()
    global p_state; % processing data struct
    global processing_fig;
    p_state = struct();

    processing_fig.Name = sprintf('Process Input File');

    processing_fig.Position = [300, 400, 800, 500];

    gl = uigridlayout(processing_fig, [3, 4]);
    gl.RowHeight = {30, 30, 'fit'};
    gl.ColumnWidth = {'fit', 'fit', 120, '1x'};

    titleLabel = uilabel(gl, 'Text', sprintf("Process %s Data"), 'FontSize', 20);
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1,4];
    
    % Column 1 Subgrid
    column1subgrid = uigridlayout(gl, [6, 1]);
    column1subgrid.RowHeight = {'fit', 'fit', 10, 'fit', 'fit', 'fit'};
    column1subgrid.ColumnWidth = {250};
    column1subgrid.Layout.Row = 3;
    column1subgrid.Layout.Column = 1;

    label3 = uilabel(column1subgrid, 'Text', 'Elevation (m):');
    label3.Layout.Row = 1;

    elevationInput = uieditfield(column1subgrid, 'Value', '255');
    elevationInput.Layout.Row = 2;
    p_state.elevation = 255;

    uploadWeatherButton = uibutton(column1subgrid, "Text", '1. Upload Weather Data');
    uploadWeatherButton.Layout.Row = 4;

    weatherButtonInstructions = uilabel(column1subgrid, "Text", ...
        "To download the required weather files, go to the link below. " + ...
        "Then, input your county into the location selector and the time " + ...
        "the experiment took place into the date selector. Click download " + ...
        "on the first option you see. The .csv file that is downloaded is " + ...
        "what you should upload here.", 'WordWrap', 'on');
    weatherButtonInstructions.Layout.Row = 5;

    weatherLink = uihyperlink(column1subgrid, 'Text', 'NOAA Data Search', ...
        'URL', 'https://www.ncei.noaa.gov/access/search/data-search/global-hourly');
    weatherLink.Layout.Row = 6;
    
    % button behavior
    uploadWeatherButton.ButtonPushedFcn = {@uploadWeatherHandler};
    elevationInput.ValueChangedFcn = {@elevationInputHandler};
end

function elevationInputHandler(src, ~)
    global p_state;
    p_state.elevation = str2double(src.Value);
end

function uploadWeatherHandler(src, ~)
    global p_state;
    [filename, filepath] = uigetfile("*.csv"); % open file selector
    if filepath == 0
        return;
    end
    infile = [filepath, filename]; % get full file path
    p_state.weather_data = readtable(infile, 'VariableNamingRule', 'preserve'); % read weather .csv file
    src.Enable = 'off';
    src.Icon = 'success';
end