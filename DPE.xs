
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

/* #define PERL_NO_GET_CONTEXT 1 */


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef OLDPERL
#define SvUOK SvIsUV
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif

/* #define DPE_USE_DOUBLE	*/
/* #define DPE_USE_LONG		*/

#ifdef WANT_GMP
#include <gmp.h>
#endif
#include "dpe.h"

DPE_DOUBLE _get_inf(int sign) {
    DPE_DOUBLE ret;
    ret = (DPE_DOUBLE)1.0 / (DPE_DOUBLE)0.0;
    if(sign < 0) ret *= (DPE_DOUBLE)-1.0;
    return ret;
}

DPE_DOUBLE _get_nan(void) {
     DPE_DOUBLE infinitude = _get_inf(1);
     return infinitude / infinitude;
}

int _is_nan(DPE_DOUBLE x) {
    if(x != x) return 1;
    return 0;
}

int  _is_inf(DPE_DOUBLE x) {
     if(x != x) return 0; /* NaN  */
     if(x == (DPE_DOUBLE)0.0) return 0; /* Zero */
     if(x/x != x/x) {
       if(x < (DPE_DOUBLE)0.0) return -1;
       else return 1;
     }
     return 0; /* Finite Real */
}

SV * XS_dpe_init(void) {
     dpe_t * dpe_t_obj;
     SV * obj_ref, * obj;

     Newx(dpe_t_obj, 1, dpe_t);
     if(dpe_t_obj == NULL) croak("Failed to allocate memory in XS_dpe_init function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::DPE");
     dpe_init(*dpe_t_obj);
     dpe_set_d(*dpe_t_obj, _get_nan());

     sv_setiv(obj, INT2PTR(IV, dpe_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

int XS_dpe_nan_p(dpe_t * op) {
    return _is_nan(DPE_MANT(*op));
}

int XS_dpe_inf_p(dpe_t * op) {
    return _is_inf(DPE_MANT(*op));
}

void dpe_set_float128(dpe_t * rop, SV * sv ) {
     DPE_MANT(*rop) = (DPE_DOUBLE)SvNV(sv);
     DPE_EXP(*rop) = 0;
     dpe_normalize (*rop);
}

void XS_dpe_set(dpe_t * rop, dpe_t * op) {
     dpe_set(*rop, *op);
}

void dpe_set_NV(dpe_t * rop, SV * sv) {
     DPE_MANT(*rop) = (DPE_DOUBLE)SvNV(sv);
     DPE_EXP(*rop) = 0;
     dpe_normalize (*rop);
}

void dpe_set_UV(dpe_t * rop, SV * sv) {
     DPE_MANT(*rop) = (DPE_DOUBLE)SvUV(sv);
     DPE_EXP(*rop) = 0;
     dpe_normalize (*rop);
}

void dpe_set_IV(dpe_t * rop, SV * sv) {
     DPE_MANT(*rop) = (DPE_DOUBLE)SvIV(sv);
     DPE_EXP(*rop) = 0;
     dpe_normalize (*rop);
}

void XS_dpe_neg(dpe_t * rop, dpe_t * op) {
     dpe_neg(*rop, *op);
}

void XS_dpe_abs(dpe_t * rop, dpe_t * op) {
     dpe_abs(*rop, *op);
}

void XS_dpe_normalize(dpe_t * op) {
     dpe_normalize(*op);
}

DPE_DOUBLE XS_dpe_scale(DPE_DOUBLE d, int s) {
    return dpe_scale(d, s);
}

void XS_dpe_set_ui(dpe_t * rop, unsigned long ul) {
     dpe_set_ui(*rop , ul);
}

void XS_dpe_set_si(dpe_t * rop, unsigned long ul) {
     dpe_set_si(*rop , ul);
}

void XS_dpe_set_d(dpe_t * rop, SV * d) {
     dpe_set_d(*rop , (double)SvNV(d));
}

void XS_dpe_set_ld(dpe_t * rop, SV * d) {
     dpe_set_ld(*rop , (long double)SvNV(d));
}

long XS_dpe_get_si(dpe_t * op) {
     return dpe_get_si(*op);
}

unsigned long XS_dpe_get_ui(dpe_t * op) {
     return dpe_get_ui(*op);
}

double XS_dpe_get_d(dpe_t * op) {
     return  dpe_get_d(*op);
}

SV * XS_dpe_get_ld(dpe_t * op) {
     return newSVnv(dpe_get_ld(*op));
}

void XS_dpe_set_z(dpe_t * rop, SV * z) { /* z is a Math::GMP or Math::GMPz object */
#ifdef __GMP_H__
     if(sv_isobject(z)) {
       const char* h = HvNAME(SvSTASH(SvRV(z)));
       if(strEQ(h, "Math::GMP") || strEQ(h, "Math::GMPz")) {
         dpe_set_z(*rop, *(INT2PTR(mpz_t *, SvIV(SvRV(z)))));
       }
       else {
         croak("Invalid object (neither Math::GMP nor Math::GMPz) provided to dpe_set_z");
       }
     }
     else {
       croak("Invalid argument (not an object) provided to dpe_set_z");
     }
#else
     croak("dpe_set_z not implemented - rebuild with -DWANT_GMP");
#endif
}

void XS_dpe_get_z(SV * z, dpe_t * rop) { /* z is a Math::GMP or Math::GMPz object */
#ifdef __GMP_H__
     if(sv_isobject(z)) {
       const char* h = HvNAME(SvSTASH(SvRV(z)));
       if(strEQ(h, "Math::GMP") || strEQ(h, "Math::GMPz")) {
         dpe_get_z(*(INT2PTR(mpz_t *, SvIV(SvRV(z)))), *rop);
       }
       else {
         croak("Invalid object (neither Math::GMP nor Math::GMPz) provided to dpe_get_z");
       }
     }
     else {
       croak("Invalid argument (not an object) provided to dpe_get_z");
     }
#else
     croak("dpe_get_z not implemented - rebuild with -DWANT_GMP");
#endif
}

SV * XS_dpe_get_z_exp(SV * z, dpe_t * rop) { /* z is a Math::GMP or Math::GMPz object */
#ifdef __GMP_H__
     if(sv_isobject(z)) {
       const char* h = HvNAME(SvSTASH(SvRV(z)));
       if(strEQ(h, "Math::GMP") || strEQ(h, "Math::GMPz")) {
         return newSViv((mp_exp_t)dpe_get_z_exp(*(INT2PTR(mpz_t *, SvIV(SvRV(z)))), *rop));
       }
       croak("Invalid object (neither Math::GMP nor Math::GMPz) provided to dpe_get_z_exp");
     }
     croak("Invalid argument (not an object) provided to dpe_get_z_exp");
#else
     croak("dpe_get_z_exp not implemented - rebuild with -DWANT_GMP");
#endif
}

void XS_dpe_add(dpe_t * rop, dpe_t *op1, dpe_t * op2) {
     dpe_add(*rop, *op1, *op2);
}

void XS_dpe_sub(dpe_t * rop, dpe_t *op1, dpe_t * op2) {
     dpe_sub(*rop, *op1, *op2);
}

void XS_dpe_mul(dpe_t * rop, dpe_t *op1, dpe_t * op2) {
     dpe_mul(*rop, *op1, *op2);
}

void XS_dpe_div(dpe_t * rop, dpe_t *op1, dpe_t * op2) {
     dpe_div(*rop, *op1, *op2);
}

void XS_dpe_sqrt(dpe_t * rop, dpe_t * op) {
     dpe_sqrt(*rop, *op);
}

void XS_dpe_mul_ui(dpe_t * rop, dpe_t *op1, unsigned long op2) {
     dpe_mul_ui(*rop, *op1, op2);
}

void XS_dpe_mul_2exp(dpe_t * rop, dpe_t *op1, unsigned long op2) {
     dpe_mul_2exp(*rop, *op1, op2);
}

void XS_dpe_div_2exp(dpe_t * rop, dpe_t *op1, unsigned long op2) {
     dpe_div_2exp(*rop, *op1, op2);
}

void XS_dpe_div_ui(dpe_t * rop, dpe_t *op1, unsigned long op2) {
     dpe_div_ui(*rop, *op1, op2);
}

SV * XS_dpe_get_si_exp (SV * x, dpe_t * op) {
     long mant;
     DPE_EXP_T exponent;

     exponent = dpe_get_si_exp(&mant, * op);
     sv_setiv(x, (IV)mant);
     return newSViv(exponent);
}

int XS_dpe_out_str(FILE * stream, dpe_t * op) {
     int ret;
     ret = dpe_out_str(stream, 10, *op);
     fflush(stream);
     return ret;
}

int _dpe_out_str_perlio(PerlIO * stream, dpe_t * op) {
     int ret;
     FILE * stdio_stream = PerlIO_exportFILE(stream, NULL);
     ret = dpe_out_str(stdio_stream, 10, *op);
     fflush(stdio_stream);
     PerlIO_releaseFILE(stream, stdio_stream);
     return ret;
}

SV * XS_dpe_inp_str(dpe_t * rop, FILE * stream) {
     size_t ret;
     ret = dpe_inp_str(*rop, stream, 10);
     return newSVuv(ret);
}

void XS_dpe_dump (dpe_t * op) {
     dpe_dump(*op);
}

int XS_dpe_zero_p(dpe_t * op) {
    return dpe_zero_p(*op);
}

int XS_dpe_cmp(dpe_t * op1, dpe_t * op2) {
    return dpe_cmp(*op1, *op2);
}

int XS_dpe_cmp_d(dpe_t * op, double d) {
    return dpe_cmp_d(*op, d);
}

int XS_dpe_cmp_ui(dpe_t * op, unsigned long d) {
    return dpe_cmp_ui(*op, d);
}

int XS_dpe_cmp_si(dpe_t * op, long d) {
    return dpe_cmp_si(*op, d);
}

void XS_dpe_round(dpe_t * rop, dpe_t * op) {
     dpe_round(*rop, *op);
}

void XS_dpe_frac(dpe_t * rop, dpe_t * op) {
     dpe_frac(*rop, *op);
}

void XS_dpe_floor(dpe_t * rop, dpe_t * op) {
     dpe_floor(*rop, *op);
}

void XS_dpe_ceil(dpe_t * rop, dpe_t * op) {
     dpe_ceil(*rop, *op);
}

void XS_dpe_swap(dpe_t * rop, dpe_t * op) {
     dpe_swap(*rop, *op);
}

void DESTROY(dpe_t * p) {
     dpe_clear(*p);
     Safefree(p);
}

int _with_gmp_support(void) {
#ifdef __GMP_H__
     return 1;
#else
     return 0;
#endif
}

/* *(INT2PTR(dpe_t *, SvIV(SvRV(a))))					*/
/* #define DPE_MANT(x) ((x)->d)						*/
/* #define DPE_EXP(x)  ((x)->exp)					*/
/* #define DPE_SIGN(x) ((DPE_MANT(x) < 0.0) ? -1 : (DPE_MANT(x) > 0.0))	*/

SV * _overload_add(SV * a, SV * b, SV * third) {
     dpe_t * dpe_t_obj;
     SV * obj_ref, * obj;

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded addition handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded addition handles only Math::DPE objects");

     Newx(dpe_t_obj, 1, dpe_t);
     if(dpe_t_obj == NULL) croak("Failed to allocate memory in _overload_add function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::DPE");
     dpe_init(*dpe_t_obj);

     sv_setiv(obj, INT2PTR(IV, dpe_t_obj));
     SvREADONLY_on(obj);

     dpe_add(*dpe_t_obj, *(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b)))));
     return obj_ref;
}

