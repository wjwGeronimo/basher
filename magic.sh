#!/usr/bin/env bash

declare list$1="test"
varname=list$1
echo $varname
eval tmp=\$$varname
tmp=$tmp" beep"

declare list$1="$tmp"
eval tmp2=\$$varname
echo $tmp2
