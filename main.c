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
    int width_byte;             // szerokosc oprazu w bajtach
    int dx, dy, sx, sy, err;    // dane dla dzilania algorytmu bresenhama
    unsigned char* pImg;	    // wskazanie na początek danych pikselowych
    unsigned char* pPix;        // wskazanie na aktualny piksel
    unsigned char mask;         // maska aktualnego piksela
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

// extern lineInfo* calculate_info(lineInfo* lInfo, int width, int x1, int x2, int y1, int y2);
extern unsigned char * calculate_pix(unsigned char * pImg, int width, int y, int x);
extern void calculate_info(imgInfo* pImg, int x1, int y1, int x2, int y2);
void Bresenham(imgInfo* pImg, int x1, int y1, int x2, int y2)
{
    calculate_info(pImg, x1, y1, x2, y2);
    pImg->pPix = calculate_pix(pImg->pImg, pImg->width_byte, y1, x1);
    pImg->dx = x2 - x1;
    pImg->dy = y1 - y2;
    pImg->sx = 1;
    pImg->sy = 1;
    if (x1 > x2)
    {
        pImg->dx = -pImg->dx;
        pImg->sx = -1;
    }
    if (y1 > y2)
    {
        pImg->dy = -pImg->dy;
        pImg->sy = -1;
    }
    int err = pImg->dx + pImg->dy;
    int e2;
    while (1<2)
    {
        *pImg->pPix &= ~pImg->mask;
        if (x1 == x2 && y1 == y2)
            break;
        e2 = err * 2;
        if (e2 >= pImg->dy)
        {
            err += pImg->dy;

            pImg->pPix -= (x1 >> 3);
            x1 += pImg->sx;
            pImg->pPix += (x1 >> 3);
            pImg->mask = 0x80 >> (x1 & 0x07);
        }
        if (e2 <= pImg->dx)
        {
            err += pImg->dx;
            y1 += pImg->sy;
            pImg->pPix += pImg->sy * pImg->width_byte;
        }
    }
}
int testBresenham(int a)
{
    imgInfo* pInfo;
    printf("Size of bmpHeader = %d\n", sizeof(bmpHdr));
//    if (sizeof(bmpHdr) != 62)
//    {
//        printf("Change compilation options so as bmpHdr struct size is 62 bytes.\n");
//        return 1;
//    }
    pInfo = InitScreen(a, a);
    int i, j;
    int ai, aj;
    ai = a>>3;
    aj = a - ai;
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
int test()
{
    int x1 = 64, y1 =64, x2 = 1, y2 = 1;
    imgInfo* pInfo;
    pInfo = InitScreen(128, 128);
    calculate_info(pInfo, x1, y1, x2, y2);
    pInfo->pPix = calculate_pix(pInfo->pImg, pInfo->width_byte, y1, x1);
    *pInfo->pPix &= ~pInfo->mask;
    saveBMP(pInfo, "result.bmp");
    FreeScreen(pInfo);
    return *pInfo->pPix;
}
int main(int argc, char* argv[])
{
    testBresenham(128);
//    printf("%d", test());
    return 0;
}
