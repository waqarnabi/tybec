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
static const char *ng0 = "C:/WAQAR/GU/Work/_TyTra_BackEnd_Compiler_/TyBEC/lib-intern/flopoco/testing/spFloatHelpers.v";
static int ng1[] = {1023, 0};
static int ng2[] = {127, 0};
static unsigned int ng3[] = {0U, 0U};
static const char *ng4 = "C:/WAQAR/GU/Work/_TyTra_BackEnd_Compiler_/TyBEC/lib-intern/flopoco/testing/testbench.v";
static const char *ng5 = "LOG.log";
static const char *ng6 = "verifyhdl.dat";
static int ng7[] = {0, 0};
static int ng8[] = {16, 0};
static int ng9[] = {1, 0};
static int ng10[] = {7, 0};
static unsigned int ng11[] = {1U, 0U};
static const char *ng12 = "\t\t           time   index    resultfromC[index]  vout[index]";
static const char *ng13 = "";
static int ng14[] = {5, 0, 0, 0};
static int ng15[] = {2, 0, 0, 0};
static const char *ng16 = "%d\t||%f\t%f\t%f";
static const char *ng17 = "TEST PASSED WITH NO ERRORS!";
static const char *ng18 = "TEST FAIL!!!";



static int sp_doubletosingle(char *t1, char *t2)
{
    char t3[8];
    char t17[8];
    char t30[8];
    int t0;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    char *t16;
    char *t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t31;
    char *t32;
    char *t33;
    unsigned int t34;
    unsigned int t35;
    unsigned int t36;
    unsigned int t37;
    unsigned int t38;
    unsigned int t39;
    char *t40;

LAB0:    t0 = 1;
    xsi_set_current_line(12, ng0);

LAB2:    xsi_set_current_line(13, ng0);
    t4 = (t1 + 7336);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memset(t3, 0, 8);
    t7 = (t3 + 4);
    t8 = (t6 + 8);
    t9 = (t6 + 12);
    t10 = *((unsigned int *)t8);
    t11 = (t10 >> 20);
    *((unsigned int *)t3) = t11;
    t12 = *((unsigned int *)t9);
    t13 = (t12 >> 20);
    *((unsigned int *)t7) = t13;
    t14 = *((unsigned int *)t3);
    *((unsigned int *)t3) = (t14 & 2047U);
    t15 = *((unsigned int *)t7);
    *((unsigned int *)t7) = (t15 & 2047U);
    t16 = ((char*)((ng1)));
    memset(t17, 0, 8);
    xsi_vlog_unsigned_minus(t17, 32, t3, 32, t16, 32);
    t18 = (t1 + 7656);
    xsi_vlogvar_assign_value(t18, t17, 0, 0, 32);
    xsi_set_current_line(14, ng0);
    t4 = (t1 + 7656);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    t7 = ((char*)((ng2)));
    memset(t3, 0, 8);
    xsi_vlog_signed_add(t3, 32, t6, 32, t7, 32);
    t8 = (t1 + 7496);
    xsi_vlogvar_assign_value(t8, t3, 0, 0, 8);
    xsi_set_current_line(15, ng0);
    t4 = (t1 + 7336);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memset(t17, 0, 8);
    t7 = (t17 + 4);
    t8 = (t6 + 4);
    t10 = *((unsigned int *)t6);
    t11 = (t10 >> 29);
    *((unsigned int *)t17) = t11;
    t12 = *((unsigned int *)t8);
    t13 = (t12 >> 29);
    *((unsigned int *)t7) = t13;
    t9 = (t6 + 8);
    t16 = (t6 + 12);
    t14 = *((unsigned int *)t9);
    t15 = (t14 << 3);
    t19 = *((unsigned int *)t17);
    *((unsigned int *)t17) = (t19 | t15);
    t20 = *((unsigned int *)t16);
    t21 = (t20 << 3);
    t22 = *((unsigned int *)t7);
    *((unsigned int *)t7) = (t22 | t21);
    t23 = *((unsigned int *)t17);
    *((unsigned int *)t17) = (t23 & 8388607U);
    t24 = *((unsigned int *)t7);
    *((unsigned int *)t7) = (t24 & 8388607U);
    t18 = (t1 + 7496);
    t25 = (t18 + 56U);
    t26 = *((char **)t25);
    t27 = (t1 + 7336);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    memset(t30, 0, 8);
    t31 = (t30 + 4);
    t32 = (t29 + 8);
    t33 = (t29 + 12);
    t34 = *((unsigned int *)t32);
    t35 = (t34 >> 31);
    t36 = (t35 & 1);
    *((unsigned int *)t30) = t36;
    t37 = *((unsigned int *)t33);
    t38 = (t37 >> 31);
    t39 = (t38 & 1);
    *((unsigned int *)t31) = t39;
    xsi_vlogtype_concat(t3, 32, 32, 3U, t30, 1, t26, 8, t17, 23);
    t40 = (t1 + 7176);
    xsi_vlogvar_assign_value(t40, t3, 0, 0, 32);
    t0 = 0;

LAB1:    return t0;
}

static int sp_singletodouble(char *t1, char *t2)
{
    char t3[8];
    char t16[8];
    char t18[8];
    char t20[16];
    int t0;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    char *t15;
    char *t17;
    char *t19;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    char *t33;

LAB0:    t0 = 1;
    xsi_set_current_line(24, ng0);

LAB2:    xsi_set_current_line(25, ng0);
    t4 = (t1 + 7976);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memset(t3, 0, 8);
    t7 = (t3 + 4);
    t8 = (t6 + 4);
    t9 = *((unsigned int *)t6);
    t10 = (t9 >> 23);
    *((unsigned int *)t3) = t10;
    t11 = *((unsigned int *)t8);
    t12 = (t11 >> 23);
    *((unsigned int *)t7) = t12;
    t13 = *((unsigned int *)t3);
    *((unsigned int *)t3) = (t13 & 255U);
    t14 = *((unsigned int *)t7);
    *((unsigned int *)t7) = (t14 & 255U);
    t15 = ((char*)((ng2)));
    memset(t16, 0, 8);
    xsi_vlog_unsigned_minus(t16, 32, t3, 32, t15, 32);
    t17 = ((char*)((ng1)));
    memset(t18, 0, 8);
    xsi_vlog_unsigned_add(t18, 32, t16, 32, t17, 32);
    t19 = (t1 + 8136);
    xsi_vlogvar_assign_value(t19, t18, 0, 0, 11);
    xsi_set_current_line(26, ng0);
    t4 = ((char*)((ng3)));
    t5 = (t1 + 7976);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    memset(t3, 0, 8);
    t8 = (t3 + 4);
    t15 = (t7 + 4);
    t9 = *((unsigned int *)t7);
    t10 = (t9 >> 0);
    *((unsigned int *)t3) = t10;
    t11 = *((unsigned int *)t15);
    t12 = (t11 >> 0);
    *((unsigned int *)t8) = t12;
    t13 = *((unsigned int *)t3);
    *((unsigned int *)t3) = (t13 & 8388607U);
    t14 = *((unsigned int *)t8);
    *((unsigned int *)t8) = (t14 & 8388607U);
    t17 = (t1 + 8136);
    t19 = (t17 + 56U);
    t21 = *((char **)t19);
    t22 = (t1 + 7976);
    t23 = (t22 + 56U);
    t24 = *((char **)t23);
    memset(t16, 0, 8);
    t25 = (t16 + 4);
    t26 = (t24 + 4);
    t27 = *((unsigned int *)t24);
    t28 = (t27 >> 31);
    t29 = (t28 & 1);
    *((unsigned int *)t16) = t29;
    t30 = *((unsigned int *)t26);
    t31 = (t30 >> 31);
    t32 = (t31 & 1);
    *((unsigned int *)t25) = t32;
    xsi_vlogtype_concat(t20, 64, 64, 4U, t16, 1, t21, 11, t3, 23, t4, 29);
    t33 = (t1 + 7816);
    xsi_vlogvar_assign_value(t33, t20, 0, 0, 64);
    t0 = 0;

LAB1:    return t0;
}