SV * _overload_mul(SV * a, SV * b, SV * third) {
     dpe_t * dpe_t_obj;
     SV * obj_ref, * obj;

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded multiplication handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded multiplication handles only Math::DPE objects");

     Newx(dpe_t_obj, 1, dpe_t);
     if(dpe_t_obj == NULL) croak("Failed to allocate memory in _overload_mul function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::DPE");
     dpe_init(*dpe_t_obj);

     sv_setiv(obj, INT2PTR(IV, dpe_t_obj));
     SvREADONLY_on(obj);

     dpe_mul(*dpe_t_obj, *(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b)))));
     return obj_ref;
}

SV * _overload_div(SV * a, SV * b, SV * third) {
     dpe_t * dpe_t_obj;
     SV * obj_ref, * obj;

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded division handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded division handles only Math::DPE objects");

     Newx(dpe_t_obj, 1, dpe_t);
     if(dpe_t_obj == NULL) croak("Failed to allocate memory in _overload_div function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::DPE");
     dpe_init(*dpe_t_obj);

     sv_setiv(obj, INT2PTR(IV, dpe_t_obj));
     SvREADONLY_on(obj);

     dpe_div(*dpe_t_obj, *(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b)))));
     return obj_ref;
}

SV * _overload_sub(SV * a, SV * b, SV * third) {
     dpe_t * dpe_t_obj;
     SV * obj_ref, * obj;

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded subtraction handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded subtraction handles only Math::DPE objects");

     Newx(dpe_t_obj, 1, dpe_t);
     if(dpe_t_obj == NULL) croak("Failed to allocate memory in _overload_sub function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::DPE");
     dpe_init(*dpe_t_obj);

     sv_setiv(obj, INT2PTR(IV, dpe_t_obj));
     SvREADONLY_on(obj);

     dpe_sub(*dpe_t_obj, *(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b)))));
     return obj_ref;
}

