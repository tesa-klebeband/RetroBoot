#include <iostream>
#include <fstream>

uint16_t loadSeg;
uint16_t loadOff;
uint16_t size;
uint8_t drv;

uint8_t zerobuff[18] = {0};

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        printf("Usage: mkconfig [CONFIG_FILENAME] ( [8.3 FILENAME] [LOAD_SEG] [LOAD_OFF] [BYTES_TO_LOAD] [EMUL_DRV] )\n\n");
        exit(1);
    }

    std::fstream config;
    config.open(argv[1], std::ios::out | std::ios::binary);

    if (argc > 2) {
        config << argv[2];
        loadSeg = atoi(argv[3]);
        config.write(reinterpret_cast<const char *>(&loadSeg), sizeof(loadSeg));
        loadOff = atoi(argv[4]);
        config.write(reinterpret_cast<const char *>(&loadOff), sizeof(loadOff));
        size = atoi(argv[5]);
        config.write(reinterpret_cast<const char *>(&size), sizeof(size));
        drv = atoi(argv[6]);
        config.write(reinterpret_cast<const char *>(&drv), sizeof(drv));
    } else {
        config.write(reinterpret_cast<const char *>(&zerobuff), sizeof(zerobuff));
    }

    config.close();
    return 0;
}