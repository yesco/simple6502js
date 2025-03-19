// From:
// - https://lodev.org/cgtutor/floodfill.html#Scanline_Floodfill_Algorithm_With_Stack

//The scanline floodfill algorithm using stack instead of recursion, more robust
void floodFillScanlineStack(int x, int y, int newColor, int oldColor)
{
  if(oldColor == newColor) return;

  int x1;
  bool spanAbove, spanBelow;

  std::vector<int> stack;
  push(stack, x, y);
  while(pop(stack, x, y))
  {
    x1 = x;
    while(x1 >= 0 && screenBuffer[y * w + x1] == oldColor) x1--;
    x1++;
    spanAbove = spanBelow = 0;
    while(x1 < w && screenBuffer[y * w + x1] == oldColor)
    {
      screenBuffer[y * w + x1] = newColor;
      if(!spanAbove && y > 0 && screenBuffer[(y - 1) * w + x1] == oldColor)
      {
        push(stack, x1, y - 1);
        spanAbove = 1;
      }
      else if(spanAbove && y > 0 && screenBuffer[(y - 1) * w + x1] != oldColor)
      {
        spanAbove = 0;
      }
      if(!spanBelow && y < h - 1 && screenBuffer[(y + 1) * w + x1] == oldColor)
      {
        push(stack, x1, y + 1);
        spanBelow = 1;
      }
      else if(spanBelow && y < h - 1 && screenBuffer[(y + 1) * w + x1] != oldColor)
      {
        spanBelow = 0;
      }
      x1++;
    }
  }
}
