#!/bin/sh
# the next line restarts using wish \
exec wish "$0" ${1+"$@"}

#This code was heavily cribbed from the table demo provided by tablelist

package require tablelist_tile 5.9
#package require tablelist 5.9
proc configureAccessPaths {} {
  # load current value into our temp value
  global tempPaths
  global configPaths
  set tempPaths $configPaths
  toplevel .accessPath
  wm title .accessPath "Access Path Configuration"
  wm geometry .accessPath 80x10
  grab .accessPath

  #
  # Add some entries to the Tk option database
  #
  set dir [file dirname [info script]]
  source [file join $dir option_tile.tcl]
  option add *Tablelist*Spinbox.background		white
  option add *Tablelist*Spinbox.readonlyBackground	white

  #
  # Create the images "checkedImg" and "uncheckedImg", as well as 16 images of
  # names like "img#FF0000", displaying colors identified by names like "red"
  #
  source [file join $dir images.tcl]

  #
  # Improve the window's appearance by using a tile
  # frame as a container for the other widgets
  #
  set f [ttk::frame .accessPath.f]

  #
  # Work around the improper appearance of the tile scrollbars in the aqua theme
  #
  if {[tablelist::getCurrentTheme] eq "aqua"} {
      interp alias {} ttk::scrollbar {} ::scrollbar
  }

  #
  # Create a tablelist widget with editable columns (except the first one)
  #
  global tbl
  set tbl $f.tbl
  tablelist::tablelist $tbl \
      -columns {0 "Directory"       left
	        0 "Shared"	  center
	        0 "Write"		  left } \
      -editstartcommand editStartCmd -editendcommand editEndCmd \
      -height 0 -width 0
  if {[$tbl cget -selectborderwidth] == 0} {
      $tbl configure -spacing 1
  }
  $tbl columnconfigure 0 -width 65 -sortmode ascii -name directory -editable yes \
      -editwindow ttk::entry -sortmode dictionary
  $tbl columnconfigure 1 -name shared -editable yes \
      -editwindow ttk::checkbutton -formatcommand emptyStr
  $tbl columnconfigure 2 -name writeable -editable yes \
      -editwindow ttk::checkbutton -formatcommand emptyStr

  set cancel [ttk::button $f.cancel -text "Cancel" -command destroy_window]
  set save [ttk::button $f.save -text "Save" -command save_config]
  set insert [ttk::button $f.insert -width 1 -text "+" -command insert_row]
  set remove [ttk::button $f.remove -width 1 -text "-" -command remove_row]


  #
  # Manage the widgets
  #
  grid $tbl -row 0 -column 0 -columnspan 4 -sticky ewn 
  grid $insert -row 1 -column 0 -sticky w 
  grid $remove -row 1 -column 0 -sticky w -padx 20 
  grid $save -row 3 -column 3 -sticky w 
  grid $cancel -row 3 -column 3 -sticky e 

  #pack $insert -side right -pady 10 -padx 5
  #pack $tbl -side top -expand yes -fill both

  #pack $cancel -side right -pady 10 -padx 5
  #pack $save -side right 
  pack $f -expand yes -fill both
  wm resizable .accessPath 0 0

  populate $tbl 

}

proc insert_row {} {
  global tbl
  global tempPaths
  $tbl insert end "/path" 
  $tbl cellconfigure end,shared -text "0" -image "uncheckedImg"
  $tbl cellconfigure end,writeable -text "0" -image "uncheckedImg"
  lappend tempPaths {{/path} {0} {0}}
}

proc remove_row {} {
  global tbl
  global tempPaths
  if { ![string equal [$tbl curselection ] ""]} {
    set selection [$tbl curselection]
    $tbl delete $selection $selection
    set tempPaths [lreplace $tempPaths $selection $selection]
  }
}

proc emptyStr val { 
return "" }

proc load_tbl {tbl} {
    global tempPaths

    foreach pathItem $tempPaths {
       # This works because the order of fields in the config file is the
       # same as the order of fields in the UX. If necessary we can re-order
       # by creating a new list out of the elements using lindex.
       $tbl insert end $pathItem
       
       $tbl cellconfigure end,shared -image [expr {[string equal [lindex $pathItem 1]  "1"] ? "checkedImg" : "uncheckedImg"}]
       
       $tbl cellconfigure end,writeable -image [expr {[string equal [lindex $pathItem 2]  "1"] ? "checkedImg" : "uncheckedImg"}]
    }

    #puts $configTagValues
    #puts $tempPaths[expr {[string equal [lindex $pathItem 1]  "yes"] ? "checkedImg" : "uncheckedImg"}]

    #puts "dumping table"
    #puts [$tbl get 0 1000] 
}

proc destroy_window {} {
    global tempPaths
    set tempPaths {}
    destroy .accessPath
} 

proc save_config {} {
    global config
    global connected
    global tempPaths
    global configPaths
    global tbl
    $tbl finishediting
    #puts "Saving configuration"
    write_path_config $tempPaths
    set configPaths $tempPaths
    destroy_window
} 

proc populate {tbl } {
    load_tbl $tbl
}

proc populate_dummy {tbl paths} {
for {set i 0; set n 1} {$i < 5} {set i $n; incr n} {
    $tbl insert end [list "Directory" 0 1]
    set checked "checkedImg"
    set unchecked "uncheckedImg"
    $tbl cellconfigure end,shared -image $unchecked
    $tbl cellconfigure end,writeable -image $checked
}
}

#------------------------------------------------------------------------------
# editStartCmd
#
# Applies some configuration options to the edit window; if the latter is a
# combobox, the procedure populates it.
#------------------------------------------------------------------------------
proc editStartCmd {tbl row col text} {
    set w [$tbl editwinpath]
    #set img [expr {$text ? "uncheckedImg" : "checkedImg"}]

    switch [$tbl columncget $col -name] {
        shared {
            $w configure -command [list $tbl finishediting]
            #$tbl cellconfigure $row,$col -image $img
        }
        writeable {
            $w configure -command [list $tbl finishediting]
        }

    }

    return $text
}

#------------------------------------------------------------------------------
# editEndCmd
#
# Performs a final validation of the text contained in the edit window and gets
# the cell's internal contents.
#------------------------------------------------------------------------------
proc editEndCmd {tbl row col text} {
    global tempPaths
    set actualrow [lindex $tempPaths $row]

    switch [$tbl columncget $col -name] {
	shared {
	    $tbl cellconfigure $row,$col -image [expr {$text ? "checkedImg" : "uncheckedImg"}]
            set tempPaths [lreplace $tempPaths $row $row [list [lindex $actualrow 0] $text [lindex $actualrow 2] ]]
	}
        writeable {
            $tbl cellconfigure $row,$col -image [expr {$text ? "checkedImg" : "uncheckedImg"}] 
            set tempPaths [lreplace $tempPaths $row $row [list [lindex $actualrow 0] [lindex $actualrow 1] $text ]]
 
        }
        directory {
            set tempPaths [lreplace $tempPaths $row $row [list $text [lindex $actualrow 1] [lindex $actualrow 2] ]]
 }

    }

    return $text 
}
