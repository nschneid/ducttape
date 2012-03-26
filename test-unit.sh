#!/usr/bin/env bash
set -eo pipefail

JAVA_OPTS="-XX:MaxJavaStackTraceDepth=7" scala -cp lib/scalatest-1.6.1.jar:bin/ \
    org.scalatest.tools.Runner \
    -p . -o \
    -s PackedDagWalkerTest \
    -s UnpackedDagWalkerTest
