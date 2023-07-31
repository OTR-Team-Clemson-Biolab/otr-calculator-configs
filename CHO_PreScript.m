function InputData = CHO_PreScript(InputData)
    % clip column 50 at 100
    a = InputData.("50");
    a(a > 100) = 100;
    InputData.("50") = a;
end