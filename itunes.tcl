package require tdom

set doc [dom parse [read stdin]]
set root [$doc documentElement]
set location_nodes [$root selectNodes {/plist/dict/dict/dict/key[text()='Location']}]
# for each location node...
foreach location_node $location_nodes {
	if {[catch {set location_string_node [$location_node nextSibling]}]} {
		continue
	}
	set location_name [$location_string_node text]
	# does it have spaces(%20) _after_ the iTunes%20Music bit?  
	# if so, look for others with the same name and those replaced with underscores
	# if any of those exist, replace this one with the underscored version and removed the others
	set location_name_list [split $location_name /]
	set new_location_name ""
	set replace 0
	set has_spaces 0
	foreach location_name_list_element $location_name_list {
		if {$replace} {
			if {!$has_spaces && [string match "*%20*" $location_name_list_element]} {
				set has_spaces 1
			}
			set new_location_name "$new_location_name/[string map {%20 _} $location_name_list_element]"
		} else {
			if {$new_location_name == ""} {
				set new_location_name "$location_name_list_element"
			} else {
				set new_location_name "$new_location_name/$location_name_list_element"
			}
		}
		if {$location_name_list_element == "iTunes%20Music"} {
			set replace 1
		}
	}
	if {$has_spaces} {
		# find all other nodes with the new underscored name
		set xpathreq "/plist/dict/dict/dict/string\[text()=\"$new_location_name\"\]"
		set new_named_nodes [$root selectNodes $xpathreq]
		set found 0
		foreach new_named_node $new_named_nodes {
			set found 1
			set new_named_node_parent_node [$new_named_node parentNode]
			$new_named_node_parent_node delete
		}
		if {!$found} {
			unset location_name_list replace new_location_name location_name location_string_node has_spaces found new_named_nodes xpathreq
			continue
		} else {
			# We have found a location to replace, so update the original location value
			set location_node_child_node [[$location_node nextSibling] childNodes]
			if {[llength $location_node_child_node] == 1} {
				$location_node_child_node nodeValue $new_location_name
			} else {
				puts "PROBLEM WITH $new_location_name"
				exit
			}
		}
		unset new_named_nodes xpathreq new_named_node
	} 
	unset location_name_list replace new_location_name location_name location_string_node has_spaces
}

# output the final doc
puts [$doc asXML]
