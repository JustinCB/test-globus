#!/usr/bin/wish
# 
# Copyright 2010-2013 University of Chicago
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Globus Connect GUI

if { [catch {package require csv}] } {
    puts "Tcllib not found."
    puts "The Globus Connect Personal GUI requires Tcllib."
    puts "Please install Tcllib using your distributions package management system."
    puts "On Debian based systems (e.g. Ubunutu):"
    puts "  apt-get install tcllib"
    puts "On Redhat based systems (e.g. CentOS, Fedora):"
    puts "  yum install tcllib"
    puts " Note: if you encounter an error about tcllib not being"
    puts " available, it can be found here and installed manually:"
    puts " http://www.tcl.tk/software/tcllib/"
    puts "You may also run Globus Connect Personal in CLI mode."
    puts "Please use the -help option or visit http://globus.org/globus-connect-personal/"
    puts "for more information."
    exit 1
}

image create photo .igonew -format GIF -file gonew.gif
image create photo .stat_red -format GIF -file red.gif
image create photo .stat_yel -format GIF -file yellow.gif
image create photo .stat_gre -format GIF -file green.gif

global home
global config
set home $env(HOME)
global connected idle debug
set connected 0
set dir [file dirname [info script]]
set idle 500			;# 500 ms
source [file join $dir accessPaths.tcl]
global configPaths
global forward
set forward "forward"

proc on_quit { widget } {
  if { $widget eq "." } {
    global connected
	  if { $connected } {
	    stop_gc_py
    }
  }
}

proc load_path_config {} {
  global config
  global configPaths
  set configPaths ""

  if { [file exists $config/lta/config-paths] } {
    set f [open $config/lta/config-paths]

    while { [gets $f line] >= 0 } {
      if { [string length $line] > 0 } {
        lappend configPaths [::csv::split $line]
      }
    }
  } else {
    # default to home directory if no path config was found
    lappend configPaths {{~/} {0} {1}}
    write_path_config $configPaths
  }
}

proc write_path_config { paths } {
    global config
    set f [open $config/lta/config-paths.tmp w]
    puts $f [::csv::joinlist $paths]
    close $f
    file rename -force $config/lta/config-paths.tmp $config/lta/config-paths
    file delete $config/lta/config-paths.tmp
}

proc start_gc_py {} {
    global config
    global gc_pipe
    global forward

    # rp is passed via the config file, the NONE argument is a hack to
    # workaround the positional arguments and tcl's refusal to pass
    # empty string args like I expect.
    if { [ catch { set gc_pipe [ open "| ./gc-ctrl.py -debug NONE NONE $config $forward" ] } fid ] } {
	puts "Error: cannot execute gc-ctrl.py: $fid"
	exit 1
    }
    fconfigure $gc_pipe -blocking 0
}

proc stop_gc_py {} {
    global gc_pipe
    fconfigure $gc_pipe -blocking 1
    catch { close $gc_pipe } status
}

proc main_loop {} {
    global forward idle gc_pipe debug
    while { [ gets $gc_pipe gcline ] >= 0 } {
	if { [ winfo exists .console ] } {
	    .console.frame.foutput.toutput insert end $gcline\n
	    .console.frame.foutput.toutput yview moveto 1
	}
	if { [ string match "#gridftp 0*" $gcline ] } {
	    .lgridftpserverinfo configure -text "Idle"
	    .lstatserver configure -image .stat_yel
	} elseif { [ string match "#gridftp*" $gcline ] } {
	    .lgridftpserverinfo configure -text "Active"
	    .lstatserver configure -image .stat_gre
	} elseif { [ string match "#relaytool connected*" $gcline ] } {
	    .lglobusonlineinfo configure -text "Connected"
	    .lstatglobus configure -image .stat_gre
	} elseif { [ string match "#relaytool connecting*" $gcline ] } {
            .lstatglobus configure -image .stat_yel
	    if { [ string match "forward" $forward ] } {
              .lglobusonlineinfo configure -text "Connecting"
            } else {
              .lglobusonlineinfo configure -text "Paused"
            }
	} elseif { [ string match "#relaytool n/a*" $gcline ] } {
	    .lglobusonlineinfo configure -text "Disconnected"
	    .lstatglobus configure -image .stat_red
	}
	#puts $gcline
    }
    if { [ eof $gc_pipe ] } {
	fconfigure $gc_pipe -blocking 1
	set status [ catch { close $gc_pipe } result ]
	if { $status != 0 } {
	    tk_messageBox -icon error -type ok -message $result
	}
	connect
    } else {
	after $idle main_loop
    }
}

