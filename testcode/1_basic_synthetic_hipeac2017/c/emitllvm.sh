#!/bin/bash

clang -O1 -S -emit-llvm illustration.oneFuncOnly.c -o illustration.c.oneFuncOnly.ll

