# - Find GNU gettext tools
# This module looks for the GNU gettext tools. This module defines the
# following values:
#  GETTEXT_MSGMERGE_EXECUTABLE: the full path to the msgmerge tool.
#  GETTEXT_MSGFMT_EXECUTABLE: the full path to the msgfmt tool.
#  GETTEXT_FOUND: True if gettext has been found.
#  GETTEXT_VERSION_STRING: the version of gettext found (since CMake 2.8.8)
#
# Additionally it provides the following macros:
# GETTEXT_CREATE_TRANSLATIONS ( outputFile [ALL] file1 ... fileN )
#    This will create a target "translations" which will convert the
#    given input po files into the binary output mo file. If the
#    ALL option is used, the translations will also be created when
#    building the default target.
# GETTEXT_PROCESS_POT( <potfile> [ALL] [INSTALL_DESTINATION <destdir>] LANGUAGES <lang1> <lang2> ... )
#     Process the given pot file to mo files.
#     If INSTALL_DESTINATION is given then automatically install rules will be created,
#     the language subdirectory will be taken into account (by default use share/locale/).
#     If ALL is specified, the pot file is processed when building the all traget.
#     It creates a custom target "potfile".
# GETTEXT_PROCESS_PO_FILES( <lang> [ALL] [INSTALL_DESTINATION <dir>] PO_FILES <po1> <po2> ... )
#     Process the given po files to mo files for the given language.
#     If INSTALL_DESTINATION is given then automatically install rules will be created,
#     the language subdirectory will be taken into account (by default use share/locale/).
#     If ALL is specified, the po files are processed when building the all traget.
#     It creates a custom target "pofiles".

#=============================================================================
# Copyright 2007-2009 Kitware, Inc.
# Copyright 2007      Alexander Neundorf <neundorf@kde.org>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

find_program(GETTEXT_MSGMERGE_EXECUTABLE msgmerge)

find_program(GETTEXT_MSGFMT_EXECUTABLE msgfmt)

if(GETTEXT_MSGMERGE_EXECUTABLE)
   execute_process(COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --version
                  OUTPUT_VARIABLE gettext_version
                  ERROR_QUIET
                  OUTPUT_STRIP_TRAILING_WHITESPACE)
   if (gettext_version MATCHES "^msgmerge \\(.*\\) [0-9]")
      string(REGEX REPLACE "^msgmerge \\([^\\)]*\\) ([0-9\\.]+[^ \n]*).*" "\\1" GETTEXT_VERSION_STRING "${gettext_version}")
   endif()
   unset(gettext_version)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/FindPackageHandleStandardArgs.cmake)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Gettext
                                  REQUIRED_VARS GETTEXT_MSGMERGE_EXECUTABLE GETTEXT_MSGFMT_EXECUTABLE
                                  VERSION_VAR GETTEXT_VERSION_STRING)

include(${CMAKE_CURRENT_LIST_DIR}/CMakeParseArguments.cmake)

function(_GETTEXT_GET_UNIQUE_TARGET_NAME _name _unique_name)
   set(propertyName "_GETTEXT_UNIQUE_COUNTER_${_name}")
   get_property(currentCounter GLOBAL PROPERTY "${propertyName}")
   if(NOT currentCounter)
      set(currentCounter 1)
   endif()
   set(${_unique_name} "${_name}_${currentCounter}" PARENT_SCOPE)
   math(EXPR currentCounter "${currentCounter} + 1")
   set_property(GLOBAL PROPERTY ${propertyName} ${currentCounter} )
endfunction()

macro(GETTEXT_CREATE_TRANSLATIONS _potFile _firstPoFileArg)
   # make it a real variable, so we can modify it here
   set(_firstPoFile "${_firstPoFileArg}")

   set(_gmoFiles)
   get_filename_component(_potName ${_potFile} NAME)
   string(REGEX REPLACE "^(.+)(\\.[^.]+)$" "\\1" _potBasename ${_potName})
   get_filename_component(_absPotFile ${_potFile} ABSOLUTE)

   set(_addToAll)
   if(${_firstPoFile} STREQUAL "ALL")
      set(_addToAll "ALL")
      set(_firstPoFile)
   endif()

   foreach (_currentPoFile ${_firstPoFile} ${ARGN})
      get_filename_component(_absFile ${_currentPoFile} ABSOLUTE)
      get_filename_component(_abs_PATH ${_absFile} PATH)
      get_filename_component(_lang ${_absFile} NAME_WE)
      set(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_lang}.gmo)

      add_custom_command(
         OUTPUT ${_gmoFile}
         COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --quiet --update --backup=none -s ${_absFile} ${_absPotFile}
         COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${_gmoFile} ${_absFile}
         DEPENDS ${_absPotFile} ${_absFile}
      )

      install(FILES ${_gmoFile} DESTINATION share/locale/${_lang}/LC_MESSAGES RENAME ${_potBasename}.mo)
      set(_gmoFiles ${_gmoFiles} ${_gmoFile})

   endforeach ()

   if(NOT TARGET translations)
      add_custom_target(translations)
   endif()

  _GETTEXT_GET_UNIQUE_TARGET_NAME(translations uniqueTargetName)

   add_custom_target(${uniqueTargetName} ${_addToAll} DEPENDS ${_gmoFiles})

   add_dependencies(translations ${uniqueTargetName})