int _overload_equiv(SV * a, SV * b, SV * third) {

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded '==' handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded '==' handles only Math::DPE objects");

     if(_is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))))) ||
        _is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(b))))))) return 0;

     if(!dpe_cmp(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b)))))) return 1;
     return 0;
}

int _overload_not_equiv(SV * a, SV * b, SV * third) {

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded '!=' handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded '!=' handles only Math::DPE objects");

     if(_is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))))) ||
        _is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(b))))))) return 1;

     if(dpe_cmp(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b)))))) return 1;
     return 0;
}

int _overload_gt(SV * a, SV * b, SV * third) {

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded '>' handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded '>' handles only Math::DPE objects");

     if(_is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))))) ||
        _is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(b))))))) return 0;

     if(dpe_cmp(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b))))) > 0) return 1;
     return 0;
}

int _overload_gte(SV * a, SV * b, SV * third) {

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded '>=' handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded '>=' handles only Math::DPE objects");

     if(_is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))))) ||
        _is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(b))))))) return 0;

     if(dpe_cmp(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b))))) >= 0) return 1;
     return 0;
}

int _overload_lt(SV * a, SV * b, SV * third) {

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded '<' handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded '<' handles only Math::DPE objects");

     if(_is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))))) ||
        _is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(b))))))) return 0;

     if(dpe_cmp(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b))))) < 0) return 1;
     return 0;
}

