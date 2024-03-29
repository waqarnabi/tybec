/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0x7708f090 */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "C:/WAQAR/GU/Work/_TyTra_BackEnd_Compiler_/TyBEC/lib-intern/flopoco/testing/FPAddSingleDepth7.vhdl";
extern char *IEEE_P_3620187407;

char *ieee_p_3620187407_sub_674691591_3965413181(char *, char *, char *, char *, unsigned char );
char *ieee_p_3620187407_sub_767668596_3965413181(char *, char *, char *, char *, char *, char *);


static void work_a_0082528624_1446275585_p_0(char *t0)
{
    unsigned char t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    unsigned char t6;
    unsigned char t7;

LAB0:    xsi_set_current_line(80, ng0);
    t2 = (t0 + 992U);
    t3 = xsi_signal_has_event(t2);
    if (t3 == 1)
        goto LAB5;

LAB6:    t1 = (unsigned char)0;

LAB7:    if (t1 != 0)
        goto LAB2;

LAB4:
LAB3:    t2 = (t0 + 3560);
    *((int *)t2) = 1;

LAB1:    return;
LAB2:    goto LAB3;

LAB5:    t4 = (t0 + 1032U);
    t5 = *((char **)t4);
    t6 = *((unsigned char *)t5);
    t7 = (t6 == (unsigned char)3);
    t1 = t7;
    goto LAB7;

}

static void work_a_0082528624_1446275585_p_1(char *t0)
{
    char t1[16];
    char t2[16];
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    unsigned char t10;
    char *t11;
    unsigned int t12;
    unsigned int t13;
    unsigned char t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;

LAB0:    xsi_set_current_line(84, ng0);

LAB3:    t3 = (t0 + 1352U);
    t4 = *((char **)t3);
    t3 = (t0 + 5972U);
    t5 = (t0 + 1512U);
    t6 = *((char **)t5);
    t5 = (t0 + 5988U);
    t7 = ieee_p_3620187407_sub_767668596_3965413181(IEEE_P_3620187407, t2, t4, t3, t6, t5);
    t8 = (t0 + 1672U);
    t9 = *((char **)t8);
    t10 = *((unsigned char *)t9);
    t8 = ieee_p_3620187407_sub_674691591_3965413181(IEEE_P_3620187407, t1, t7, t2, t10);
    t11 = (t1 + 12U);
    t12 = *((unsigned int *)t11);
    t13 = (1U * t12);
    t14 = (27U != t13);
    if (t14 == 1)
        goto LAB5;

LAB6:    t15 = (t0 + 3656);
    t16 = (t15 + 56U);
    t17 = *((char **)t16);
    t18 = (t17 + 56U);
    t19 = *((char **)t18);
    memcpy(t19, t8, 27U);
    xsi_driver_first_trans_fast_port(t15);

LAB2:    t20 = (t0 + 3576);
    *((int *)t20) = 1;

LAB1:    return;
LAB4:    goto LAB2;

LAB5:    xsi_size_not_matching(27U, t13, 0);
    goto LAB6;

}


extern void work_a_0082528624_1446275585_init()
{
	static char *pe[] = {(void *)work_a_0082528624_1446275585_p_0,(void *)work_a_0082528624_1446275585_p_1};
	xsi_register_didat("work_a_0082528624_1446275585", "isim/testbench_isim_beh.exe.sim/work/a_0082528624_1446275585.didat");
	xsi_register_executes(pe);
}
