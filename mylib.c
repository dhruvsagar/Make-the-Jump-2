#include "mylib.h"

typedef unsigned short U16;
typedef unsigned char u8;
U16 *videobuffer = (U16 *) 0x6000000;
U16 *palette = (U16 *) 0x5000000;

//void setPixel(int x, int y, char index);
void delay();
void pageFlip();
void waitForVblank();
void fillScreen4(char index);
void drawRect4(int x, int y, int width, int height, char index);
void drawImage4(int x, int y, int width, int height, const U16 *image);
void drawChar(int row, int col, char ch, u8 color);
void drawString(int row, int col, char *str, u8 color);
void setPixel4(int row, int col, u8 index);



void delay() {
    int count = 0;
    while (count < 1000) {
        waitForVblank();
        count++;
    }
}


void fillScreen4(char index) {
    unsigned short color = (index<<8) | index;
    DMA[3].src = &color;
    DMA[3].dst = videobuffer;
    DMA[3].cnt = 19200 | DMA_ON | DMA_SOURCE_FIXED;
}

void setPixel4(int row, int col, u8 index) {
    int pixel = OFFSET(row, col, 240);
    int shrt = pixel/2;
    if(col & 1) {
        videobuffer[shrt] = (videobuffer[shrt] & 0x00FF) | (index<<8);
    }
    else {
        videobuffer[shrt] = (videobuffer[shrt] & 0xFF00) | (index);
    }
}

void pageFlip() {
    if (REG_DISPCNT & BUFFER1FLAG) {
        //WERE DISPLAYING BUFFER 1, VIDEO BUFFER WAS BUFFER0
        REG_DISPCNT = REG_DISPCNT & (~BUFFER1FLAG);
        videobuffer = BUFFER1;
    } else {
        REG_DISPCNT = REG_DISPCNT | BUFFER1FLAG;
        videobuffer = BUFFER0;
    }
}

void drawRect4(int x, int y, int width, int height, char index)
{
    volatile unsigned short color = index | (index<<8);
    int r;
    for(r=0; r<height; r++)
    {
        DMA[3].src = &color;
        DMA[3].dst = &videobuffer[OFFSET(y+r, x, 240)/2];
        DMA[3].cnt = (width/2) | DMA_SOURCE_FIXED | DMA_ON; 
    }
}



void drawImage4(int x, int y, int width, int height, const U16 *image) {

    int c;
    for (c = 0; c < height; c++) {
        DMA[3].src = &image[(width*c)/2];
        DMA[3].dst = &videobuffer[(240*(y+c) + x)/2];
        DMA[3].cnt = (width/2) | DMA_ON;
    }
}

void drawChar(int row, int col, char ch, u8 color)
{
    int r,c;
    for(r=0; r<8; r++)
    {
        for(c=0; c<6; c++)
        {
            if(fontdata_6x8[OFFSET(r, c, 6)+ch*48])
            {
                setPixel4(row+r, col+c, color);
            }
        }
    }
}

void drawString(int row, int col, char *str, u8 color)
{
    while(*str)
    {
        drawChar(row, col, *str++, color);
        col += 6;
    }
}


void waitForVblank() {
    while(SCANLINECOUNTER > 160);
    while(SCANLINECOUNTER < 160);
}



