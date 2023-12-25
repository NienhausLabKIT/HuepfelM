%------------Adjust values-------------------------------
function Output = adjust(Input, grey)
Input = angle(exp(1i*Input))+pi;
Input = uint8(255*Input/(2*pi));
Output = (grey/255)*Input;
end