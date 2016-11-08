cmake_minimum_required(VERSION 3.0)
project(cmdtest)

execute_process(
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND ruby bin/cmdtest.rb --shortversion
  OUTPUT_VARIABLE CMDTEST_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )

execute_process(
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND date +%Y%m%d
  OUTPUT_VARIABLE CMDTEST_DATE
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )

set(CPACK_GENERATOR "STGZ;TGZ;TZ;ZIP")
if( ${CMAKE_SYSTEM_NAME} STREQUAL "Linux" )
  set(CPACK_GENERATOR "DEB;${CPACK_GENERATOR}")
endif()

set(CPACK_PACKAGE_VERSION "${CMDTEST_VERSION}.${CMDTEST_DATE}")

set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Johan Holmberg <holmberg556@gmail.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Cmdtest, xUnit style testing of commands")
set(CPACK_PACKAGE_DESCRIPTION "Cmdtest, xUnit style testing of commands ...")

set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "all")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "ruby | ruby-interpreter")

INCLUDE(CPack)

execute_process(
  COMMAND git rev-parse --short HEAD
  OUTPUT_VARIABLE GIT_REV
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )

execute_process(
  COMMAND git show -s --format=%ci HEAD
  OUTPUT_VARIABLE GIT_DATE
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )

message(STATUS "GIT_REV  = '${GIT_REV}'")
message(STATUS "GIT_DATE = '${GIT_DATE}'")

execute_process(
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND ./replace_strings.pl
  "GIT_REV_STRING=${GIT_REV}"
  "GIT_DATE_STRING=${GIT_DATE}"
  "VERSION=${CPACK_PACKAGE_VERSION}"
  bin/cmdtest.rb bin/cmdtest.rb.generated
  )


install(
  FILES
  lib/cmdtest/argumentparser.rb
  lib/cmdtest/baselogger.rb
  lib/cmdtest/cmdeffects.rb
  lib/cmdtest/consolelogger.rb
  lib/cmdtest/fileinfo.rb
  lib/cmdtest/fssnapshot.rb
  lib/cmdtest/junitfile.rb
  lib/cmdtest/junitlogger.rb
  lib/cmdtest/lcs.rb
  lib/cmdtest/methodfilter.rb
  lib/cmdtest/notify.rb
  lib/cmdtest/output.rb
  lib/cmdtest/testcase.rb
  lib/cmdtest/util.rb
  lib/cmdtest/workdir.rb
  DESTINATION lib/ruby/vendor_ruby/cmdtest
  )

install(
  FILES
  doc/cmdtest.html
  COPYING.txt
  README.html
  DESTINATION share/doc/rake
  )

install(
  PROGRAMS
  bin/cmdtest.rb.generated
  DESTINATION bin
  RENAME cmdtest
  )
