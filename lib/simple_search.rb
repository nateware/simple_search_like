module SimpleSearch
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    # Player.simple_search(:filters => {:name => "nwiger"}, :order => 'id')
    # Player.simple_search(params, :order => 'id')
    def simple_search(options={}, extras=nil)
      options.merge!(extras) if extras
      paginate_args = simple_search_conditions(options)

      # retrieve total_count to pass total_entries to paginate
      use_table_name = options[:from] ? options[:from] : table_name
      if paginate_args[:conditions].nil?
        total_count = count(:select => "#{use_table_name}.id",
                            :from => use_table_name)
      else
        total_count = count(:select => "#{use_table_name}.id",
                            :from => use_table_name,
                            :conditions => paginate_args[:conditions], 
                            :joins => paginate_args[:joins], 
                            :include => paginate_args[:include])
      end

      unless paginate_args[:total_entries]
        paginate_args[:per_page] = options[:per_page]
        paginate_args[:total_entries] = total_count
      end

      # bounds check total_entries
      if paginate_args[:total_entries] > total_count
        paginate_args[:total_entries] = total_count
      end
    
      if options[:use_index]
        paginate_args[:from] = "#{use_table_name} USE INDEX (#{options[:use_index]})"
      end
    
      paginate(paginate_args)
    end

    # clean params to prevent SQL injection
    # added default sort_column (id) since if this parameter is not present in the options hash
    # it will generate invalid SQL. If the ORDER BY does not specify a column in the SQL the db will generate:
    # ORA-00936: missing expression:
    def simple_search_conditions(options={}, extras=nil)
      options.merge!(extras) if extras
      paginate_args = {}

      # figure out what table name to use to prefix column names with
      # WOW, ActiveRecord does not properly figure out the table name to use properly in two different cases.
      # 1. Count from a db view counts from the original table name set in 'table_name' when using :from option
      # 2. Find does not prefix the column names correctly when selecting from a db view using the :from option.
      #    Example: SELECT * FROM v_my_table where id = 10 
      #             will actually result in
      #             SELECT * FROM v_my_table where my_table.id = 10    
      # So appears ActiveRecord does not properly prefix the table_name for columns in where conditions when using the :from option properly in all cases    
      use_table_name = options[:from] ? options[:from] : table_name

      if !options[:sort_column].nil?
        paginate_args[:order] = options[:sort_column].to_s.gsub(/\W+/,'')
      else
        paginate_args[:order] = options[:order].nil? ? "#{use_table_name}.id" : options[:order]   # allow :order to be passed explicitly
      end

      if !options[:sort_order].nil?
        paginate_args[:order] += ' ' + options[:sort_order].to_s.gsub(/\W+/,'')
      end

      # extreme sanity checking
      paginate_args[:page] = (options[:page] || 1).to_i
      if paginate_args[:page].nil? or paginate_args[:page] == '' or paginate_args[:page] < 1
        raise "Invalid page '#{paginate_args[:page]}' for #{self.name}.search"
      end

      # default per_page to something sane if unset
      options[:per_page] = (options[:per_page] || 10).to_i
    
      # delete filter options that are blank or nil
      if !options[:filters].nil?
        options[:filters] = options[:filters].delete_if {|k,v| v.nil? || v == ''}

        if options[:conditions].is_a? Array
          conditions = options[:conditions].shift
          bind_vals  = options[:conditions]
        else
          conditions = ''
          bind_vals  = []
        end
              
        options[:filters].each do |filter, value|
          conditions += ' AND ' unless bind_vals.empty?

          # append the proper table name to the column name in where conditions 
          # for handling db views when using the :from option
          if value.is_a? Array # if value passed in an Array using IN instead of = (equal)
            conditions += "#{use_table_name}.#{filter} IN (?)"
          # Need a way to do greater than or less than with dates, so going to follow the convention
          # assume if the name follows the _at ('created_at') it is a date and you want to do a diff conditional check
          elsif /_at$/ =~ filter
            conditions += "#{use_table_name}.#{filter} > ?"
          else
            conditions += "#{use_table_name}.#{filter} = ?"
          end        

          bind_vals << value
        end
                  
         paginate_args[:conditions] = [conditions, *bind_vals]      
      elsif !options[:conditions].nil?
        paginate_args[:conditions] = options[:conditions]
      end

      if !options[:joins].nil?
        paginate_args[:joins] = options[:joins]
      end

      if !options[:include].nil?
        paginate_args[:include] = options[:include]
      end

      if !options[:from].nil?
        paginate_args[:from] = options[:from]
      end

      if !options[:select].nil?
        paginate_args[:select] = options[:select]
      end
    
      # :limit is two places due to a will_paginate workaround - see also simple_search itself
      if !options[:limit].nil?
        if options[:limit] < options[:per_page]
          paginate_args[:per_page] = options[:limit]
          paginate_args[:total_entries] = options[:limit]
        else
          paginate_args[:per_page] = options[:per_page]
          paginate_args[:total_entries] = options[:limit]
        end
      end

      paginate_args
    end

    def simple_search_like(options={}, search_columns_in=%w(name))
      # Accept single column name as a string, or an array of strings with multiple column names
      search_columns = search_columns_in.is_a?(String) ? [ search_columns_in ] : search_columns_in
      # Make sure the programmer got his act together
      if look = options[:search] and look != ''
        look = '' if look =~ /^\s*search\s*/i
        text = '%'+ look.downcase.gsub(/[\'\;]/,'') +'%'

        stmt, bind = [], []
        search_columns.each do |el|
          stmt << "lower(#{el}) like ?"
          bind << text
        end
        simple_search(options.merge(:conditions => ['(' + stmt.join(' OR ') + ')', *bind]))
      else
        # passthru
        simple_search(options)
      end
    end
  end
end

ActiveRecord::Base.extend SimpleSearch::ClassMethods if defined?(ActiveRecord::Base)