endmacro()


function(GETTEXT_PROCESS_POT_FILE _potFile)
   set(_gmoFiles)
   set(_options ALL)
   set(_oneValueArgs INSTALL_DESTINATION)
   set(_multiValueArgs LANGUAGES)

   CMAKE_PARSE_ARGUMENTS(_parsedArguments "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" ${ARGN})

   get_filename_component(_potName ${_potFile} NAME)
   string(REGEX REPLACE "^(.+)(\\.[^.]+)$" "\\1" _potBasename ${_potName})
   get_filename_component(_absPotFile ${_potFile} ABSOLUTE)

   foreach (_lang ${_parsedArguments_LANGUAGES})
      set(_poFile  "${CMAKE_CURRENT_BINARY_DIR}/${_lang}.po")
      set(_gmoFile "${CMAKE_CURRENT_BINARY_DIR}/${_lang}.gmo")

      add_custom_command(
         OUTPUT "${_poFile}"
         COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --quiet --update --backup=none -s ${_poFile} ${_absPotFile}
         DEPENDS ${_absPotFile}
      )

      add_custom_command(
         OUTPUT "${_gmoFile}"
         COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${_gmoFile} ${_poFile}
         DEPENDS ${_absPotFile} ${_poFile}
      )

      if(_parsedArguments_INSTALL_DESTINATION)
         install(FILES ${_gmoFile} DESTINATION ${_parsedArguments_INSTALL_DESTINATION}/${_lang}/LC_MESSAGES RENAME ${_potBasename}.mo)
      endif()
      list(APPEND _gmoFiles ${_gmoFile})
   endforeach ()

  if(NOT TARGET potfiles)
     add_custom_target(potfiles)
  endif()

  _GETTEXT_GET_UNIQUE_TARGET_NAME( potfiles uniqueTargetName)

   if(_parsedArguments_ALL)
      add_custom_target(${uniqueTargetName} ALL DEPENDS ${_gmoFiles})
   else()
      add_custom_target(${uniqueTargetName} DEPENDS ${_gmoFiles})
   endif()

   add_dependencies(potfiles ${uniqueTargetName})

endfunction()


function(GETTEXT_PROCESS_PO_FILES _lang)
   set(_options ALL)
   set(_oneValueArgs INSTALL_DESTINATION)
   set(_multiValueArgs PO_FILES)
   set(_gmoFiles)

   CMAKE_PARSE_ARGUMENTS(_parsedArguments "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" ${ARGN})

   foreach(_current_PO_FILE ${_parsedArguments_PO_FILES})
      get_filename_component(_name ${_current_PO_FILE} NAME)
      string(REGEX REPLACE "^(.+)(\\.[^.]+)$" "\\1" _basename ${_name})
      set(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_basename}.gmo)
      add_custom_command(OUTPUT ${_gmoFile}
            COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${_gmoFile} ${_current_PO_FILE}
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            DEPENDS ${_current_PO_FILE}
         )

      if(_parsedArguments_INSTALL_DESTINATION)
         install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${_basename}.gmo DESTINATION ${_parsedArguments_INSTALL_DESTINATION}/${_lang}/LC_MESSAGES/ RENAME ${_basename}.mo)
      endif()
      list(APPEND _gmoFiles ${_gmoFile})
   endforeach()


  if(NOT TARGET pofiles)
     add_custom_target(pofiles)
  endif()

  _GETTEXT_GET_UNIQUE_TARGET_NAME( pofiles uniqueTargetName)

   if(_parsedArguments_ALL)
      add_custom_target(${uniqueTargetName} ALL DEPENDS ${_gmoFiles})
   else()
      add_custom_target(${uniqueTargetName} DEPENDS ${_gmoFiles})
   endif()

   add_dependencies(pofiles ${uniqueTargetName})

endfunction()
