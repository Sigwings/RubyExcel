require_relative 'address.rb'
require_relative 'data.rb'
require_relative 'element.rb'
require_relative 'section.rb'

module RubyExcel

  #
  # Example data to use in tests / demos
  #
  
  def self.sample_data
    [
      [ 'Part',  'Ref1', 'Ref2', 'Qty', 'Cost' ],
      [ 'Type1', 'QT1',  '231',  1,     35.15  ], 
      [ 'Type2', 'QT3',  '123',  1,     40     ], 
      [ 'Type3', 'XT1',  '321',  3,     0.1    ], 
      [ 'Type1', 'XY2',  '132',  1,     30.00  ], 
      [ 'Type4', 'XT3',  '312',  2,     3      ], 
      [ 'Type2', 'QY2',  '213',  1,     99.99  ], 
      [ 'Type1', 'QT4',  '123',  2,     104    ]
    ]
  end
  
  #
  # Shortcut to create a Sheet with example data
  #
  
  def self.sample_sheet
    Workbook.new.load RubyExcel.sample_data
  end
 
end