int _overload_lte(SV * a, SV * b, SV * third) {

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded '<=' handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded '<=' handles only Math::DPE objects");

     if(_is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))))) ||
        _is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(b))))))) return 0;

     if(dpe_cmp(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b))))) <= 0) return 1;
     return 0;
}

SV * _overload_spaceship(SV * a, SV * b, SV * third) {
     int ret;

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));
       if(!strEQ(h, "Math::DPE")) croak("overloaded '<=>' handles only Math::DPE objects, not %s objects", h);
     }
     else croak("overloaded '<=>' handles only Math::DPE objects");

     if(_is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))))) ||
        _is_nan(DPE_MANT(*(INT2PTR(dpe_t *, SvIV(SvRV(b))))))) return &PL_sv_undef;

     ret = dpe_cmp(*(INT2PTR(dpe_t *, SvIV(SvRV(a)))), *(INT2PTR(dpe_t *, SvIV(SvRV(b)))));
     if(third == &PL_sv_yes) ret *= -1;
     if(ret < 0) return newSViv(-1);
     if(ret > 0) return newSViv(1);
     return newSViv(0);
}

SV * _overload_sqrt(dpe_t * a, SV * b, SV * third) {
     dpe_t * dpe_t_obj;
     SV * obj_ref, * obj;

     Newx(dpe_t_obj, 1, dpe_t);
     if(dpe_t_obj == NULL) croak("Failed to allocate memory in _overload_sqrt function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::DPE");
     dpe_init(*dpe_t_obj);

     sv_setiv(obj, INT2PTR(IV, dpe_t_obj));
     SvREADONLY_on(obj);

     dpe_sqrt(*dpe_t_obj, *a);
     return obj_ref;
}
void dpe_get_str (dpe_t * op) {
     dXSARGS;
     char * buffer;
     DPE_DOUBLE d = DPE_MANT(*op);
     DPE_EXP_T e2 = DPE_EXP(*op);
     int e10 = 0;
     char sign = ' ';

     Newx(buffer, 96, char);
     if(buffer == NULL) croak("Failed to allocate memory in dpe_get_str");

     EXTEND(SP, 1);

     if(d == 0.0) {
#ifdef DPE_USE_DOUBLE
       sprintf (buffer, "%1.*f", dpe_str_prec, d);
       ST(0) = sv_2mortal(newSVpv(buffer, 0));
       Safefree(buffer);
       XSRETURN(1);
     }
#else
       sprintf (buffer, "%1.*Lf", dpe_str_prec, (long double) d);
       ST(0) = sv_2mortal(newSVpv(buffer, 0));
       Safefree(buffer);
       XSRETURN(1);
     }
