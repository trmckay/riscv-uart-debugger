#!/bin/sh

set -x
set -e

aclocal
autoconf
automake --add-missing
