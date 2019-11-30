require "../src/term_app"

pr = ::TermApp::Data.new

pr.input.on(::TermApp::DataEvent) { |e|
  pr.tput.print e.data[...e.len]
  pr.tput.sety 10
  pr.tput.setx 10
}

p :Running

sleep 4