#endif
     if(d < 0) {
       d = -d;
       sign = '-';
     }
     if(e2 > 0) {
       while (e2 > 0) {
         e2 --;
         d *= 2.0;
         if(d >= 10.0) {
           d /= 10.0;
           e10 ++;
         }
       }
     }
     else { /* e2 <= 0 */
       while(e2 < 0) {
         e2 ++;
         d /= 2.0;
         if(d < 1.0) {
           d *= 10.0;
           e10 --;
         }
       }
     }
#ifdef DPE_USE_DOUBLE
     sprintf (buffer, "%c%1.*f*10^%d", sign, dpe_str_prec, d, e10);
     ST(0) = sv_2mortal(newSVpv(buffer, 0));
     Safefree(buffer);
     XSRETURN(1);
#else
     sprintf (buffer, "%c%1.*Lf*10^%d", sign, dpe_str_prec, (long double) d, e10);
     ST(0) = sv_2mortal(newSVpv(buffer, 0));
     Safefree(buffer);
     XSRETURN(1);
#endif
}

SV * _itsa(SV * a) {
     if(SvUOK(a)) return newSVuv(1);
     if(SvIOK(a)) return newSVuv(2);
     if(SvNOK(a)) return newSVuv(3);
     if(SvPOK(a)) return newSVuv(4);
     if(sv_isobject(a)) {
       const char* h = HvNAME(SvSTASH(SvRV(a)));

       if(strEQ(h, "Math::MPFR")) return newSVuv(5);
       if(strEQ(h, "Math::GMPf")) return newSVuv(6);
       if(strEQ(h, "Math::GMPq")) return newSVuv(7);
       if(strEQ(h, "Math::GMPz")) return newSVuv(8);
       if(strEQ(h, "Math::GMP")) return newSVuv(9);        }
     return newSVuv(0);
}