static int sp_realtobitsSingle(char *t1, char *t2)
{
    char t7[16];
    char t25[8];
    int t0;
    char *t3;
    char *t4;
    char *t5;
    double t6;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    int t21;
    char *t22;
    char *t23;
    char *t24;
    char *t26;
    char *t27;
    char *t28;
    char *t29;

LAB0:    t0 = 1;
    xsi_set_current_line(35, ng0);

LAB2:    xsi_set_current_line(36, ng0);
    t3 = (t1 + 8456);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = *((double *)t5);
    t8 = xsi_vlog_convert_real_to_bits(t6, t7, 64);
    t9 = (t1 + 8616);
    xsi_vlogvar_assign_value(t9, t7, 0, 0, 64);
    xsi_set_current_line(37, ng0);
    t3 = (t1 + 8616);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t8 = (t2 + 56U);
    t9 = *((char **)t8);
    t10 = (t1 + 848);
    t11 = xsi_create_subprogram_invocation(t9, 0, t1, t10, 0, t2);
    t12 = (t1 + 7336);
    xsi_vlogvar_assign_value(t12, t5, 0, 0, 64);

LAB3:    t13 = (t2 + 64U);
    t14 = *((char **)t13);
    t15 = (t14 + 80U);
    t16 = *((char **)t15);
    t17 = (t16 + 272U);
    t18 = *((char **)t17);
    t19 = (t18 + 0U);
    t20 = *((char **)t19);
    t21 = ((int  (*)(char *, char *))t20)(t1, t14);
    if (t21 != 0)
        goto LAB5;

LAB4:    t14 = (t2 + 64U);
    t22 = *((char **)t14);
    t14 = (t1 + 7176);
    t23 = (t14 + 56U);
    t24 = *((char **)t23);
    memcpy(t25, t24, 8);
    t26 = (t1 + 848);
    t27 = (t2 + 56U);
    t28 = *((char **)t27);
    xsi_delete_subprogram_invocation(t26, t22, t1, t28, t2);
    t29 = (t1 + 8296);
    xsi_vlogvar_assign_value(t29, t25, 0, 0, 32);
    t0 = 0;

LAB1:    return t0;
LAB5:    t13 = (t2 + 48U);
    *((char **)t13) = &&LAB3;
    goto LAB1;

}

static int sp_bitstorealSingle(char *t1, char *t2)
{
    char t23[16];
    char t28[8];
    int t0;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    char *t22;
    char *t24;
    char *t25;
    char *t26;
    char *t27;

LAB0:    t0 = 1;
    xsi_set_current_line(46, ng0);

LAB2:    xsi_set_current_line(47, ng0);
    t3 = (t1 + 8936);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t2 + 56U);
    t7 = *((char **)t6);
    t8 = (t1 + 1280);
    t9 = xsi_create_subprogram_invocation(t7, 0, t1, t8, 0, t2);
    t10 = (t1 + 7976);
    xsi_vlogvar_assign_value(t10, t5, 0, 0, 32);

LAB3:    t11 = (t2 + 64U);
    t12 = *((char **)t11);
    t13 = (t12 + 80U);
    t14 = *((char **)t13);
    t15 = (t14 + 272U);
    t16 = *((char **)t15);
    t17 = (t16 + 0U);
    t18 = *((char **)t17);
    t19 = ((int  (*)(char *, char *))t18)(t1, t12);
    if (t19 != 0)
        goto LAB5;

LAB4:    t12 = (t2 + 64U);
    t20 = *((char **)t12);
    t12 = (t1 + 7816);
    t21 = (t12 + 56U);
    t22 = *((char **)t21);
    memcpy(t23, t22, 16);
    t24 = (t1 + 1280);
    t25 = (t2 + 56U);
    t26 = *((char **)t25);
    xsi_delete_subprogram_invocation(t24, t20, t1, t26, t2);
    t27 = (t1 + 9096);
    xsi_vlogvar_assign_value(t27, t23, 0, 0, 64);
    xsi_set_current_line(48, ng0);
    t3 = (t1 + 9096);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    *((int *)t28) = *((int *)t5);
    t6 = (t28 + 4);
    t7 = (t5 + 8);
    *((int *)t6) = *((int *)t7);
    t8 = (t1 + 8776);
    xsi_vlogvar_assign_value_double(t8, *((double *)t28), 0);
    t0 = 0;

LAB1:    return t0;
LAB5:    t11 = (t2 + 48U);
    *((char **)t11) = &&LAB3;
    goto LAB1;

}

static void Initial_55_0(char *t0)
{
    char t1[8];
    char *t2;
    char *t3;

LAB0:    xsi_set_current_line(56, ng4);

LAB2:    xsi_set_current_line(57, ng4);
    *((int *)t1) = xsi_vlogfile_file_open_of_cname(ng5);
    t2 = (t1 + 4);
    *((int *)t2) = 0;
    t3 = (t0 + 5576);
    xsi_vlogvar_assign_value(t3, t1, 0, 0, 32);
    xsi_set_current_line(58, ng4);
    *((int *)t1) = xsi_vlogfile_file_open_of_cname(ng6);
    t2 = (t1 + 4);
    *((int *)t2) = 0;
    t3 = (t0 + 5736);
    xsi_vlogvar_assign_value(t3, t1, 0, 0, 32);

LAB1:    return;
}

static void Initial_73_1(char *t0)
{
    char t5[8];
    char t36[8];
    char t41[8];
    char t42[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    char *t13;
    char *t14;
    double t15;
    double t16;
    char *t17;
    double t18;
    double t19;
    char *t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    int t32;
    char *t33;
    char *t34;
    char *t35;
    char *t37;
    char *t38;
    char *t39;
    char *t40;
    char *t43;
    char *t44;
    char *t45;
    char *t46;
    char *t47;
    char *t48;
    char *t49;
    char *t50;
    char *t51;
    char *t52;
    unsigned int t53;
    int t54;
    char *t55;
    unsigned int t56;
    int t57;
    int t58;
    unsigned int t59;
    unsigned int t60;
    int t61;
    int t62;

LAB0:    xsi_set_current_line(74, ng4);
    xsi_set_current_line(74, ng4);
    t1 = ((char*)((ng7)));
    t2 = (t0 + 6376);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 32);

LAB2:    t1 = (t0 + 6376);
    t2 = (t1 + 56U);
    t3 = *((char **)t2);
    t4 = ((char*)((ng8)));
    memset(t5, 0, 8);
    xsi_vlog_signed_less(t5, 32, t3, 32, t4, 32);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB3;

LAB4:
LAB1:    return;
LAB3:    xsi_set_current_line(74, ng4);

LAB5:    xsi_set_current_line(75, ng4);
    t12 = (t0 + 6376);
    t13 = (t12 + 56U);
    t14 = *((char **)t13);
    t15 = xsi_vlog_convert_to_real(t14, 32, 1);
    t16 = (3.1400000000000001 + t15);
    t17 = ((char*)((ng9)));
    t18 = xsi_vlog_convert_to_real(t17, 32, 1);
    t19 = (t16 + t18);
    t20 = (t0 + 10072);
    t21 = (t0 + 1712);
    t22 = xsi_create_subprogram_invocation(t20, 0, t0, t21, 0, 0);
    t23 = (t0 + 8456);
    xsi_vlogvar_assign_value_double(t23, t19, 0);

LAB6:    t24 = (t0 + 10168);
    t25 = *((char **)t24);
    t26 = (t25 + 80U);
    t27 = *((char **)t26);
    t28 = (t27 + 272U);
    t29 = *((char **)t28);
    t30 = (t29 + 0U);
    t31 = *((char **)t30);
    t32 = ((int  (*)(char *, char *))t31)(t0, t25);
    if (t32 != 0)
        goto LAB8;

LAB7:    t25 = (t0 + 10168);
    t33 = *((char **)t25);
    t25 = (t0 + 8296);
    t34 = (t25 + 56U);
    t35 = *((char **)t34);
    memcpy(t36, t35, 8);
    t37 = (t0 + 1712);
    t38 = (t0 + 10072);
    t39 = 0;
    xsi_delete_subprogram_invocation(t37, t33, t0, t38, t39);
    t40 = (t0 + 5896);
    t43 = (t0 + 5896);
    t44 = (t43 + 72U);
    t45 = *((char **)t44);
    t46 = (t0 + 5896);
    t47 = (t46 + 64U);
    t48 = *((char **)t47);
    t49 = (t0 + 6376);
    t50 = (t49 + 56U);
    t51 = *((char **)t50);
    xsi_vlog_generic_convert_array_indices(t41, t42, t45, t48, 2, 1, t51, 32, 1);
    t52 = (t41 + 4);
    t53 = *((unsigned int *)t52);
    t54 = (!(t53));
    t55 = (t42 + 4);
    t56 = *((unsigned int *)t55);
    t57 = (!(t56));
    t58 = (t54 && t57);
    if (t58 == 1)
        goto LAB9;

LAB10:    xsi_set_current_line(76, ng4);
    t1 = (t0 + 6376);
    t2 = (t1 + 56U);
    t3 = *((char **)t2);
    t15 = xsi_vlog_convert_to_real(t3, 32, 1);
    t16 = (3.1400000000000001 + t15);
    t4 = ((char*)((ng9)));
    t18 = xsi_vlog_convert_to_real(t4, 32, 1);
    t19 = (t16 + t18);
    t6 = (t0 + 10072);
    t12 = (t0 + 1712);
    t13 = xsi_create_subprogram_invocation(t6, 0, t0, t12, 0, 0);
    t14 = (t0 + 8456);
    xsi_vlogvar_assign_value_double(t14, t19, 0);

LAB11:    t17 = (t0 + 10168);
    t20 = *((char **)t17);
    t21 = (t20 + 80U);
    t22 = *((char **)t21);
    t23 = (t22 + 272U);
    t24 = *((char **)t23);
    t25 = (t24 + 0U);
    t26 = *((char **)t25);
    t32 = ((int  (*)(char *, char *))t26)(t0, t20);
    if (t32 != 0)
        goto LAB13;

LAB12:    t20 = (t0 + 10168);
    t27 = *((char **)t20);
    t20 = (t0 + 8296);
    t28 = (t20 + 56U);
    t29 = *((char **)t28);
    memcpy(t5, t29, 8);
    t30 = (t0 + 1712);
    t31 = (t0 + 10072);
    t33 = 0;
    xsi_delete_subprogram_invocation(t30, t27, t0, t31, t33);
    t34 = (t0 + 6056);
    t35 = (t0 + 6056);
    t37 = (t35 + 72U);
    t38 = *((char **)t37);
    t39 = (t0 + 6056);
    t40 = (t39 + 64U);
    t43 = *((char **)t40);
    t44 = (t0 + 6376);
    t45 = (t44 + 56U);
    t46 = *((char **)t45);
    xsi_vlog_generic_convert_array_indices(t36, t41, t38, t43, 2, 1, t46, 32, 1);
    t47 = (t36 + 4);
    t7 = *((unsigned int *)t47);
    t54 = (!(t7));
    t48 = (t41 + 4);
    t8 = *((unsigned int *)t48);
    t57 = (!(t8));
    t58 = (t54 && t57);
    if (t58 == 1)
        goto LAB14;

LAB15:    xsi_set_current_line(77, ng4);
    t1 = ((char*)((ng7)));
    t2 = (t0 + 6216);
    t3 = (t0 + 6216);
    t4 = (t3 + 72U);
    t6 = *((char **)t4);
    t12 = (t0 + 6216);
    t13 = (t12 + 64U);
    t14 = *((char **)t13);
    t17 = (t0 + 6376);
    t20 = (t17 + 56U);
    t21 = *((char **)t20);
    xsi_vlog_generic_convert_array_indices(t5, t36, t6, t14, 2, 1, t21, 32, 1);
    t22 = (t5 + 4);
    t7 = *((unsigned int *)t22);
    t32 = (!(t7));
    t23 = (t36 + 4);
    t8 = *((unsigned int *)t23);
    t54 = (!(t8));
    t57 = (t32 && t54);
    if (t57 == 1)
        goto LAB16;

LAB17:    xsi_set_current_line(74, ng4);
    t1 = (t0 + 6376);
    t2 = (t1 + 56U);
    t3 = *((char **)t2);
    t4 = ((char*)((ng9)));
    memset(t5, 0, 8);
    xsi_vlog_signed_add(t5, 32, t3, 32, t4, 32);
    t6 = (t0 + 6376);
    xsi_vlogvar_assign_value(t6, t5, 0, 0, 32);
    goto LAB2;

LAB8:    t24 = (t0 + 10264U);
    *((char **)t24) = &&LAB6;
    goto LAB1;

LAB9:    t59 = *((unsigned int *)t41);
    t60 = *((unsigned int *)t42);
    t61 = (t59 - t60);
    t62 = (t61 + 1);
    xsi_vlogvar_assign_value(t40, t36, 0, *((unsigned int *)t42), t62);
    goto LAB10;

LAB13:    t17 = (t0 + 10264U);
    *((char **)t17) = &&LAB11;
    goto LAB1;

LAB14:    t9 = *((unsigned int *)t36);
    t10 = *((unsigned int *)t41);
    t61 = (t9 - t10);
    t62 = (t61 + 1);
    xsi_vlogvar_assign_value(t34, t5, 0, *((unsigned int *)t41), t62);
    goto LAB15;

LAB16:    t9 = *((unsigned int *)t5);
    t10 = *((unsigned int *)t36);
    t58 = (t9 - t10);
    t61 = (t58 + 1);
    xsi_vlogvar_assign_value(t2, t1, 0, *((unsigned int *)t36), t61);
    goto LAB17;

}

