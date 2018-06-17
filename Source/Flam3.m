#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "Flam3.h"

Control *cPtr = NULL;

void setControlPointer(Control *ptr) { cPtr = ptr; }

void controlReset(void) {
    int fIndex = 1;
    
    for(int i=0;i<3;++i) {
        Group *g = &(cPtr->group[i]);
        g->active = 1;
        g->weight = 0.33;
        g->colorIndex = 16 + i * 50;
        
        for(int j=0;j<3;++j) {
            Function *f = &(g->function[j]);
            f->index = fIndex++;
            f->weight = 0.33;
            f->xT = 0;
            f->yT = 0;
            f->rot = 0;
            f->xS = 1;
            f->yS = 1;
            f->colorIndex = 16 + j * 40;
        }
    }
}

int rndI(int max) { return rand() % max; }
float rndF(float max) { return max * (float)(rand() % 1000) / 1000; }

void controlRandom(void) {
    for(int i=0;i<3;++i) {
        Group *g = &(cPtr->group[i]);
        g->active = 1;
        g->weight = 0.1 + rndF(0.9);
        g->colorIndex = rndI(150);
        
        for(int j=0;j<3;++j) {
            Function *f = &(g->function[j]);
            f->index = rndI(20);
            f->weight = 0.1 + rndF(0.9);
            f->xT = rndF(2) - 1;
            f->yT = rndF(2) - 1;
            f->rot = rndF(2) - 1;
            f->xS = 0.7 + rndF(0.6);
            f->yS = 0.7 + rndF(0.6);
            f->colorIndex = rndI(150);
        }
    }
}

void controlDebug(void) {
    for(int g=0;g<3;++g) {
        Group *gg = &(cPtr->group[g]);
        printf("\n\n=============================\nGrp %d, Act %d, Wt %8.5f Color %d [%8.5f,%8.5f,%8.5f] \n",g+1,gg->active,gg->weight,gg->colorIndex,gg->color.x,gg->color.y,gg->color.z);
        for(int ff=0;ff<3;++ff) {
            Function *f = &(gg->function[ff]);
            printf("   F %d, Ind %d, CI %3d Wt %8.5f  T %8.5f %8.5f  S %8.5f %8.5f  R %8.5f\n",ff+1,
                   f->index,f->colorIndex,f->weight,f->xT,f->yT,f->xS,f->yS,f->rot);
        }
    }
}

void setGroupActive(int index, int onoff) { cPtr->group[index].active = (onoff > 0) ? 1 : 0; }
int getGroupActive(int index) { return cPtr->group[index].active; }

float* groupWtPointer(int index) {
    if(cPtr == NULL) { printf("*********************\nMust init cPtr first!\nYou Fool!\n*********************\n"); exit(0); }
    return &(cPtr->group[index].weight);
}

//MARK: -

int* groupColorIndexPointer(int index) { return &(cPtr->group[index].colorIndex); }
int  groupColorIndex(int index) { return cPtr->group[index].colorIndex; }

int* functionColorIndexPointer(int gIndex,int fIndex) { return &(cPtr->group[gIndex].function[fIndex].colorIndex); }
int  functionColorIndex(int gIndex,int fIndex) { return cPtr->group[gIndex].function[fIndex].colorIndex; }

void rgbForIndex(int index,float *r,float *g,float *b)
{
    #define A 100
    #define B 33
    #define C 66
    static int colorLookup[][3] = {
        {0,0,A}, {0,B,A}, {B,0,A}, {B,B,A}, {0,C,A}, {C,C,A}, {0,A,A}, {0,A,0}, {0,A,C}, {C,A,0},
        {B,A,B}, {C,A,C}, {A,A,0}, {A,C,0}, {A,0,0}, {A,B,0}, {A,0,B}, {A,0,C}, {A,B,B}, {A,C,C},
        {A,0,A}, {C,0,A}};
    
    int y = index / 9;
    int x = (index % 9) + 2; // skip 2 darkest entries
    
    *r = (float)(x * colorLookup[y][0]) / 1000;
    *g = (float)(x * colorLookup[y][1]) / 1000;
    *b = (float)(x * colorLookup[y][2]) / 1000;
}

void updateGroupRGB(int gIndex,int colorIndex) {
    float r,g,b;
    
    cPtr->group[gIndex].colorIndex = colorIndex;
    rgbForIndex(colorIndex,&r,&g,&b);
    
    cPtr->group[gIndex].color.z = r;
    cPtr->group[gIndex].color.y = g;
    cPtr->group[gIndex].color.x = b;
}

void updateFunctionRGB(int gIndex, int fIndex, int colorIndex) {
    float r,g,b;
    
    cPtr->group[gIndex].function[fIndex].colorIndex = colorIndex;
    rgbForIndex(colorIndex,&r,&g,&b);
    
    cPtr->group[gIndex].function[fIndex].color.z = r;
    cPtr->group[gIndex].function[fIndex].color.y = g;
    cPtr->group[gIndex].function[fIndex].color.x = b;
}

//MARK: -

int* funcIndexPointer(int gIndex,int fIndex) { return &(cPtr->group[gIndex].function[fIndex].index); }
int  funcIndex(int gIndex,int fIndex) { return cPtr->group[gIndex].function[fIndex].index; }

float* funcWhtPointer(int gIndex,int fIndex) { return &(cPtr->group[gIndex].function[fIndex].weight); }
float groupWeight(int index) { return cPtr->group[index].weight; }

float* funcXtPointer(int gIndex,int fIndex) { return &(cPtr->group[gIndex].function[fIndex].xT); }
float* funcYtPointer(int gIndex,int fIndex) { return &(cPtr->group[gIndex].function[fIndex].yT); }
float* funcXsPointer(int gIndex,int fIndex) { return &(cPtr->group[gIndex].function[fIndex].xS); }
float* funcYsPointer(int gIndex,int fIndex) { return &(cPtr->group[gIndex].function[fIndex].yS); }
float* funcRotPointer(int gIndex,int fIndex) { return &(cPtr->group[gIndex].function[fIndex].rot); }















