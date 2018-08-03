#include <metal_stdlib>
#include <simd/simd.h>
#include "Source/Flam3.h"

using namespace metal;

// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
float rand(float y, float z) {
    int seed = 13 + int(y * 1000) * 57 + int(z * 1000) * 241;
    seed = (seed << 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

int weightedRandomSelection(float seed,float w1, float w2, float w3) {
    float total = w1 + w2 + w3;
    if(total == 0) return -1;
    
    float rVal = rand(seed,total);
    float r = rVal * total; // r = 0 ... total
    if(r < w1) return 0;
    if(r < w1+w2) return 1;
    return 2;
}

int modn(int n, int m ) { return ( (n % m) + m ) % m; }

kernel void Flam3Shader
(
 texture2d<float, access::read_write> dst [[texture(0)]],
 constant Control &control [[ buffer(0) ]],
 uint p [[thread_position_in_grid]])
{
    const float pi = 3.141592654;
    float lastRandom = float(p) * 10240;
    float2 pt,old;
    int gIndex,fIndex;
    
    lastRandom = rand(lastRandom,float(p));
    pt.x = -2 + lastRandom * 4;
    lastRandom = rand(lastRandom,pt.x);
    pt.y = -2 + lastRandom * 4;
    
    for(int iter = 0;iter < 200; ++iter) {
        
        // pick random group
        lastRandom = rand(lastRandom,float(iter));
        gIndex = weightedRandomSelection(lastRandom,
                                         control.group[0].weight * float(control.group[0].active),
                                         control.group[1].weight * float(control.group[1].active),
                                         control.group[2].weight * float(control.group[2].active));
        if(gIndex == -1) return; // total of all active group weights == 0
        
        // pick random function from that group
        lastRandom = rand(lastRandom,float(iter + gIndex));
        fIndex = weightedRandomSelection(lastRandom,
                                         control.group[gIndex].function[0].weight,
                                         control.group[gIndex].function[1].weight,
                                         control.group[gIndex].function[2].weight);
        if(fIndex == -1) return; // total of all group[gIndex] function weights == 0
        
        Function func = control.group[gIndex].function[fIndex];
        old = pt;
        
        switch(control.group[gIndex].function[fIndex].index) {
            case 0 : // linear
                break;
            case 1 : // 'Sinusoidal'
                pt.x = sin(pt.x);
                pt.y = sin(pt.y);
                break;
            case 2 : // 'Spherical'
            {
                float r = length(pt);
                float den = pow(r,2);
                pt.x /= den;
                pt.y /= den;
            }
                break;
            case 3 : // 'Swirl'
            {
                float r = length(pt);
                float den = pow(r,2);
                pt.x = (old.x * sin(den)) - (old.y * cos(den));
                pt.y = (old.x * cos(den)) + (old.y * sin(den));
            }
                break;
            case 4 : // 'Horseshoe'
            {
                float r = length(old);
                pt.x = ( 1 / r ) * ( old.x - old.y ) * ( old.x + old.y );
                pt.y = ( 1 / r ) * 2 * old.x * old.y;
            }
                break;
            case 5 : // 'Polar'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                pt.x = th / pi;
                pt.y = r - 1;
            }
                break;
            case 6 : // 'Hankerchief'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                pt.x = r * sin(th + r);
                pt.y = r * cos(th - r);
            }
                break;
            case 7 : // 'Heart'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                pt.x = r * sin( th * r );
                pt.y = r * -cos( th * r );
            }
                break;
            case 8 : // 'Disc'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                pt.x = ( th / pi ) * sin(pi * r );
                pt.y = ( th / pi ) * cos(pi * r );
            }
                break;
            case 9 : // 'Spiral'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                pt.x = ( 1 / r ) * ( cos(th) + sin(r) );
                pt.y = ( 1 / r ) * ( sin(th) - cos(r) );
            }
                break;
            case 10 : // 'Hyperbolic'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                pt.x = sin(th) / r;
                pt.y = r * cos(th);
            }
                break;
            case 11 : // 'Diamond'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                pt.x = sin(th) * cos(r);
                pt.y = cos(th) * sin(r);
            }
                break;
            case 12 : // 'Ex'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                float p0 = sin( th + r );
                float p1 = cos( th - r );
                pt.x = r * ( pow( p0, 3 ) + pow( p1, 3 ) );
                pt.y = r * ( pow( p0, 3 ) - pow( p1, 3 ) );
            }
                break;
            case 13 : // 'Julia'
            {
                float rs = sqrt(length(pt));
                float th = atan2(pt.y,pt.x);
                float om = func.weight || ( func.xT + func.rot + func.xS + func.yT + func.yS );
                pt.x = rs * cos( th / 2 + om );
                pt.y = rs * sin( th / 2 + om );
            }
                break;
            case 14 : // 'JuliaN',
            {
                float r = length(pt);
                float ph = atan2(pt.x,pt.y);
                float p1 = 1;
                float p2 = 0.75;
                float rrnd = func.weight + 0.5; //  || 0.5;
                float p3 = trunc( abs( p1 ) * rrnd );
                float t = ( ph + ( 2 * pi * p3 ) ) / p1;
                float rpp = pow( r, p2/p1 );
                pt.x = rpp * cos( t );
                pt.y = rpp * sin( t );
            }
                break;
            case 15 : // 'Bent'
            {
                if(pt.x >= 0 && pt.y >= 0 ) break;
                if(pt.x < 0 && pt.y >= 0) {
                    pt.x *= 2;
                }
                else if( pt.x >= 0 && pt.y < 0 ) {
                    pt.y /= 2;
                }
                else {
                    pt.x *= 2;
                    pt.y /= 2;
                }
            }
                break;
            case 16 : // 'Waves'
                pt.x = old.x + ( func.rot * sin( old.y / pow( func.xS, 2 ) ) );
                pt.y = old.y + ( func.rot * sin( old.x / pow( func.yS, 2 ) ) );
                break;
            case 17 : // 'Fisheye'
            {
                float re = 2 / ( sqrt( pow( old.x, 2 ) + pow( old.y, 2 ) ) + 1 );
                pt.x = re * old.y;
                pt.y = re * old.x;
            }
                break;
            case 18 : // 'Popcorn'
                pt.x = old.x + ( func.xS * sin( tan( 3 * old.y ) ) );
                pt.y = old.y + ( func.yS * sin( tan( 3 * old.x ) ) );
                break;
            case 19 : // 'Power'
            {
                 float th = atan2( old.y, old.x );
                 float rsth = pow( sqrt( pow( old.x, 2 ) + pow( old.y, 2 ) ), sin(th) );
                pt.x = rsth * cos(th);
                pt.y = rsth * sin(th);
            }
                break;
            case 20 : // 'Rings'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                float re = modn( ( r + pow( func.xS, 2 ) ), ( 2 * pow( func.xS, 2 ) ) ) - pow( func.xS, 2 ) + ( r * ( 1 - pow( func.xS, 2 ) ) );
                pt.x = re * cos(th);
                pt.y = re * sin(th);
            }
                break;
            case 21 : // 'Fan'
            {
                float r = length(pt);
                float th = atan2(pt.y,pt.x);
                float t = pi * pow( func.xS, 2 );
                if( modn( ( th + func.yS ), t ) > ( t / 2 ) ) {
                    pt.x = r * cos( th - ( t / 2 ) );
                    pt.y = r * sin( th - ( t / 2 ) );
                 }
                 else {
                     pt.x = r * cos( th + ( t / 2 ) );
                     pt.y = r * sin( th + ( t / 2 ) );
                 }
            }
                break;
            case 22 : // 'Eyefish'
            {
                float  re = 2 / ( sqrt( pow( pt.x, 2 ) + pow( pt.y, 2 ) ) + 1 );
                pt.x *= re;
                pt.y *= re;
            }
                break;
            case 23 : // 'Bubble'
            {
                float re = 4 / ( pow( sqrt( pow( pt.x, 2 ) + pow( pt.y, 2 ) ), 2 ) + 4 );
                pt.x *= re;
                pt.y *= re;
            }
                break;
            case 24 : // 'Cylinder'
                pt.x = sin(pt.y);
                break;
            case 25 : // 'Tangent'
                pt.x = sin(pt.x) / cos(pt.y);
                pt.y = tan(pt.y);
                break;
            case 26 : // 'Cross',
            {
                float s = sqrt( 1 / pow( pow( pt.x, 2 ) - pow( pt.y, 2 ), 2 ) );
                pt.x *= s;
                pt.y *= s;
            }
                break;
            case 27 : // 'Noise'
            {
                lastRandom = rand(lastRandom,pt.x);
                float p1 = lastRandom;
                lastRandom = rand(lastRandom,pt.y);
                float p2 = lastRandom;
                pt.x = p1 * pt.x * cos( 2 * pi * p2 );
                pt.y = p1 * pt.y * sin( 2 * pi * p2 );
            }
                break;
            case 28 : // 'Blur'
            {
                lastRandom = rand(lastRandom,pt.x);
                float p1 = lastRandom;
                lastRandom = rand(lastRandom,pt.y);
                float p2 = lastRandom;
                pt.x = p1 * cos( 2 * pi * p2 );
                pt.y = p1 * sin( 2 * pi * p2 );
            }
                break;
            case 29 : // 'Square'
            {
                lastRandom = rand(lastRandom,pt.x);
                float p1 = lastRandom;
                lastRandom = rand(lastRandom,pt.y);
                float p2 = lastRandom;
                pt.x = p1 - 0.5;
                pt.y = p2 - 0.5;
            }
                break;
        }
        
        // translate
        pt.x += control.group[gIndex].function[fIndex].xT;
        pt.y += control.group[gIndex].function[fIndex].yT;
        
        // rotate
        if(func.rot != 0) {
            float qt = pt.x;
            float ss = sin(func.rot);
            float cc = cos(func.rot);
            pt.x = pt.x * cc - pt.y * ss;
            pt.y = qt   * ss + pt.y * cc;
        }
        
        // scale
        pt.x *= func.xS;
        pt.y *= func.yS;

        // render
        if(iter > 10) {     // let the point settle down first
            float xx = 512 + pt.x * control.xscale;
            float yy = 512 + pt.y * control.yscale;
            float4 color = float4(control.group[gIndex].function[fIndex].color,1);

            if(xx >= 0 && xx < 1024 && yy >= 0 && yy < 1024) {
                uint2 p;
                
                if(control.radialAngle < 0.01) {  // radial sym disabled
                    p.x = uint(xx);
                    p.y = uint(yy);
                    dst.write(color,p);
                }
                else { // radial sym
                    float dx = xx - 512;
                    float dy = yy - 512;
                    float angle = fabs(atan2(dy,dx));
                    
                    float dRatio = 0.01 + control.radialAngle;
                    while(angle > dRatio/2) angle -= dRatio;
                    
                    float dist = sqrt(dx * dx + dy * dy);
                    float offset = 0;
                    
                    for(;;) {
                        p.x = uint(512 + cos(angle+offset) * dist);
                        p.y = uint(512 + sin(angle+offset) * dist);
                        dst.write(color,p);
                        
                        offset += control.radialAngle / 2;
                        if(offset >= pi*2) break;
                        angle = -angle;  // flip left/right so pie slices mate
                    }
                }
            }
        }
    }
}
