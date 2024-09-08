#include "cpputils/bitmap.hpp"
#include <iostream>
#include <vector>

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
  if (argc < 3) {
    std::cout << "Usage: " << argv[0] << " input_bmp output_bmp" << std::endl;
    return 1;
  }

  Bitmap bitmap = loadBitmap(argv[1]);
  invert(bitmap);

  saveBitmap(bitmap, argv[2]);

  return 0;
}