static void Initial_82_2(char *t0)
{
    char t6[8];
    char t7[8];
    char t16[8];
    char t17[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    char *t15;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    unsigned int t28;
    int t29;
    char *t30;
    unsigned int t31;
    int t32;
    int t33;
    unsigned int t34;
    unsigned int t35;
    int t36;
    int t37;

LAB0:    xsi_set_current_line(83, ng4);
    xsi_set_current_line(83, ng4);
    t1 = ((char*)((ng8)));
    t2 = (t0 + 6536);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 32);

LAB2:    t1 = (t0 + 6536);
    t2 = (t1 + 56U);
    t3 = *((char **)t2);
    t4 = ((char*)((ng8)));
    t5 = ((char*)((ng10)));
    memset(t6, 0, 8);
    xsi_vlog_signed_add(t6, 32, t4, 32, t5, 32);
    memset(t7, 0, 8);
    xsi_vlog_signed_less(t7, 32, t3, 32, t6, 32);
    t8 = (t7 + 4);
    t9 = *((unsigned int *)t8);
    t10 = (~(t9));
    t11 = *((unsigned int *)t7);
    t12 = (t11 & t10);
    t13 = (t12 != 0);
    if (t13 > 0)
        goto LAB3;

LAB4:
LAB1:    return;
LAB3:    xsi_set_current_line(83, ng4);

LAB5:    xsi_set_current_line(84, ng4);
    t14 = ((char*)((ng7)));
    t15 = (t0 + 5896);
    t18 = (t0 + 5896);
    t19 = (t18 + 72U);
    t20 = *((char **)t19);
    t21 = (t0 + 5896);
    t22 = (t21 + 64U);
    t23 = *((char **)t22);
    t24 = (t0 + 6536);
    t25 = (t24 + 56U);
    t26 = *((char **)t25);
    xsi_vlog_generic_convert_array_indices(t16, t17, t20, t23, 2, 1, t26, 32, 1);
    t27 = (t16 + 4);
    t28 = *((unsigned int *)t27);
    t29 = (!(t28));
    t30 = (t17 + 4);
    t31 = *((unsigned int *)t30);
    t32 = (!(t31));
    t33 = (t29 && t32);
    if (t33 == 1)
        goto LAB6;

LAB7:    xsi_set_current_line(85, ng4);
    t1 = ((char*)((ng7)));
    t2 = (t0 + 6056);
    t3 = (t0 + 6056);
    t4 = (t3 + 72U);
    t5 = *((char **)t4);
    t8 = (t0 + 6056);
    t14 = (t8 + 64U);
    t15 = *((char **)t14);
    t18 = (t0 + 6536);
    t19 = (t18 + 56U);
    t20 = *((char **)t19);
    xsi_vlog_generic_convert_array_indices(t6, t7, t5, t15, 2, 1, t20, 32, 1);
    t21 = (t6 + 4);
    t9 = *((unsigned int *)t21);
    t29 = (!(t9));
    t22 = (t7 + 4);
    t10 = *((unsigned int *)t22);
    t32 = (!(t10));
    t33 = (t29 && t32);
    if (t33 == 1)
        goto LAB8;

LAB9:    xsi_set_current_line(86, ng4);
    t1 = ((char*)((ng7)));
    t2 = (t0 + 6216);
    t3 = (t0 + 6216);
    t4 = (t3 + 72U);
    t5 = *((char **)t4);
    t8 = (t0 + 6216);
    t14 = (t8 + 64U);
    t15 = *((char **)t14);
    t18 = (t0 + 6536);
    t19 = (t18 + 56U);
    t20 = *((char **)t19);
    xsi_vlog_generic_convert_array_indices(t6, t7, t5, t15, 2, 1, t20, 32, 1);
    t21 = (t6 + 4);
    t9 = *((unsigned int *)t21);
    t29 = (!(t9));
    t22 = (t7 + 4);
    t10 = *((unsigned int *)t22);
    t32 = (!(t10));
    t33 = (t29 && t32);
    if (t33 == 1)
        goto LAB10;

LAB11:    xsi_set_current_line(83, ng4);
    t1 = (t0 + 6536);
    t2 = (t1 + 56U);
    t3 = *((char **)t2);
    t4 = ((char*)((ng9)));
    memset(t6, 0, 8);
    xsi_vlog_signed_add(t6, 32, t3, 32, t4, 32);
    t5 = (t0 + 6536);
    xsi_vlogvar_assign_value(t5, t6, 0, 0, 32);
    goto LAB2;

LAB6:    t34 = *((unsigned int *)t16);
    t35 = *((unsigned int *)t17);
    t36 = (t34 - t35);
    t37 = (t36 + 1);
    xsi_vlogvar_assign_value(t15, t14, 0, *((unsigned int *)t17), t37);
    goto LAB7;

LAB8:    t11 = *((unsigned int *)t6);
    t12 = *((unsigned int *)t7);
    t36 = (t11 - t12);
    t37 = (t36 + 1);
    xsi_vlogvar_assign_value(t2, t1, 0, *((unsigned int *)t7), t37);
    goto LAB9;

LAB10:    t11 = *((unsigned int *)t6);
    t12 = *((unsigned int *)t7);
    t36 = (t11 - t12);
    t37 = (t36 + 1);
    xsi_vlogvar_assign_value(t2, t1, 0, *((unsigned int *)t7), t37);
    goto LAB11;

}