proc connect {} {
    global connected idle
    if { $connected } {
	set connected 0
	stop_gc_py
	.lstatglobus configure -image .stat_red
	.lglobusonlineinfo configure -text "Disconnected"
	.lstatserver configure -image .stat_yel
	.lgridftpserverinfo configure -text "Idle"
	.bconnect configure -text "Connect"
	after cancel main_loop
    } else {
	set connected 1
	start_gc_py

	.bconnect configure -text "Disconnect"
	after $idle main_loop
    }
}

proc log {output} {
  set outfile [open log.txt "a"]
  puts $outfile $output
  close $outfile
}

proc pause_transfers {} {
  global idle connected forward
  if { $connected } {
    #log "current state: $forward"
    if { [ string compare $forward "forward" ] == 0 } {
      .bpause configure -text "Unpause"
      stop_gc_py
      after cancel main_loop
      set forward "paused"
      after 3000
      start_gc_py
      after $idle main_loop
    } else {
      .bpause configure -text "Pause"
      stop_gc_py
      after cancel main_loop
      set forward "forward"
      after 3000
      start_gc_py
      after $idle main_loop
    }
  } else {
    #do nothing
  }
}

proc need_setup {} {
    global config
    if { [ file exists $config/lta/config ] \
	    && [ file exists $config/lta/gridmap ] } {
	return 0
    }
    return 1
}

proc setup {} {
	global home
    global config
    set code [ .setup.frame.register.ecode get ]
    set server [ .setup.frame.register.eserver get ]
    if { [ string length $code ] != 36 } {
	tk_messageBox -icon error -type ok -message "Incorrect Security Code"
    } elseif { [ string length $server ] == 0 } {
	tk_messageBox -icon error -type ok -message "Incorrect Server Name"
    } else {
	create_register_dialog
	catch { exec mkdir $config }
	set ::env(GCP_RELAY_SERVER) $server
	set pipe [ open "| ./gc-ctrl.py -setup $code $config" ]
	set data [ read $pipe ]
	destroy_register_dialog
	if { [ catch {close $pipe} error ] } {
	    create_error_dialog $data
	    grab .setup
	} else {
	    destroy_setup_dialog
	    tk_messageBox -icon info -type ok -message "Registered successfully"
	    .bconnect configure -state normal
      # load configuration written by setup.py
	    connect
	}
    }
}

proc create_console_dialog {} {
    toplevel .console
    wm title .console "Globus Connect Personal Console"

    frame .console.frame -pady 10 -padx 10 -relief raised -borderwidth 1
    label .console.frame.linfo -text "The status of a connection to Globus Online and GridFTP transfers"

    frame .console.frame.foutput
    text .console.frame.foutput.toutput -yscrollcommand ".console.frame.foutput.soutput set" -wrap word -width 80 -height 20 -background white
    scrollbar .console.frame.foutput.soutput -command ".console.frame.foutput.toutput yview" -orient v
    grid .console.frame.foutput.toutput -row 0 -column 0
    grid .console.frame.foutput.soutput -row 0 -column 1 -sticky ns

    button .console.frame.bok -text "OK" -width 8 -command destroy_console_dialog
    pack .console.frame.linfo -pady 5
    pack .console.frame.foutput -pady 5
    pack .console.frame.bok -pady 5
    pack .console.frame
    wm resizable .console 0 0
    raise .console
#    tkwait window .console
}

proc destroy_console_dialog {} {
    destroy .console
}

proc create_error_dialog { data } {
    toplevel .error
    wm title .error "Error"
    grab .error

    frame .error.frame -pady 10 -padx 10 -relief raised -borderwidth 1
    label .error.frame.linfo -text "There was an error running setup. The output is below:"
    text .error.frame.toutput -wrap word -width 80 -height 20 -background white
    .error.frame.toutput insert end $data
    button .error.frame.bok -text "OK" -width 8 -command destroy_error_dialog
    pack .error.frame.linfo -pady 5
    pack .error.frame.toutput -pady 5
    pack .error.frame.bok -pady 5
    pack .error.frame
    wm resizable .error 0 0
    raise .error
    tkwait window .error
}

proc destroy_error_dialog {} {
    destroy .error
}

proc create_about_dialog {} {
    toplevel .about
    wm title .about "About"
    grab .about

    frame .about.frame -pady 10 -padx 10 -relief raised -borderwidth 1
    # TODO: get the version from common location, or pass it in as arg
    label .about.frame.linfo -text "Globus Connect Personal 2.3.5"
    label .about.frame.lgonew -image .igonew
    frame .about.frame.empty -relief sunken -borderwidth 1 -height 2
    button .about.frame.bok -text "OK" -width 8 -command destroy_about_dialog
    grid .about.frame.linfo -row 0 -column 0
    grid .about.frame.lgonew -row 0 -column 1
    grid .about.frame.empty -row 1 -column 0 -columnspan 2 -pady 10 -sticky ew
    grid .about.frame.bok -row 2 -column 0 -columnspan 2
    pack .about.frame
    wm resizable .about 0 0
    raise .about
}

