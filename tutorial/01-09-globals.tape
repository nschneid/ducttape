# Chapter 1: Basics
# Lesson 9:  Global variables
#
# TODO: Why are these useful?

task hello_global_world :: who=$someone {
  echo hello $who
}

# a block of global variables
# these are variables that should
# be shared among *all* configs
global {
  someone=world
  ducttape_structure=flat
}
