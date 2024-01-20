#!/usr/bin/env bash

#mkdir 01.raw_data/ 00.mapping/
echo "Below are the sample names for config.yaml"
SAMPLES=($(ls -1 01.raw_data/ | grep -Ev "MANIFEST|seq" - |sort -V)) && \
 (echo -ne '[';echo ${SAMPLES[*]} | sed -E 's/ /, /g' | sed -E 's/([A-Za-z0-9_-]+)/"\1"/g'; echo -e ']')
