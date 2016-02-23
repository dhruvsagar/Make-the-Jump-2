#include "mylib.h"
#include <stdio.h>
#include <stdlib.h>
#include "men.h"


struct man {
    char color;
    int x;
    int y;
    int jump;
    int mode;
    int level;
};

struct obstacle {
    int x;
    int y;
    int width;
    int height;
    int level;
};

int menHeight[6] = {0, MTJ1_HEIGHT, MTJ2_HEIGHT, MTJ3_HEIGHT, MTJ4_HEIGHT, MTJ5_HEIGHT};
int menWidth[6] = {0, MTJ1_WIDTH, MTJ2_WIDTH, MTJ3_WIDTH, MTJ4_WIDTH, MTJ5_WIDTH};
char scoreText[50];
char scoreText2[50];

void definePalette() {
    for (int i = 0; i < 156; i++) {
        palette[i] = men_palette[i];
    }
    palette[156] = COLOR(27/8, 34/8, 50/8);
}

void drawGameBackground() {
    drawRect4(0, 0, 240, 76, NICE_RED);
    drawRect4(0, 76, 240, 4, NICE_BLACK);
    drawRect4(0, 80, 240, 76, NICE_RED);
    drawRect4(0, 156, 240, 4, NICE_BLACK);
}

struct man updateJump(struct man man) {
    if (man.jump != 0 && man.y == (man.level == 0 ? RED_Y : BLUE_Y) - MTJ1_HEIGHT) {
        man.jump = 0;
    }
    if (KEY_DOWN_NOW(BUTTON_A) && man.jump == 0) {
        man.jump = 1;
    }
    if (man.jump == 1) {
        if (man.y > (man.level == 0 ? RED_Y : BLUE_Y) - MAN_HEIGHT - JUMP_LIMIT) {
            man.y--;
            man.level == 0 ? man.x++ : man.x--;
        } else {
            man.jump = -1;
        }
    }
    if (man.jump == -1) {
        man.y++;
        man.level == 0 ? man.x++ : man.x--;
    }
    return man;
}

struct man nextLevel(struct man man) {
    man.level = (man.level + 1) % 2;
    if (man.level == 0) {
        man.y = RED_Y - menHeight[man.mode];
        man.x = 0;
    } else {
        man.y = BLUE_Y - menHeight[man.mode];
        man.x = 240 - menWidth[man.mode];
    }
    return man;
}

unsigned short flipBits(unsigned short bits) {
    return (((bits >> 8) & 0xFF) | ((bits & 0x00FF) << 8));
}

void flipImage(int width, int height, const unsigned short *image, unsigned short * img) {
    int c = 0;
    for (int i = 1; i < height; i++) {
        for (int j = width - 1; j >= 0; j--) {
            img[c] = flipBits(image[i*width + j]);
            c++;
        }
    }
}

void setObstacles(struct obstacle obstacles[]) {
    for (int i = 0; i < 40; i+=4) {
        struct obstacle a = {30 + rand() % 50, 0, rand() % 11 + 5, rand() % 6 + 5, 0};
        obstacles[i] = a;
        struct obstacle b = {149 - rand() % (80 - obstacles[i].x), 0, rand() % 11 + 5, rand() % 6 + 5, 0};
        obstacles[i+1] = b;
        struct obstacle c = {130 - rand() % 50, 0, rand() % 11 + 5, rand() % 6 + 5, 1};
        obstacles[i+2] = c;
        struct obstacle d = {rand() % (obstacles[i+2].x - 70), 0, rand() % 11 + 5, rand() % 6 + 5, 1};
        obstacles[i+3] = d;
    }
    for (int i = 0; i < 40; i++) {
        obstacles[i].y = (obstacles[i].level == 0 ? RED_Y : BLUE_Y) - obstacles[i].height;
    }
}

void drawObstacles(int index, struct obstacle obstacles[]) {
    for (int i = 0; i < 4; i++) {
        drawRect4(obstacles[index+i].x, obstacles[index+i].y, obstacles[index+i].width, obstacles[index+i].height, NICE_BLACK);
    }
}

int checkCollision(struct man man, int hittingIndex, struct obstacle arr[]) {
    if ((man.x + menWidth[man.mode] >= arr[hittingIndex].x && man.x + menWidth[man.mode] <= arr[hittingIndex].x + arr[hittingIndex].width)
        || (man.x >= arr[hittingIndex].x && man.x <= arr[hittingIndex].x + arr[hittingIndex].width) ) {

        if (man.y + menHeight[man.mode] >= arr[hittingIndex].y) {
            return 1;
        }
    }
    return 0;
}

void showLives(int lives) {
    sprintf(scoreText, "Lives: %d", lives);
    drawString(10, 180, scoreText, NICE_BLACK);
}

void showLevel(int counter) {
    sprintf(scoreText2, "Level: %d", counter/4 + 1);
    drawString(90, 180, scoreText2, NICE_BLACK);
}

int main() {
    REG_DISPCNT = MODE_4 | BG2_ENABLE;
    definePalette();
    drawGameBackground();
    struct man testMan = {'r', 0, RED_Y - MTJ1_HEIGHT, 0, 1, 0};

    struct obstacle obstacles[40];
    setObstacles(obstacles);

    drawImage4(testMan.x, testMan.y, MTJ1_WIDTH, MTJ1_HEIGHT, mtj1);
    videobuffer = BUFFER1;
    int counter = 0;
    int lives = 10;
    while (counter < 36 && lives >= 0) {
        lives = 10;
        while ((testMan.level == 0 ? testMan.x + menWidth[testMan.mode] <= 240 : testMan.x >= 0) && lives >=0) {
            testMan = updateJump(testMan);
            drawGameBackground();
            drawObstacles(counter, obstacles);
            showLives(lives);
            showLevel(counter);
            if (testMan.mode == 1) {
                drawImage4(testMan.x, testMan.y, MTJ1_WIDTH, MTJ1_HEIGHT, (testMan.level == 0 ? mtj1 : mtj1flipped));
            }
            if (testMan.mode == 2) {
                drawImage4(testMan.x, testMan.y, MTJ2_WIDTH, MTJ2_HEIGHT, (testMan.level == 0 ? mtj2 : mtj2flipped));
            }
            if (testMan.mode == 3) {
                drawImage4(testMan.x, testMan.y, MTJ3_WIDTH, MTJ3_HEIGHT, (testMan.level == 0 ? mtj3 : mtj3flipped));
            }
            if (testMan.mode == 4) {
                drawImage4(testMan.x, testMan.y, MTJ4_WIDTH, MTJ4_HEIGHT, (testMan.level == 0 ? mtj4 : mtj4flipped));
            }
            if (testMan.mode == 5) {
                drawImage4(testMan.x, testMan.y, MTJ5_WIDTH, MTJ5_HEIGHT, (testMan.level == 0 ? mtj5 : mtj5flipped));
            }
            testMan.level == 0 ? testMan.x++ : testMan.x--;
            testMan.mode = testMan.mode % 5 + 1;

            if (checkCollision(testMan, testMan.level == 0? counter : counter+2, obstacles) ||
                checkCollision(testMan, testMan.level == 0? counter+1 : counter+3, obstacles)) {
                lives -= 1;
                testMan.x = (testMan.level == 0 ? 0 : 240 - menWidth[testMan.mode]);
                testMan.y = (testMan.level == 0 ? RED_Y - menHeight[testMan.mode] : BLUE_Y - menHeight[testMan.mode]);
            }

            pageFlip();
            waitForVblank();
        }
        testMan = nextLevel(testMan);
        if (testMan.level == 0) {
            counter += 4;
        }
    }
}

