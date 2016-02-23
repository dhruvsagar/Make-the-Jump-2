#include "mylib.h"
#include <stdio.h>
#include <stdlib.h>
#include "men.h"
#include "gameOver.h"
#include "startScreen.h"


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
char gameOverText[50];

void definePalette(int num) {
	if (num == 0) {
		for (int i = 0; i < 256; i++) {
			palette[i] = startScreen_palette[i];
		}
	} else if (num == 1) {
	    for (int i = 0; i < 156; i++) {
	        palette[i] = men_palette[i];
	    }
	    palette[156] = COLOR(27/8, 34/8, 50/8);
	} else {
		for (int i = 0; i < 253; i++) {
			palette[i] = gameOver_palette[i];
		}
	}
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

void drawStartScreen() {
	definePalette(0);
	drawImage4(0, 0, 240, 160, startScreen);
	pageFlip();
}

void drawGameOver(int level) {
	definePalette(2);
	palette[255] = COLOR(27/8, 34/8, 50/8);
	drawImage4(0, 0, 240, 160, gameover);
	if (level == 11) {
		sprintf(gameOverText, "YOU WON!");
		drawString(106, 84, gameOverText, 255);
	} else {
		sprintf(gameOverText, "Level reached: %d", level);
		drawString(106, 66, gameOverText, 255);
	}
	pageFlip();
}

int main() {
    REG_DISPCNT = MODE_4 | BG2_ENABLE;
	videobuffer = BUFFER1;



    drawStartScreen();

   	int hasBegun = 0;
   	int isGameOver = 0;
   	int counter = 0;
   	int counterCopy = counter;

   	while (1) {

		if (KEY_DOWN_NOW(BUTTON_START) && isGameOver == 0) {
			hasBegun = 1;
			definePalette(1);
		}


		if (hasBegun == 1) {
			struct man testMan = {'r', 0, RED_Y - MTJ1_HEIGHT, 0, 1, 0};
			struct obstacle obstacles[40];
			setObstacles(obstacles);
		    counter = 0;
		    int lives = 10;
		    testMan.level = 0;
		    while (counter < 36 && lives >= 0 && hasBegun == 1) {
		    	lives = 10;
			    while ((testMan.level == 0 ? testMan.x + menWidth[testMan.mode] <= 240 : testMan.x >= 0) && lives >=0 && hasBegun == 1) {
			        testMan = updateJump(testMan);
			        drawGameBackground();
			        drawObstacles(counter, obstacles);
			        showLives(lives);
			        counterCopy = counter;
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


			        if (KEY_DOWN_NOW(BUTTON_SELECT)) {
	            		hasBegun = 0;
						drawStartScreen();
            		}

			    }
			    if (hasBegun == 1) {
				    testMan = nextLevel(testMan);
				    if (testMan.level == 0) {
				    	counter += 4;
				    }
				}
			}
			if (hasBegun != 0) {
				isGameOver = 1;
				hasBegun = 0;
			}
		}

		if (isGameOver == 1) {
			drawGameOver(counterCopy/4 + 1);
			isGameOver = 0;
		}

		if (KEY_DOWN_NOW(BUTTON_SELECT)) {
			drawStartScreen();
        }

	}
}

