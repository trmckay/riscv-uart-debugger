AC_INIT([rvdb], [1.4])

AM_INIT_AUTOMAKE

AC_PROG_RANLIB

AC_LANG(C)
AC_PROG_CC

AC_CONFIG_FILES([Makefile src/Makefile man/Makefile])

PKG_CHECK_MODULES([DEPS], [glib-2.0 >= 2.24.1])
PKG_CHECK_MODULES([DEPS], [readline >= 8.1.0])

AC_OUTPUT
