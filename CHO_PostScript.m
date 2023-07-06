function Data = CHO_PostScript(Data)
    % data is a table
    % set all values in the Data.y0 column to 0 if they are less than zero
    Data.y0(Data.y0 < 0) = 0;
end