function InputData = AMBRCHO_PreScript(InputData)
    % take input data get datetime column (format is 18-Feb-2019 04:35:00)
    InputData.DateTime = datetime(InputData.("Date Time"),'InputFormat','dd-MMM-yyyy HH:mm:ss');

    % remove the "Date Time" column
    InputData.("Date Time") = [];

    % find the index of the first occurence where InputData.("Phase") is "Innoculation"
    % this is the start of the experiment
    StartIndex = find(cellfun(@(x) strcmp(x, 'Inoculation'), InputData.Phase), 1, 'first');

    % remove every row before the start of the experiment
    InputData = InputData(StartIndex:end,:);

    % assign the Time column in seconds using the datetime (but not as a duration value)
    InputData.Time = seconds(InputData.DateTime - InputData.DateTime(1));
end