SV * XS_DPE_MANT(dpe_t * x) {
     return newSVnv(DPE_MANT(*x));
}

SV * XS_DPE_EXP(dpe_t *x) {
     return newSViv(DPE_EXP(*x));
}

int  XS_DPE_SIGN(dpe_t * x) {
     return DPE_SIGN(*x);
}

int XS_dpe_str_prec(void) {
     return dpe_str_prec;
}

int _defined_LONGDOUBLE_IS_DOUBLEDOUBLE(void) {
#ifdef LONGDOUBLE_IS_DOUBLEDOUBLE
     return 1;
#else
     return 0;
#endif
}

int _defined_DPE_USE_DOUBLE(void) {
#ifdef DPE_USE_DOUBLE
     return 1;
#else
     return 0;
#endif
}

int _defined_DPE_USE_LONGDOUBLE(void) {
#ifdef DPE_USE_LONGDOUBLE
     return 1;
#else
     return 0;
#endif
}

int _defined_DPE_USE_FLOAT128(void) {
#ifdef DPE_USE_FLOAT128
     return 1;
#else
     return 0;
#endif
}

int _defined_DPE_USE_LONG(void) {
#ifdef DPE_USE_LONG
     return 1;
#else
     return 0;
#endif
}

int _defined_DPE_USE_LONGLONG(void) {
#ifdef DPE_USE_LONGLONG
     return 1;
#else
     return 0;
#endif
}
MODULE = Math::DPE  PACKAGE = Math::DPE  PREFIX = XS_

PROTOTYPES: DISABLE


SV *
XS_dpe_init ()


int
XS_dpe_nan_p (op)
	dpe_t *	op

int
XS_dpe_inf_p (op)
	dpe_t *	op