static void NetDecl_96_3(char *t0)
{
    char t3[8];
    char *t1;
    char *t2;
    char *t4;
    char *t5;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    char *t13;
    char *t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    unsigned int t28;
    unsigned int t29;
    char *t30;
    unsigned int t31;
    unsigned int t32;
    char *t33;
    unsigned int t34;
    unsigned int t35;
    char *t36;

LAB0:    t1 = (t0 + 10760U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(96, ng4);
    t2 = (t0 + 4296);
    t4 = (t2 + 56U);
    t5 = *((char **)t4);
    memset(t3, 0, 8);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB7;

LAB5:    if (*((unsigned int *)t6) == 0)
        goto LAB4;

LAB6:    t12 = (t3 + 4);
    *((unsigned int *)t3) = 1;
    *((unsigned int *)t12) = 1;

LAB7:    t13 = (t3 + 4);
    t14 = (t5 + 4);
    t15 = *((unsigned int *)t5);
    t16 = (~(t15));
    *((unsigned int *)t3) = t16;
    *((unsigned int *)t13) = 0;
    if (*((unsigned int *)t14) != 0)
        goto LAB9;

LAB8:    t21 = *((unsigned int *)t3);
    *((unsigned int *)t3) = (t21 & 1U);
    t22 = *((unsigned int *)t13);
    *((unsigned int *)t13) = (t22 & 1U);
    t23 = (t0 + 15336);
    t24 = (t23 + 56U);
    t25 = *((char **)t24);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    memset(t27, 0, 8);
    t28 = 1U;
    t29 = t28;
    t30 = (t3 + 4);
    t31 = *((unsigned int *)t3);
    t28 = (t28 & t31);
    t32 = *((unsigned int *)t30);
    t29 = (t29 & t32);
    t33 = (t27 + 4);
    t34 = *((unsigned int *)t27);
    *((unsigned int *)t27) = (t34 | t28);
    t35 = *((unsigned int *)t33);
    *((unsigned int *)t33) = (t35 | t29);
    xsi_driver_vfirst_trans(t23, 0, 0U);
    t36 = (t0 + 15048);
    *((int *)t36) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t3) = 1;
    goto LAB7;

LAB9:    t17 = *((unsigned int *)t3);
    t18 = *((unsigned int *)t14);
    *((unsigned int *)t3) = (t17 | t18);
    t19 = *((unsigned int *)t13);
    t20 = *((unsigned int *)t14);
    *((unsigned int *)t13) = (t19 | t20);
    goto LAB8;

}

static void Initial_129_4(char *t0)
{
    char *t1;
    char *t2;

LAB0:    xsi_set_current_line(130, ng4);
    t1 = ((char*)((ng7)));
    t2 = (t0 + 4136);
    xsi_vlogvar_wait_assign_value(t2, t1, 0, 0, 1, 0LL);

LAB1:    return;
}

static void Always_132_5(char *t0)
{
    char t3[8];
    char *t1;
    char *t2;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    char *t13;
    char *t14;
    char *t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    char *t24;

LAB0:    t1 = (t0 + 11256U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(133, ng4);
    t2 = (t0 + 11064);
    xsi_process_wait(t2, 5000LL);
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(133, ng4);
    t4 = (t0 + 4136);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memset(t3, 0, 8);
    t7 = (t6 + 4);
    t8 = *((unsigned int *)t7);
    t9 = (~(t8));
    t10 = *((unsigned int *)t6);
    t11 = (t10 & t9);
    t12 = (t11 & 1U);
    if (t12 != 0)
        goto LAB8;

LAB6:    if (*((unsigned int *)t7) == 0)
        goto LAB5;

LAB7:    t13 = (t3 + 4);
    *((unsigned int *)t3) = 1;
    *((unsigned int *)t13) = 1;

LAB8:    t14 = (t3 + 4);
    t15 = (t6 + 4);
    t16 = *((unsigned int *)t6);
    t17 = (~(t16));
    *((unsigned int *)t3) = t17;
    *((unsigned int *)t14) = 0;
    if (*((unsigned int *)t15) != 0)
        goto LAB10;

LAB9:    t22 = *((unsigned int *)t3);
    *((unsigned int *)t3) = (t22 & 1U);
    t23 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t23 & 1U);
    t24 = (t0 + 4136);
    xsi_vlogvar_assign_value(t24, t3, 0, 0, 1);
    goto LAB2;

LAB5:    *((unsigned int *)t3) = 1;
    goto LAB8;

LAB10:    t18 = *((unsigned int *)t3);
    t19 = *((unsigned int *)t15);
    *((unsigned int *)t3) = (t18 | t19);
    t20 = *((unsigned int *)t14);
    t21 = *((unsigned int *)t15);
    *((unsigned int *)t14) = (t20 | t21);
    goto LAB9;

}

static void Initial_135_6(char *t0)
{
    char *t1;
    char *t2;
    char *t3;

LAB0:    t1 = (t0 + 11504U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(136, ng4);

LAB4:    xsi_set_current_line(138, ng4);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 4296);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(139, ng4);
    t2 = (t0 + 15064);
    *((int *)t2) = 1;
    t3 = (t0 + 11536);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB5;

LAB1:    return;
LAB5:    xsi_set_current_line(140, ng4);
    t2 = (t0 + 15080);
    *((int *)t2) = 1;
    t3 = (t0 + 11536);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB6;
    goto LAB1;

LAB6:    xsi_set_current_line(141, ng4);
    t2 = ((char*)((ng11)));
    t3 = (t0 + 4296);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB1;

}

