require_relative 'lib/RubyExcel_Components.rb'
require_relative 'lib/RubyExcel_Advanced.rb'
require_relative 'lib/Excel_Tools.rb'

class Regexp
  def to_proc
    proc { |s| self =~ s.to_s }
  end
end

module RubyExcel

  class Workbook

    def initialize
      @sheets = []
    end
    
    def add( ref=nil )
      case ref
      when nil
        s = Sheet.new( 'Sheet' + ( @sheets.count + 1 ).to_s, self )
      when Sheet
        s = ref
      when String
        s = Sheet.new( ref, self )
      else
        fail TypeError, "Unsupported Type: #{ ref.class }"
      end
      @sheets << s; s
    end
    alias add_sheet add
    
    def delete( ref )
      case ref
      when Fixnum
        @sheets.delete_at( ref - 1 )
      when String
        @sheets.reject! { |s| s.name == ref }
      when Regexp
        @sheets.reject! { |s| s.name =~ ref }
      when Sheet
        @sheets.reject! { |s| s == ref }
      else
        fail ArgumentError, "Unrecognised Argument Type: #{ ref.class }"
      end
    end
    
    def dup
      wb = Workbook.new
      self.each {|s| wb.add s.dup }
      wb
    end
    
    def empty?
      @sheets.empty?
    end
    
    def load( *args )
      add.load( *args )
    end
    
    def sheets( ref=nil )
      return to_enum (:each) if ref.nil?
      ref.is_a?( Fixnum ) ? @sheets[ ref - 1 ] : @sheets.find { |s| s.name =~ /^#{ ref }$/i }
    end
    
    include Enumerable
    
    def each
      return to_enum(:each) unless block_given?
      @sheets.each { |s| yield s }
    end
    
    include Excel_Tools
    
  end

  class Sheet

    attr_reader :data
    attr_accessor :name, :header_rows, :header_cols, :workbook
    
    include Address
    
    def initialize( name, workbook )
      @workbook = workbook
      @name = name
    end

    def[]( addr )
      range( addr ).value
    end

    def []=( addr, val )
      range( addr ).value = val
    end

    def cell( row, col )
      Element.new( self, indices_to_address( row, col ) )
    end
    alias cells cell
    
    def column( index )
      Column.new( self, col_letter( index ) )
    end
    
    def columns( start_column = 'A', end_column = data.cols )
      start_column, end_column = col_letter( start_column ), col_letter( end_column )
      return to_enum(:columns, start_column, end_column) unless block_given?
      ( start_column..end_column ).each { |idx| yield column( idx ) }
    end
    
    def delete
      workbook.delete self
    end
    
    def dup
      Sheet.new( name, workbook ).load( data.dup, header_rows, header_cols )
    end
    
    def inspect
      "#{ self.class }: #{ name }"
    end
    
    def load( input_data, header_rows=1, header_cols=0 )
      @header_rows, @header_cols = header_rows, header_cols
      @data = Data.new( self, input_data )
      self
    end
    
    def range( first_cell, last_cell=nil )
      Element.new( self, 
      ( if last_cell
        last_cell.is_a?( String ) ? ( first_cell + ':' + last_cell ) : "#{ first_cell.address }:#{ last_cell.address }"
      else
        first_cell.is_a?( String ) ? first_cell : first_cell.address
      end ) )
    end

    def row( index )
      Row.new( self, index )
    end
    
    def rows( start_row = 1, end_row = data.rows )
      return to_enum(:rows, start_row, end_row) unless block_given?
      ( start_row..end_row ).each { |idx| yield row( idx ) }
    end
    
    def to_a
      data.all
    end
    
    def to_s
      data.map { |ar| ar.join "\t" }.join $/
    end
    
  end
  
end