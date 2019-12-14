require "../src/term_app"

pr = ::TermApp::Data.new

#pr.input.on(::TermApp::DataEvent) { |e|
#  pr.tput.print e.data[...e.len]
#  #pr.tput.sety 10
#  #pr.tput.setx 2
#
#  # Same as:
#  pr.tput.move 10, 2
#}

pr.input.on(::TermApp::KeyPressEvent) { |e|
  puts e.key
  pr.tput.setx 0
}

sleep 10
