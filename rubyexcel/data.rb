module RubyExcel

require_relative 'address.rb'

  class Data
    attr_reader :rows, :cols
    attr_accessor :sheet
    alias parent sheet
    
    include Address
    
    def initialize( sheet, input_data )
      ( input_data.kind_of?( Array ) &&  input_data.all? { |el| el.kind_of?( Array ) } ) or fail ArgumentError, 'Input must be Array of Arrays'
      @sheet = sheet
      @data = input_data.dup
      calc_dimensions
    end
    
    def all
      @data.dup
    end
    
    def append( multi_array )
      @data << multi_array
      calc_dimensions
    end
    
    def colref_by_header( header )
      sheet.header_rows > 0 or fail NoMethodError, 'No header rows present'
      @data[ 0..sheet.header_rows-1 ].each { |r| idx = r.index( header ); return col_letter( idx+1 ) if idx }
      fail IndexError, "#{ header } is not a valid header"
    end
    
    def compact!
      compact_columns!
      compact_rows!
    end
    
    def compact_columns!
      ensure_shape
      @data = @data.transpose.delete_if { |ar| ar.all? { |el| el.to_s.empty? } || ar.empty? }.transpose
      calc_dimensions
    end
    
    def compact_rows!
      @data.delete_if { |ar| ar.all? { |el| el.to_s.empty? } || ar.empty? }
      calc_dimensions
    end
    
    def delete( object )
      case object
      when Row
        @data.slice!( object.idx - 1 )
      when Column
        idx = col_index( object.idx ) - 1
        @data.each { |r| r.slice! idx }
      when Element
        addresses = expand( object.address )
        indices = [ address_to_indices( addresses.first.first ), address_to_indices( addresses.last.last ) ].flatten.map { |n| n-1 }
        @data[ indices[0]..indices[2] ].each { |r| r.slice!( indices[1], indices[3] - indices[1] + 1 ) }
        @data.delete_if.with_index { |r,i| r.empty? && i.between?( indices[0], indices[2] ) }
      else
        fail NoMethodError, "#{ object.class } is not supported"
      end
      calc_dimensions
    end
    
    def delete_column( ref )
      delete( Column.new( sheet, ref ) )
      calc_dimensions
    end
  
    def delete_row( ref )
      delete( Row.new( sheet, ref ) )
      calc_dimensions
    end
    
    def delete_range( ref )
      delete( Element.new( sheet, ref ) )
      calc_dimensions
    end
    
    def dup
      Data.new( sheet, @data.map(&:dup) )
    end
    
    def empty?
      no_headers.empty?
    end

    def filter!( header )
      hrows = sheet.header_rows
      idx = col_index( hrows > 0 ? colref_by_header( header ) : header )
      @data = @data.select.with_index { |row, i| hrows > i || yield( row[ idx -1 ] ) }
      calc_dimensions
    end
  
    def get_columns!( *headers )
      headers = headers.flatten
      hrow = sheet.header_rows - 1
      ensure_shape
      @data = @data.transpose.select{ |col| headers.include?( col[hrow] ) }
      @data = @data.sort_by{ |col| headers.index( col[hrow] ) || col[hrow] }.transpose
      calc_dimensions
    end
    
    def insert_columns( before, number=1 )
      a = Array.new( number, nil )
      before = col_index( before ) - 1
      @data.map! { |row|  row.insert( before, *a ) }
      calc_dimensions
    end
    
    def insert_rows( before, number=1 )
      @data = @data.insert( ( col_index( before ) - 1 ), *Array.new( number, [nil] ) )
      calc_dimensions
    end
    
    def no_headers
      @data[ sheet.header_rows..-1 ]
    end
    
    def read( addr )
      row_idx, col_idx = address_to_indices( addr )
      @data[ row_idx-1 ][ col_idx-1 ]
    end
    alias [] read
    
    def reverse_columns!
      ensure_shape
      @data = @data.transpose.reverse.transpose
    end
    
    def reverse_rows!
      @data = skip_headers &:reverse
    end

    def sort!( &block )
      @data = skip_headers { |d| d.sort( &block ) }; self
    end
    
    def sort_by!( &block )
      @data = skip_headers { |d| d.sort_by( &block ) }
    end
    
    def uniq!( header )
      column = col_index( colref_by_header( header ) )
      @data = @data.uniq { |row| row[ column - 1 ] }
      calc_dimensions
    end
    alias unique! uniq!
    
    def write( addr, val )
      row_idx, col_idx = address_to_indices( addr )
      ( row_idx - rows ).times { @data << [] }
      @data[ row_idx-1 ][ col_idx-1 ] = val
      calc_dimensions
    end
    alias []= write

    include Enumerable
    
    def each
      @data.each { |ar| yield ar }
    end
    
    private
    
    def calc_dimensions
      @rows, @cols = @data.length, @data.max_by { |row| row.length }.length; self
    end
    
    def ensure_shape
      calc_dimensions
      @data = @data.map { |ar| ar.length == cols ? ar : ar + Array.new( cols - ar.length, nil) }
    end
    
    def skip_headers
      hr = sheet.header_rows
      if hr > 0
        block_given? ? @data[ 0..hr - 1 ] + yield( @data[ hr..-1 ] ) : @data[ hr..-1 ]
      else
        block_given? ? yield( @data ) : @data 
      end 
    end
  
  end

end