proc destroy_about_dialog {} {
    destroy .about
}

proc create_register_dialog {} {
    toplevel .register
    wm title .register "Globus Connect Personal"
    grab .register

    frame .register.frame -relief raised -padx 30 -pady 30 -borderwidth 1
    label .register.frame.linfo1 -text "Registering the Globus Connect Personal..."
    label .register.frame.linfo2 -text "Please wait"
    grid .register.frame.linfo1 -row 0 -column 0 -sticky nsw
    grid .register.frame.linfo2 -row 1 -column 0 -sticky nsw
    pack .register.frame
    wm resizable .register 0 0
    raise .register
    tkwait visibility .register.frame.linfo1
}

proc destroy_register_dialog {} {
    destroy .register
}

proc create_preferences_dialog {} {
    toplevel .setup
    wm title .setup "Globus Connect Personal - Initial Setup"
    grab .setup

    frame .setup.frame -pady 10 -padx 10 -relief raised -borderwidth 1
    frame .setup.frame.top
    label .setup.frame.top.linitial -text "Initial Setup" -font "Helvetica 14 bold"
    label .setup.frame.top.linfo1 -text "Please type or paste your security code into the field below"
    label .setup.frame.top.linfo2 -text "and click 'OK' when finished"
    label .setup.frame.top.lgonew -image .igonew
    grid .setup.frame.top.linitial -row 0 -column 0 -columnspan 2 -padx 5 -sticky w
    grid .setup.frame.top.linfo1 -row 1 -column 0 -padx 5 -sticky sw
    grid .setup.frame.top.linfo2 -row 2 -column 0 -padx 5 -sticky nw
    grid .setup.frame.top.lgonew -row 1 -column 1 -rowspan 2 -padx 5 -sticky nsew
    grid rowconfigure .setup.frame.top {0 1 2} -weight 1
    grid columnconfigure .setup.frame.top {0 1} -weight 1

    frame .setup.frame.register
    label .setup.frame.register.lcode -text "Setup Key:"
    label .setup.frame.register.lserver -text "Server:"
    entry .setup.frame.register.ecode -width 50 -background white
    grid .setup.frame.register.lcode -row 0 -column 0 -pady 5 -padx 5 -sticky nsw
    grid .setup.frame.register.ecode -row 0 -column 1 -pady 5 -padx 5 -sticky ew
    grid rowconfigure .setup.frame.register {0} -weight 1
    grid columnconfigure .setup.frame.register {0 1} -weight 1

    frame .setup.frame.fempty -relief sunken -borderwidth 1 -height 2 -width 300

    button .setup.frame.bok -text "OK" -width 8 -command "setup"

    grid .setup.frame.top -sticky nsew
    grid .setup.frame.register -pady 5 -sticky nsew
    grid .setup.frame.fempty -pady 10 -padx 5 -sticky nsew
    grid .setup.frame.bok -pady 5 -padx 7 -sticky e
    pack .setup.frame
    wm resizable .setup 0 0
}

proc destroy_preferences_dialog {} {
    destroy .setup
}
proc create_setup_dialog {} {
    toplevel .setup
    wm title .setup "Globus Connect Personal - Initial Setup"
    grab .setup

    frame .setup.frame -pady 10 -padx 10 -relief raised -borderwidth 1
    frame .setup.frame.top
    label .setup.frame.top.linitial -text "Initial Setup" -font "Helvetica 14 bold"
    label .setup.frame.top.linfo1 -text "Please type or paste your security code into the field below"
    label .setup.frame.top.linfo2 -text "and click 'OK' when finished"
    label .setup.frame.top.lgonew -image .igonew
    grid .setup.frame.top.linitial -row 0 -column 0 -columnspan 2 -padx 5 -sticky w
    grid .setup.frame.top.linfo1 -row 1 -column 0 -padx 5 -sticky sw
    grid .setup.frame.top.linfo2 -row 2 -column 0 -padx 5 -sticky nw
    grid .setup.frame.top.lgonew -row 1 -column 1 -rowspan 2 -padx 5 -sticky nsew
    grid rowconfigure .setup.frame.top {0 1 2} -weight 1
    grid columnconfigure .setup.frame.top {0 1} -weight 1

    frame .setup.frame.register
    label .setup.frame.register.lcode -text "Security Code:"
    label .setup.frame.register.lserver -text "Server:"
    entry .setup.frame.register.ecode -width 50 -background white
    entry .setup.frame.register.eserver -width 50 -background white
    .setup.frame.register.eserver insert 0 relay.globusonline.org
    grid .setup.frame.register.lcode -row 0 -column 0 -pady 5 -padx 5 -sticky nsw
    grid .setup.frame.register.ecode -row 0 -column 1 -pady 5 -padx 5 -sticky ew
    grid .setup.frame.register.lserver -row 1 -column 0 -pady 5 -padx 5 -sticky nsw
    grid .setup.frame.register.eserver -row 1 -column 1 -pady 5 -padx 5 -sticky ew
    grid rowconfigure .setup.frame.register {0 1} -weight 1
    grid columnconfigure .setup.frame.register {0 1} -weight 1

    frame .setup.frame.fempty -relief sunken -borderwidth 1 -height 2 -width 300

    button .setup.frame.bok -text "OK" -width 8 -command "setup"

    grid .setup.frame.top -sticky nsew
    grid .setup.frame.register -pady 5 -sticky nsew
    grid .setup.frame.fempty -pady 10 -padx 5 -sticky nsew
    grid .setup.frame.bok -pady 5 -padx 7 -sticky e
    pack .setup.frame
    wm resizable .setup 0 0
    raise .setup
}

