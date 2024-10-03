#include "cpputils/bitmap.hpp"
#include <iostream>
#include <vector>
#include <fstream>

using namespace cpputils;

void invert(Bitmap& bitmap) {
  auto pixels = reinterpret_cast<uint32_t*>(bitmap.data);
  const size_t h = bitmap.size()[0];
  const size_t w = bitmap.size()[1];

  std::vector<uint32_t> buf(w);

  for (size_t i = 0; i < h / 2; ++i) {
    memcpy(buf.data(), pixels + i * w, w * sizeof(uint32_t));
    memcpy(pixels + i * w, pixels + (h - 1 - i) * w, w * sizeof(uint32_t));
    memcpy(pixels + (h - 1 - i) * w, buf.data(), w * sizeof(uint32_t));
  }
}

int main(int argc, char** argv) {
  std::ifstream stream("./screenshot", std::ios::binary);

  size_t size[] = { 1080, 1920, 4 };
  Bitmap screenshot(size);
  stream.read(reinterpret_cast<char*>(screenshot.data), 1920 * 1080 * 4);

  invert(screenshot);
  saveBitmap(screenshot, "./screenshot.bmp");

  return 0;
}
