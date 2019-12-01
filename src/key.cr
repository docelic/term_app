module TermApp
  record Key,
    sequence : String,
    code : String,
    name : String,
    full : String,
    ctrl : Bool,
    meta : Bool,
    shift : Bool

    #def initialize(@sequence,@code,@name,@full,@ctrl,@meta,@shift)
    #end
  #end
end