void
dpe_set_float128 (rop, sv)
	dpe_t *	rop
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dpe_set_float128(rop, sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_set (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_set(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
dpe_set_NV (rop, sv)
	dpe_t *	rop
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dpe_set_NV(rop, sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
dpe_set_UV (rop, sv)
	dpe_t *	rop
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dpe_set_UV(rop, sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
dpe_set_IV (rop, sv)
	dpe_t *	rop
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dpe_set_IV(rop, sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_neg (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_neg(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_abs (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_abs(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_normalize (op)
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_normalize(op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_set_ui (rop, ul)
	dpe_t *	rop
	unsigned long	ul
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_set_ui(rop, ul);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_set_si (rop, ul)
	dpe_t *	rop
	unsigned long	ul
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_set_si(rop, ul);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_set_d (rop, d)
	dpe_t *	rop
	SV *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_set_d(rop, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_set_ld (rop, d)
	dpe_t *	rop
	SV *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_set_ld(rop, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

long
XS_dpe_get_si (op)
	dpe_t *	op

unsigned long
XS_dpe_get_ui (op)
	dpe_t *	op

double
XS_dpe_get_d (op)
	dpe_t *	op

SV *
XS_dpe_get_ld (op)
	dpe_t *	op

void
XS_dpe_set_z (rop, z)
	dpe_t *	rop
	SV *	z
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_set_z(rop, z);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_get_z (z, rop)
	SV *	z
	dpe_t *	rop
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_get_z(z, rop);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
XS_dpe_get_z_exp (z, rop)
	SV *	z
	dpe_t *	rop

void
XS_dpe_add (rop, op1, op2)
	dpe_t *	rop
	dpe_t *	op1
	dpe_t *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_add(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_sub (rop, op1, op2)
	dpe_t *	rop
	dpe_t *	op1
	dpe_t *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_sub(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_mul (rop, op1, op2)
	dpe_t *	rop
	dpe_t *	op1
	dpe_t *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_mul(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_div (rop, op1, op2)
	dpe_t *	rop
	dpe_t *	op1
	dpe_t *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_div(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_sqrt (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_sqrt(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_mul_ui (rop, op1, op2)
	dpe_t *	rop
	dpe_t *	op1
	unsigned long	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_mul_ui(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_mul_2exp (rop, op1, op2)
	dpe_t *	rop
	dpe_t *	op1
	unsigned long	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_mul_2exp(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_div_2exp (rop, op1, op2)
	dpe_t *	rop
	dpe_t *	op1
	unsigned long	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_div_2exp(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_div_ui (rop, op1, op2)
	dpe_t *	rop
	dpe_t *	op1
	unsigned long	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_div_ui(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
XS_dpe_get_si_exp (x, op)
	SV *	x
	dpe_t *	op

int
XS_dpe_out_str (stream, op)
	FILE *	stream
	dpe_t *	op

int
_dpe_out_str_perlio (stream, op)
	PerlIO *	stream
	dpe_t *	op

SV *
XS_dpe_inp_str (rop, stream)
	dpe_t *	rop
	FILE *	stream

void
XS_dpe_dump (op)
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_dump(op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
XS_dpe_zero_p (op)
	dpe_t *	op

int
XS_dpe_cmp (op1, op2)
	dpe_t *	op1
	dpe_t *	op2

int
XS_dpe_cmp_d (op, d)
	dpe_t *	op
	double	d

int
XS_dpe_cmp_ui (op, d)
	dpe_t *	op
	unsigned long	d

int
XS_dpe_cmp_si (op, d)
	dpe_t *	op
	long	d

void
XS_dpe_round (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_round(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_frac (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_frac(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_floor (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_floor(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_ceil (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_ceil(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
XS_dpe_swap (rop, op)
	dpe_t *	rop
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        XS_dpe_swap(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
DESTROY (p)
	dpe_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_with_gmp_support ()


SV *
_overload_add (a, b, third)
	SV *	a
	SV *	b
	SV *	third

SV *
_overload_mul (a, b, third)
	SV *	a
	SV *	b
	SV *	third

SV *
_overload_div (a, b, third)
	SV *	a
	SV *	b
	SV *	third

SV *
_overload_sub (a, b, third)
	SV *	a
	SV *	b
	SV *	third

int
_overload_equiv (a, b, third)
	SV *	a
	SV *	b
	SV *	third

int
_overload_not_equiv (a, b, third)
	SV *	a
	SV *	b
	SV *	third

int
_overload_gt (a, b, third)
	SV *	a
	SV *	b
	SV *	third

int
_overload_gte (a, b, third)
	SV *	a
	SV *	b
	SV *	third

int
_overload_lt (a, b, third)
	SV *	a
	SV *	b
	SV *	third

int
_overload_lte (a, b, third)
	SV *	a
	SV *	b
	SV *	third

SV *
_overload_spaceship (a, b, third)
	SV *	a
	SV *	b
	SV *	third

SV *
_overload_sqrt (a, b, third)
	dpe_t *	a
	SV *	b
	SV *	third

void
dpe_get_str (op)
	dpe_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dpe_get_str(op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_itsa (a)
	SV *	a

SV *
XS_DPE_MANT (x)
	dpe_t *	x

SV *
XS_DPE_EXP (x)
	dpe_t *	x

int
XS_DPE_SIGN (x)
	dpe_t *	x

int
XS_dpe_str_prec ()


int
_defined_LONGDOUBLE_IS_DOUBLEDOUBLE ()


int
_defined_DPE_USE_DOUBLE ()


int
_defined_DPE_USE_LONGDOUBLE ()


int
_defined_DPE_USE_FLOAT128 ()


int
_defined_DPE_USE_LONG ()


int
_defined_DPE_USE_LONGLONG ()


