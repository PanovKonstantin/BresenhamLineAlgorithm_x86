#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>

typedef struct
{
    unsigned short bfType;
    unsigned long  bfSize;
    unsigned short bfReserved1;
    unsigned short bfReserved2;
    unsigned long  bfOffBits;
    unsigned long  biSize;
    long  biWidth;
    long  biHeight;
    short biPlanes;
    short biBitCount;
    unsigned long  biCompression;
    unsigned long  biSizeImage;
    long biXPelsPerMeter;
    long biYPelsPerMeter;
    unsigned long  biClrUsed;
    unsigned long  biClrImportant;
    unsigned long  RGBQuad_0;
    unsigned long  RGBQuad_1;
} bmpHdr;

typedef struct
{
    int width, height;		    // szerokosc i wysokosc obrazu
    unsigned char* pImg;	    // wskazanie na początek danych pikselowych
} imgInfo;

void* freeResources(FILE* pFile, void* pFirst, void* pSnd)
{
    if (pFile != 0)
        fclose(pFile);
    if (pFirst != 0)
        free(pFirst);
    if (pSnd !=0)
        free(pSnd);
    return 0;
}

imgInfo* readBMP(const char* fname)
{
    imgInfo* pInfo = 0;
    FILE* fbmp = 0;
    bmpHdr bmpHead;
    int lineBytes, y;
    unsigned long imageSize = 0;
    unsigned char* ptr;

    pInfo = 0;
    fbmp = fopen(fname, "rb");
    if (fbmp == 0)
        return 0;

    fread((void *) &bmpHead, sizeof(bmpHead), 1, fbmp);
    // some basic checks
    if (bmpHead.bfType != 0x4D42 || bmpHead.biPlanes != 1 ||
        bmpHead.biBitCount != 1 || bmpHead.biClrUsed != 2 ||
        (pInfo = (imgInfo *) malloc(sizeof(imgInfo))) == 0)
        return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

    pInfo->width = bmpHead.biWidth;
    pInfo->height = bmpHead.biHeight;
    imageSize = (((pInfo->width + 31) >> 5) << 2) * pInfo->height;

    if ((pInfo->pImg = (unsigned char*) malloc(imageSize)) == 0)
        return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

    // process height (it can be negative)
    ptr = pInfo->pImg;
    lineBytes = ((pInfo->width + 31) >> 5) << 2; // line size in bytes
    if (pInfo->height > 0)
    {
        // "upside down", bottom of the image first
        ptr += lineBytes * (pInfo->height - 1);
        lineBytes = -lineBytes;
    }
    else
        pInfo->height = -pInfo->height;

    // reading image
    // moving to the proper position in the file
    if (fseek(fbmp, bmpHead.bfOffBits, SEEK_SET) != 0)
        return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

    for (y=0; y<pInfo->height; ++y)
    {
        fread(ptr, 1, abs(lineBytes), fbmp);
        ptr += lineBytes;
    }
    fclose(fbmp);
    return pInfo;
}

int saveBMP(const imgInfo* pInfo, const char* fname)
{
    int lineBytes = ((pInfo->width + 31) >> 5)<<2;
    bmpHdr bmpHead =
            {
                    0x4D42,				// unsigned short bfType;
                    sizeof(bmpHdr),		// unsigned long  bfSize;
                    0, 0,				// unsigned short bfReserved1, bfReserved2;
                    sizeof(bmpHdr),		// unsigned long  bfOffBits;
                    40,					// unsigned long  biSize;
                    pInfo->width,		// long  biWidth;
                    pInfo->height,		// long  biHeight;
                    1,					// short biPlanes;
                    1,					// short biBitCount;
                    0,					// unsigned long  biCompression;
                    lineBytes * pInfo->height,	// unsigned long  biSizeImage;
                    11811,				// long biXPelsPerMeter; = 300 dpi
                    11811,				// long biYPelsPerMeter;
                    2,					// unsigned long  biClrUsed;
                    0,					// unsigned long  biClrImportant;
                    0x00000000,			// unsigned long  RGBQuad_0;
                    0x00FFFFFF			// unsigned long  RGBQuad_1;
            };

    FILE * fbmp;
    unsigned char *ptr;
    int y;

    if ((fbmp = fopen(fname, "wb")) == 0)
        return -1;
    if (fwrite(&bmpHead, sizeof(bmpHdr), 1, fbmp) != 1)
    {
        fclose(fbmp);
        return -2;
    }

    ptr = pInfo->pImg + lineBytes * (pInfo->height - 1);
    for (y=pInfo->height; y > 0; --y, ptr -= lineBytes)
        if (fwrite(ptr, sizeof(unsigned char), lineBytes, fbmp) != lineBytes)
        {
            fclose(fbmp);
            return -3;
        }
    fclose(fbmp);
    return 0;
}

void FreeScreen(imgInfo* pInfo)
{
    if (pInfo && pInfo->pImg)
        free(pInfo->pImg);
    if (pInfo)
        free(pInfo);
}

imgInfo* InitScreen (int w, int h)
{
    imgInfo *pImg;
    if ( (pImg = (imgInfo *) malloc(sizeof(imgInfo))) == 0)
        return 0;
    pImg->height = h;
    pImg->width = w;
    pImg->pImg = (unsigned char*) malloc((((w + 31) >> 5) << 2) * h);
    if (pImg->pImg == 0)
    {
        free(pImg);
        return 0;
    }
    memset(pImg->pImg, 0xFF, (((w + 31) >> 5) << 2) * h);
    return pImg;
}

extern void draw_line(imgInfo* pImg, int x1, int y1, int x2, int y2);
extern void horizontal_line(imgInfo* pImg, int x1, int x2, int y);
extern void vertical_line(imgInfo* pImg, int y1, int y2, int x);
extern void single_pixel(imgInfo* pImg, int x, int y);
void Bresenham(imgInfo* pImg, int x1, int y1, int x2, int y2)
{
    if (x1 == x2 && y1 == y2)
        single_pixel(pImg, x1, y1);
    else if (y1 == y2)
        horizontal_line(pImg, x1, x2, y1);
    else if (x1 == x2)
        vertical_line(pImg, y1, y2, x1);
    else
        draw_line(pImg, x1, y1, x2, y2);
}
int testBresenham(int a)
{
    imgInfo* pInfo;
    printf("Size of bmpHeader = %d\n", sizeof(bmpHdr));
    if (sizeof(bmpHdr) != 62)
    {
        printf("Change compilation options so as bmpHdr struct size is 62 bytes.\n");
        return 1;
    }
    pInfo = InitScreen(a, a);
    int i, j;
    int ai, aj;
    ai = 0;
    aj = a;
    for(i = ai; i <= aj; i+=(a>>2))
    {
        for (j = ai; j <= aj; j+=(a>>2))
        {
            Bresenham(pInfo, a>>1, a>>1, i, j);
        }
    }
    saveBMP(pInfo, "result.bmp");
    FreeScreen(pInfo);
    return 0;
}
int main(int argc, char* argv[])
{
    testBresenham(256);
    return 0;
}
