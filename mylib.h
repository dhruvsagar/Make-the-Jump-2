typedef unsigned short u16;
typedef unsigned int u32;
typedef struct {
	const volatile void *src;
	volatile void *dst;
	volatile u32 cnt;
} DMA_CONTROLLER;


#define REG_DISPCNT *(u16 *)0x4000000
#define MODE_4 4
#define BG2_ENABLE (1<<10)
#define SCANLINECOUNTER *(volatile u16 *) 0x4000006
#define BUFFER0 (u16 *) 0x6000000
#define BUFFER1 (u16 *) 0x600A000
#define BUFFER1FLAG (1<<4)

extern u16 *palette;
extern unsigned short *videobuffer;
extern const unsigned char fontdata_6x8[12288];


#define DMA ((volatile DMA_CONTROLLER*) 0x40000B0)
#define DMA_CHANNEL_0 0
#define DMA_CHANNEL_1 1
#define DMA_CHANNEL_2 2
#define DMA_CHANNEL_3 3

#define DMA_DESTINATION_INCREMENT (0 << 21)
#define DMA_DESTINATION_DECREMENT (1 << 21)
#define DMA_DESTINATION_FIXED (2 << 21)
#define DMA_DESTINATION_RESET (3 << 21)

#define DMA_SOURCE_INCREMENT (0 << 23)
#define DMA_SOURCE_DECREMENT (1 << 23)
#define DMA_SOURCE_FIXED (2 << 23)

#define DMA_REPEAT (1 << 25)

#define DMA_16 (0 << 26)
#define DMA_32 (1 << 26)

#define DMA_NOW (0 << 28)
#define DMA_AT_VBLANK (1 << 28)
#define DMA_AT_HBLANK (2 << 28)
#define DMA_AT_REFRESH (3 << 28)

#define DMA_IRQ (1 << 30)
#define DMA_ON (1 << 31)



#define COLOR(r, g, b) ((r) | (g)<<5 | (b)<<10)
#define RED COLOR(31,0,0)
#define GREEN COLOR(0,31,0)
#define BLUE COLOR(0,0,31)
#define WHITE COLOR(31,31,31)
#define NICE_BLUE COLOR(75/8, 141/8, 165/8)
#define NICE_RED 148
#define NICE_BLACK 156
#define NICE_YELLOW COLOR(255/8, 224/8, 119/8)
#define BLACK 0
#define YELLOW COLOR(31,31,0)
#define CYAN COLOR(0,31,31)
#define MAGENTA COLOR(31,0,31)
#define LTGRAY COLOR(22,22,22)


#define RED_Y 156
#define BLUE_Y 76
#define AVG_DISTANCE 80
#define MAN_HEIGHT 18
#define MAN_WIDTH 15
#define MIN_DIST 60
#define JUMP_LIMIT 30
#define OFFSET(r, c, rowlen) ((r)*(rowlen)+(c))



// *** Input =========================================================

// Buttons

#define BUTTON_A        (1<<0)
#define BUTTON_B        (1<<1)
#define BUTTON_SELECT       (1<<2)
#define BUTTON_START        (1<<3)
#define BUTTON_RIGHT        (1<<4)
#define BUTTON_LEFT     (1<<5)
#define BUTTON_UP       (1<<6)
#define BUTTON_DOWN     (1<<7)
#define BUTTON_R        (1<<8)
#define BUTTON_L        (1<<9)

#define KEY_DOWN_NOW(key)  (~(BUTTONS) & key)

#define BUTTONS *(volatile unsigned int *)0x4000130



// Prototypes
void delay();
void pageFlip();
void waitForVblank();
void fillScreen4(char index);
void drawRect4(int x, int y, int width, int height, char index);
void drawImage4(int x, int y, int width, int height, const u16 *image);
void drawChar(int row, int col, char ch, unsigned char color);
void drawString(int row, int col, char *str, unsigned char color);
void setPixel4(int row, int col, unsigned char index);



