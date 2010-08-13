Simple Search - Easy ActiveRecord searching with hashes
=======================================================

There is a newer project, scoped_search, which I would recommend instead.  This exists for backwards compatibility.
See: [Scoped Search](http://techblog.floorplanner.com/2008/07/26/easy-search-with-activerecord/)

This gem is incompatible with the "simple_search" gem.

Example
-------

    require 'simple_search'
    
    class User < ActiveRecord::Base
    end

    User.simple_search(:name => 'bob')
    User.simple_search_like('bob', [:name, :description])

Author
------
Copyright (c) 2010 [Nate Wiger](http://nateware.com). See LICENSE for details.
