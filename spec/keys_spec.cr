require "./spec_helper"
require "../src/keys"

class ClsKeys
  include ::TermApp::Keys
end

describe "Keys" do
  it "has needed regexes" do
    [
      ::TermApp::Keys::MetaKeyCodeAnywhereRegex,
      ::TermApp::Keys::MetaKeyCodeRegex,
      ::TermApp::Keys::FunctionKeyCodeAnywhereRegex,
      ::TermApp::Keys::FunctionKeyCodeRegex,
      ::TermApp::Keys::EscapeCodeAnywhereRegex,
    ].each do |r|
      r.should be_a Regex
    end
  end

  #it "recognizes mouse" do
  #  obj = ClsKeys.new
  #  obj.mouse?("\x1b[1;1;1M").should be_true
  #  obj.mouse?("a").should be_false
  #end
end