proc destroy_setup_dialog {} {
    destroy .setup
}

proc run_browser {url} {
    set browser $::env(BROWSER)
    exec $browser $url
    #https://www.globusonline.org/xfer/ViewTransfers
}

proc start_transfer {} {
    run_browser "https://www.globus.org/xfer/StartTransfer" 
}

proc view_transfer {} {
    run_browser "https://www.globus.org/xfer/ViewTransfers"
}
  
proc create_main_window {} {
    wm title . "Globus Connect Personal"

    bind . <Destroy> {
	on_quit %W
    }
    frame .window -relief raised -borderwidth 1
    frame .menubar -relief raised -borderwidth 1
    menubutton .menubar.file -text "File" -underline 0 -menu .menubar.file.menu
    menubutton .menubar.help -text "Help" -underline 0 -menu .menubar.help.menu
    menu .menubar.file.menu -tearoff 0
    menu .menubar.help.menu -tearoff 0

    if { ![catch { set browser $::env(BROWSER) } fid] } {
      .menubar.file.menu add command -label "Web: Start Transfer" -command start_transfer
      .menubar.file.menu add command -label "Web: View Transfer" -command view_transfer
      .menubar.file.menu add separator
    }

    .menubar.file.menu add separator
    .menubar.file.menu add command -label "Setup" -command create_setup_dialog
    .menubar.file.menu add command -label "Preferences" -command configureAccessPaths 
    .menubar.file.menu add command -label "Console" -command create_console_dialog
    .menubar.file.menu add command -label "Quit" -command exit
    .menubar.help.menu add command -label "About" -command create_about_dialog
    pack .menubar.file -side left
    pack .menubar.help -side right
    
    frame .main -padx 10 -pady 10
    label .lstatglobus -image .stat_red
    label .lstatserver -image .stat_yel
    label .lglobusonline -text "Globus Online:"
    label .lgridftpserver -text "Transfer Status:"
    label .lglobusonlineinfo -text "Disconnected"
    label .lgridftpserverinfo -text "Idle"
    frame .fempty -relief sunken -borderwidth 1 -height 2 -width 300
    button .bconnect -text "Connect" -width 10 -command "connect"
    button .bpause -text "Pause" -width 10 -command "pause_transfers"
    grid .lstatglobus -in .main -row 0 -column 0 -padx 5 -pady 5 -sticky w
    grid .lglobusonline -in .main -row 0 -column 1 -padx 5 -pady 5 -sticky w
    grid .lglobusonlineinfo -in .main -row 0 -column 2 -padx 5 -pady 5 -sticky w
    grid .lstatserver -in .main -row 1 -column 0 -padx 5 -pady 5 -sticky w
    grid .lgridftpserver -in .main -row 1 -column 1 -padx 5 -pady 5 -sticky w
    grid .lgridftpserverinfo -in .main -row 1 -column 2 -padx 5 -pady 5 -sticky w
    grid .fempty -in .main -row 2 -column 0 -columnspan 3 -pady 10 -sticky nsew
    grid .bpause -in .main -row 3 -column 1 -columnspan 3 -sticky e
    grid .bconnect -in .main -row 3 -column 0 -columnspan 1 -sticky w 
    grid rowconfigure .main {0 1 2 3} -weight 1
    grid columnconfigure .main {0 1} -weight 0
    grid columnconfigure .main {2} -weight 1
    pack .menubar -in .window -fill x -expand 1
    pack .main -in .window
    pack .window
    wm resizable . 0 0
    tkwait visibility .
}

set debug $argc

if { $argc == 0 } {
    set config $env(HOME)/.globusonline
} else {
    set config [ lindex $argv 0 ]
}

file mkdir $config/lta
load_path_config

create_main_window

if { [ need_setup ] } {
    .bconnect configure -state disabled
    create_setup_dialog
}
