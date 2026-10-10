#!/bin/bash
# PalaceRef pins a release tag, not the branch head, so a rebuild is the same FFmpeg.
GIT_BRANCH="n8.1.3"
# Sourced after the variant: PalaceRef's configure replaces parts of its own.
palaceref_configure
