function Data = CHO_PostScript(Data)
    % data is a table

    Data.StirSpeed = zeros(size(Data.StirSpeed)) + 150;

    % Time offset
    timeoffset = 3.35 * 3600 / (Data.Time(2) - Data.Time(1));
    Data = Data(timeoffset:end, :);
    Data.Time = Data.Time - timeoffset - 3.35 * 3600;

    Data.y0(1: (25 * 3600 / (Data.Time(2) - Data.Time(1)))) = 0.199025;

    % correct y3 to start at y0
    offset = Data.y3(1) - Data.y0(1);
    Data.y3 = Data.y3 - offset;

    % TEMP
    % Remove values after 80 hours
    % cutoff = (80 * 60 * 60) / (Data.Time(2) - Data.Time(1));
    % Data = Data(1:cutoff, :);
end