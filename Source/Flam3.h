#pragma once
#include <simd/simd.h>

typedef struct {
    int index;
    float weight;
    float xT,yT;
    float xS,yS;
    float rot;
    int colorIndex;
    vector_float3 color;
    float unused[4];
} Function;

typedef struct {
    int active;
    float weight;
    int colorIndex;
    vector_float3 color;
    Function function[3];
    float unused[4];
} Group;

typedef struct {
    int version;
    float xscale;
    float yscale;
    float ratio;

    Group group[3];
    
    float radialAngle;
    float unused[3];
} Control;

// Swift access to arrays in Control
#ifndef __METAL_VERSION__

void setControlPointer(Control *ptr);

void controlReset(void);
void controlRandom(void);
void controlDebug(void);

void setGroupActive(int index, int onoff);
int getGroupActive(int index);

float* groupWtPointer(int index);
void updateGroupRGB(int gIndex, int colorIndex);
void updateFunctionRGB(int gIndex, int fIndex, int colorIndex);
void rgbForIndex(int index,float *r,float *g,float *b);

int* groupColorIndexPointer(int index);
int  groupColorIndex(int index);

int* functionColorIndexPointer(int gIndex,int fIndex);
int  functionColorIndex(int gIndex,int fIndex);

int* funcIndexPointer(int gIndex,int fIndex);
int funcIndex(int gIndex,int fIndex);

float* funcWhtPointer(int gIndex,int fIndex);
float* funcXtPointer(int gIndex,int fIndex);
float* funcYtPointer(int gIndex,int fIndex);
float* funcXsPointer(int gIndex,int fIndex);
float* funcYsPointer(int gIndex,int fIndex);
float* funcRotPointer(int gIndex,int fIndex);

#endif