static void Always_151_7(char *t0)
{
    char t4[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    char *t15;
    char *t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    char *t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    char *t32;

LAB0:    t1 = (t0 + 11752U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(151, ng4);
    t2 = (t0 + 15096);
    *((int *)t2) = 1;
    t3 = (t0 + 11784);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(151, ng4);

LAB5:    xsi_set_current_line(152, ng4);
    t5 = (t0 + 4296);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    memset(t4, 0, 8);
    t8 = (t7 + 4);
    t9 = *((unsigned int *)t8);
    t10 = (~(t9));
    t11 = *((unsigned int *)t7);
    t12 = (t11 & t10);
    t13 = (t12 & 1U);
    if (t13 != 0)
        goto LAB9;

LAB7:    if (*((unsigned int *)t8) == 0)
        goto LAB6;

LAB8:    t14 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t14) = 1;

LAB9:    t15 = (t4 + 4);
    t16 = (t7 + 4);
    t17 = *((unsigned int *)t7);
    t18 = (~(t17));
    *((unsigned int *)t4) = t18;
    *((unsigned int *)t15) = 0;
    if (*((unsigned int *)t16) != 0)
        goto LAB11;

LAB10:    t23 = *((unsigned int *)t4);
    *((unsigned int *)t4) = (t23 & 1U);
    t24 = *((unsigned int *)t15);
    *((unsigned int *)t15) = (t24 & 1U);
    t25 = (t4 + 4);
    t26 = *((unsigned int *)t25);
    t27 = (~(t26));
    t28 = *((unsigned int *)t4);
    t29 = (t28 & t27);
    t30 = (t29 != 0);
    if (t30 > 0)
        goto LAB12;

LAB13:    xsi_set_current_line(155, ng4);
    t2 = (t0 + 6696);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = ((char*)((ng9)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_add(t4, 32, t5, 2, t6, 32);
    t7 = (t0 + 6696);
    xsi_vlogvar_wait_assign_value(t7, t4, 0, 0, 2, 0LL);

LAB14:    goto LAB2;

LAB6:    *((unsigned int *)t4) = 1;
    goto LAB9;

LAB11:    t19 = *((unsigned int *)t4);
    t20 = *((unsigned int *)t16);
    *((unsigned int *)t4) = (t19 | t20);
    t21 = *((unsigned int *)t15);
    t22 = *((unsigned int *)t16);
    *((unsigned int *)t15) = (t21 | t22);
    goto LAB10;

LAB12:    xsi_set_current_line(153, ng4);
    t31 = ((char*)((ng7)));
    t32 = (t0 + 6696);
    xsi_vlogvar_wait_assign_value(t32, t31, 0, 0, 2, 0LL);
    goto LAB14;

}

static void Always_162_8(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;

LAB0:    t1 = (t0 + 12000U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(162, ng4);
    t2 = (t0 + 15112);
    *((int *)t2) = 1;
    t3 = (t0 + 12032);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(162, ng4);

LAB5:    xsi_set_current_line(174, ng4);
    t4 = ((char*)((ng9)));
    t5 = (t0 + 4616);
    xsi_vlogvar_wait_assign_value(t5, t4, 0, 0, 1, 0LL);
    goto LAB2;

}

static void Always_180_9(char *t0)
{
    char t4[8];
    char t33[8];
    char t34[8];
    char t35[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    char *t15;
    char *t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    char *t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    char *t32;
    char *t36;

LAB0:    t1 = (t0 + 12248U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(180, ng4);
    t2 = (t0 + 15128);
    *((int *)t2) = 1;
    t3 = (t0 + 12280);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(181, ng4);
    t5 = (t0 + 4296);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    memset(t4, 0, 8);
    t8 = (t7 + 4);
    t9 = *((unsigned int *)t8);
    t10 = (~(t9));
    t11 = *((unsigned int *)t7);
    t12 = (t11 & t10);
    t13 = (t12 & 1U);
    if (t13 != 0)
        goto LAB8;

LAB6:    if (*((unsigned int *)t8) == 0)
        goto LAB5;

LAB7:    t14 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t14) = 1;

LAB8:    t15 = (t4 + 4);
    t16 = (t7 + 4);
    t17 = *((unsigned int *)t7);
    t18 = (~(t17));
    *((unsigned int *)t4) = t18;
    *((unsigned int *)t15) = 0;
    if (*((unsigned int *)t16) != 0)
        goto LAB10;

LAB9:    t23 = *((unsigned int *)t4);
    *((unsigned int *)t4) = (t23 & 1U);
    t24 = *((unsigned int *)t15);
    *((unsigned int *)t15) = (t24 & 1U);
    t25 = (t4 + 4);
    t26 = *((unsigned int *)t25);
    t27 = (~(t26));
    t28 = *((unsigned int *)t4);
    t29 = (t28 & t27);
    t30 = (t29 != 0);
    if (t30 > 0)
        goto LAB11;

LAB12:    xsi_set_current_line(183, ng4);
    t2 = (t0 + 4776);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = ((char*)((ng8)));
    t7 = ((char*)((ng9)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_minus(t4, 32, t6, 32, t7, 32);
    t8 = ((char*)((ng10)));
    t14 = ((char*)((ng9)));
    memset(t33, 0, 8);
    xsi_vlog_unsigned_multiply(t33, 32, t8, 32, t14, 32);
    memset(t34, 0, 8);
    xsi_vlog_unsigned_add(t34, 32, t4, 32, t33, 32);
    memset(t35, 0, 8);
    t15 = (t5 + 4);
    if (*((unsigned int *)t15) != 0)
        goto LAB15;

LAB14:    t16 = (t34 + 4);
    if (*((unsigned int *)t16) != 0)
        goto LAB15;

LAB18:    if (*((unsigned int *)t5) < *((unsigned int *)t34))
        goto LAB17;

LAB16:    *((unsigned int *)t35) = 1;

LAB17:    t31 = (t35 + 4);
    t9 = *((unsigned int *)t31);
    t10 = (~(t9));
    t11 = *((unsigned int *)t35);
    t12 = (t11 & t10);
    t13 = (t12 != 0);
    if (t13 > 0)
        goto LAB19;

LAB20:    xsi_set_current_line(185, ng4);
    t2 = (t0 + 4616);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = (t5 + 4);
    t9 = *((unsigned int *)t6);
    t10 = (~(t9));
    t11 = *((unsigned int *)t5);
    t12 = (t11 & t10);
    t13 = (t12 != 0);
    if (t13 > 0)
        goto LAB22;

LAB23:    xsi_set_current_line(188, ng4);
    t2 = (t0 + 4776);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = (t0 + 4776);
    xsi_vlogvar_wait_assign_value(t6, t5, 0, 0, 32, 0LL);

LAB24:
LAB21:
LAB13:    goto LAB2;

LAB5:    *((unsigned int *)t4) = 1;
    goto LAB8;

LAB10:    t19 = *((unsigned int *)t4);
    t20 = *((unsigned int *)t16);
    *((unsigned int *)t4) = (t19 | t20);
    t21 = *((unsigned int *)t15);
    t22 = *((unsigned int *)t16);
    *((unsigned int *)t15) = (t21 | t22);
    goto LAB9;

LAB11:    xsi_set_current_line(182, ng4);
    t31 = ((char*)((ng7)));
    t32 = (t0 + 4776);
    xsi_vlogvar_wait_assign_value(t32, t31, 0, 0, 32, 0LL);
    goto LAB13;

LAB15:    t25 = (t35 + 4);
    *((unsigned int *)t35) = 1;
    *((unsigned int *)t25) = 1;
    goto LAB17;

LAB19:    xsi_set_current_line(184, ng4);
    t32 = ((char*)((ng7)));
    t36 = (t0 + 4776);
    xsi_vlogvar_wait_assign_value(t36, t32, 0, 0, 32, 0LL);
    goto LAB21;

LAB22:    xsi_set_current_line(186, ng4);
    t7 = (t0 + 4776);
    t8 = (t7 + 56U);
    t14 = *((char **)t8);
    t15 = ((char*)((ng9)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_add(t4, 32, t14, 32, t15, 32);
    t16 = (t0 + 4776);
    xsi_vlogvar_wait_assign_value(t16, t4, 0, 0, 32, 0LL);
    goto LAB24;

}

static void Always_192_10(char *t0)
{
    char t4[8];
    char t33[8];
    char t34[8];
    char t35[8];
    char t41[8];
    char t49[8];
    char t91[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    char *t15;
    char *t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    char *t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    char *t32;
    unsigned int t36;
    unsigned int t37;
    char *t38;
    char *t39;
    char *t40;
    char *t42;
    unsigned int t43;
    unsigned int t44;
    unsigned int t45;
    unsigned int t46;
    unsigned int t47;
    char *t48;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    char *t53;
    char *t54;
    char *t55;
    unsigned int t56;
    unsigned int t57;
    unsigned int t58;
    unsigned int t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    char *t63;
    char *t64;
    unsigned int t65;
    unsigned int t66;
    unsigned int t67;
    unsigned int t68;
    unsigned int t69;
    unsigned int t70;
    unsigned int t71;
    unsigned int t72;
    int t73;
    int t74;
    unsigned int t75;
    unsigned int t76;
    unsigned int t77;
    unsigned int t78;
    unsigned int t79;
    unsigned int t80;
    char *t81;
    unsigned int t82;
    unsigned int t83;
    unsigned int t84;
    unsigned int t85;
    unsigned int t86;
    char *t87;
    char *t88;
    char *t89;
    char *t90;
    char *t92;

LAB0:    t1 = (t0 + 12496U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(192, ng4);
    t2 = (t0 + 15144);
    *((int *)t2) = 1;
    t3 = (t0 + 12528);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(193, ng4);
    t5 = (t0 + 4296);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    memset(t4, 0, 8);
    t8 = (t7 + 4);
    t9 = *((unsigned int *)t8);
    t10 = (~(t9));
    t11 = *((unsigned int *)t7);
    t12 = (t11 & t10);
    t13 = (t12 & 1U);
    if (t13 != 0)
        goto LAB8;

LAB6:    if (*((unsigned int *)t8) == 0)
        goto LAB5;

LAB7:    t14 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t14) = 1;

LAB8:    t15 = (t4 + 4);
    t16 = (t7 + 4);
    t17 = *((unsigned int *)t7);
    t18 = (~(t17));
    *((unsigned int *)t4) = t18;
    *((unsigned int *)t15) = 0;
    if (*((unsigned int *)t16) != 0)
        goto LAB10;

LAB9:    t23 = *((unsigned int *)t4);
    *((unsigned int *)t4) = (t23 & 1U);
    t24 = *((unsigned int *)t15);
    *((unsigned int *)t15) = (t24 & 1U);
    t25 = (t4 + 4);
    t26 = *((unsigned int *)t25);
    t27 = (~(t26));
    t28 = *((unsigned int *)t4);
    t29 = (t28 & t27);
    t30 = (t29 != 0);
    if (t30 > 0)
        goto LAB11;

LAB12:    xsi_set_current_line(195, ng4);
    t2 = (t0 + 4776);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = ((char*)((ng8)));
    t7 = ((char*)((ng9)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_minus(t4, 32, t6, 32, t7, 32);
    t8 = ((char*)((ng10)));
    memset(t33, 0, 8);
    xsi_vlog_unsigned_add(t33, 32, t4, 32, t8, 32);
    memset(t34, 0, 8);
    t14 = (t5 + 4);
    t15 = (t33 + 4);
    t9 = *((unsigned int *)t5);
    t10 = *((unsigned int *)t33);
    t11 = (t9 ^ t10);
    t12 = *((unsigned int *)t14);
    t13 = *((unsigned int *)t15);
    t17 = (t12 ^ t13);
    t18 = (t11 | t17);
    t19 = *((unsigned int *)t14);
    t20 = *((unsigned int *)t15);
    t21 = (t19 | t20);
    t22 = (~(t21));
    t23 = (t18 & t22);
    if (t23 != 0)
        goto LAB17;

LAB14:    if (t21 != 0)
        goto LAB16;

LAB15:    *((unsigned int *)t34) = 1;

LAB17:    memset(t35, 0, 8);
    t25 = (t34 + 4);
    t24 = *((unsigned int *)t25);
    t26 = (~(t24));
    t27 = *((unsigned int *)t34);
    t28 = (t27 & t26);
    t29 = (t28 & 1U);
    if (t29 != 0)
        goto LAB18;

LAB19:    if (*((unsigned int *)t25) != 0)
        goto LAB20;

LAB21:    t32 = (t35 + 4);
    t30 = *((unsigned int *)t35);
    t36 = *((unsigned int *)t32);
    t37 = (t30 || t36);
    if (t37 > 0)
        goto LAB22;

LAB23:    memcpy(t49, t35, 8);

LAB24:    t81 = (t49 + 4);
    t82 = *((unsigned int *)t81);
    t83 = (~(t82));
    t84 = *((unsigned int *)t49);
    t85 = (t84 & t83);
    t86 = (t85 != 0);
    if (t86 > 0)
        goto LAB32;

LAB33:    xsi_set_current_line(198, ng4);
    t2 = (t0 + 4936);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = (t0 + 4936);
    xsi_vlogvar_wait_assign_value(t6, t5, 0, 0, 32, 0LL);

LAB34:
LAB13:    goto LAB2;

LAB5:    *((unsigned int *)t4) = 1;
    goto LAB8;

LAB10:    t19 = *((unsigned int *)t4);
    t20 = *((unsigned int *)t16);
    *((unsigned int *)t4) = (t19 | t20);
    t21 = *((unsigned int *)t15);
    t22 = *((unsigned int *)t16);
    *((unsigned int *)t15) = (t21 | t22);
    goto LAB9;

LAB11:    xsi_set_current_line(194, ng4);
    t31 = ((char*)((ng7)));
    t32 = (t0 + 4936);
    xsi_vlogvar_wait_assign_value(t32, t31, 0, 0, 32, 0LL);
    goto LAB13;

LAB16:    t16 = (t34 + 4);
    *((unsigned int *)t34) = 1;
    *((unsigned int *)t16) = 1;
    goto LAB17;

LAB18:    *((unsigned int *)t35) = 1;
    goto LAB21;

LAB20:    t31 = (t35 + 4);
    *((unsigned int *)t35) = 1;
    *((unsigned int *)t31) = 1;
    goto LAB21;

LAB22:    t38 = (t0 + 4616);
    t39 = (t38 + 56U);
    t40 = *((char **)t39);
    memset(t41, 0, 8);
    t42 = (t40 + 4);
    t43 = *((unsigned int *)t42);
    t44 = (~(t43));
    t45 = *((unsigned int *)t40);
    t46 = (t45 & t44);
    t47 = (t46 & 1U);
    if (t47 != 0)
        goto LAB25;

LAB26:    if (*((unsigned int *)t42) != 0)
        goto LAB27;

LAB28:    t50 = *((unsigned int *)t35);
    t51 = *((unsigned int *)t41);
    t52 = (t50 & t51);
    *((unsigned int *)t49) = t52;
    t53 = (t35 + 4);
    t54 = (t41 + 4);
    t55 = (t49 + 4);
    t56 = *((unsigned int *)t53);
    t57 = *((unsigned int *)t54);
    t58 = (t56 | t57);
    *((unsigned int *)t55) = t58;
    t59 = *((unsigned int *)t55);
    t60 = (t59 != 0);
    if (t60 == 1)
        goto LAB29;

LAB30:
LAB31:    goto LAB24;

LAB25:    *((unsigned int *)t41) = 1;
    goto LAB28;

LAB27:    t48 = (t41 + 4);
    *((unsigned int *)t41) = 1;
    *((unsigned int *)t48) = 1;
    goto LAB28;

LAB29:    t61 = *((unsigned int *)t49);
    t62 = *((unsigned int *)t55);
    *((unsigned int *)t49) = (t61 | t62);
    t63 = (t35 + 4);
    t64 = (t41 + 4);
    t65 = *((unsigned int *)t35);
    t66 = (~(t65));
    t67 = *((unsigned int *)t63);
    t68 = (~(t67));
    t69 = *((unsigned int *)t41);
    t70 = (~(t69));
    t71 = *((unsigned int *)t64);
    t72 = (~(t71));
    t73 = (t66 & t68);
    t74 = (t70 & t72);
    t75 = (~(t73));
    t76 = (~(t74));
    t77 = *((unsigned int *)t55);
    *((unsigned int *)t55) = (t77 & t75);
    t78 = *((unsigned int *)t55);
    *((unsigned int *)t55) = (t78 & t76);
    t79 = *((unsigned int *)t49);
    *((unsigned int *)t49) = (t79 & t75);
    t80 = *((unsigned int *)t49);
    *((unsigned int *)t49) = (t80 & t76);
    goto LAB31;

LAB32:    xsi_set_current_line(196, ng4);
    t87 = (t0 + 4936);
    t88 = (t87 + 56U);
    t89 = *((char **)t88);
    t90 = ((char*)((ng9)));
    memset(t91, 0, 8);
    xsi_vlog_unsigned_add(t91, 32, t89, 32, t90, 32);
    t92 = (t0 + 4936);
    xsi_vlogvar_wait_assign_value(t92, t91, 0, 0, 32, 0LL);
    goto LAB34;

}

static void NetDecl_204_11(char *t0)
{
    char t7[8];
    char t8[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;

LAB0:    t1 = (t0 + 12744U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(204, ng4);
    t2 = (t0 + 4776);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng10)));
    t6 = ((char*)((ng9)));
    memset(t7, 0, 8);
    xsi_vlog_unsigned_multiply(t7, 32, t5, 32, t6, 32);
    memset(t8, 0, 8);
    xsi_vlog_unsigned_minus(t8, 32, t4, 32, t7, 32);
    t9 = (t0 + 15400);
    t10 = (t9 + 56U);
    t11 = *((char **)t10);
    t12 = (t11 + 56U);
    t13 = *((char **)t12);
    memcpy(t13, t8, 8);
    xsi_driver_vfirst_trans(t9, 0, 31U);
    t14 = (t0 + 15160);
    *((int *)t14) = 1;

LAB1:    return;
}

static void Cont_205_12(char *t0)
{
    char t5[16];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;

LAB0:    t1 = (t0 + 12992U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(205, ng4);
    t2 = (t0 + 5896);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t6 = (t0 + 5896);
    t7 = (t6 + 72U);
    t8 = *((char **)t7);
    t9 = (t0 + 5896);
    t10 = (t9 + 64U);
    t11 = *((char **)t10);
    t12 = (t0 + 4776);
    t13 = (t12 + 56U);
    t14 = *((char **)t13);
    xsi_vlog_generic_get_array_select_value(t5, 34, t4, t8, t11, 2, 1, t14, 32, 2);
    t15 = (t0 + 15464);
    t16 = (t15 + 56U);
    t17 = *((char **)t16);
    t18 = (t17 + 56U);
    t19 = *((char **)t18);
    xsi_vlog_bit_copy(t19, 0, t5, 0, 34);
    xsi_driver_vfirst_trans(t15, 0, 33);
    t20 = (t0 + 15176);
    *((int *)t20) = 1;

LAB1:    return;
}

static void Cont_206_13(char *t0)
{
    char t5[16];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;

LAB0:    t1 = (t0 + 13240U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(206, ng4);
    t2 = (t0 + 6056);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t6 = (t0 + 6056);
    t7 = (t6 + 72U);
    t8 = *((char **)t7);
    t9 = (t0 + 6056);
    t10 = (t9 + 64U);
    t11 = *((char **)t10);
    t12 = (t0 + 4776);
    t13 = (t12 + 56U);
    t14 = *((char **)t13);
    xsi_vlog_generic_get_array_select_value(t5, 34, t4, t8, t11, 2, 1, t14, 32, 2);
    t15 = (t0 + 15528);
    t16 = (t15 + 56U);
    t17 = *((char **)t16);
    t18 = (t17 + 56U);
    t19 = *((char **)t18);
    xsi_vlog_bit_copy(t19, 0, t5, 0, 34);
    xsi_driver_vfirst_trans(t15, 0, 33);
    t20 = (t0 + 15192);
    *((int *)t20) = 1;

LAB1:    return;
}

static void Always_210_14(char *t0)
{
    char t9[8];
    char t10[8];
    char t22[8];
    char t23[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    char *t20;
    char *t21;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    unsigned int t32;
    int t33;
    char *t34;
    unsigned int t35;
    int t36;
    int t37;
    unsigned int t38;
    unsigned int t39;
    int t40;
    int t41;

LAB0:    t1 = (t0 + 13488U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(210, ng4);
    t2 = (t0 + 15208);
    *((int *)t2) = 1;
    t3 = (t0 + 13520);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(211, ng4);
    t4 = (t0 + 4776);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    t7 = ((char*)((ng10)));
    t8 = ((char*)((ng9)));
    memset(t9, 0, 8);
    xsi_vlog_unsigned_multiply(t9, 32, t7, 32, t8, 32);
    memset(t10, 0, 8);
    t11 = (t6 + 4);
    if (*((unsigned int *)t11) != 0)
        goto LAB6;

LAB5:    t12 = (t9 + 4);
    if (*((unsigned int *)t12) != 0)
        goto LAB6;

LAB9:    if (*((unsigned int *)t6) < *((unsigned int *)t9))
        goto LAB8;

LAB7:    *((unsigned int *)t10) = 1;

LAB8:    t14 = (t10 + 4);
    t15 = *((unsigned int *)t14);
    t16 = (~(t15));
    t17 = *((unsigned int *)t10);
    t18 = (t17 & t16);
    t19 = (t18 != 0);
    if (t19 > 0)
        goto LAB10;

LAB11:
LAB12:    goto LAB2;

LAB6:    t13 = (t10 + 4);
    *((unsigned int *)t10) = 1;
    *((unsigned int *)t13) = 1;
    goto LAB8;

LAB10:    xsi_set_current_line(211, ng4);

LAB13:    xsi_set_current_line(212, ng4);
    t20 = (t0 + 3256U);
    t21 = *((char **)t20);
    t20 = (t0 + 6216);
    t24 = (t0 + 6216);
    t25 = (t24 + 72U);
    t26 = *((char **)t25);
    t27 = (t0 + 6216);
    t28 = (t27 + 64U);
    t29 = *((char **)t28);
    t30 = (t0 + 3576U);
    t31 = *((char **)t30);
    xsi_vlog_generic_convert_array_indices(t22, t23, t26, t29, 2, 1, t31, 32, 2);
    t30 = (t22 + 4);
    t32 = *((unsigned int *)t30);
    t33 = (!(t32));
    t34 = (t23 + 4);
    t35 = *((unsigned int *)t34);
    t36 = (!(t35));
    t37 = (t33 && t36);
    if (t37 == 1)
        goto LAB14;

LAB15:    goto LAB12;

LAB14:    t38 = *((unsigned int *)t22);
    t39 = *((unsigned int *)t23);
    t40 = (t38 - t39);
    t41 = (t40 + 1);
    xsi_vlogvar_wait_assign_value(t20, t21, 0, *((unsigned int *)t23), t41, 0LL);
    goto LAB15;

}

static void Initial_221_15(char *t0)
{
    char *t1;
    char *t2;
    char *t3;

LAB0:    xsi_set_current_line(222, ng4);
    t1 = (t0 + 5736);
    t2 = (t1 + 56U);
    t3 = *((char **)t2);
    xsi_vlogfile_fwrite(*((unsigned int *)t3), 1, 0, 0, ng12, 1, t0);

LAB1:    return;
}

static void Initial_224_16(char *t0)
{
    char *t1;
    char *t2;

LAB0:    xsi_set_current_line(224, ng4);

LAB2:    xsi_set_current_line(225, ng4);
    t1 = ((char*)((ng9)));
    t2 = (t0 + 5256);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 32);
    xsi_set_current_line(226, ng4);
    t1 = ((char*)((ng7)));
    t2 = (t0 + 5416);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 32);

LAB1:    return;
}

static void NetDecl_229_17(char *t0)
{
    char t7[8];
    char t10[8];
    char t11[8];
    char t12[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t8;
    char *t9;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    unsigned int t21;
    unsigned int t22;
    char *t23;
    unsigned int t24;
    unsigned int t25;
    char *t26;
    unsigned int t27;
    unsigned int t28;
    char *t29;

LAB0:    t1 = (t0 + 14232U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(229, ng4);
    t2 = (t0 + 4776);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng8)));
    t6 = ((char*)((ng9)));
    memset(t7, 0, 8);
    xsi_vlog_unsigned_minus(t7, 32, t5, 32, t6, 32);
    t8 = ((char*)((ng10)));
    t9 = ((char*)((ng9)));
    memset(t10, 0, 8);
    xsi_vlog_unsigned_multiply(t10, 32, t8, 32, t9, 32);
    memset(t11, 0, 8);
    xsi_vlog_unsigned_add(t11, 32, t7, 32, t10, 32);
    memset(t12, 0, 8);
    t13 = (t4 + 4);
    if (*((unsigned int *)t13) != 0)
        goto LAB5;

LAB4:    t14 = (t11 + 4);
    if (*((unsigned int *)t14) != 0)
        goto LAB5;

LAB8:    if (*((unsigned int *)t4) < *((unsigned int *)t11))
        goto LAB7;

LAB6:    *((unsigned int *)t12) = 1;

LAB7:    t16 = (t0 + 15592);
    t17 = (t16 + 56U);
    t18 = *((char **)t17);
    t19 = (t18 + 56U);
    t20 = *((char **)t19);
    memset(t20, 0, 8);
    t21 = 1U;
    t22 = t21;
    t23 = (t12 + 4);
    t24 = *((unsigned int *)t12);
    t21 = (t21 & t24);
    t25 = *((unsigned int *)t23);
    t22 = (t22 & t25);
    t26 = (t20 + 4);
    t27 = *((unsigned int *)t20);
    *((unsigned int *)t20) = (t27 | t21);
    t28 = *((unsigned int *)t26);
    *((unsigned int *)t26) = (t28 | t22);
    xsi_driver_vfirst_trans(t16, 0, 0U);
    t29 = (t0 + 15224);
    *((int *)t29) = 1;

LAB1:    return;
LAB5:    t15 = (t12 + 4);
    *((unsigned int *)t12) = 1;
    *((unsigned int *)t15) = 1;
    goto LAB7;

}

static void Always_231_18(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;

LAB0:    t1 = (t0 + 14480U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(231, ng4);
    t2 = (t0 + 15240);
    *((int *)t2) = 1;
    t3 = (t0 + 14512);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(232, ng4);
    t4 = (t0 + 3736U);
    t5 = *((char **)t4);
    t4 = (t0 + 6856);
    xsi_vlogvar_wait_assign_value(t4, t5, 0, 0, 1, 0LL);
    goto LAB2;

}

static void Always_235_19(char *t0)
{
    char t15[8];
    char t16[16];
    char t20[16];
    char t21[16];
    char t28[8];
    char t58[8];
    char t62[8];
    char t92[8];
    char t96[8];
    char t126[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    char *t13;
    char *t14;
    char *t17;
    char *t18;
    char *t19;
    char *t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t29;
    char *t30;
    char *t31;
    char *t32;
    char *t33;
    char *t34;
    char *t35;
    char *t36;
    char *t37;
    char *t38;
    char *t39;
    char *t40;
    char *t41;
    char *t42;
    char *t43;
    char *t44;
    char *t45;
    char *t46;
    char *t47;
    char *t48;
    char *t49;
    int t50;
    char *t51;
    char *t52;
    char *t53;
    double t54;
    char *t55;
    char *t56;
    char *t57;
    char *t59;
    char *t60;
    char *t61;
    char *t63;
    char *t64;
    char *t65;
    char *t66;
    char *t67;
    char *t68;
    char *t69;
    char *t70;
    char *t71;
    char *t72;
    char *t73;
    char *t74;
    char *t75;
    char *t76;
    char *t77;
    char *t78;
    char *t79;
    char *t80;
    char *t81;
    char *t82;
    char *t83;
    int t84;
    char *t85;
    char *t86;
    char *t87;
    double t88;
    char *t89;
    char *t90;
    char *t91;
    char *t93;
    char *t94;
    char *t95;
    char *t97;
    char *t98;
    char *t99;
    char *t100;
    char *t101;
    char *t102;
    char *t103;
    char *t104;
    char *t105;
    char *t106;
    char *t107;
    char *t108;
    char *t109;
    char *t110;
    char *t111;
    char *t112;
    char *t113;
    char *t114;
    char *t115;
    char *t116;
    char *t117;
    int t118;
    char *t119;
    char *t120;
    char *t121;
    double t122;
    char *t123;
    char *t124;
    char *t125;

LAB0:    t1 = (t0 + 14728U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(235, ng4);
    t2 = (t0 + 15256);
    *((int *)t2) = 1;
    t3 = (t0 + 14760);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(235, ng4);

LAB5:    xsi_set_current_line(237, ng4);
    t4 = (t0 + 6856);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    t7 = (t6 + 4);
    t8 = *((unsigned int *)t7);
    t9 = (~(t8));
    t10 = *((unsigned int *)t6);
    t11 = (t10 & t9);
    t12 = (t11 != 0);
    if (t12 > 0)
        goto LAB6;

LAB7:
LAB8:    goto LAB2;

LAB6:    xsi_set_current_line(237, ng4);

LAB9:    xsi_set_current_line(239, ng4);
    xsi_set_current_line(239, ng4);
    t13 = ((char*)((ng7)));
    t14 = (t0 + 7016);
    xsi_vlogvar_assign_value(t14, t13, 0, 0, 32);

LAB10:    t2 = (t0 + 7016);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng8)));
    memset(t15, 0, 8);
    xsi_vlog_signed_less(t15, 32, t4, 32, t5, 32);
    t6 = (t15 + 4);
    t8 = *((unsigned int *)t6);
    t9 = (~(t8));
    t10 = *((unsigned int *)t15);
    t11 = (t10 & t9);
    t12 = (t11 != 0);
    if (t12 > 0)
        goto LAB11;

LAB12:    xsi_set_current_line(263, ng4);
    t2 = (t0 + 5256);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t8 = *((unsigned int *)t5);
    t9 = (~(t8));
    t10 = *((unsigned int *)t4);
    t11 = (t10 & t9);
    t12 = (t11 != 0);
    if (t12 > 0)
        goto LAB23;

LAB24:    xsi_set_current_line(266, ng4);
    xsi_vlogfile_write(1, 0, 0, ng18, 1, t0);

LAB25:    xsi_set_current_line(268, ng4);
    t2 = (t0 + 5576);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    xsi_vlogfile_fclose(*((unsigned int *)t4));
    xsi_set_current_line(269, ng4);
    t2 = (t0 + 5736);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    xsi_vlogfile_fclose(*((unsigned int *)t4));
    xsi_set_current_line(270, ng4);
    xsi_vlog_stop(1);
    goto LAB8;

LAB11:    xsi_set_current_line(239, ng4);

LAB13:    xsi_set_current_line(240, ng4);
    t7 = (t0 + 5736);
    t13 = (t7 + 56U);
    t14 = *((char **)t13);
    t17 = xsi_vlog_time(t16, 1000.0000000000000, 1000.0000000000000);
    t18 = ((char*)((ng14)));
    t19 = ((char*)((ng15)));
    xsi_vlog_unsigned_multiply(t20, 64, t18, 32, t19, 32);
    xsi_vlog_unsigned_divide(t21, 64, t16, 64, t20, 64);
    xsi_vlogfile_fwrite(*((unsigned int *)t14), 0, 0, 0, ng13, 2, t0, (char)118, t21, 64);
    t22 = (t0 + 7016);
    t23 = (t22 + 56U);
    t24 = *((char **)t23);
    t25 = (t0 + 6056);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    t29 = (t0 + 6056);
    t30 = (t29 + 72U);
    t31 = *((char **)t30);
    t32 = (t0 + 6056);
    t33 = (t32 + 64U);
    t34 = *((char **)t33);
    t35 = (t0 + 7016);
    t36 = (t35 + 56U);
    t37 = *((char **)t36);
    xsi_vlog_generic_get_array_select_value(t28, 32, t27, t31, t34, 2, 1, t37, 32, 1);
    t38 = (t0 + 14536);
    t39 = (t0 + 2144);
    t40 = xsi_create_subprogram_invocation(t38, 0, t0, t39, 0, 0);
    t41 = (t0 + 8936);
    xsi_vlogvar_assign_value(t41, t28, 0, 0, 32);

LAB14:    t42 = (t0 + 14632);
    t43 = *((char **)t42);
    t44 = (t43 + 80U);
    t45 = *((char **)t44);
    t46 = (t45 + 272U);
    t47 = *((char **)t46);
    t48 = (t47 + 0U);
    t49 = *((char **)t48);
    t50 = ((int  (*)(char *, char *))t49)(t0, t43);
    if (t50 != 0)
        goto LAB16;

LAB15:    t43 = (t0 + 14632);
    t51 = *((char **)t43);
    t43 = (t0 + 8776);
    t52 = (t43 + 56U);
    t53 = *((char **)t52);
    t54 = *((double *)t53);
    t55 = (t0 + 2144);
    t56 = (t0 + 14536);
    t57 = 0;
    xsi_delete_subprogram_invocation(t55, t51, t0, t56, t57);
    *((double *)t58) = t54;
    t59 = (t0 + 5896);
    t60 = (t59 + 56U);
    t61 = *((char **)t60);
    t63 = (t0 + 5896);
    t64 = (t63 + 72U);
    t65 = *((char **)t64);
    t66 = (t0 + 5896);
    t67 = (t66 + 64U);
    t68 = *((char **)t67);
    t69 = (t0 + 7016);
    t70 = (t69 + 56U);
    t71 = *((char **)t70);
    xsi_vlog_generic_get_array_select_value(t62, 32, t61, t65, t68, 2, 1, t71, 32, 1);
    t72 = (t0 + 14536);
    t73 = (t0 + 2144);
    t74 = xsi_create_subprogram_invocation(t72, 0, t0, t73, 0, 0);
    t75 = (t0 + 8936);
    xsi_vlogvar_assign_value(t75, t62, 0, 0, 32);

LAB17:    t76 = (t0 + 14632);
    t77 = *((char **)t76);
    t78 = (t77 + 80U);
    t79 = *((char **)t78);
    t80 = (t79 + 272U);
    t81 = *((char **)t80);
    t82 = (t81 + 0U);
    t83 = *((char **)t82);
    t84 = ((int  (*)(char *, char *))t83)(t0, t77);
    if (t84 != 0)
        goto LAB19;

LAB18:    t77 = (t0 + 14632);
    t85 = *((char **)t77);
    t77 = (t0 + 8776);
    t86 = (t77 + 56U);
    t87 = *((char **)t86);
    t88 = *((double *)t87);
    t89 = (t0 + 2144);
    t90 = (t0 + 14536);
    t91 = 0;
    xsi_delete_subprogram_invocation(t89, t85, t0, t90, t91);
    *((double *)t92) = t88;
    t93 = (t0 + 6216);
    t94 = (t93 + 56U);
    t95 = *((char **)t94);
    t97 = (t0 + 6216);
    t98 = (t97 + 72U);
    t99 = *((char **)t98);
    t100 = (t0 + 6216);
    t101 = (t100 + 64U);
    t102 = *((char **)t101);
    t103 = (t0 + 7016);
    t104 = (t103 + 56U);
    t105 = *((char **)t104);
    xsi_vlog_generic_get_array_select_value(t96, 32, t95, t99, t102, 2, 1, t105, 32, 1);
    t106 = (t0 + 14536);
    t107 = (t0 + 2144);
    t108 = xsi_create_subprogram_invocation(t106, 0, t0, t107, 0, 0);
    t109 = (t0 + 8936);
    xsi_vlogvar_assign_value(t109, t96, 0, 0, 32);

LAB20:    t110 = (t0 + 14632);
    t111 = *((char **)t110);
    t112 = (t111 + 80U);
    t113 = *((char **)t112);
    t114 = (t113 + 272U);
    t115 = *((char **)t114);
    t116 = (t115 + 0U);
    t117 = *((char **)t116);
    t118 = ((int  (*)(char *, char *))t117)(t0, t111);
    if (t118 != 0)
        goto LAB22;

LAB21:    t111 = (t0 + 14632);
    t119 = *((char **)t111);
    t111 = (t0 + 8776);
    t120 = (t111 + 56U);
    t121 = *((char **)t120);
    t122 = *((double *)t121);
    t123 = (t0 + 2144);
    t124 = (t0 + 14536);
    t125 = 0;
    xsi_delete_subprogram_invocation(t123, t119, t0, t124, t125);
    *((double *)t126) = t122;
    xsi_vlogfile_fwrite(*((unsigned int *)t14), 1, 0, 0, ng16, 5, t0, (char)119, t24, 32, (char)114, t58, 64, (char)114, t92, 64, (char)114, t126, 64);
    xsi_set_current_line(239, ng4);
    t2 = (t0 + 7016);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng9)));
    memset(t15, 0, 8);
    xsi_vlog_signed_add(t15, 32, t4, 32, t5, 32);
    t6 = (t0 + 7016);
    xsi_vlogvar_assign_value(t6, t15, 0, 0, 32);
    goto LAB10;

LAB16:    t42 = (t0 + 14728U);
    *((char **)t42) = &&LAB14;
    goto LAB1;

LAB19:    t76 = (t0 + 14728U);
    *((char **)t76) = &&LAB17;
    goto LAB1;

LAB22:    t110 = (t0 + 14728U);
    *((char **)t110) = &&LAB20;
    goto LAB1;

LAB23:    xsi_set_current_line(264, ng4);
    xsi_vlogfile_write(1, 0, 0, ng17, 1, t0);
    goto LAB25;

}


extern void work_m_00000000003233607263_1949178628_init()
{
	static char *pe[] = {(void *)Initial_55_0,(void *)Initial_73_1,(void *)Initial_82_2,(void *)NetDecl_96_3,(void *)Initial_129_4,(void *)Always_132_5,(void *)Initial_135_6,(void *)Always_151_7,(void *)Always_162_8,(void *)Always_180_9,(void *)Always_192_10,(void *)NetDecl_204_11,(void *)Cont_205_12,(void *)Cont_206_13,(void *)Always_210_14,(void *)Initial_221_15,(void *)Initial_224_16,(void *)NetDecl_229_17,(void *)Always_231_18,(void *)Always_235_19};
	static char *se[] = {(void *)sp_doubletosingle,(void *)sp_singletodouble,(void *)sp_realtobitsSingle,(void *)sp_bitstorealSingle};
	xsi_register_didat("work_m_00000000003233607263_1949178628", "isim/testbench_isim_beh.exe.sim/work/m_00000000003233607263_1949178628.didat");
	xsi_register_executes(pe);
	xsi_register_subprogram_executes(se);
}
