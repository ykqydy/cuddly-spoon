#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <uf.h>
#include <uf_ui.h>
#include <uf_modl.h>
#include <uf_curve.h>
#include <uf_obj.h>
#include <uf_eval.h>
#include <stdio.h>
#include <cmath>
#include <cstring>
#include <uf_part.h>
#include <uf_modl_curves.h>
#include <uf_mtx.h>
#include <fstream>
#include <uf_disp.h>
#include <uf_assem.h>
#include "json.hpp"
#include <uf_obj_types.h>
#include <uf_defs.h>
#include <uf_mfm.h>
using json = nlohmann::json;

#define UF_CALL(X) (report_error( __FILE__, __LINE__, #X, (X)))

// 打开 prt 文件，返回 part tag。path 为 NULL 时用当前显示的 part
tag_t OpenPart(char* fullPath)
{
    if (UF_is_initialized() == false)
        return NULL_TAG;

    tag_t part = NULL_TAG;
    UF_PART_load_status_t error_status;

    if (fullPath != NULL && strlen(fullPath) > 0)
    {
        int failID = UF_PART_open(fullPath, &part, &error_status);
        if (failID != 0)
            part = UF_PART_ask_display_part();
    }
    else
    {
        part = UF_PART_ask_display_part();
    }
    return part;
}

// 统计 part 中实体（UF_solid_body_subtype）的数量
int CountSolidBodies(tag_t part)
{
    if (part == NULL_TAG)
        return 0;

    int count = 0;
    tag_t object = NULL_TAG;
    int obj_type = UF_solid_type;

    while (UF_OBJ_cycle_objs_in_part(part, obj_type, &object) == 0 && object != NULL_TAG)
    {
        int type = 0, subtype = 0;
        if (UF_OBJ_ask_type_and_subtype(object, &type, &subtype) == 0)
        {
            if (type == UF_solid_type && subtype == UF_solid_body_subtype)
            {
                count++;
            }
        }
    }
    return count;
}

int main(int argc, char* argv[])
{
    UF_initialize();

    if (UF_is_initialized() == false)
    {
        printf("UG initialization failed\n");
        UF_terminate();
        return 1;
    }

    char* partPath = NULL;
    if (argc >= 2 && strlen(argv[1]) > 0)
    {
        partPath = argv[1];
    }

    tag_t part = OpenPart(partPath);
    if (part == NULL_TAG)
    {
        if (partPath == NULL)
            UF_UI_write_listing_window("No part is currently open\n");
        else
            printf("{\"code\":0,\"error\":\"Failed to open part\"}\n");
        UF_terminate();
        return 1;
    }

    int count = CountSolidBodies(part);

    if (partPath == NULL)
    {
        // 从 NX 菜单调用，写信息窗口
        char msg[128];
        sprintf_s(msg, sizeof(msg), "\nSolid bodies found in current part: %d\n", count);
        UF_UI_write_listing_window(msg);
    }
    else
    {
        // 命令行模式，输出 JSON
        json result = {
            {"code", 1},
            {"solid_count", count},
            {"file", partPath}
        };
        std::cout << result.dump() << std::endl;
    }

    UF_terminate();
    return 0;
}